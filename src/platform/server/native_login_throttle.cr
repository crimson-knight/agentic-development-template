require "amber/support/server_only"

module App::Server
  # Bounded per-process admission; a deployment with several workers/proxies
  # additionally needs a shared edge limit. Forwarded-IP headers are not trusted.
  class NativeLoginThrottle
    @buckets = {} of String => {Time::Span, Int32}
    @mutex = Mutex.new

    def initialize(@limit = 10, @window = 1.minute, @capacity = 4096)
    end

    def allow?(peer : String, now = Time.monotonic) : Bool
      @mutex.synchronize do
        @buckets.reject! { |_, value| now - value[0] >= @window }
        if previous = @buckets[peer]?
          return false if previous[1] >= @limit
          @buckets[peer] = {previous[0], previous[1] + 1}
        else
          return false if @buckets.size >= @capacity
          @buckets[peer] = {now, 1}
        end
        true
      end
    end

    {% if @top_level.has_constant?("Spec") %}
      def reset_for_spec : Nil
        @mutex.synchronize { @buckets.clear }
      end
    {% end %}
  end
end
