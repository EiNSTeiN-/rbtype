require 'digest'

module Rbtype
  class Cache
    def initialize(path)
      @path = path
    end

    def for_file(source_filename, key_prefix:)
      cache_filename = build_filename("#{key_prefix}:#{source_filename}")
      comparators = [FileComparator.new(source_filename, cache_filename)]
      CacheFile.new(cache_filename, comparators: comparators)
    end

    def build(key, comparators: nil)
      cache_filename = build_filename(key)
      CacheFile.new(cache_filename, comparators: comparators)
    end

    def build_filename(key)
      hash = Digest::SHA1.hexdigest(key)
      @path.join(hash)
    end

    class FileComparator
      attr_reader :source_filename, :compare_filename

      def initialize(source_filename, compare_filename)
        @source_filename = source_filename
        @compare_filename = compare_filename
      end

      def source_changed?
        if can_compare?
          source_mtime > compare_mtime
        else
          true
        end
      end

      private

      def source_mtime
        File.mtime(source_filename)
      end

      def compare_mtime
        File.mtime(compare_filename)
      end

      def can_compare?
        File.exists?(source_filename) &&
          File.exists?(compare_filename)
      end
    end

    class CacheFile
      attr_reader :filename, :comparators

      def initialize(filename, comparators: nil)
        @filename = filename
        @comparators = comparators || []
      end

      def build(&block)
        if exist?
          unless expired?
            object = load_object
          end
        end

        unless object
          object = yield
          update(object)
        end

        object
      end

      def load_object
        Marshal.load(data) if data != ""
      rescue ArgumentError
        nil
      end

      def update(object)
        File.open(filename, 'wb') do |f|
          data = Marshal.dump(object)
          f.write(data)
        end
      end

      def exist?
        File.exist?(filename)
      end

      def expired?
        comparators.any? do |cmp|
          cmp.source_changed?
        end
      end

      private

      def data
        File.read(filename)
      end
    end
  end
end
