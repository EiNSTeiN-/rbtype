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

    def render
      if !@location
        ["(program): #{level}: #{message} (#{reason})"]
      else
        range = @location.source_range
        if range.line == range.last_line || range.is?("\n")
          ["#{range}: #{level}: #{message} (#{reason})"] + render_line(range)
        else
          # multi-line diagnostic
          first_line = first_line_only(range)
          last_line  = last_line_only(range)
          num_lines  = (range.last_line - range.line) + 1
          buffer     = range.source_buffer

          last_lineno, last_column = buffer.decompose_position(range.end_pos)
          ["#{range}-#{last_lineno}:#{last_column}: #{level}: #{message} (#{reason})"] +
            render_line(first_line, num_lines > 2, false) +
            render_line(last_line, false, true)
        end
      end
    end

    def render_line(range, ellipsis=false, range_end=false)
      source_line    = range.source_line
      highlight_line = ' ' * source_line.length

      line_range = range.source_buffer.line_range(range.line)
      if highlight = range.intersect(line_range)
        highlight_line[highlight.column_range] = '~' * highlight.size
      end

      if range.is?("\n")
        highlight_line += "^"
      else
        if !range_end && range.size >= 1
          highlight_line[range.column_range] = '^' + '~' * (range.size - 1)
        else
          highlight_line[range.column_range] = '~' * range.size
        end
      end

      highlight_line += '...' if ellipsis

      [source_line, highlight_line].
        map { |line| "#{range.source_buffer.name}:#{range.line}: #{line}" }
    end

    def first_line_only(range)
      if range.line != range.last_line
        range.resize(range.source =~ /\n/)
      else
        range
      end
    end

    def last_line_only(range)
      if range.line != range.last_line
        range.adjust(begin_pos: range.source =~ /[^\n]*\z/)
      else
        range
      end
    end
  end
end
