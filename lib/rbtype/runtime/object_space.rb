module Rbtype
  module Runtime
    class ObjectSpace
      include Enumerable

      attr_reader :parent, :definitions, :references

      def initialize(parent = nil)
        @objects = {}
        @parent = parent
        @definitions = Set.new
        @references = Set.new
      end

      def path
        @path ||= Lexical::ConstReference.base
      end

      def type
        :object_space
      end

      def top_level?
        type == :top_level
      end

      def class?
        type == :class
      end

      def module?
        type == :module
      end

      def define(object)
        if exists?(object)
          our_object = self[object.name]
          if our_object.type == :undefined
            object.definitions.merge(our_object.definitions)
            object.references.merge(our_object.references)
            @objects[object.name] = object
          else
            raise_on_conflicts!(object)
            our_object.definitions.merge(object.definitions)
            our_object.references.merge(object.references)
            object = our_object
          end
        else
          @objects[object.name] = object
        end
        object
      end

      def each(&block)
        @objects.each(&block)
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
        if superclasses_conflict?(our_object, their_object)
          raise RuntimeError, \
            "Conflicting object superclass #{their_object.path} "\
            "was already defined as #{previous_definition_snippet(our_object)} "\
            "at #{previous_definition_location(our_object)} "\
            "instead of #{previous_definition_snippet(their_object)} "\
            "at #{previous_definition_location(their_object)}"
        end
      end

      def to_s
        "#{type}"
      end

      def inspect
        "#<#{self.class} #{path}>"
      end

      private

      def superclasses_conflict?(ours, theirs)
        ours.type == :class &&
          theirs.type == :class &&
          ours.superclass &&
          theirs.superclass &&
          ours.superclass != theirs.superclass
      end

      def relevant_superclass_definition(object)
        object.definitions.find { |item| item.superclass_expr }
      end

      def previous_definition_snippet(object)
        defn = relevant_superclass_definition(object)
        "#{object.superclass.inspect} (in `#{defn.location.source_line.strip}`)" if defn
      end

      def previous_definition_location(object)
        defn = relevant_superclass_definition(object)
        "#{defn.location.source_buffer.name}:#{defn.location.line}" if defn
      end
    end
  end
end
