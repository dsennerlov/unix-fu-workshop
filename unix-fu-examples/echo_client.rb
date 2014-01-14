require 'socket'
socket = UNIXSocket.open('echo.sock')
socket.write 'hej'
puts socket.readpartial(512)
