module Iro
  module Ruby
    class Base < Ripper
      Ripper::SCANNER_EVENTS.each do |event|
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def on_#{event}(tok)
            [:@#{event}, tok, [lineno(), column()]]
          end
        End
      end
    end

    class Parser < Base
      using RipperWrapper

      EVENT_NAME_TO_HIGHLIGHT_NAME = {
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
        qwords_beg: 'Delimiter', # For `**%w[**foo]`
        words_sep: 'Delimiter', # For `%w[foo**]**` in Ruby 2.4 or older
        embexpr_beg: 'Delimiter',
        embexpr_end: 'Delimiter',
        backtick: 'Delimiter',

        symbeg: 'rubySymbolDelimiter',

        ivar: 'rubyInstanceVariable',
        cvar: 'rubyClassVariable',
        gvar: 'rubyGlobalVariable',
      }.freeze

      attr_reader :tokens

      def initialize(*)
        super
        @tokens = {}
        @end_stack = []
      end

      def parse
        super
        @end_stack.each do |end_kw|
          register_scanner_event 'Keyword', end_kw
        end
      end

      def register_token(group, token)
        @tokens[group] ||= []
        @tokens[group] << token
      end

      # TODO: Maybe multiline support is needed.
      def register_scanner_event(group, event)
        pos = event.position
        register_token group, [pos[0], pos[1]+1, event.content.bytesize]
      end

      def highlight_end_as(group)
        register_scanner_event group, @end_stack.pop
      end

      def unhighlight!(scanner_event)
        t = scanner_event.type[1..-1].to_sym
        group = EVENT_NAME_TO_HIGHLIGHT_NAME[t] ||
          (scanner_event.kw_type? && kw_group(scanner_event.content))
        raise 'bug' unless group

        t = scanner_event.position + [scanner_event.content.bytesize]
        t[1] += 1
        @tokens[group].reject! { |ev| ev == t }
        @end_stack.reject!{|e| e == scanner_event} if scanner_event.kw_type? && scanner_event.content == 'end'
      end

      EVENT_NAME_TO_HIGHLIGHT_NAME.each do |tok_type, group|
        eval <<~RUBY
          def on_#{tok_type}(str)
            str.split("\\n").each.with_index do |s, idx|
              register_token #{group.inspect}, [
                lineno + idx,
                idx == 0 ? column+1 : 1,
                s.bytesize]
            end
            super
          end
        RUBY
      end

      def on_kw(str)
        super.tap do |result|
          if str == 'end'
            @end_stack << result
          else
            group = kw_group(str)
            register_token group, [lineno, column+1, str.bytesize]
          end
        end
      end

      # foo: bar
      # ^^^ rubySymbol
      #    ^ no highlight
      def on_label(str)
        register_token 'rubySymbol', [lineno, column+1, str.bytesize-1]
        super
      end

      def kw_group(str)
        {
          'def' => 'rubyDefine',
          'alias' => 'rubyDefine',
        }[str] || 'Keyword'
      end

      def on_def(name, params, body)
        unhighlight! name if name.kw_type?
        register_scanner_event 'rubyFunction', name
        highlight_end_as 'rubyDefine'
        nil
      end

      def on_defs(recv, period, name, params, body)
        unhighlight! name if name.kw_type?
        register_scanner_event 'rubyFunction', name
        highlight_end_as 'rubyDefine'
        nil
      end

      def on_symbol(node)
        unhighlight! node if node.gvar_type? || node.ivar_type? || node.cvar_type? || node.kw_type?
        register_scanner_event 'rubySymbol', node
        nil
      end

      def on_var_ref(name)
        case name.type
        when :@ident
          register_scanner_event 'rubyLocalVariable', name
        when :@const
          register_scanner_event 'Type', name
        end
        nil
      end

      def on_var_field(name)
        register_scanner_event 'Type', name if name.const_type?
        nil
      end

      def on_top_const_ref(*, name)
        register_scanner_event 'Type', name
        nil
      end
      alias on_const_ref        on_top_const_ref
      alias on_const_path_ref   on_top_const_ref
      alias on_const_path_field on_top_const_ref

      def on_fcall(ident)
        highlight_keyword_like_method(ident)
      end

      def on_vcall(ident)
        highlight_keyword_like_method(ident)
      end

      def on_command(ident, _)
        highlight_keyword_like_method(ident)
      end

      def highlight_keyword_like_method(ident)
        case ident.content
        when 'private', 'public', 'protected', 'private_class_method',
             'attr_reader', 'attr_writer', 'attr_accessor', 'attr',
             'include', 'extend', 'prepend', 'module_function', 'refine', 'using',
             'raise', 'fail', 'catch', 'throw',
             'require', 'require_relative'
          register_scanner_event 'Keyword', ident # TODO: Change highlight group
        end
      end

      def self.tokens(source)
        parser = self.new(source)
        parser.parse
        parser.tokens
      end
    end
  end
end
