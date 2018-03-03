module Iro
  module Formatter
    class HTMLFormatter
      module ConvertedHighlight
        refine Array do
          def group()  self[0] end
          def line()   self[1]-1 end 
          def column() self[2]-1 end
          def length() self[3] end
        end
      end
      using ConvertedHighlight

      def self.format(source, highlight, prefix: '')
        formatter = self.new(
          source: source,
          highlight: highlight,
          prefix: prefix,
        )
        formatter.format
      end

      def self.sample_stylesheet
        File.join(__dir__, 'sample.css')
      end

      def initialize(source:, highlight:, prefix:)
        @source = source.each_line.map(&:chomp)
        @highlight = sort_highlight_by_position(highlight)
        @prefix = prefix
      end

      def format
        buf = []

        @source.each.with_index do |line, lineno|
          highlights = pop_highlight(lineno)
          if highlights.empty?
            buf << CGI.escapeHTML(line)
            next
          end

          last_col = 0
          highlighted_line = +''
          highlights.each do |hi|
            highlighted_line << CGI.escapeHTML(line[last_col...hi.column])
            last_col = hi.column + hi.length
            token = CGI.escapeHTML(line[(hi.column)...last_col])
            highlighted_line << %Q!<span class="#{@prefix}#{hi.group}">#{token}</span>!
          end
          highlighted_line << line[last_col..-1]
          buf << highlighted_line
        end

        buf.join("\n")
      end

      def sort_highlight_by_position(highlight)
        highlight.flat_map do |group, positions|
          positions.map do |pos|
            [group, *pos]
          end
        end.sort_by do |pos|
          [pos.line, pos.column]
        end
      end

      def pop_highlight(lineno)
        [].tap do |res|
          while @highlight.first&.line == lineno
            res << @highlight.shift
          end
        end
      end
    end
  end
end
