require 'readline'
require 'shellwords'

BUILTINS = {
  'exit' => -> {exit}
#  'cd' => -> {|dir| Dir.chdir(dir)}
}

while input = Readline.readline("$ ") do
  if BUILTINS[input]
    BUILTINS[input].call
  else
    pid = fork {
      command, *args = Shellwords.shellsplit(input)

      exec(command, *args)
    }
  end

  Process.wait(pid)
end
