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
    deadline.remaining?(exception)
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
    deadline.remaining?(exception)
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
          raise(exception) if wait_writable(deadline.remaining(exception)).nil?
        when :wait_readable
          raise(exception) if wait_readable(deadline.remaining(exception)).nil?
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
          if ::IO.select(nil, [self], nil, deadline.remaining(exception)).nil?
            raise(exception)
          end
        when :wait_readable
          if ::IO.select([self], nil, nil, deadline.remaining(exception)).nil?
            raise(exception)
          end
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
