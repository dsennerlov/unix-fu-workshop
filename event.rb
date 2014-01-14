require 'socket'

class Minivent
  class Stream
    def initialize(client)
      @client = client
    end

    def on_readable(data)
    end

    def write(data)
      begin
        to_io.write_nonblock(data)
      rescue Errno::EWOULDBLOCK
        rest = data[bytes..-1]

        @pending = rest
      end
    end

    def pending?
      @pending
    end

    def pending_write
      @pending
    end

    def pending_write?
      !!@penging
    end

    def to_io
      @client
    end
  end

  class Server
    def initialize(port, stream_class)
      @server = TCPServer.new(port)
      @streams =[]
      @stream_class = stream_class
    end

    def tick
      monitor_for_reading = @streams + [@server]
      monitor_for_writing = @streams.select(&:pending_write?)
      ready = IO.select(monitor_for_reading, monitor_for_writing)
      readables = ready.first
      readables.each do |readable|
        if readable == @server
          begin
            client = @server.accept_nonblock
            stream = @stream_class.new(client)
            @streams << stream
          rescue Errno::EWOULDBLOCK
          end

        else #client
          begin
            data = readable.to_io.read_nonblock(512)
            readable.on_readable(data)
            readable.write(data)
          rescue Errno::EWOULDBLOCK
          rescue Errno::EOFError
            readable.close
            @streams.delete(stream)
          end

          readable.close
          @monitor_for_reading.delete readable
        end
      end

      writables.each do |writables|
        writable.write(writable.pending_write)
      end
    end

    def run
      loop {
        tick
      }
    end
  end
end



class EchoStream < Minivent::Stream
  def on_readable(data)
    write(data)
  end
end
event = Minivent.new(3355, EchoStream)
event.run
