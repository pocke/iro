module Iro
  module Ruby
    class Base < Ripper::SexpBuilderPP
      Ripper::SCANNER_EVENT.each do |e|
        define_method(:"on_#{e}") do |str|
          check_lineno!
          super
        end
      end
    end

    class Parser < Ripper::SexpBuilderPP
      using RipperWrapper

      EVENT_NAME_TO_HIGHLIGT_NAME = {
        tstring_content: 'String',
        CHAR: 'Character',
        int: 'Number',
        float: 'Float',
        
        comment: 'Comment',
        embdoc: 'Comment',
        embdoc_beg: 'Comment',
        embdoc_end: 'Comment',

        regexp_beg: 'Delimiter',
        regexp_end: 'Delimiter',
        heredoc_beg: 'Delimiter',
        heredoc_end: 'Delimiter',
        tstring_beg: 'Delimiter',
        tstring_end: 'Delimiter',
        embexpr_beg: 'Delimiter',
        embexpr_end: 'Delimiter',
        backtick: 'Delimiter',

        symbeg: 'rubySymbolDelimiter',

        ivar: 'rubyInstanceVariable',
        cvar: 'rubyClassVariable',
        gvar: 'rubyGlobalVariable',
      }.freeze

      attr_reader :tokens

      def initialize(source, range:)
        super(source)
        @tokens = {}
        @range = range
      end

      def check_lineno!
        if @range && !@range.cover?(lineno)
      end

      def register_token(group, token)
        @tokens[group] ||= []
        @tokens[group] << token
      end

      # TODO: Maybe multiline support is needed.
      def register_scanner_event(group, event)
        pos = event.position
        register_token group, [pos[0], pos[1]+1, event.content.size]
      end

      def unhighlight!(scanner_event)
        t = scanner_event.type[1..-1].to_sym
        group = EVENT_NAME_TO_HIGHLIGT_NAME[t] ||
          (scanner_event.kw_type? && kw_group(scanner_event.content))
        raise 'bug' unless group

        t = scanner_event.position + [scanner_event.content.size]
        t[1] += 1
        @tokens[group].reject! { |ev| ev == t }
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

      def on_kw(str)
        group = kw_group(str)
        register_token group, [lineno, column+1, str.size]
        super
      end

      # foo: bar
      # ^^^ rubySymbol
      #    ^ no highlight
      def on_label(str)
        register_token 'rubySymbol', [lineno, column+1, str.size-1]
        super
      end

      def kw_group(str)
        {
          'def' => 'rubyDefine',
          'alias' => 'rubyDefine',
        }[str] || 'Keyword'
      end

      def on_def(name, params, body)
        super.tap do
          register_scanner_event 'rubyFunction', name
        end
      end

      def on_defs(recv, period, name, params, body)
        super.tap do
          register_scanner_event 'rubyFunction', name
        end
      end

      def on_symbol(node)
        super.tap do
          unhighlight! node if node.gvar_type? || node.ivar_type? || node.cvar_type?
          register_scanner_event 'rubySymbol', node
        end
      end

      def on_var_ref(name)
        super.tap do
          case name.type
          when :@ident
            register_scanner_event 'rubyLocalVariable', name
          when :@const
            register_scanner_event 'Type', name
          end
        end
      end

      def on_var_field(name)
        super.tap do
          register_scanner_event 'Type', name if name.const_type?
        end
      end

      def on_top_const_ref(name)
        super.tap do
          register_scanner_event 'Type', name
        end
      end
      alias on_const_ref on_top_const_ref

      def on_const_path_ref(_base, name)
        super.tap do
          register_scanner_event 'Type', name
        end
      end

      def traverse(node)
        if node.kw_type?
          unhighlight!(node)
        end

        return if node.scanner_event?

        node.children.each do |child|
          traverse(child) if child.is_a?(Array)
        end
      end

      def self.tokens(source, range: nil)
        parser = self.new(source, range: range)
        sexp = parser.parse
        parser.traverse(sexp) unless parser.error?
        parser.tokens
      end
    end
  end
end
