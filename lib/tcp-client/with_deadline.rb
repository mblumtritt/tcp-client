# frozen_string_literal: true

class TCPClient
  module WithDeadline
    def read_with_deadline(nbytes, deadline)
      deadline.remaining_time
      return fetch_avail(deadline) if nbytes.nil?
      @read_buffer ||= ''.b
      while (diff = nbytes - @read_buffer.bytesize) > 0
        read = fetch_next(deadline, diff)
        read ? @read_buffer << read : (break close)
      end
      fetch_slice(nbytes)
    end

    def read_to_with_deadline(sep, deadline)
      deadline.remaining_time
      @read_buffer ||= ''.b
      while (index = @read_buffer.index(sep)).nil?
        read = fetch_next(deadline)
        read ? @read_buffer << read : (break close)
      end
      return fetch_slice(index + sep.bytesize) if index
      result = @read_buffer
      @read_buffer = nil
      result
    end

    def write_with_deadline(data, deadline)
      return 0 if (size = data.bytesize).zero?
      deadline.remaining_time
      result = 0
      while true
        written =
          with_deadline(deadline) { write_nonblock(data, exception: false) }
        return result if (result += written) >= size
        data = data.byteslice(written, data.bytesize - written)
      end
    end

    private

    def fetch_avail(deadline)
      if (result = @read_buffer || fetch_next(deadline)).nil?
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

    def fetch_next(deadline, size = 65_536)
      with_deadline(deadline) { read_nonblock(size, exception: false) }
    end

    def with_deadline(deadline)
      while true
        case ret = yield
        when :wait_writable
          wait_write[deadline.remaining_time] or deadline.timed_out!
        when :wait_readable
          wait_read[deadline.remaining_time] or deadline.timed_out!
        else
          return ret
        end
      end
    rescue Errno::ETIMEDOUT
      deadline.timed_out!
    end

    def wait_write
      @wait_write ||=
        if defined?(wait_writable)
          ->(t) { wait_writable(t) }
        elsif defined?(to_io)
          ->(t) { to_io.wait_writable(t) }
        else
          ->(t) { ::IO.select(nil, [self], nil, t) }
        end
    end

    def wait_read
      @wait_read ||=
        if defined?(wait_readable)
          ->(t) { wait_readable(t) }
        elsif defined?(to_io)
          ->(t) { to_io.wait_readable(t) }
        else
          ->(t) { ::IO.select([self], nil, nil, t) }
        end
    end
  end

  private_constant(:WithDeadline)
end
