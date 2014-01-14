SIGNAL_QUEUE = []

[:INT, :QUIT, :TERM].each do |sig|
  Signal.trap(sig) {SIGNAL_QUEUE << sig}
end

#defered signal handling
loop do
  case SIGNAL_QUEUE.shift
  when :INT
    #do stuff here
    exit
  when :QUIT
  when :TERM
  else
    sleep 1
  end
end
