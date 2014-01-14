require 'readline'
require 'shellwords'

BUILTINS = {
  'exit' => -> { exit }
  #'cd' => -> { |dir| Dir.chdir(dir) }
}
PIDS = []
while input = Readline.readline("$ ") do
  if BUILTINS[input]
    BUILTINS[input].call
  else
    commands = input.split("|")
    # ["ls", "grep md"]

    # Exercise
    # ========
    # Assuming that you have two commands connected by a pipe,
    # how would you spawn them both and hook up the pipeline?
    #
    # $ ls | grep md
    #
    # Bonus challenge
    # ===============
    # Assuming that you have N commands connected in a pipeline,
    # how would you spawn them all and hook up pipes between them?
    #
    # $ ls | grep md | wc -c | pbcopy

    rd = []
    wr = []
    commands.length.times do |i|
      rd[i], wr[i] = IO.pipe
    end

    commands.length.times do |i|

      PIDS << fork {
        command, *args = Shellwords.shellsplit(commands[i])
        $stdout.reopen(wr[i])
        exec(command[i], *args)
      }
    end
    commands.length.times do |i|
      rd[i].close
      wr[i].close
    end
    Process.waitall
  end
end

