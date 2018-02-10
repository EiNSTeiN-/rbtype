module Rbtype
  module Processors
    class TaggerBase < ::Parser::AST::Processor
      def updated(node, new_properties)
        node.class.new(
          node.type,
          node.children,
          node.properties.merge(new_properties)
        )
      end
    end
  end
end
