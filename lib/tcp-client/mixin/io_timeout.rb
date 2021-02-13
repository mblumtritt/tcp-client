# I keep this file for backward compatibility.
# This may be removed in one of the next versions.
# Let me know if you like to use it elsewhere...

IOTimeoutError = Class.new(IOError) unless defined?(IOTimeoutError)

module IOTimeoutMixin
  def self.included(mod)
    im = mod.instance_methods
    if im.index(:wait_writable) && im.index(:wait_readable)
      mod.include(DeadlineMethods)
    else
      mod.include(DeadlineIO)
    end
  end

  def read_with_deadline(nbytes, deadline, exception)
    result = ''.b
    return result if nbytes.zero?
    loop do
      junk_size = nbytes - result.bytesize
      read =
        with_deadline(deadline, exception) do
          read_nonblock(junk_size, exception: false)
        end
      unless read
        close
        return result
      end
      result += read
      return result if result.bytesize >= nbytes
    end
  end

  def read(nbytes, timeout: nil, exception: IOTimeoutError)
    timeout = timeout.to_f
    return read_all(nbytes) { |junk_size| super(junk_size) } if timeout <= 0
    deadline = Time.now + timeout
    read_all(nbytes) do |junk_size|
      with_deadline(deadline, exception) do
        read_nonblock(junk_size, exception: false)
      end
    end
  end

  def write(*msgs, timeout: nil, exception: IOTimeoutError)
    timeout = timeout.to_f
    return write_all(msgs.join.b) { |junk| super(junk) } if timeout <= 0
    deadline = Time.now + timeout
    write_all(msgs.join.b) do |junk|
      with_deadline(deadline, exception) do
        write_nonblock(junk, exception: false)
      end
    end
  end

  private

  def read_all(nbytes)
    return ''.b if nbytes.zero?
    result = ''.b
    loop do
      unless read = yield(nbytes - result.bytesize)
        close
        return result
      end
      result += read
      return result if result.bytesize >= nbytes
    end
  end

  def write_all(data)
    return 0 if (size = data.bytesize).zero?
    result = 0
    loop do
      written = yield(data)
      result += written
      return result if result >= size
      data = data.byteslice(written, data.bytesize - written)
    end
  end

  module DeadlineMethods
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
    end
  end

  module DeadlineIO
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
    end
  end

  private_constant(:DeadlineMethods, :DeadlineIO)
end
