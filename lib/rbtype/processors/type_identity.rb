module Rbtype
  module Processors
    class TypeIdentity < TaggerBase
      def on_str(node)
        updated(node, type_identity: Type::NativeType.new('String'))
      end
      alias_method :on_dstr, :on_str
      alias_method :on_xstr, :on_str

      def on_int(node)
        updated(node, type_identity: Type::NativeType.new('Integer'))
      end

      def on_regexp(node)
        updated(node, type_identity: Type::NativeType.new('Regexp'))
      end

      def on_array(node)
        updated(node, type_identity: Type::NativeType.new('Array'))
      end

      def on_sym(node)
        updated(node, type_identity: Type::NativeType.new('Symbol'))
      end
      alias_method :on_dsym, :on_sym

      def on_float(node)
        updated(node, type_identity: Type::NativeType.new('Float'))
      end

      def on_hash(node)
        updated(node, type_identity: Type::NativeType.new('Hash'))
      end

      def on_true(node)
        updated(node, type_identity: Type::NativeType.new('TrueClass'))
      end

      def on_false(node)
        updated(node, type_identity: Type::NativeType.new('FalseClass'))
      end

      def on_nil(node)
        updated(node, type_identity: Type::NativeType.new('NilClass'))
      end

      def on_irange(node)
        updated(node, type_identity: Type::NativeType.new('Range'))
      end
      alias_method :on_erange, :on_irange

      def on_complex(node)
        updated(node, type_identity: Type::NativeType.new('Complex'))
      end

      def on_rational(node)
        updated(node, type_identity: Type::NativeType.new('Rational'))
      end

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
