# frozen_string_literal: true

class TCPClient
  module IOWithDeadlineMixin
    class << self
      private

      def included(mod)
        return if supports_wait?(mod)
        mod.include(mod.method_defined?(:to_io) ? WaitWithIO : WaitWithSelect)
      end

      def supports_wait?(mod)
        mod.method_defined?(:wait_writable) &&
          mod.method_defined?(:wait_readable)
      end
    end

    def read_with_deadline(nbytes, deadline, exception)
      raise(exception) unless deadline.remaining_time
      return fetch_avail(deadline, exception) if nbytes.nil?
      return ''.b if nbytes.zero?
      @read_buffer ||= ''.b
      while @read_buffer.bytesize < nbytes
        read = fetch_next(deadline, exception) and next @read_buffer << read
        close
        break
      end
      fetch_slice(nbytes)
    end

    def read_to_with_deadline(sep, deadline, exception)
      raise(exception) unless deadline.remaining_time
      @read_buffer ||= ''.b
      while @read_buffer.index(sep).nil?
        read = fetch_next(deadline, exception) and next @read_buffer << read
        close
        break
      end
      index = @read_buffer.index(sep)
      return fetch_slice(index + sep.bytesize) if index
      result = @read_buffer
      @read_buffer = nil
      result
    end

    def write_with_deadline(data, deadline, exception)
      return 0 if (size = data.bytesize).zero?
      raise(exception) unless deadline.remaining_time
      result = 0
      while true
        written =
          with_deadline(deadline, exception) do
            write_nonblock(data, exception: false)
          end
        (result += written) >= size and return result
        data = data.byteslice(written, data.bytesize - written)
      end
    end

    private

    def fetch_avail(deadline, exception)
      if (result = @read_buffer || fetch_next(deadline, exception)).nil?
        close
        return ''.b
      end
      @read_buffer = nil
      result
    end

    def fetch_slice(size)
      return ''.b if size.zero?
      result = @read_buffer.byteslice(0, size)
      rest = @read_buffer.bytesize - result.bytesize
      @read_buffer = rest.zero? ? nil : @read_buffer.byteslice(size, rest)
      result
    end

    def fetch_next(deadline, exception)
      with_deadline(deadline, exception) do
        read_nonblock(65_536, exception: false)
      end
    end

    def with_deadline(deadline, exception)
      while true
        case ret = yield
        when :wait_writable
          remaining_time = deadline.remaining_time or raise(exception)
          wait_writable(remaining_time) or raise(exception)
        when :wait_readable
          remaining_time = deadline.remaining_time or raise(exception)
          wait_readable(remaining_time) or raise(exception)
        else
          return ret
        end
      end
    rescue Errno::ETIMEDOUT
      raise(exception)
    end

    module WaitWithIO
      def wait_writable(remaining_time)
        to_io.wait_writable(remaining_time)
      end

      def wait_readable(remaining_time)
        to_io.wait_readable(remaining_time)
      end
    end

    module WaitWithSelect
      def wait_writable(remaining_time)
        ::IO.select(nil, [self], nil, remaining_time)
      end

      def wait_readable(remaining_time)
        ::IO.select([self], nil, nil, remaining_time)
      end
    end

    private_constant(:WaitWithIO, :WaitWithSelect)
  end

  private_constant(:IOWithDeadlineMixin)
end
