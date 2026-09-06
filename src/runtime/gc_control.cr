# AgentC runtime GC control — the "next level" of the *current* collector, available at
# RUNTIME (no compile flag). Binds the Boehm (bdw-gc) generational/incremental + heap-tuning
# knobs that Crystal doesn't expose, plus scoped helpers to skip collection in known-hot
# sections.
#
# These work with the STOCK compiler today (they only call into the already-linked libgc —
# every symbol below ships in bdw-gc 8.x, which Crystal links). They are a *tuning* layer:
# they configure the collector you already have. The deeper, structural wins (a per-thread /
# concurrent allocator — MMTk/Immix — and a precise moving GC) live in the toolchain fork.
# See docs/performance/MEMORY_AND_GC.md and docs/performance/GC_ROADMAP.md.
#
# Measured reality (Apple M1 Max, see bench/gc_modes_bench.cr + docs/performance/MEMORY_AND_GC.md):
#   * Default Boehm concurrent allocation REGRESSES (~123 Mops 1w -> ~21 Mops 8w): the
#     global alloc lock + stop-the-world pauses, NOT collection frequency.
#   * `without_collection` (GC.disable) removes the *pause* half (~58% of the HTTP MT
#     regression) for a bounded burst; the alloc-lock half remains.
#   * `enable_incremental` is a LATENCY tool, not a throughput one — it adds a write barrier
#     (and pays even single-threaded). Under *concurrent* allocation the mprotect-based dirty
#     barrier is pathological (multi-worker runs failed to finish — see the doc). Use ONLY
#     when p99 pause matters more than ops/sec, and effectively only single-threaded.
#   * Heap-size knobs (`free_space_divisor`, max heap) do NOT relieve the contention; they
#     trade collection frequency for RSS. Exposed here for RSS/footprint control, not speed.
#
# libgc symbols used (all present in bdw-gc 8.x):
#   GC_enable_incremental, GC_collect_a_little, GC_set_time_limit, GC_gcollect_and_unmap,
#   GC_set_free_space_divisor, GC_get_free_space_divisor, GC_set_markers_count,
#   GC_get_parallel, GC_get_heap_size, GC_get_free_bytes, GC_set_max_heap_size.
@[Link("gc")]
lib LibGCExt
  # `GC_word` is C `unsigned long` in bdw-gc's public API (the `set_*` setters below are all
  # declared `unsigned long`). LibC::ULong matches it on every target Crystal supports.
  alias Word = LibC::ULong

  # --- collection control ---------------------------------------------------------------
  fun enable_incremental = GC_enable_incremental : Void
  fun collect_a_little = GC_collect_a_little : LibC::Int
  fun set_time_limit = GC_set_time_limit(value : LibC::ULong) : Void
  fun gcollect_and_unmap = GC_gcollect_and_unmap : Void

  # --- heap / collection-frequency tuning ----------------------------------------------
  fun set_free_space_divisor = GC_set_free_space_divisor(value : Word) : Void
  fun get_free_space_divisor = GC_get_free_space_divisor : Word
  fun set_max_heap_size = GC_set_max_heap_size(n : Word) : Void

  # --- parallel marker tuning ----------------------------------------------------------
  fun set_markers_count = GC_set_markers_count(count : LibC::UInt) : Void
  fun get_parallel = GC_get_parallel : LibC::Int

  # --- read-only introspection ---------------------------------------------------------
  fun get_heap_size = GC_get_heap_size : LibC::SizeT
  fun get_free_bytes = GC_get_free_bytes : LibC::SizeT
end

module AgentC
  # Runtime tuning surface for Crystal's Boehm collector. All methods are safe to call from
  # stock-compiler app builds; they just talk to the linked libgc. Reentrant where noted.
  module GCControl
    extend self

    UNLIMITED = 0xFFFFFFFF_u32 # GC_TIME_UNLIMITED — never pause-bound the collector

    # Nesting depth for `without_collection`, so nested scopes don't re-enable the collector
    # early. Atomic because nesting can occur across fibers on different worker threads.
    @@disable_depth = Atomic(Int32).new(0)

    # ----------------------------------------------------------------------------------
    # Collection control
    # ----------------------------------------------------------------------------------

    # Enable Boehm's GENERATIONAL + INCREMENTAL mode: the collector tracks dirtied pages
    # (a virtual-dirty-bit / mprotect write barrier) and collects a little at a time, so
    # young garbage is reclaimed cheaply and stop-the-world pauses shrink.
    #
    # THIS IS A LATENCY TOOL, NOT A THROUGHPUT TOOL. The write barrier costs throughput even
    # single-threaded (~123 -> ~74 Mops here), and under concurrent multi-thread allocation
    # the mprotect barrier is pathological (multi-worker benches did not finish). Enable ONLY
    # when tail-latency / pause time matters more than ops/sec — and in practice only for
    # single-threaded or allocation-light workloads. Call once at startup; it cannot be undone.
    #
    # Optionally cap each incremental step's pause at `pause_ms` (`GC_set_time_limit`).
    def enable_incremental(pause_ms : Int32? = nil) : Nil
      LibGCExt.set_time_limit((pause_ms || UNLIMITED).to_u64) if pause_ms
      LibGCExt.enable_incremental
    end

    # Run a block with collection fully DISABLED — no stop-the-world pauses at all. This
    # removes the *pause* half of the MT allocation regression (~58% of the HTTP MT loss in
    # our benchmarks) for the duration of the block.
    #
    # Allocations still go through the GC heap (and still take the alloc lock), so keep the
    # block's allocation BOUNDED — the heap grows until the next collection after the scope.
    # Nestable: only the outermost scope re-enables the collector.
    def without_collection(&)
      GC.disable
      @@disable_depth.add(1)
      begin
        yield
      ensure
        # Re-enable only when the outermost scope exits. `sub` returns the value *before*
        # the subtraction, so a result of 1 means we just left the last nested scope.
        GC.enable if @@disable_depth.sub(1) == 1
      end
    end

    # Perform one small slice of incremental collection (cooperative; call from idle points,
    # e.g. when a worker has no pending request). Returns true if more incremental work
    # remains. Only meaningful after `enable_incremental`; in non-incremental mode Boehm runs
    # a small amount of marking and typically returns false.
    def collect_a_little : Bool
      LibGCExt.collect_a_little != 0
    end

    # Force a full collection and return free memory to the OS (unmaps empty heap blocks).
    # Good to call when a worker goes idle / between request bursts so RSS doesn't stay high.
    # This is a full stop-the-world collection — do not call on the hot path.
    def release_to_os : Nil
      LibGCExt.gcollect_and_unmap
    end

    # ----------------------------------------------------------------------------------
    # Heap / footprint tuning (RSS vs CPU trade — NOT a contention fix)
    # ----------------------------------------------------------------------------------

    # Set Boehm's free-space divisor. Heuristic: the collector tries to keep
    # `heap_size / divisor` bytes free, so it collects after roughly that much new allocation.
    #
    #   * HIGHER divisor  -> collects MORE often -> smaller heap / lower RSS, more CPU in GC.
    #   * LOWER  divisor  -> collects LESS often -> larger heap / higher RSS, less GC CPU.
    #
    # Default is 3. For a throughput-first, RSS-tolerant service, LOWERING it (e.g. 3 -> 1)
    # reduces collection frequency. NOTE: our benchmarks show this does NOT relieve the
    # multi-core *contention* (that's the alloc lock + pauses) — it only trades collection
    # frequency for memory. Use it to control footprint, not to "fix" MT scaling. `divisor`
    # must be >= 1.
    def free_space_divisor=(divisor : Int) : Nil
      raise ArgumentError.new("free_space_divisor must be >= 1") if divisor < 1
      LibGCExt.set_free_space_divisor(LibGCExt::Word.new(divisor))
    end

    # Current free-space divisor (see `free_space_divisor=`).
    def free_space_divisor : UInt64
      LibGCExt.get_free_space_divisor.to_u64
    end

    # Hard cap on total heap size, in bytes. **Footgun:** when the heap *cannot* be kept under
    # this cap, Boehm's default out-of-memory path aborts the PROCESS — it does NOT raise a
    # Crystal exception (the only escape is a custom `GC_oom_fn`, which Crystal does not
    # install). Use only as a deliberate guardrail for bounded-lifetime workers where
    # death-on-OOM is preferable to unbounded growth — and size it with headroom. Pass 0 to
    # mean "no limit". Opt-in only.
    def max_heap_size=(bytes : Int) : Nil
      raise ArgumentError.new("max_heap_size must be >= 0") if bytes < 0
      LibGCExt.set_max_heap_size(LibGCExt::Word.new(bytes))
    end

    # ----------------------------------------------------------------------------------
    # Parallel marker tuning
    # ----------------------------------------------------------------------------------

    # Set the number of parallel marker threads. Crystal/Boehm already enables parallel mark
    # (~one marker per core) at GC init, so the common use is to *reduce* it to leave cores for
    # request handling, or pin it for reproducible benchmarks. `count` is clamped to >= 1.
    #
    # GOTCHA: this is only honoured *before the marker threads are started* (i.e. before the
    # first parallel collection). bdw-gc starts them lazily, so calling this very early at
    # startup (before significant allocation / first GC) is the reliable path; calling it after
    # markers exist is a no-op for the running set. It never reduces correctness — only the
    # parallelism of marking. No effect when parallel mark is unavailable (see `parallel?`).
    def markers_count=(count : Int) : Nil
      clamped_count = count < 1 ? 1 : count
      LibGCExt.set_markers_count(LibC::UInt.new(clamped_count))
    end

    # True if Boehm parallel marking is active in this build/runtime.
    def parallel? : Bool
      LibGCExt.get_parallel != 0
    end

    # ----------------------------------------------------------------------------------
    # Read-only introspection
    # ----------------------------------------------------------------------------------

    # Total bytes the GC has reserved for its heap (grows/shrinks with demand).
    def heap_size : UInt64
      LibGCExt.get_heap_size.to_u64
    end

    # Approximate free bytes within the current heap (pessimistic per bdw-gc docs).
    def free_bytes : UInt64
      LibGCExt.get_free_bytes.to_u64
    end

    # The full Crystal `GC::Stats` snapshot (heap_size, free_bytes, unmapped_bytes,
    # bytes_since_gc, total_bytes).
    def stats : GC::Stats
      GC.stats
    end
  end
end
