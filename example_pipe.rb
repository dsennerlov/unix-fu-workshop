reader, writer = IO.pipe

pid = fork {
  reader.close
  writer.write('Hi parent process!')
}

writer.close

Process.wait(pid)
puts reader.read
#puts reader.readpartial(512)
