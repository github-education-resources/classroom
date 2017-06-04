delimiter = ARGV[0]
engine = ARGV[1]
handler = case engine
  when 'erubi'
    require 'erubi'
    Erubi::Engine
  when 'erubis'
    require 'erubis'
    Erubis::Eruby
  when 'erb'
    require 'erb'
    ERB
  else raise "Unknown templating engine `#{engine}`"
end

if engine == 'erubi'
  puts "#{delimiter}#{eval(handler.new(STDIN.read).src)}#{delimiter}"
else
  puts "#{delimiter}#{handler.new(STDIN.read).result}#{delimiter}"
end
