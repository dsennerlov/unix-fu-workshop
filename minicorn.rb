require 'socket'
require 'rack'
require 'rack/builder'
require 'http_tools'

#TODO
# automatic cleanup of old master
# spawn new master in same console
# generic reexec file name
#

class Minicorn
  NUM_WORKERS = 4
  CHILD_PIDS = []
  SIGNAL_QUEUE = []
  SELF_PIPE_R, SELF_PIPE_W = IO.pipe

  def initialize(port = 8080)
    puts "Master process ID: #{Process.pid}"

    if listener_fd = ENV['LISTENER_FD']
      @listener = TCPServer.for_fd(listener_fd.to_i)
    else
#      @listener = TCPServer.new(port)
      # socket(2)
      @listener = Socket.new(:INET, :STREAM)
      @listener = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)

      # bind (2)
      @listener.bind(Socket.sockaddr_in(port, '0.0.0.0'))

      @listener.setsockopt(:SOCKET, :REUSEADDR, true)
      @listener.setsockopt(:SOCKET, :REUSEPORT, true)

      # listen(2)
      @listener.listen(512)
    end
  end

  def load_app
    rackup_file = 'config.ru'
    @app, options = Rack::Builder.parse_file(rackup_file)
  end

  def run
    load_app
    spawn_workers
    trap_signals
    set_title
    main_loop
  end

  def main_loop
    loop do
      rs = IO.select([SELF_PIPE_R])
      SELF_PIPE_R.read(1)
#      if r = rs[0]
#        r.read(1)
#      end

      case SIGNAL_QUEUE.shift
      when :INT, :QUIT, :TERM
        shutdown
      when :USR2
        reexec
      when :CHLD
        pid = Process.wait
        if CHILD_PIDS.delete(pid)
          spawn_worker
        end
      end
    end
  end

  def set_title
    $PROGRAM_NAME = "Minicorn master"
  end

  def trap_signals
    [:INT, :QUIT, :TERM, :USR2, :CHLD].each do |sig|
      Signal.trap(sig) {
        SIGNAL_QUEUE << sig
        SELF_PIPE_W.write_nonblock('.')
      }
    end
  end

  def reexec
    fork {
      $PROGRAM_NAME = "Minicorn New master"

      ENV['LISTENER_FD'] = @listener.fileno.to_s
      exec("ruby minicorn.rb", { @listener.fileno => @listener })
    }
    Process.kill("INT", Process.pid)
  end

  def shutdown
    CHILD_PIDS.each do |pid|
      Process.kill(:INT, pid)
    end

    sleep 1

    CHILD_PIDS.each do |pid|
      begin
        Process.waitpid(pid, Process::WNOHANG)
        Process.kill(:KILL, pid)
      rescue Errno::ECHILD, Errno::ESRCH
      end
    end

    exit
  end

  def trap_child_signals
    Signal.trap(:INT) {
      exit
    }
  end

  #after_fork do...

  #heartbeat
  def spawn_workers
    NUM_WORKERS.times do |num|
      spawn_worker
    end
  end

  def spawn_worker
    CHILD_PIDS << fork {

    #  after_fork

      $PROGRAM_NAME = "Minicorn worker #{num}"
      trap_child_signals
      work_runner(num)
    }
  end

  def work_runner(num)
    puts "Process ##{num} running"
    loop do
      connection, _ = @listener.accept
      #data = connection.read
      #vs
      raw_request = connection.readpartial(4096)

      parser = HTTPTools::Parser.new

      parser.on(:finish) do
        env = parser.env.merge!("rack.multiprocess" => true)
        status, header, body = @app.call(env)

        header['Connection'] = 'close'
        connection.write HTTPTools::Builder.response(status, header)

        body.each { |chunk| connection.write chunk }
        body.close if body.respond_to? :close
      end

      parser << raw_request
      connection.close
      puts "##{num} handled request"
    end
  end
end

server = Minicorn.new
server.run
