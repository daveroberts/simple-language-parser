module SimpleLanguage
  class Tokenizer
    MATCHES = [
      { name: :comment, regex: /\A\/\*.*?\*\//m },
      { name: :comment, regex: /\A\/\/.*?\n/ },
      { name: :string, regex: /\A"""\n(.*?)\n"""/m },
      { name: :double_quoted_string, regex: /\A"((?:[^"\\]|\\.)*)"/ },
      { name: :single_quoted_string, regex: /\A'((?:[^'\\]|\\.)*)'/ },
      { name: :backtick_string, regex: /\A`((?:[^`\\]|\\.)*)`/ },
      { name: :regex, regex: /\A\/(?:[^\/\\]|\\.)*\/[i|m]*/ },
      { name: :whitespace, regex: /\A\s+/ },
      { name: :symbol, regex: /\A:([a-z][a-z0-9_]+)/ },
      { name: :symbol, regex: /\A([a-z][a-z0-9_]+):/ },
      { name: :identifier, regex: /\A[A-Za-z][A-Za-z0-9_]*/ },
      { name: :number, regex: /\A[0-9]+/ },
      { name: :colon, regex: /\A:/ },
      { name: :question_mark, regex: /\A\?/ },
      { name: :double_ampersand, regex: /\A&&/ },
      { name: :double_equals, regex: /\A==/ },
      { name: :not_equals, regex: /\A!=/ },
      { name: :equals, regex: /\A=/ },
      { name: :arrow, regex: /\A\-\>/ },
      { name: :less_than_or_equals, regex: /\A\<=/ },
      { name: :less_than, regex: /\A\</ },
      { name: :greater_than_or_equals, regex: /\A\>=/ },
      { name: :greater_than, regex: /\A\>/ },
      { name: :plus, regex: /\A\+/ },
      { name: :minus, regex: /\A\-/ },
      { name: :multiply, regex: /\A\*/ },
      { name: :divide, regex: /\A\\/ },
      { name: :dot, regex: /\A\./ },
      { name: :double_pipe, regex: /\A\|\|/ },
      { name: :pipe, regex: /\A\|/ },
      { name: :left_paren, regex: /\A\(/ },
      { name: :right_paren, regex: /\A\)/ },
      { name: :left_curly, regex: /\A\{/ },
      { name: :right_curly, regex: /\A\}/ },
      { name: :comma, regex: /\A\,/ },
      { name: :left_bracket, regex: /\A\[/ },
      { name: :right_bracket, regex: /\A\]/ },
    ]

    def self.lex(str)
      tokens = []
      while str.length > 0
        any_match = false
        MATCHES.each do |token|
          match = token[:regex].match(str)
          if match
            any_match = true
            if token[:name] == :double_quoted_string
              val = match[1].gsub('\\"','"')
              tokens.push({
                type: :string,
                value: val
              })
            elsif token[:name] == :single_quoted_string
              val = match[1].gsub("\\'","'")
              tokens.push({
                type: :string,
                value: val
              })
            elsif token[:name] == :backtick_string
              val = match[1].gsub("\\`","`")
              tokens.push({
                type: :template_string,
                value: val
              })
            elsif token[:name] == :whitespace
            elsif token[:name] == :comment
            else
              tokens.push({
                type: token[:name],
                value: match[1] ? match[1] : match[0]
              })
            end
            raise Exception, "Zero length match" if match[0].length == 0
            str = str[match[0].length..-1]
            break
          end
        end
        if !any_match
          puts "___"
          puts str
          puts "---"
          raise Exception, "No match"
        end
      end
      return tokens
    end
  end
end
