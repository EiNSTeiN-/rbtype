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

      def instance_of(what)
        Rbtype::Lexical::InstanceReference.new(what)
      end

      def const_ref(*const)
        Rbtype::Lexical::ConstReference.new(const)
      end

      def union_ref(*members)
        Rbtype::Type::UnionReference.new(members)
      end
    end
  end
end
