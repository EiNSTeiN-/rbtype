module Rbtype
  module Processors
    class AssignmentTagger < TaggerBase
      def on_lvasgn(node)
        if (type_identity = node.children[1]&.type_identity)
          updated(node, type_identity: type_identity)
        end
      end
      alias_method :on_ivasgn, :on_lvasgn
      alias_method :on_cvasgn, :on_lvasgn
      alias_method :on_gvasgn, :on_lvasgn

      def on_casgn(node)
        if (type_identity = node.children[2]&.type_identity)
          updated(node, type_identity: type_identity)
        end
      end
    end
  end
end
