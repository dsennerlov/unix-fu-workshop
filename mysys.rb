def my_system(cmd)
  pid = fork {
    begin
      exec(cmd)
    rescue Errno::ENOENT
      exit 1
    end
  }
  _, status = Process.wait2(pid)
  status.success? || nil
end
