# frozen_string_literal: true
require 'parser/ruby24'

module Rbtype
  class SourceSet
    def initialize
      @map = {}
    end

    def <<(source)
      @map[source.filename] = source
    end

    def build_source(filename)
      @map[filename] ||= build_cached_source(filename)
    end

    private

    def build_cached_source(filename)
      processed_source = Rbtype::ProcessedSource.initialize_from_cache(filename)
      processed_source ||= begin
        data = read_file(filename)
        Rbtype::ProcessedSource.new(filename, data, ::Parser::Ruby24)
      end
    end

    def read_file(filename)
      content = File.read(filename)
      unless content.encoding == Encoding::UTF_8
        content.force_encoding(Encoding::UTF_8)
      end
      content
    end
  end
end
