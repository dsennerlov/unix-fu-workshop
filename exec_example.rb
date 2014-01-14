exec('ls')

null = File.open('/dev/null')

exec("NULL_FD=#{null.fileno} ruby -e \"puts IO.for_fd()")
