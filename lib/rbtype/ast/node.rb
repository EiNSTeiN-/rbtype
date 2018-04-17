# frozen_string_literal: true
require 'parser'

module Rbtype
  module AST
    class Node < ::AST::Node
      attr_reader :type_identity
      attr_reader :location
      alias_method :loc, :location

      def properties
        {
          location: location,
          type_identity: type_identity,
        }
      end

      def eql?(other)
        super(other) &&
          properties.eql?(other.properties)
      end
    end
  end
end
