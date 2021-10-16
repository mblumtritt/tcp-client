# frozen_string_literal: true

module IOWithDeadlineMixin
  def self.included(mod)
    methods = mod.instance_methods
    if methods.index(:wait_writable) && methods.index(:wait_readable)
      mod.include(ViaWaitMethod)
    else
      mod.include(ViaSelect)
    end
  end

  def read_with_deadline(bytes_to_read, deadline, exception)
    raise(exception) unless deadline.remaining_time
    if bytes_to_read.nil?
      return(
        with_deadline(deadline, exception) do
          read_nonblock(65_536, exception: false)
        end
      )
    end
    result = ''.b
    while result.bytesize < bytes_to_read
      read =
        with_deadline(deadline, exception) do
          read_nonblock(bytes_to_read - result.bytesize, exception: false)
        end
      next result += read if read
      close
      break
    end
    result
  end

  def write_with_deadline(data, deadline, exception)
    raise(exception) unless deadline.remaining_time
    return 0 if (size = data.bytesize).zero?
    result = 0
    loop do
      written =
        with_deadline(deadline, exception) do
          write_nonblock(data, exception: false)
        end
      result += written
      return result if result >= size
      data = data.byteslice(written, data.bytesize - written)
    end
  end

  module ViaWaitMethod
    private def with_deadline(deadline, exception)
      loop do
        case ret = yield
        when :wait_writable
          remaining_time = deadline.remaining_time or raise(exception)
          raise(exception) if wait_writable(remaining_time).nil?
        when :wait_readable
          remaining_time = deadline.remaining_time or raise(exception)
          raise(exception) if wait_readable(remaining_time).nil?
        else
          return ret
        end
      end
    rescue Errno::ETIMEDOUT
      raise(exception)
    end
  end

  module ViaSelect
    private def with_deadline(deadline, exception)
      loop do
        case ret = yield
        when :wait_writable
          remaining_time = deadline.remaining_time or raise(exception)
          raise(exception) if ::IO.select(nil, [self], nil, remaining_time).nil?
        when :wait_readable
          remaining_time = deadline.remaining_time or raise(exception)
          raise(exception) if ::IO.select([self], nil, nil, remaining_time).nil?
        else
          return ret
        end
      end
    rescue Errno::ETIMEDOUT
      raise(exception)
    end
  end

  private_constant(:ViaWaitMethod, :ViaSelect)
end
