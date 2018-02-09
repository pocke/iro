module Iro
  module RipperWrapper
    refine Array do
      def type
        self.first
      end

      def children
        [].tap do |res|
          self[1..-1].each do |child|
            if child.is_a?(Array)
              if child.node?
                res << child
              else
                res.concat(child)
              end
            else
              res << child
            end
          end
        end
      end

      def content
        self[1]
      end

      def position
        self[2]
      end

      def node?
        self.first.is_a?(Symbol)
      end

      def parser_event?
        type !~ /\A@/
      end

      def scanner_event?
        type =~ /\A@/
      end

      Ripper::SCANNER_EVENTS.each do |e|
        eval <<~RUBY
          def #{e}_type?
            type == #{:"@#{e}".inspect}
          end
        RUBY
      end

      Ripper::PARSER_EVENTS.each do |e|
        eval <<~RUBY
          def #{e}_type?
            type == #{e.inspect}
          end
        RUBY
      end
    end
  end
end
