module Rbtype
  class CLI
    class Uses
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
                "#{source.filename} refers to #{required_file.uses.size} class/module:",
                *uses(required_file),
              ]
            else
              "#{filename}: no such file"
            end
          else
            "#{filename}: no such file"
          end
        end.join("\n")
      end

      def uses(required_file)
        required_file.uses.map do |_, uses|
          uses.map do |use|
            [
              "  #{use.full_path} on line #{use.location.line} has #{use.definitions.size} prior definition(s):",
              use.definitions.map do |definition|
                "    at #{definition.format_location} `#{definition.source_line}`"
              end
            ]
          end
        end.flatten
      end
    end
  end
end
