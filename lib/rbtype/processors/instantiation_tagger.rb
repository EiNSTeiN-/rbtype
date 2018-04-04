module Rbtype
  module Processors
    class InstantiationTagger < TaggerBase
      def on_send(node)
        return if node.type_identity

        return unless receiver = node.children[0]
        method_name = node.children[1]

        return unless method_name == :new
        return unless receiver.type_identity&.is_a?(Constants::ConstReference)

        updated(node, type_identity: instance_of(receiver.type_identity))
      end
      alias_method :on_csend, :on_send
    end
  end
end
