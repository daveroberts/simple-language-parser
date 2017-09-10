require 'pry'

file = File.read('sample.scrape')
program = file.split " "
@stack = []
@variables = {}

def go(url)
  #puts "Navigating browser to #{url}"
end

def grablinks()
  #puts "Grabbing links from current page"
  return ["link1","link2","link3","link4"]
end

def click(sel)
  # dummy click on selector
end

def parselinks(links, regex)
  #puts "parsing #{links.count} links with #{regex}"
  chosen_links = []
  chosen = true
  links.each do |link|
    chosen_links.push(link) if chosen
    chosen = !chosen
  end
  return chosen_links
end

def grabcss(sel)
  #puts "grabbing #{sel} from page"
  return "Content found in #{sel}"
end

def has_element?(sel)
  return sel.start_with? "true"
end

def evaluate(program)
  loop do
    break if program.length == 0
    cmd = program.shift
    if cmd.start_with? '"'
      strval = cmd[1..cmd.length-2]
      @stack.push strval
    elsif cmd.start_with? "/"
      @stack.push Regexp.new(cmd)
    elsif cmd.start_with? ":"
      @stack.push cmd[1..cmd.length].to_sym
    elsif cmd == "["
      arr = []
      count = 1
      loop do
        next_cmd = program.shift
        count = count + 1 if next_cmd == '['
        count = count - 1 if next_cmd == ']'
        break if count == 0
        arr.push next_cmd
      end
      @stack.push arr
    elsif cmd == "let"
      sym = @stack.pop
      value = @stack.pop
      @variables[sym] = value
    elsif cmd == "print"
      sym = @stack.pop
      puts @variables[sym]
    elsif cmd == "set"
      map = @stack.pop
      sym = @stack.pop
      value = @stack.pop
      @variables[map][sym] = value
    elsif cmd == "arr"
      sym = @stack.pop
      @variables[sym] = []
    elsif cmd == "map"
      sym = @stack.pop
      @variables[sym] = {}
    elsif cmd == "val"
      sym = @stack.pop
      @stack.push @variables[sym]
    elsif cmd == "push"
      value = @stack.pop
      sym = @stack.pop
      @variables[sym].push value
    elsif cmd == "loop"
      sym = @stack.pop
      collection = @variables[@stack.pop]
      loop = @stack.pop
      collection.each do |item|
        @variables[sym] = item
        evaluate(loop.dup)
      end
    elsif cmd == "if"
      bool = @stack.pop
      f_block = @stack.pop
      t_block = @stack.pop
      if bool
        evaluate(t_block.dup)
      else
        evaluate(f_block.dup)
      end
    elsif cmd == "concat"
      arr = @stack.pop
      @stack.push(arr.join())
    elsif cmd == "go"
      url = @stack.pop
      go(url)
    elsif cmd == "grablinks"
      links = grablinks()
      @stack.push(links)
    elsif cmd == "grabcss"
      sel = @stack.pop
      content = grabcss(sel)
      @stack.push(content)
    elsif cmd == "has_element?"
      sel = @stack.pop
      @stack.push(has_element?(sel))
    elsif cmd == "click"
      sel = @stack.pop
      click(sel)
    elsif cmd == "parselinks"
      sym = @stack.pop
      links = @variables[sym]
      regex = @stack.pop
      parsed_links = parselinks(links, regex)
      @stack.push(parsed_links)
    else
      puts "I don't understand #{cmd}"
      exit(-1)
    end
  end
end

evaluate(program)