IOTimeoutError = Class.new(IOError) unless defined?(IOTimeoutError)

module IOTimeoutMixin
  def self.included(mod)
    im = mod.instance_methods
    mod.include(im.index(:wait_writable) && im.index(:wait_readable) ? WithDeadlineMethods : WidthDeadlineIO)
  end

  def read(nbytes, timeout: nil)
    timeout = timeout.to_f
    return read_all(nbytes){ |junk_size| super(junk_size) } if timeout <= 0
    deadline = Time.now + timeout
    read_all(nbytes) do |junk_size|
      with_deadline(deadline){ read_nonblock(junk_size, exception: false) }
    end
  end

  def write(*args, timeout: nil)
    timeout = timeout.to_f
    return write_all(args.join){ |junk| super(junk) } if timeout <= 0
    deadline = Time.now + timeout
    write_all(args.join) do |junk|
      with_deadline(deadline){ write_nonblock(junk, exception: false) }
    end
  end

  private

  def read_all(nbytes)
    return '' if nbytes == 0
    result = ''
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
    return 0 if 0 == (size = data.bytesize)
    result = 0
    loop do
      written = yield(data)
      result += written
      return result if result >= size
      data = data.byteslice(written, data.bytesize - written)
    end
  end

  module WithDeadlineMethods
    private

    def with_deadline(deadline)
      loop do
        case ret = yield
        when :wait_writable
          remaining_time = deadline - Time.now
          raise(IOTimeoutError) if remaining_time <= 0 || wait_writable(remaining_time).nil?
        when :wait_readable
          remaining_time = deadline - Time.now
          raise(IOTimeoutError) if remaining_time <= 0 || wait_readable(remaining_time).nil?
        else
          return ret
        end
      end
    end
  end

  module WidthDeadlineIO
    private

    def with_deadline(deadline)
      loop do
        case ret = yield
        when :wait_writable
          remaining_time = deadline - Time.now
          raise(IOTimeoutError) if remaining_time <= 0 || ::IO.select(nil, [self], nil, remaining_time).nil?
        when :wait_readable
          remaining_time = deadline - Time.now
          raise(IOTimeoutError) if remaining_time <= 0 || ::IO.select([self], nil, nil, remaining_time).nil?
        else
          return ret
        end
      end
    end
  end

  private_constant :WithDeadlineMethods, :WidthDeadlineIO
end
