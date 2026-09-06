require "log"
require "./gc_control"

# Periodic memory tracing for a long-running Amber process, plus an idle
# "give the pages back" step that is ON by default in production.
#
# WHY THIS EXISTS: two apps in this family grew to 60-100 MiB of anonymous heap
# over days while their siblings sat at 9-19 MiB. A restart dropped one from
# 62 MiB to 10 MiB. That shape has two very different causes and RSS alone cannot
# tell them apart:
#
#   * a LEAK        -> `heap_size` climbs and `free_bytes` stays small (live data
#                      the collector cannot reclaim, so the heap must keep growing)
#   * HOARDING      -> `heap_size` is flat-ish and `free_bytes` is large (the
#                      collector reclaimed the objects but never returned the
#                      pages to the OS, so RSS stays high)
#
# One structured line per interval carries both halves — the kernel's view (VmRSS,
# RssAnon) and the collector's view (GC.stats) — so the two can be separated from
# the log alone, without attaching a profiler to production. HOARDING is the half
# this module can also FIX, by handing the pages back once the process has gone
# quiet, so that no operator has to restart an app to reclaim its own memory.
#
# ── Boehm environment knobs (settable in a systemd unit, NO code change) ──────
#
# These are CANDIDATES TO MEASURE against our binaries, not established fixes.
# Nothing here should be turned on in production before the trace above shows
# which of the two shapes we actually have.
#
#   GC_FREE_SPACE_DIVISOR (default 3)
#     Boehm tries to keep roughly `heap_size / divisor` bytes free, so it collects
#     after about that much fresh allocation. A HIGHER divisor collects sooner and
#     keeps the heap smaller (lower RSS, more CPU spent collecting); a LOWER one
#     collects less often (larger heap, less GC CPU). NOTE the measurement AgentC
#     has already taken against this collector: this divisor does NOT relieve the
#     multi-core allocation contention — that is the alloc lock plus stop-the-world
#     pauses, not collection frequency. It is a FOOTPRINT control only, which is
#     exactly the axis this module cares about. See also `AgentC::GCControl`, which
#     exposes the same knob at runtime via `free_space_divisor=`.
#
#   GC_UNMAP_THRESHOLD
#     How many collection cycles a heap block must sit empty before Boehm unmaps
#     it. Only effective when libgc was built with munmap support (USE_MUNMAP);
#     where it was not, the variable is silently inert. WE HAVE NOT CONFIRMED the
#     build flag on our shipped binaries, so treat any effect as unmeasured until
#     a trace before/after says otherwise. `1` unmaps most aggressively; `0`
#     disables unmapping entirely.
#
# Neither knob is set by this module. The module reports, and — once the process
# has been idle for long enough — calls the collector's own release path.
#
# ── Environment variables and their defaults ─────────────────────────────────
#
#   MEMORY_TRACE_INTERVAL_SECONDS            (default 300)
#     Seconds between trace lines. `0` switches tracing (and therefore releasing)
#     off entirely.
#
#   MEMORY_TRACE_RELEASE_AFTER_IDLE_INTERVALS (default 2)
#     How many CONSECUTIVE idle intervals must pass before the pages are handed
#     back. At the 300-second default that is a release after about 10 minutes
#     idle. `0` disables releasing and leaves this module reporting only.
#
#   MEMORY_TRACE_IDLE_ALLOCATION_BYTES        (default 1 MiB)
#     What "idle" MEANS. An interval counts as idle when the process allocated
#     fewer than this many bytes since the previous sample (`GC.stats.total_bytes`
#     is cumulative, so the delta is real allocation, not a free-list reading).
#     Allocation is the honest idleness signal: a free ratio can sit high on a
#     BUSY app that churns short-lived objects, and releasing there just buys a
#     stop-the-world pause the app immediately allocates back.
#
#   MEMORY_TRACE_RELEASE_MINIMUM_FREE_BYTES   (default 4 MiB)
#     Do not pay for a full collection when there is nothing to give back. Below
#     this much free heap the release is skipped silently — only the normal trace
#     line is logged — so a small idle app does not collect every 10 minutes for
#     no gain.
#
#   MEMORY_TRACE_RELEASE_REPEAT_INTERVALS     (default 12)
#     After a release, the next one waits either for the app to be BUSY again (a
#     single non-idle interval) or for this many further idle intervals — at the
#     300-second default, at most one release an hour while an app sits idle for
#     days. Without this an idle process would burn CPU being idle.
module AgentC
  # One fiber, one log line per interval. Started once from the app's boot path.
  module MemoryTrace
    extend self

    PROC_STATUS_PATH = "/proc/self/status"

    INTERVAL_VARIABLE         = "MEMORY_TRACE_INTERVAL_SECONDS"
    RELEASE_VARIABLE          = "MEMORY_TRACE_RELEASE_AFTER_IDLE_INTERVALS"
    IDLE_ALLOCATION_VARIABLE  = "MEMORY_TRACE_IDLE_ALLOCATION_BYTES"
    MINIMUM_FREE_VARIABLE     = "MEMORY_TRACE_RELEASE_MINIMUM_FREE_BYTES"
    REPEAT_INTERVALS_VARIABLE = "MEMORY_TRACE_RELEASE_REPEAT_INTERVALS"

    BYTES_PER_KIB =      1024_u64
    BYTES_PER_MIB = 1_048_576_u64

    # The kernel's view of this process's memory, read from /proc/self/status.
    # Both values are nil where the file does not exist (macOS) or does not carry
    # the field, and the log line then reads `unknown` rather than a made-up zero.
    struct ProcessMemoryReading
      getter rss_kib : UInt64?
      getter anon_kib : UInt64?

      def initialize(@rss_kib : UInt64? = nil, @anon_kib : UInt64? = nil)
      end

      # No /proc on this platform, or it could not be read.
      def self.unavailable : ProcessMemoryReading
        new(nil, nil)
      end

      # Parse the text of /proc/self/status. `VmRSS` is the whole resident set;
      # `RssAnon` is the anonymous part — the heap — which is the number that grew
      # on the affected apps. Both are reported by the kernel in kB (really KiB).
      def self.from_proc_status(status_text : String) : ProcessMemoryReading
        rss_kib = nil
        anon_kib = nil

        status_text.each_line do |line|
          resident_value = kibibytes_on(line, "VmRSS:")
          rss_kib = resident_value if resident_value

          anonymous_value = kibibytes_on(line, "RssAnon:")
          anon_kib = anonymous_value if anonymous_value
        end

        new(rss_kib, anon_kib)
      end

      # "VmRSS:\t   17244 kB" -> 17244
      private def self.kibibytes_on(line : String, label : String) : UInt64?
        return nil unless line.starts_with?(label)

        remainder = line[label.size..]
        first_token = remainder.strip.split.first?
        return nil unless first_token

        first_token.to_u64?
      end
    end

    # One interval's worth of numbers, from both viewpoints.
    struct Sample
      getter interval_number : Int32
      getter rss_kib : UInt64?
      getter anon_kib : UInt64?
      getter heap_bytes : UInt64
      getter free_bytes : UInt64
      getter unmapped_bytes : UInt64
      getter bytes_since_gc : UInt64
      getter total_bytes : UInt64

      def initialize(@interval_number : Int32,
                     @rss_kib : UInt64?,
                     @anon_kib : UInt64?,
                     @heap_bytes : UInt64,
                     @free_bytes : UInt64,
                     @unmapped_bytes : UInt64,
                     @bytes_since_gc : UInt64,
                     @total_bytes : UInt64)
      end

      def self.from_reading(interval_number : Int32,
                            reading : ProcessMemoryReading,
                            stats : GC::Stats) : Sample
        new(
          interval_number,
          reading.rss_kib,
          reading.anon_kib,
          stats.heap_size,
          stats.free_bytes,
          stats.unmapped_bytes,
          stats.bytes_since_gc,
          stats.total_bytes,
        )
      end

      # Share of the reserved heap that the collector currently considers free.
      # A DIAGNOSTIC only: a high, persistent ratio is the HOARDING shape, but the
      # release decision is made on allocation (see `ReleasePolicy`), because a
      # busy app that churns short-lived objects also shows a high free ratio.
      def free_ratio : Float64
        return 0.0 if heap_bytes.zero?
        free_bytes / heap_bytes
      end

      def to_log_line : String
        String.build do |line|
          line << "memory.trace"
          line << " n=" << interval_number
          line << " rss_kib=" << MemoryTrace.reported(rss_kib)
          line << " anon_kib=" << MemoryTrace.reported(anon_kib)
          line << " heap_kib=" << heap_bytes // BYTES_PER_KIB
          line << " free_kib=" << free_bytes // BYTES_PER_KIB
          line << " unmapped_kib=" << unmapped_bytes // BYTES_PER_KIB
          line << " since_gc_kib=" << bytes_since_gc // BYTES_PER_KIB
          line << " total_alloc_mib=" << total_bytes // BYTES_PER_MIB
        end
      end
    end

    # What one interval's numbers earned. Separating the decision from the act
    # means a spec can assert on WHY nothing was released without a collector
    # ever running.
    enum ReleaseDecision
      # Not idle long enough yet (or releasing is switched off).
      KeepWatching
      # Idle long enough, but a release happened too recently and the app has not
      # been busy since.
      HoldAfterRecentRelease
      # Idle long enough, but the heap has too little free to be worth the pause.
      SkipWithTooLittleFree
      # Hand the pages back now.
      ReleaseNow
    end

    # Decides whether the process has been quiet for long enough that asking the
    # collector to hand pages back is worth a stop-the-world pause.
    #
    # Idleness is measured by ALLOCATION — how many bytes the process allocated
    # since the previous sample — not by how full the free list looks. Two further
    # guards keep an idle process from burning CPU being idle: a release must have
    # something to give back, and it must not repeat until the app has been busy
    # again or a full repeat window has passed.
    struct ReleasePolicy
      getter required_consecutive_idle_intervals : Int32
      getter idle_allocation_bytes : UInt64
      getter minimum_free_bytes : UInt64
      getter repeat_intervals : Int32

      def initialize(@required_consecutive_idle_intervals : Int32,
                     @idle_allocation_bytes : UInt64 = Configuration::DEFAULT_IDLE_ALLOCATION_BYTES,
                     @minimum_free_bytes : UInt64 = Configuration::DEFAULT_RELEASE_MINIMUM_FREE_BYTES,
                     @repeat_intervals : Int32 = Configuration::DEFAULT_RELEASE_REPEAT_INTERVALS)
      end

      # 0 required intervals means "report only, never release".
      def enabled? : Bool
        required_consecutive_idle_intervals > 0
      end

      # Strictly below the threshold is idle; exactly at it is not. `GC.stats
      # .total_bytes` is cumulative, so this delta is fresh allocation.
      def interval_was_idle?(allocated_bytes_since_previous_sample : UInt64) : Bool
        allocated_bytes_since_previous_sample < idle_allocation_bytes
      end

      # A full collection is only worth its pause when there are pages to hand
      # back. A truly small app sits below this line and is left alone.
      def heap_has_something_to_give_back?(free_bytes : UInt64) : Bool
        free_bytes >= minimum_free_bytes
      end
    end

    # What the release actually accomplished, so the log can be read as evidence
    # rather than as a claim. RSS is carried on both sides because it is the only
    # number that proves the pages reached the OS; it reads `unknown` where there
    # is no /proc (macOS).
    struct ReleaseOutcome
      getter interval_number : Int32
      getter heap_bytes_before : UInt64
      getter free_bytes_before : UInt64
      getter heap_bytes_after : UInt64
      getter free_bytes_after : UInt64
      getter rss_kib_before : UInt64?
      getter rss_kib_after : UInt64?

      def initialize(@interval_number : Int32,
                     @heap_bytes_before : UInt64,
                     @free_bytes_before : UInt64,
                     @heap_bytes_after : UInt64,
                     @free_bytes_after : UInt64,
                     @rss_kib_before : UInt64? = nil,
                     @rss_kib_after : UInt64? = nil)
      end

      def to_log_line : String
        String.build do |line|
          line << "memory.release"
          line << " n=" << interval_number
          line << " heap_kib_before=" << heap_bytes_before // BYTES_PER_KIB
          line << " heap_kib_after=" << heap_bytes_after // BYTES_PER_KIB
          line << " free_kib_before=" << free_bytes_before // BYTES_PER_KIB
          line << " free_kib_after=" << free_bytes_after // BYTES_PER_KIB
          line << " rss_kib_before=" << MemoryTrace.reported(rss_kib_before)
          line << " rss_kib_after=" << MemoryTrace.reported(rss_kib_after)
        end
      end
    end

    # Boot-time settings, read once. A garbage value never takes the process down
    # and never silently becomes zero — it falls back to the default and says so.
    struct Configuration
      DEFAULT_INTERVAL_SECONDS             = 300
      DEFAULT_RELEASE_AFTER_IDLE_INTERVALS =   2
      DEFAULT_IDLE_ALLOCATION_BYTES        = BYTES_PER_MIB
      DEFAULT_RELEASE_MINIMUM_FREE_BYTES   = 4_u64 * BYTES_PER_MIB
      DEFAULT_RELEASE_REPEAT_INTERVALS     = 12

      getter interval_seconds : Int32
      getter release_after_idle_intervals : Int32
      getter idle_allocation_bytes : UInt64
      getter release_minimum_free_bytes : UInt64
      getter release_repeat_intervals : Int32
      getter list_of_warnings : Array(String)

      def initialize(@interval_seconds : Int32,
                     @release_after_idle_intervals : Int32,
                     @idle_allocation_bytes : UInt64 = DEFAULT_IDLE_ALLOCATION_BYTES,
                     @release_minimum_free_bytes : UInt64 = DEFAULT_RELEASE_MINIMUM_FREE_BYTES,
                     @release_repeat_intervals : Int32 = DEFAULT_RELEASE_REPEAT_INTERVALS,
                     @list_of_warnings : Array(String) = [] of String)
      end

      def self.from_environment(environment : Hash(String, String)) : Configuration
        list_of_warnings = [] of String

        interval_seconds = whole_number_from(
          environment, INTERVAL_VARIABLE, DEFAULT_INTERVAL_SECONDS, list_of_warnings
        )
        release_after_idle_intervals = whole_number_from(
          environment, RELEASE_VARIABLE, DEFAULT_RELEASE_AFTER_IDLE_INTERVALS, list_of_warnings
        )
        idle_allocation_bytes = byte_count_from(
          environment, IDLE_ALLOCATION_VARIABLE, DEFAULT_IDLE_ALLOCATION_BYTES, list_of_warnings
        )
        release_minimum_free_bytes = byte_count_from(
          environment, MINIMUM_FREE_VARIABLE, DEFAULT_RELEASE_MINIMUM_FREE_BYTES, list_of_warnings
        )
        release_repeat_intervals = whole_number_from(
          environment, REPEAT_INTERVALS_VARIABLE, DEFAULT_RELEASE_REPEAT_INTERVALS, list_of_warnings
        )

        new(
          interval_seconds,
          release_after_idle_intervals,
          idle_allocation_bytes,
          release_minimum_free_bytes,
          release_repeat_intervals,
          list_of_warnings,
        )
      end

      def self.from_process_environment : Configuration
        environment = {} of String => String
        {
          INTERVAL_VARIABLE,
          RELEASE_VARIABLE,
          IDLE_ALLOCATION_VARIABLE,
          MINIMUM_FREE_VARIABLE,
          REPEAT_INTERVALS_VARIABLE,
        }.each do |name|
          present_value = ENV[name]?
          environment[name] = present_value if present_value
        end
        from_environment(environment)
      end

      # 0 disables tracing entirely.
      def enabled? : Bool
        interval_seconds > 0
      end

      def interval : Time::Span
        interval_seconds.seconds
      end

      def release_policy : ReleasePolicy
        ReleasePolicy.new(
          required_consecutive_idle_intervals: release_after_idle_intervals,
          idle_allocation_bytes: idle_allocation_bytes,
          minimum_free_bytes: release_minimum_free_bytes,
          repeat_intervals: release_repeat_intervals,
        )
      end

      private def self.whole_number_from(environment : Hash(String, String),
                                         name : String,
                                         fallback : Int32,
                                         list_of_warnings : Array(String)) : Int32
        raw_value = environment[name]?
        return fallback unless raw_value

        trimmed_value = raw_value.strip
        # An empty variable means "unset", not "garbage" — no warning for it.
        return fallback if trimmed_value.empty?

        parsed_value = trimmed_value.to_i?
        if parsed_value.nil? || parsed_value < 0
          list_of_warnings << "memory.trace ignoring #{name}=#{raw_value.inspect}; using #{fallback}"
          return fallback
        end

        parsed_value
      end

      # Byte counts get their own parser because they legitimately exceed Int32
      # and because a negative byte count is garbage, not a disable switch.
      private def self.byte_count_from(environment : Hash(String, String),
                                       name : String,
                                       fallback : UInt64,
                                       list_of_warnings : Array(String)) : UInt64
        raw_value = environment[name]?
        return fallback unless raw_value

        trimmed_value = raw_value.strip
        return fallback if trimmed_value.empty?

        parsed_value = trimmed_value.to_u64?
        if parsed_value.nil?
          list_of_warnings << "memory.trace ignoring #{name}=#{raw_value.inspect}; using #{fallback}"
          return fallback
        end

        parsed_value
      end
    end

    # Where an interval's numbers come from, and what a release does. Both are
    # injected so a spec can drive the loop body without a timer and without ever
    # calling the real collector.
    alias SampleSource = Proc(Int32, Sample)
    alias ReleaseAction = Proc(Sample, ReleaseOutcome)

    @@trace_has_started = false

    # The single call a boot path makes. Tracing is ON by default in production,
    # because that is where the growth was measured and where nobody is watching a
    # terminal. Anywhere else it is opt-in: a developer running the app locally
    # should not get memory lines they did not ask for, so the trace starts only
    # when MEMORY_TRACE_INTERVAL_SECONDS is explicitly set.
    def perform_for_environment(running_in_production : Bool) : Bool
      return false unless requested_for_environment?(running_in_production)
      perform
    end

    def requested_for_environment?(running_in_production : Bool,
                                   interval_was_set : Bool = ENV.has_key?(INTERVAL_VARIABLE)) : Bool
      running_in_production || interval_was_set
    end

    # Start the trace fiber. Safe to call once from the boot path; a second call is
    # a no-op so a reload can never stack two tracers on one process.
    # Returns true when a fiber was started.
    def perform(configuration : Configuration = Configuration.from_process_environment) : Bool
      configuration.list_of_warnings.each do |warning|
        Log.warn { warning }
      end

      return false unless configuration.enabled?
      return false if @@trace_has_started

      @@trace_has_started = true
      Log.info do
        "memory.trace starting interval_seconds=#{configuration.interval_seconds} " \
        "release_after_idle_intervals=#{configuration.release_after_idle_intervals} " \
        "idle_allocation_bytes=#{configuration.idle_allocation_bytes} " \
        "release_minimum_free_bytes=#{configuration.release_minimum_free_bytes} " \
        "release_repeat_intervals=#{configuration.release_repeat_intervals}"
      end

      spawn(name: "memory-trace") do
        loop do
          # `sleep` first so boot is never delayed and the first sample reflects a
          # settled process rather than the tail of startup allocation.
          sleep configuration.interval
          record_one_interval(configuration)
        end
      end

      true
    end

    # The loop body, extracted so specs can drive it directly instead of waiting on
    # a timer. Advances the interval counter, logs the trace line, and releases
    # when this interval earned it. Returns the decision so a caller (or a spec)
    # can see why nothing happened.
    def record_one_interval(configuration : Configuration,
                            state : TraceState = shared_state,
                            sample_source : SampleSource = default_sample_source,
                            release_action : ReleaseAction = default_release_action) : ReleaseDecision
      state.interval_number += 1

      sample = sample_source.call(state.interval_number)
      Log.info { sample.to_log_line }

      decision = record_sample_and_decide(sample, configuration.release_policy, state)
      release_action.call(sample) if decision.release_now?
      decision
    rescue ex
      # A tracer must never be the reason a process dies.
      Log.warn { "memory.trace unavailable: #{ex.class}: #{ex.message}" }
      ReleaseDecision::KeepWatching
    end

    # The state machine, kept apart from the logging and the collector so it can be
    # driven one sample at a time in a spec. Advances the counters on `state` and
    # answers what this interval earned.
    def record_sample_and_decide(sample : Sample,
                                 policy : ReleasePolicy,
                                 state : TraceState) : ReleaseDecision
      allocated_bytes = state.allocated_bytes_since_previous_sample(sample.total_bytes)
      state.previous_total_bytes = sample.total_bytes

      return ReleaseDecision::KeepWatching unless policy.enabled?

      # No previous sample means no evidence yet, so the first interval after boot
      # counts as busy: nothing releases on an empty record.
      unless allocated_bytes && policy.interval_was_idle?(allocated_bytes)
        state.count_of_consecutive_idle_intervals = 0
        # Being busy is what clears the wait after a release.
        state.count_of_idle_intervals_since_release = nil
        return ReleaseDecision::KeepWatching
      end

      state.count_of_consecutive_idle_intervals += 1
      count_since_release = state.count_of_idle_intervals_since_release
      state.count_of_idle_intervals_since_release = count_since_release + 1 if count_since_release

      if state.count_of_consecutive_idle_intervals < policy.required_consecutive_idle_intervals
        return ReleaseDecision::KeepWatching
      end

      count_since_release = state.count_of_idle_intervals_since_release
      if count_since_release && count_since_release < policy.repeat_intervals
        return ReleaseDecision::HoldAfterRecentRelease
      end

      # Nothing worth a stop-the-world pause. The idle run keeps counting, so the
      # moment the heap does hold something back this fires on the next interval.
      unless policy.heap_has_something_to_give_back?(sample.free_bytes)
        return ReleaseDecision::SkipWithTooLittleFree
      end

      state.count_of_idle_intervals_since_release = 0
      ReleaseDecision::ReleaseNow
    end

    def default_sample_source : SampleSource
      ->(interval_number : Int32) do
        Sample.from_reading(interval_number, MemoryTrace.current_process_reading, GC.stats)
      end
    end

    def default_release_action : ReleaseAction
      ->(sample_before : Sample) { MemoryTrace.release_to_operating_system(sample_before) }
    end

    # Full collection plus `GC_gcollect_and_unmap`, via the runtime's existing GC
    # surface. Note this is `GCControl.release_to_os`, NOT a bare `GC.collect`:
    # collecting alone reclaims objects into the free list but leaves every page
    # mapped, so RSS does not move — which is precisely the symptom being chased.
    def release_to_operating_system(sample_before : Sample) : ReleaseOutcome
      GCControl.release_to_os
      stats_after = GC.stats
      reading_after = current_process_reading

      outcome = ReleaseOutcome.new(
        interval_number: sample_before.interval_number,
        heap_bytes_before: sample_before.heap_bytes,
        free_bytes_before: sample_before.free_bytes,
        heap_bytes_after: stats_after.heap_size,
        free_bytes_after: stats_after.free_bytes,
        rss_kib_before: sample_before.rss_kib,
        rss_kib_after: reading_after.rss_kib,
      )
      Log.info { outcome.to_log_line }
      outcome
    end

    def current_process_reading : ProcessMemoryReading
      return ProcessMemoryReading.unavailable unless File.exists?(PROC_STATUS_PATH)
      ProcessMemoryReading.from_proc_status(File.read(PROC_STATUS_PATH))
    rescue
      ProcessMemoryReading.unavailable
    end

    def reported(value : UInt64?) : String
      value ? value.to_s : "unknown"
    end

    # Mutable per-process trace state. Held separately from the fiber so a spec can
    # supply its own and assert on what accumulated.
    class TraceState
      property interval_number : Int32
      # Cumulative allocation at the previous sample; nil until the first one.
      property previous_total_bytes : UInt64?
      property count_of_consecutive_idle_intervals : Int32
      # Idle intervals since the last release; nil when no release is holding the
      # next one back (never released, or the app has been busy since).
      property count_of_idle_intervals_since_release : Int32?

      def initialize(@interval_number : Int32 = 0,
                     @previous_total_bytes : UInt64? = nil,
                     @count_of_consecutive_idle_intervals : Int32 = 0,
                     @count_of_idle_intervals_since_release : Int32? = nil)
      end

      # Fresh allocation since the previous sample, or nil when there is no
      # previous sample to measure against. A counter that did not move reads as
      # zero rather than underflowing.
      def allocated_bytes_since_previous_sample(total_bytes : UInt64) : UInt64?
        previous_value = previous_total_bytes
        return nil unless previous_value
        return 0_u64 if total_bytes <= previous_value

        total_bytes - previous_value
      end
    end

    @@shared_state = TraceState.new

    def shared_state : TraceState
      @@shared_state
    end
  end
end
