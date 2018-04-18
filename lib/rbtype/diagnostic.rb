module Rbtype
  class Diagnostic
    attr_reader :level, :reason, :message, :arguments, :location

    LEVELS = [:note, :warning, :error, :fatal].freeze

    def initialize(level, reason, message, arguments, location)
      unless LEVELS.include?(level)
        raise ArgumentError,
              "Diagnostic#level must be one of #{LEVELS.join(', ')}; " \
              "#{level.inspect} provided."
      end
      raise "Expected `#{location.class}` to be `Rbtype::Constants::Location`" unless location.nil? || location.is_a?(Rbtype::Constants::Location)

      @level       = level
      @reason      = reason
      @message     = message
      @arguments   = (arguments || {}).dup.freeze
      @location    = location
    end

    def message
      @message % @arguments
    end
  end
end
