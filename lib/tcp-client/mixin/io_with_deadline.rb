# frozen_string_literal: true

# @!visibility private
module IOWithDeadlineMixin # :nodoc:
  def self.included(mod)
    methods = mod.instance_methods
    if methods.index(:wait_writable) && methods.index(:wait_readable)
      mod.include(ViaWaitMethod)
    elsif methods.index(:to_io)
      mod.include(ViaIOWaitMethod)
    else
      mod.include(ViaSelect)
    end
  end

  def read_with_deadline(nbytes, deadline, exception)
    raise(exception) unless deadline.remaining_time
    if nbytes.nil?
      return read_next(deadline, exception) if @buf.nil?
      result, @buf = @buf, nil
      return result
    end
    return ''.b if nbytes.zero?
    @buf ||= read_next(deadline, exception).b
    @buf << read_next(deadline, exception) while @buf.bytesize < nbytes
    result = @buf.byteslice(0, nbytes)
    rest = @buf.bytesize - nbytes
    @buf = rest.zero? ? nil : @buf.byteslice(nbytes, rest)
    result
  end

  def readto_with_deadline(sep, deadline, exception)
    raise(exception) unless deadline.remaining_time
    @buf ||= read_next(deadline, exception).b
    @buf << read_next(deadline, exception) while (index = @buf.index(sep)).nil?
    index += sep.bytesize
    result = @buf.byteslice(0, index)
    rest = @buf.bytesize - result.bytesize
    @buf = rest.zero? ? nil : @buf.byteslice(index, rest)
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
      (result += written) >= size and return result
      data = data.byteslice(written, data.bytesize - written)
    end
  end

  private

  def read_next(deadline, exception)
    with_deadline(deadline, exception) do
      read_nonblock(65_536, exception: false)
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

  module ViaIOWaitMethod
    private def with_deadline(deadline, exception)
      loop do
        case ret = yield
        when :wait_writable
          remaining_time = deadline.remaining_time or raise(exception)
          raise(exception) if to_io.wait_writable(remaining_time).nil?
        when :wait_readable
          remaining_time = deadline.remaining_time or raise(exception)
          raise(exception) if to_io.wait_readable(remaining_time).nil?
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

  private_constant(:ViaWaitMethod, :ViaIOWaitMethod, :ViaSelect)
end
