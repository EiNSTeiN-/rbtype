module Rbtype
  module Processors
    class TypeIdentity < TaggerBase
      def on_str(node)
        updated(node, type_identity: instance_of(const_ref(nil, :String))) unless node.type_identity
      end
      alias_method :on_dstr, :on_str
      alias_method :on_xstr, :on_str

      def on_int(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Integer))) unless node.type_identity
      end

      def on_regexp(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Regexp))) unless node.type_identity
      end

      def on_array(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Array))) unless node.type_identity
      end

      def on_sym(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Symbol))) unless node.type_identity
      end
      alias_method :on_dsym, :on_sym

      def on_float(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Float))) unless node.type_identity
      end

      def on_hash(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Hash))) unless node.type_identity
      end

      def on_true(node)
        updated(node, type_identity: instance_of(const_ref(nil, :TrueClass))) unless node.type_identity
      end

      def on_false(node)
        updated(node, type_identity: instance_of(const_ref(nil, :FalseClass))) unless node.type_identity
      end

      def on_nil(node)
        updated(node, type_identity: instance_of(const_ref(nil, :NilClass))) unless node.type_identity
      end

      def on_irange(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Range))) unless node.type_identity
      end
      alias_method :on_erange, :on_irange

      def on_complex(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Complex))) unless node.type_identity
      end

      def on_rational(node)
        updated(node, type_identity: instance_of(const_ref(nil, :Rational))) unless node.type_identity
      end

      def on_lvasgn(node)
        return if node.type_identity
        if (type_identity = node.children[1]&.type_identity)
          updated(node, type_identity: type_identity)
        end
      end
      alias_method :on_ivasgn, :on_lvasgn
      alias_method :on_cvasgn, :on_lvasgn
      alias_method :on_gvasgn, :on_lvasgn

      def on_defined?(node)
        type_identity = union_ref(
          instance_of(const_ref(nil, :TrueClass)),
          instance_of(const_ref(nil, :FalseClass)),
        )
        updated(node, type_identity: type_identity) unless node.type_identity
      end
    end
  end
end
