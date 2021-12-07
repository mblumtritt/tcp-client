# frozen_string_literal: true

class TCPClient
  class Deadline
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

    if defined?(Process::CLOCK_MONOTONIC)
      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    else
      def now
        ::Time.now
      end
    end
  end

  private_constant(:Deadline)
end
