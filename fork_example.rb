#if pid = Process.fork
#  puts "Parent is #{pid}"
#else
#  puts "Child is #{pid}"
#  exit
#end

@val = 1

pid = Process.fork {
  puts "Parent is #{pid}"
  @val += 1
  puts "Val #{@val}"
}

puts "Child is #{pid}"
Process.waitpid pid
puts "Val #{@val}"
puts "Exit now"

##############################################################################
# Resque example

class BigJob
  def self.work
    puts "Phew, working hard"
  end
end

class MiniResque
  def self.reserve
    #get job
    BigJob
  end

  def self.work
    loop do
      child_pid = fork {
        job = reserve
        job.work
      }

      Process.waitpid(child_pid)
    end
  end
end



##############################################################################
# Lock file example

lock_file = File.open "lockfile", "w"

if lockfile.flock(File::LOCK_EX | File::LOCK_NB)
  #work
else
  #exit
end

