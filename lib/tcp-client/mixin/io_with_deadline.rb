module IOWithDeadlineMixin
  def self.included(mod)
    im = mod.instance_methods
    if im.index(:wait_writable) && im.index(:wait_readable)
      mod.include(ViaWaitMethod)
    else
      mod.include(ViaSelect)
    end
  end

  def read_with_deadline(nbytes, deadline, exclass)
    raise(exclass) if Time.now > deadline
    result = ''.b
    return result if nbytes.zero?
    loop do
      read =
        with_deadline(deadline, exclass) do
          read_nonblock(nbytes - result.bytesize, exception: false)
        end
      unless read
        close
        return result
      end
      result += read
      return result if result.bytesize >= nbytes
    end
  end

  def write_with_deadline(data, deadline, exclass)
    raise(exclass) if Time.now > deadline
    return 0 if (size = data.bytesize).zero?
    result = 0
    loop do
      written =
        with_deadline(deadline, exclass) do
          write_nonblock(data, exception: false)
        end
      result += written
      return result if result >= size
      data = data.byteslice(written, data.bytesize - written)
    end
  end

  module ViaWaitMethod
    private def with_deadline(deadline, exclass)
      loop do
        case ret = yield
        when :wait_writable
          raise(exclass) if (remaining_time = deadline - Time.now) <= 0
          raise(exclass) if wait_writable(remaining_time).nil?
        when :wait_readable
          raise(exclass) if (remaining_time = deadline - Time.now) <= 0
          raise(exclass) if wait_readable(remaining_time).nil?
        else
          return ret
        end
      end
    rescue Errno::ETIMEDOUT
      raise(exclass)
    end
  end

  module ViaSelect
    private def with_deadline(deadline, exclass)
      loop do
        case ret = yield
        when :wait_writable
          raise(exclass) if (remaining_time = deadline - Time.now) <= 0
          raise(exclass) if ::IO.select(nil, [self], nil, remaining_time).nil?
        when :wait_readable
          raise(exclass) if (remaining_time = deadline - Time.now) <= 0
          raise(exclass) if ::IO.select([self], nil, nil, remaining_time).nil?
        else
          return ret
        end
      end
    rescue Errno::ETIMEDOUT
      raise(exclass)
    end
  end

  private_constant(:ViaWaitMethod, :ViaSelect)
end
