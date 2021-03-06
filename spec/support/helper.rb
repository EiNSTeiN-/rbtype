# frozen_string_literal: true

require 'rbtype'
require 'rbtype/constants/const_reference'
require 'rbtype/lexical/instance_reference'
require 'rbtype/type/union_reference'

module Support
  module Helper
    extend RSpec::SharedContext

    def build_processed_source(source, filename: 'test.rb', parser: ::Parser::Ruby24)
      Rbtype::ProcessedSource.new(filename, source, parser)
    end

    def const_ref(*parts)
      Rbtype::Constants::ConstReference.new(parts)
    end

    def union_ref(*members)
      Rbtype::Type::UnionReference.new(members)
    end

    def instance_of(what)
      Rbtype::Lexical::InstanceReference.new(what)
    end

    def string_class_ref
      const_ref(nil, :String)
    end

    def integer_class_ref
      const_ref(nil, :Integer)
    end

    def string_instance_ref
      instance_of(string_class_ref)
    end

    def integer_instance_ref
      instance_of(integer_class_ref)
    end

    def boolean_instance_ref
      union_ref(
        instance_of(const_ref(nil, :TrueClass)),
        instance_of(const_ref(nil, :FalseClass)),
      )
    end
  end
end
