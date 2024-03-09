# frozen_string_literal: true

class TCPClient
  module IOWithDeadlineMixin
    class << self
      private

      def included(mod)
        return if defined?(mod.wait_writable) && defined?(mod.wait_readable)
        mod.include(defined?(mod.to_io) ? WaitWithIO : WaitWithSelect)
      end
    end

    def read_with_deadline(nbytes, deadline, exception)
      raise(exception) unless deadline.remaining_time
      return fetch_avail(deadline, exception) if nbytes.nil?
      @read_buffer ||= ''.b
      while @read_buffer.bytesize < nbytes
        read = fetch_next(deadline, exception)
        read ? @read_buffer << read : (break close)
      end
      fetch_slice(nbytes)
    end

    def read_to_with_deadline(sep, deadline, exception)
      raise(exception) unless deadline.remaining_time
      @read_buffer ||= ''.b
      while (index = @read_buffer.index(sep)).nil?
        read = fetch_next(deadline, exception)
        read ? @read_buffer << read : (break close)
      end
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
        return result if (result += written) >= size
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
      return ''.b if size <= 0
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
      def wait_writable(time) = to_io.wait_writable(time)
      def wait_readable(time) = to_io.wait_readable(time)
    end

    module WaitWithSelect
      def wait_writable(time) = ::IO.select(nil, [self], nil, time)
      def wait_readable(time) = ::IO.select([self], nil, nil, time)
    end

    private_constant(:WaitWithIO, :WaitWithSelect)
  end

  private_constant(:IOWithDeadlineMixin)
end
