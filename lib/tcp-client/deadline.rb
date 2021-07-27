class TCPClient
  class Deadline < BasicObject
    if defined?(Process::CLOCK_MONOTONIC)
      def initialize(timeout)
        @deadline = timeout + Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def remaining_time
        @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    else
      def initialize(timeout)
        @deadline = ::Time.now + timeout
      end

      def remaining_time
        @deadline - ::Time.now
      end
    end

    def remaining(exception)
      (time = remaining_time) > 0 ? time : ::Kernel.raise(exception)
    end
    alias remaining? remaining
  end
end
