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
    return fetch_avail(deadline, exception) if nbytes.nil?
    return ''.b if nbytes.zero?
    @buf ||= ''.b
    while @buf.bytesize < nbytes
      read = fetch_next(deadline, exception) and next @buf << read
      close
      break
    end
    fetch_buffer_slice(nbytes)
  end

  def readto_with_deadline(sep, deadline, exception)
    raise(exception) unless deadline.remaining_time
    @buf ||= ''.b
    while (index = @buf.index(sep)).nil?
      read = fetch_next(deadline, exception) and next @buf << read
      close
      break
    end
    index = @buf.index(sep) and return fetch_buffer_slice(index + sep.bytesize)
    result = @buf
    @buf = nil
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

  def fetch_avail(deadline, exception)
    if @buf.nil?
      result = fetch_next(deadline, exception) and return result
      close
      return ''.b
    end
    result = @buf
    @buf = nil
    result
  end

  def fetch_buffer_slice(size)
    result = @buf.byteslice(0, size)
    rest = @buf.bytesize - result.bytesize
    @buf = rest.zero? ? nil : @buf.byteslice(size, rest)
    result
  end

  def fetch_next(deadline, exception)
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
