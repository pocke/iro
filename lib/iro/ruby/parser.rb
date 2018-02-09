module Iro
  module Ruby
    class Parser < Ripper::SexpBuilderPP
      using RipperWrapper

      EVENT_NAME_TO_HIGHLIGT_NAME = {
        tstring_content: 'String',
        CHAR: 'Character',
        int: 'Number',
        float: 'Float',
        
        kw: 'Keyword',
        comment: 'Comment',
        embdoc: 'Comment',
        embdoc_beg: 'Comment',
        embdoc_end: 'Comment',
        const: 'Type',
        
        regexp_beg: 'Delimiter',
        regexp_end: 'Delimiter',
        heredoc_beg: 'Delimiter',
        heredoc_end: 'Delimiter',
        tstring_beg: 'Delimiter',
        tstring_end: 'Delimiter',
        embexpr_beg: 'Delimiter',
        embexpr_end: 'Delimiter',
      }.freeze

      attr_reader :tokens

      def initialize(*)
        super
        @tokens = {}
      end

      def register_token(group, token)
        @tokens[group] ||= []
        @tokens[group] << token
      end

      EVENT_NAME_TO_HIGHLIGT_NAME.each do |tok_type, group|
        eval <<~RUBY
          def on_#{tok_type}(str)
            str.split("\\n").each.with_index do |s, idx|
              register_token #{group.inspect}, [
                lineno + idx,
                idx == 0 ? column+1 : 1,
                s.size]
            end
            super
          end
        RUBY
      end

      def traverse(node)
        return if node.scanner_event?

        if node.var_ref_type?
          ident = node.children.first
          if ident.ident_type?
            pos = ident.position
            register_token 'rubyLocalVariable', [pos[0], pos[1]+1, ident.content.size]
          end
        end
        node.children.each do |child|
          traverse(child) if child.is_a?(Array)
        end
      end

      def self.tokens(source)
        parser = self.new(source)
        sexp = parser.parse
        parser.traverse(sexp) unless parser.error?
        parser.tokens
      end
    end
  end
end