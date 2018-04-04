module Rbtype
  module Processors
    class ConstReferenceTagger < TaggerBase
      def on_const(node)
        ref = Constants::ConstReference.from_node(node)
        updated(node, type_identity: ref) unless node.type_identity
      end
    end
  end
end
