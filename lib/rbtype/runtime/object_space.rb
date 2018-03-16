module Rbtype
  module Runtime
    class ObjectSpace
      attr_reader :parent

      def initialize(parent = nil)
        @objects = {}
        @parent = parent

        parent&.define(self)
      end

      def path
        @path ||= Lexical::ConstReference.base
      end

      def type
        :const_base
      end

      def define(object)
        if exists?(object)
          our_object = self[object.name]
          if our_object.type == :undefined
            object.definitions.concat(our_object.definitions)
            @objects[object.name] = object
          else
            raise_on_conflicts!(object)
            our_object.definitions.concat(object.definitions)
          end
        else
          @objects[object.name] = object
        end
        object
      end

      def [](name)
        @objects[name]
      end

      def names
        @objects.keys
      end

      def exists?(object)
        !!@objects[object.name]
      end

      def raise_on_conflicts!(their_object)
        our_object = self[their_object.name]
        unless our_object.type == their_object.type
          raise RuntimeError.new("conflicting object redefinition: #{their_object.path} "\
            "is already defined as #{our_object.type} instead of #{their_object.type}")
        end
      end

      def to_s
        "#{type}"
      end

      def inspect
        "#<#{self.class} #{path}>"
      end
    end
  end
end
