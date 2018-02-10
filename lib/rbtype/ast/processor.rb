module Rbtype
  module AST
    class Processor < ::AST::Processor
      attr_reader :updated

      def initialize(handlers)
        @handlers = handlers
      end

      def process(node)
        return if node.nil?
        return node unless node.is_a?(Rbtype::AST::Node)

        while true
          new_node = node.updated(nil, process_all(node), node.properties)
          break if new_node.eql?(node)
          node = new_node
        end

        while true
          updated = false
          on_handler = :"on_#{node.type}"
          @handlers.each do |handler|
            if handler.respond_to?(on_handler)
              new_node = handler.send(on_handler, node)
              updated = new_node && !new_node.eql?(node)
              node = new_node || node
            end
          end
          break unless updated
        end

        node
      end
    end
  end
end
