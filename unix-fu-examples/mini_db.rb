# Exercise 
# ========
# Given what you just learned about fork, implement the #background_save
# method that will call the slow #save without blocking other commands.  
# In other words, perform the #save, but let the db continue processing 
# commands.
  
# Bonus Challenges
# ===============
# How would you prevent multiple background saves from occuring at the same time?
# How would you ensure that the DB doesn't exit until all pending saves are finished?

require 'yaml'

class MiniDb
  BACKUP_LOCATION = 'minidb.backup'
  
  attr_reader :background_save_pid
  def initialize
    @backend = Hash.new

  end
  
  def get(key)
    @backend[key]
  end
  
  def set(key, value)
    @backend[key] = value
  end
  
  def save
    File.open(BACKUP_LOCATION, 'w') do |file|  
      file.flock(File::LOCK_EX)

      sleep 3 # pretend it's slow
      file.write(YAML.dump(@backend))
    end
  end
  
  def background_save
    @background_save_pid = fork {
      save
    }
  end
end

# Simple testing of the db

db = MiniDb.new

at_exit {
  begin
    db.background_save_pid && Process.waitpid(db.background_save_pid)
  rescue Errno::ECHILD
  end
}

db.set('prez', 'obama')
puts db.get('prez')

db.background_save
db.set('phaser', 'stun')

db.background_save
puts db.get('phaser')

