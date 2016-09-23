require 'treetop'

  require_relative 'metric_parser_node_extentions.rb'

class MetricExpressionParser

  base_path = File.expand_path(File.dirname(__FILE__))

  Treetop.load(File.join(base_path, 'metric_parser_extentions.treetop'))
  @@parser = MexParser.new


  def self.parse(data)

      # Pass the data over to the parser instance
      tree = @@parser.parse(data)

      # If the AST is nil then there was an error during parsing
      # we need to report a simple error message to help the user
      if(tree.nil?)
        puts "Input : #{data}"
        puts @@parser.terminal_failures.join("\n")
        raise Exception, "Parse error: #{@@parser.failure_reason}"
      # else
      #   puts "Result => #{tree.value}\n"
     end

     return tree.value
  end

end