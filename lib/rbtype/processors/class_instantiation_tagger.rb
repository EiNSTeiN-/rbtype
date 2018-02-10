module Rbtype
  module Processors
    class ClassInstantiationTagger < TaggerBase
      def on_send(node)
        if new_called?(node) && eligible_receiver?(node)
          updated(node, type_identity: Rbtype::Type::NativeType.new(to_name(node.children[0])))
        end
      end
      alias_method :on_csend, :on_send

      private

      def new_called?(node)
        node.children[1] == :new
      end

      def eligible_receiver?(node)
        return unless (receiver = node.children[0])
        receiver.type == :const &&
          (receiver.children[0].nil? ||
            receiver.children[0].type == :cbase ||
            eligible_receiver?(receiver))
      end

      def to_name(node)
        case node&.type
        when :const
          [to_name(node.children[0]), node.children[1].to_s].compact.join('::')
        when :cbase
          ""
        end
      end
    end
  end
end
