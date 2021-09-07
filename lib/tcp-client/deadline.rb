# frozen_string_literal: true

class TCPClient
  class Deadline
    MONOTONIC = defined?(Process::CLOCK_MONOTONIC) ? true : false

    def initialize(timeout)
      timeout = timeout&.to_f
      @deadline = timeout&.positive? ? now + timeout : 0
    end

    def valid?
      @deadline != 0
    end

    def remaining_time
      (@deadline != 0) && (remaining = @deadline - now) > 0 ? remaining : nil
    end

    private

    if MONOTONIC
      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    else
      def now
        ::Time.now
      end
    end
  end
end
