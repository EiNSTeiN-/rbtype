# frozen_string_literal: true

require 'rbtype/namespace/const_reference'
require 'rbtype/namespace/union_reference'
require 'rbtype/namespace/instance_reference'

module Support
  module Helper
    extend RSpec::SharedContext

    def const_ref(*parts)
      Rbtype::Namespace::ConstReference.new(parts)
    end

    def union_ref(*members)
      Rbtype::Namespace::UnionReference.new(members)
    end

    def instance_of(what)
      Rbtype::Namespace::InstanceReference.new(what)
    end

    def string_class_ref
      const_ref(nil, :String)
    end

    def string_instance_ref
      instance_of(string_class_ref)
    end

    def boolean_instance_ref
      union_ref(
        instance_of(const_ref(nil, :TrueClass)),
        instance_of(const_ref(nil, :FalseClass)),
      )
    end
  end
end
