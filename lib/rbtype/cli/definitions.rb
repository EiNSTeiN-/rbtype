# frozen_string_literal: true
module Rbtype
  class CLI
    class Definitions
      def initialize(runtime, files:, **options)
        @runtime = runtime
        @files = files
      end

      def to_s
        @files.map do |filename|
          source = @runtime.find(filename)
          if source
            required_file = @runtime.load_source(source)
            if required_file
              [
                "#{filename} defines #{required_file.definitions.size} class/module",
                *definitions(required_file),
              ]
            else
              "#{filename}: no such file"
            end
          else
            "#{filename}: no such file"
          end
        end.join("\n")
      end

      def definitions(required_file)
        required_file.definitions.map do |_, group|
          length = group.map(&:location).map(&:line).map(&:to_s).map(&:length).max
          group.map do |definition|
            line = definition.location.line.to_s.rjust(length)
            "#{line}: #{definition.location.source_line}"
          end
        end.flatten
      end
    end
  end
end
