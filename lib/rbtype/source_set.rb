module Rbtype
  class SourceSet
    def initialize(cache:)
      @cache = cache
      @map = {}
    end

    def load_source(filename)
      cached_source = @map[filename]
      unless cached_source
        cached_source = build_cached_source(filename)
        @map[filename] = cached_source
      end
      cached_source.processed_source
    end

    def save_cache
      @map.each do |_, cached_source|
        cached_source.update
      end
    end

    class CachedSource
      attr_reader :processed_source

      def initialize(cache_file, processed_source)
        @cache_file = cache_file
        @processed_source = processed_source
        @ast_loaded = processed_source.ast_loaded?
      end

      def update
        if processed_source && processed_source.ast_loaded? && !@ast_loaded
          @cache_file.update(processed_source)
        end
      end
    end

    private

    def build_cached_source(filename)
      cache_file = @cache.for_file(filename, key: "processed-source")
      source = cache_file.build do
        buffer = build_buffer(filename)
        Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24)
      end
      CachedSource.new(cache_file, source)
    rescue Parser::SyntaxError
      puts "Parser error while loading #{filename}"
      raise unless @ignore_errors
    end

    def read_file(filename)
      content = File.read(filename)
      unless content.encoding == Encoding::UTF_8
        content.force_encoding(Encoding::UTF_8)
      end
      content
    end

    def build_buffer(filename)
      buffer = ::Parser::Source::Buffer.new(filename)
      buffer.source = read_file(filename)
      buffer
    end
  end
end
