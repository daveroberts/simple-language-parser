require 'pry'

module SimpleLanguage
  class Tokenizer

    COMMENTS = [/^\s*;/, /^\s*\/\//, /\s*^#/]

    TOKEN_DEFS = [
      { type: :float, regex: /^[-+]?\d*\.\d+([eE][-+]?\d+)?/ },
      { type: :int, regex: /^\d+/ },
      { type: :null, regex: /^null/ },
      { type: :true, regex: /^true/ },
      { type: :false, regex: /^false/ },
      { type: :double_equals, regex: /^==/ },
      { type: :not_equals, regex: /^!=/ },
      { type: :equals, regex: /^=/ },
      { type: :return, regex: /^return/ },
      { type: :if, regex: /^if/ },
      { type: :elsif, regex: /^elsif/ },
      { type: :else, regex: /^else/ },
      { type: :foreach, regex: /^foreach/ },
      { type: :in, regex: /^in/ },
      { type: :loop, regex: /^loop/ },
      { type: :while, regex: /^while/ },
      { type: :break, regex: /^break/ },
      { type: :arrow, regex: /^\-\>/ },
      { type: :less_than_or_equals, regex: /^\<=/ },
      { type: :less_than, regex: /^\</ },
      { type: :greater_than_or_equals, regex: /^\>=/ },
      { type: :greater_than, regex: /^\>/ },
      { type: :plus, regex: /^\+/ },
      { type: :minus, regex: /^\-/ },
      { type: :multiply, regex: /^\*/ },
      { type: :divide, regex: /^\// },
      { type: :doublepipe, regex: /^\|\|/ },
      { type: :pipe, regex: /^\|/ },
      { type: :doublepipe, regex: /^\|/ },
      { type: :left_paren, regex: /^\(/ },
      { type: :right_paren, regex: /^\)/ },
      { type: :left_curly, regex: /^\{/ },
      { type: :right_curly, regex: /^\}/ },
      { type: :left_bracket, regex: /^\[/ },
      { type: :right_bracket, regex: /^\]/ },
      { type: :comma, regex: /^\,/ },
      { type: :whitespace, regex: /^\s/ },
      { type: :symbol, regex: /^[A-Za-z_]+:/ },
      { type: :symbol, regex: /^:[A-Za-z_]+/ },
      { type: :word, regex: /^[A-Za-z_]+/ },
      { type: :string, regex: /^`[^`\\]*(?:\\.[^`\\]*)*`/ },
      { type: :string, regex: /^"[^"\\]*(?:\\.[^"\\]*)*"/ },
      { type: :string, regex: /^'[^'\\]*(?:\\.[^'\\]*)*'/ },
    ]

      def tokenize(script)
        tokens = []
        # Remove comments
        script = script.split("\n").select{|line|
          match_any = false
          COMMENTS.each do |comment|
            next if !line.match(comment)
            match_any = true
            break
          end
          !match_any
        }.join(" ")
        while script.length > 0
          any_match = false
          TOKEN_DEFS.each do |td|
            match = script.match(td[:regex])
            if match
              any_match = true
              if td[:type] != :whitespace
                tokens.push({type: td[:type], value: match[0]})
              end
              raise Exception, "Parse error.  Matched on #{td[:type]}, but match section was empty.  Script: #{script}" if match[0].length == 0
              script = script.sub(match[0], "")
              break
            end
          end
          raise Exception, "Parse error.  Could not find a token for code: #{script}" if !any_match
        end
        return tokens
      end
  end
end
