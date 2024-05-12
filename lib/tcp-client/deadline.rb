# frozen_string_literal: true

class TCPClient
  class Deadline
    attr_accessor :exception

    def initialize(timeout, exception)
      @timeout = timeout.to_f
      @exception = exception
      @deadline = @timeout.positive? ? now + @timeout : nil
    end

    def valid? = !@deadline.nil?

    def remaining_time
      (remaining = @deadline - now) > 0 ? remaining : timed_out!(caller(1))
    end

    def timed_out!(call_stack = nil)
      raise(
        @exception,
        "execution expired - #{@timeout} seconds",
        call_stack || caller(1)
      )
    end

    private

    if defined?(Process::CLOCK_MONOTONIC)
      def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    else
      def now = ::Time.now
    end
  end

  private_constant(:Deadline)
end
