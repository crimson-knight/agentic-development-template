require "spec"
require "../../src/runtime/memory_trace"

# These specs cover the parts of the memory tracer that decide things: parsing the
# kernel's numbers, formatting the one line an operator will actually read, the
# idle-release state machine, and configuration parsing. Nothing here sleeps —
# the interval loop's body is a callable method for exactly that reason, so a spec
# never has to wait 300 seconds to learn whether the counter advanced — and the
# release specs drive an INJECTED sampler and release action, so no collection
# runs to prove that a release was decided.

# A trimmed but faithful /proc/self/status, in the kernel's real column layout
# (tab after the label, right-aligned number, "kB" suffix).
PROC_STATUS_FIXTURE = <<-STATUS
Name:\tapp
Umask:\t0022
State:\tS (sleeping)
VmPeak:\t  221304 kB
VmSize:\t  221304 kB
VmRSS:\t   17244 kB
RssAnon:\t    7012 kB
RssFile:\t   10232 kB
RssShmem:\t       0 kB
Threads:\t9
STATUS

private ONE_MIB = 1_048_576_u64

# Allocation deltas either side of the 1 MiB idle threshold, and free-heap sizes
# either side of the 4 MiB "worth releasing" threshold. Named rather than inlined
# so a scripted run below reads as a story about the app, not as arithmetic.
private IDLE_ALLOCATION = 65_536_u64
private BUSY_ALLOCATION = 4_u64 * ONE_MIB
private PLENTY_OF_FREE  = 8_u64 * ONE_MIB
private TOO_LITTLE_FREE = ONE_MIB

private def sample_with(free_ratio : Float64, interval_number : Int32 = 1) : AgentC::MemoryTrace::Sample
  heap_bytes = 8_388_608_u64
  AgentC::MemoryTrace::Sample.new(
    interval_number: interval_number,
    rss_kib: 17_244_u64,
    anon_kib: 7_012_u64,
    heap_bytes: heap_bytes,
    free_bytes: (heap_bytes * free_ratio).to_u64,
    unmapped_bytes: 0_u64,
    bytes_since_gc: 318_464_u64,
    total_bytes: 956_301_312_u64,
  )
end

private def configuration_with(release_after_idle_intervals : Int32 = 2,
                               release_repeat_intervals : Int32 = 12) : AgentC::MemoryTrace::Configuration
  AgentC::MemoryTrace::Configuration.new(
    interval_seconds: 1,
    release_after_idle_intervals: release_after_idle_intervals,
    release_repeat_intervals: release_repeat_intervals,
  )
end

# What one scripted interval looked like from the app's side: how much it
# allocated since the previous interval, and how much free heap it is sitting on.
private record ScriptedInterval,
  allocated_bytes : UInt64,
  free_bytes : UInt64

# What a whole scripted run produced.
private record RecordedRun,
  list_of_decisions : Array(AgentC::MemoryTrace::ReleaseDecision),
  list_of_released_interval_numbers : Array(Int32),
  state : AgentC::MemoryTrace::TraceState

# Drive the real loop body over a scripted allocation history, with the sampler
# and the release action both injected: no timer, and no collector ever runs.
private def run_scripted(list_of_intervals : Array(ScriptedInterval),
                         configuration = configuration_with) : RecordedRun
  state = AgentC::MemoryTrace::TraceState.new
  list_of_decisions = [] of AgentC::MemoryTrace::ReleaseDecision
  list_of_released_interval_numbers = [] of Int32

  # `GC.stats.total_bytes` is cumulative, so the scripted per-interval deltas are
  # summed into the running total the tracer actually reads.
  running_total_bytes = 1_000_000_000_u64

  sample_source = ->(interval_number : Int32) do
    scripted_interval = list_of_intervals[interval_number - 1]
    running_total_bytes += scripted_interval.allocated_bytes

    AgentC::MemoryTrace::Sample.new(
      interval_number: interval_number,
      rss_kib: 17_244_u64,
      anon_kib: 7_012_u64,
      heap_bytes: 16_777_216_u64,
      free_bytes: scripted_interval.free_bytes,
      unmapped_bytes: 0_u64,
      bytes_since_gc: 318_464_u64,
      total_bytes: running_total_bytes,
    )
  end

  release_action = ->(sample_before : AgentC::MemoryTrace::Sample) do
    list_of_released_interval_numbers << sample_before.interval_number

    AgentC::MemoryTrace::ReleaseOutcome.new(
      interval_number: sample_before.interval_number,
      heap_bytes_before: sample_before.heap_bytes,
      free_bytes_before: sample_before.free_bytes,
      heap_bytes_after: sample_before.heap_bytes,
      free_bytes_after: 0_u64,
    )
  end

  list_of_intervals.size.times do
    list_of_decisions << AgentC::MemoryTrace.record_one_interval(
      configuration, state, sample_source, release_action
    )
  end

  RecordedRun.new(list_of_decisions, list_of_released_interval_numbers, state)
end

# Sugar for the scripts below: one busy interval, one idle interval.
private def busy(free_bytes : UInt64 = PLENTY_OF_FREE) : ScriptedInterval
  ScriptedInterval.new(BUSY_ALLOCATION, free_bytes)
end

private def idle(free_bytes : UInt64 = PLENTY_OF_FREE) : ScriptedInterval
  ScriptedInterval.new(IDLE_ALLOCATION, free_bytes)
end

describe AgentC::MemoryTrace do
  describe AgentC::MemoryTrace::ProcessMemoryReading do
    it "parses VmRSS and RssAnon out of a /proc/self/status fixture" do
      reading = AgentC::MemoryTrace::ProcessMemoryReading.from_proc_status(PROC_STATUS_FIXTURE)

      reading.rss_kib.should eq(17_244_u64)
      reading.anon_kib.should eq(7_012_u64)
    end

    it "does not confuse RssFile or RssShmem for the anonymous heap" do
      reading = AgentC::MemoryTrace::ProcessMemoryReading.from_proc_status(PROC_STATUS_FIXTURE)

      # RssFile is 10232 and RssShmem is 0 in the fixture; neither may win.
      reading.anon_kib.should eq(7_012_u64)
    end

    it "does not mistake VmPeak or VmSize for VmRSS" do
      # Both are 221304 in the fixture and both start with "Vm".
      reading = AgentC::MemoryTrace::ProcessMemoryReading.from_proc_status(PROC_STATUS_FIXTURE)

      reading.rss_kib.should_not eq(221_304_u64)
    end

    it "reports nil for fields the status text does not carry" do
      reading = AgentC::MemoryTrace::ProcessMemoryReading.from_proc_status("Name:\tapp\nThreads:\t9\n")

      reading.rss_kib.should be_nil
      reading.anon_kib.should be_nil
    end

    it "reports nil rather than raising on a malformed value" do
      reading = AgentC::MemoryTrace::ProcessMemoryReading.from_proc_status("VmRSS:\t   ??? kB\n")

      reading.rss_kib.should be_nil
    end

    it "answers unavailable with both fields nil" do
      reading = AgentC::MemoryTrace::ProcessMemoryReading.unavailable

      reading.rss_kib.should be_nil
      reading.anon_kib.should be_nil
    end
  end

  describe AgentC::MemoryTrace::Sample do
    it "formats one line carrying both the kernel and the collector viewpoints" do
      reading = AgentC::MemoryTrace::ProcessMemoryReading.new(17_244_u64, 7_012_u64)
      sample = AgentC::MemoryTrace::Sample.new(
        interval_number: 12,
        rss_kib: reading.rss_kib,
        anon_kib: reading.anon_kib,
        heap_bytes: 8_388_608_u64, # 8192 KiB
        free_bytes: 2_097_152_u64, # 2048 KiB
        unmapped_bytes: 0_u64,
        bytes_since_gc: 318_464_u64,  # 311 KiB
        total_bytes: 956_301_312_u64, # 912 MiB
      )

      sample.to_log_line.should eq(
        "memory.trace n=12 rss_kib=17244 anon_kib=7012 heap_kib=8192 free_kib=2048 " \
        "unmapped_kib=0 since_gc_kib=311 total_alloc_mib=912"
      )
    end

    it "prints unknown, not zero, where the platform has no /proc" do
      sample = AgentC::MemoryTrace::Sample.from_reading(
        1,
        AgentC::MemoryTrace::ProcessMemoryReading.unavailable,
        GC.stats,
      )

      sample.to_log_line.should contain("rss_kib=unknown")
      sample.to_log_line.should contain("anon_kib=unknown")
    end

    it "computes the free ratio against the reserved heap" do
      sample_with(0.75).free_ratio.should be_close(0.75, 0.001)
    end

    it "answers a zero free ratio for an empty heap instead of dividing by zero" do
      sample = AgentC::MemoryTrace::Sample.new(
        interval_number: 1, rss_kib: nil, anon_kib: nil,
        heap_bytes: 0_u64, free_bytes: 0_u64, unmapped_bytes: 0_u64,
        bytes_since_gc: 0_u64, total_bytes: 0_u64,
      )

      sample.free_ratio.should eq(0.0)
    end
  end

  describe AgentC::MemoryTrace::ReleasePolicy do
    it "is disabled at zero, which is how releasing is switched off" do
      policy = AgentC::MemoryTrace::ReleasePolicy.new(0)

      policy.enabled?.should be_false
    end

    it "is enabled at the default of two consecutive idle intervals" do
      policy = AgentC::MemoryTrace::ReleasePolicy.new(2)

      policy.enabled?.should be_true
    end

    describe "#interval_was_idle?" do
      it "counts an allocation delta below the threshold as idle" do
        policy = AgentC::MemoryTrace::ReleasePolicy.new(2, idle_allocation_bytes: ONE_MIB)

        policy.interval_was_idle?(ONE_MIB - 1).should be_true
        policy.interval_was_idle?(0_u64).should be_true
      end

      it "does not count a delta exactly at the threshold as idle" do
        policy = AgentC::MemoryTrace::ReleasePolicy.new(2, idle_allocation_bytes: ONE_MIB)

        policy.interval_was_idle?(ONE_MIB).should be_false
      end

      it "does not count a delta above the threshold as idle" do
        policy = AgentC::MemoryTrace::ReleasePolicy.new(2, idle_allocation_bytes: ONE_MIB)

        policy.interval_was_idle?(ONE_MIB + 1).should be_false
        policy.interval_was_idle?(BUSY_ALLOCATION).should be_false
      end
    end

    describe "#heap_has_something_to_give_back?" do
      it "answers true at or above the minimum free heap" do
        policy = AgentC::MemoryTrace::ReleasePolicy.new(2, minimum_free_bytes: 4_u64 * ONE_MIB)

        policy.heap_has_something_to_give_back?(4_u64 * ONE_MIB).should be_true
        policy.heap_has_something_to_give_back?(PLENTY_OF_FREE).should be_true
      end

      it "answers false below the minimum, so a small idle app is left alone" do
        policy = AgentC::MemoryTrace::ReleasePolicy.new(2, minimum_free_bytes: 4_u64 * ONE_MIB)

        policy.heap_has_something_to_give_back?(4_u64 * ONE_MIB - 1).should be_false
        policy.heap_has_something_to_give_back?(TOO_LITTLE_FREE).should be_false
      end
    end
  end

  describe AgentC::MemoryTrace::TraceState do
    it "has no allocation delta to answer before the first sample" do
      state = AgentC::MemoryTrace::TraceState.new

      state.allocated_bytes_since_previous_sample(1_000_u64).should be_nil
    end

    it "answers the delta since the previous sample" do
      state = AgentC::MemoryTrace::TraceState.new(previous_total_bytes: 1_000_u64)

      state.allocated_bytes_since_previous_sample(1_600_u64).should eq(600_u64)
    end

    it "answers zero rather than underflowing when the counter did not advance" do
      state = AgentC::MemoryTrace::TraceState.new(previous_total_bytes: 1_000_u64)

      state.allocated_bytes_since_previous_sample(1_000_u64).should eq(0_u64)
      state.allocated_bytes_since_previous_sample(900_u64).should eq(0_u64)
    end
  end

  describe AgentC::MemoryTrace::ReleaseOutcome do
    it "formats before and after heap, free, and RSS" do
      outcome = AgentC::MemoryTrace::ReleaseOutcome.new(
        interval_number: 12,
        heap_bytes_before: 8_388_608_u64, # 8192 KiB
        free_bytes_before: 6_291_456_u64, # 6144 KiB
        heap_bytes_after: 4_194_304_u64,  # 4096 KiB
        free_bytes_after: 1_048_576_u64,  # 1024 KiB
        rss_kib_before: 17_244_u64,
        rss_kib_after: 11_008_u64,
      )

      outcome.to_log_line.should eq(
        "memory.release n=12 heap_kib_before=8192 heap_kib_after=4096 " \
        "free_kib_before=6144 free_kib_after=1024 " \
        "rss_kib_before=17244 rss_kib_after=11008"
      )
    end

    it "prints unknown for RSS where the platform has no /proc" do
      outcome = AgentC::MemoryTrace::ReleaseOutcome.new(
        interval_number: 1,
        heap_bytes_before: 0_u64, free_bytes_before: 0_u64,
        heap_bytes_after: 0_u64, free_bytes_after: 0_u64,
      )

      outcome.to_log_line.should contain("rss_kib_before=unknown")
      outcome.to_log_line.should contain("rss_kib_after=unknown")
    end
  end

  describe AgentC::MemoryTrace::Configuration do
    it "defaults to a five-minute interval with releasing switched ON after two idle intervals" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({} of String => String)

      configuration.interval_seconds.should eq(300)
      configuration.release_after_idle_intervals.should eq(2)
      configuration.enabled?.should be_true
      configuration.release_policy.enabled?.should be_true
      configuration.list_of_warnings.should be_empty
    end

    it "defaults idleness to 1 MiB, the release floor to 4 MiB, and the repeat wait to 12 intervals" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({} of String => String)

      configuration.idle_allocation_bytes.should eq(1_048_576_u64)
      configuration.release_minimum_free_bytes.should eq(4_194_304_u64)
      configuration.release_repeat_intervals.should eq(12)
    end

    it "carries every default through to the policy it builds" do
      policy = AgentC::MemoryTrace::Configuration.from_environment({} of String => String).release_policy

      policy.required_consecutive_idle_intervals.should eq(2)
      policy.idle_allocation_bytes.should eq(1_048_576_u64)
      policy.minimum_free_bytes.should eq(4_194_304_u64)
      policy.repeat_intervals.should eq(12)
    end

    it "treats a release interval count of zero as switched off, not as garbage" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_RELEASE_AFTER_IDLE_INTERVALS" => "0",
      })

      configuration.release_after_idle_intervals.should eq(0)
      configuration.release_policy.enabled?.should be_false
      configuration.list_of_warnings.should be_empty
    end

    it "reads every variable when they are set" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_INTERVAL_SECONDS"             => "60",
        "MEMORY_TRACE_RELEASE_AFTER_IDLE_INTERVALS" => "4",
        "MEMORY_TRACE_IDLE_ALLOCATION_BYTES"        => "2097152",
        "MEMORY_TRACE_RELEASE_MINIMUM_FREE_BYTES"   => "8388608",
        "MEMORY_TRACE_RELEASE_REPEAT_INTERVALS"     => "6",
      })

      configuration.interval_seconds.should eq(60)
      configuration.interval.should eq(60.seconds)
      configuration.release_after_idle_intervals.should eq(4)
      configuration.idle_allocation_bytes.should eq(2_097_152_u64)
      configuration.release_minimum_free_bytes.should eq(8_388_608_u64)
      configuration.release_repeat_intervals.should eq(6)
      configuration.release_policy.required_consecutive_idle_intervals.should eq(4)
      configuration.list_of_warnings.should be_empty
    end

    it "accepts a byte count larger than Int32 can hold" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_RELEASE_MINIMUM_FREE_BYTES" => "4294967296",
      })

      configuration.release_minimum_free_bytes.should eq(4_294_967_296_u64)
      configuration.list_of_warnings.should be_empty
    end

    it "treats an interval of zero as disabled, not as garbage" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_INTERVAL_SECONDS" => "0",
      })

      configuration.enabled?.should be_false
      configuration.list_of_warnings.should be_empty
    end

    it "falls back to the default and warns on a value that is not a number" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_INTERVAL_SECONDS" => "soon",
      })

      configuration.interval_seconds.should eq(300)
      configuration.list_of_warnings.size.should eq(1)
      configuration.list_of_warnings.first.should contain("MEMORY_TRACE_INTERVAL_SECONDS")
    end

    it "falls back to the default and warns on a negative value" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_RELEASE_AFTER_IDLE_INTERVALS" => "-1",
      })

      configuration.release_after_idle_intervals.should eq(2)
      configuration.list_of_warnings.size.should eq(1)
      configuration.list_of_warnings.first.should contain("MEMORY_TRACE_RELEASE_AFTER_IDLE_INTERVALS")
    end

    it "falls back to the default and warns on a garbage byte count" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_IDLE_ALLOCATION_BYTES"      => "lots",
        "MEMORY_TRACE_RELEASE_MINIMUM_FREE_BYTES" => "-4096",
      })

      configuration.idle_allocation_bytes.should eq(1_048_576_u64)
      configuration.release_minimum_free_bytes.should eq(4_194_304_u64)
      configuration.list_of_warnings.size.should eq(2)
    end

    it "treats an empty variable as unset without warning" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_INTERVAL_SECONDS"      => "   ",
        "MEMORY_TRACE_IDLE_ALLOCATION_BYTES" => "",
      })

      configuration.interval_seconds.should eq(300)
      configuration.idle_allocation_bytes.should eq(1_048_576_u64)
      configuration.list_of_warnings.should be_empty
    end

    it "collects a warning per bad variable" do
      configuration = AgentC::MemoryTrace::Configuration.from_environment({
        "MEMORY_TRACE_INTERVAL_SECONDS"             => "nope",
        "MEMORY_TRACE_RELEASE_AFTER_IDLE_INTERVALS" => "also nope",
      })

      configuration.list_of_warnings.size.should eq(2)
    end
  end

  describe ".requested_for_environment?" do
    it "traces in production without any variable being set" do
      AgentC::MemoryTrace.requested_for_environment?(true, interval_was_set: false).should be_true
    end

    it "stays quiet outside production until the interval is explicitly set" do
      AgentC::MemoryTrace.requested_for_environment?(false, interval_was_set: false).should be_false
    end

    it "traces outside production once the interval is explicitly set" do
      AgentC::MemoryTrace.requested_for_environment?(false, interval_was_set: true).should be_true
    end
  end

  describe ".record_one_interval" do
    it "advances the interval counter without sleeping" do
      run = run_scripted([busy, busy, busy])

      run.state.interval_number.should eq(3)
    end

    it "never releases while releasing is switched off, however long the app idles" do
      run = run_scripted(
        [busy] + Array.new(9) { idle },
        configuration_with(release_after_idle_intervals: 0)
      )

      run.list_of_released_interval_numbers.should be_empty
      run.list_of_decisions.all?(&.keep_watching?).should be_true
    end

    it "does not treat the very first interval as idle, because there is nothing to compare it to" do
      run = run_scripted([idle], configuration_with(release_after_idle_intervals: 1))

      run.list_of_released_interval_numbers.should be_empty
      run.state.count_of_consecutive_idle_intervals.should eq(0)
    end

    it "releases on exactly the Nth consecutive idle interval, not before" do
      # Interval 1 establishes the allocation baseline; 2 and 3 are the two idle
      # intervals the default policy asks for.
      run = run_scripted([busy, idle, idle, idle])

      run.list_of_released_interval_numbers.should eq([3])
      run.list_of_decisions[1].should eq(AgentC::MemoryTrace::ReleaseDecision::KeepWatching)
      run.list_of_decisions[2].should eq(AgentC::MemoryTrace::ReleaseDecision::ReleaseNow)
    end

    it "resets the idle run when a busy interval lands in the middle of it" do
      run = run_scripted([busy, idle, busy, idle, idle])

      # Without the reset the release would have landed on interval 4.
      run.list_of_released_interval_numbers.should eq([5])
    end

    it "skips the release when there is too little free heap to be worth the pause" do
      run = run_scripted([busy(TOO_LITTLE_FREE), idle(TOO_LITTLE_FREE), idle(TOO_LITTLE_FREE)])

      run.list_of_released_interval_numbers.should be_empty
      run.list_of_decisions.last.should eq(AgentC::MemoryTrace::ReleaseDecision::SkipWithTooLittleFree)
    end

    it "keeps counting idle intervals through a skip, and releases as soon as the heap is worth it" do
      run = run_scripted([
        busy(TOO_LITTLE_FREE),
        idle(TOO_LITTLE_FREE),
        idle(TOO_LITTLE_FREE),
        idle(PLENTY_OF_FREE),
      ])

      run.state.count_of_consecutive_idle_intervals.should eq(3)
      run.list_of_released_interval_numbers.should eq([4])
    end

    it "does not release twice in a row while the app stays idle" do
      run = run_scripted([busy, idle, idle, idle, idle])

      run.list_of_released_interval_numbers.should eq([3])
      run.list_of_decisions.last.should eq(
        AgentC::MemoryTrace::ReleaseDecision::HoldAfterRecentRelease
      )
    end

    it "releases again once the app has been busy and gone idle again" do
      run = run_scripted([busy, idle, idle, idle, busy, idle, idle])

      run.list_of_released_interval_numbers.should eq([3, 7])
    end

    it "releases again after the repeat wait even when the app never goes busy" do
      run = run_scripted(
        [busy] + Array.new(8) { idle },
        configuration_with(release_repeat_intervals: 3)
      )

      # Released on 3, then every third idle interval after it.
      run.list_of_released_interval_numbers.should eq([3, 6, 9])
    end

    it "releases at most once an hour on the shipped defaults while an app idles for days" do
      # 12 repeat intervals at the 300-second default interval is one hour.
      run = run_scripted([busy] + Array.new(26) { idle })

      run.list_of_released_interval_numbers.should eq([3, 15, 27])
    end

    it "never lets a broken sample take the process down" do
      state = AgentC::MemoryTrace::TraceState.new
      exploding_source = ->(_interval_number : Int32) : AgentC::MemoryTrace::Sample do
        raise "no /proc today"
      end
      untouched_release = ->(_sample : AgentC::MemoryTrace::Sample) : AgentC::MemoryTrace::ReleaseOutcome do
        raise "must not be called"
      end

      decision = AgentC::MemoryTrace.record_one_interval(
        configuration_with, state, exploding_source, untouched_release
      )

      decision.should eq(AgentC::MemoryTrace::ReleaseDecision::KeepWatching)
      state.interval_number.should eq(1)
    end
  end

  describe ".current_process_reading" do
    it "answers a reading on every platform, with nils where /proc is absent" do
      reading = AgentC::MemoryTrace.current_process_reading

      {% if flag?(:linux) %}
        reading.rss_kib.should_not be_nil
      {% else %}
        reading.rss_kib.should be_nil
      {% end %}
    end
  end

  describe ".release_to_operating_system" do
    it "collects, unmaps, and reports what the heap did" do
      before = AgentC::MemoryTrace::Sample.from_reading(
        7, AgentC::MemoryTrace.current_process_reading, GC.stats
      )

      outcome = AgentC::MemoryTrace.release_to_operating_system(before)

      outcome.interval_number.should eq(7)
      outcome.heap_bytes_before.should eq(before.heap_bytes)
      outcome.rss_kib_before.should eq(before.rss_kib)
      outcome.to_log_line.should contain("memory.release n=7")
      outcome.to_log_line.should contain("rss_kib_after=")
    end
  end
end
