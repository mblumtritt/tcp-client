# frozen_string_literal: true

class TCPClient
  class Deadline
    def initialize(timeout)
      timeout = timeout&.to_f
      @deadline = timeout&.positive? ? now + timeout : nil
    end

    def valid?
      !@deadline.nil?
    end

    def remaining_time
      @deadline && (remaining = @deadline - now) > 0 ? remaining : nil
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
