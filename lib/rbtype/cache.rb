require 'digest'

module Rbtype
  class Cache
    def initialize(path)
      @path = path
    end

    def for_file(source_filename, key:)
      hash = Digest::SHA1.hexdigest("#{key}:#{source_filename}")
      cache_filename = @path.join(hash)
      CacheFile.new(cache_filename, monitored_files: [MonitoredFile.new(source_filename)])
    end

    class MonitoredFile
      attr_reader :filename

      def initialize(filename)
        @filename = filename
      end

      def mtime
        File.mtime(filename)
      end
    end

    class CacheFile
      attr_reader :filename, :monitored_files

      def initialize(filename, monitored_files:)
        @filename = filename
        @monitored_files = monitored_files
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
        monitored_files.any? do |file|
          file.mtime > File.mtime(filename)
        end
      end

      private

      def data
        File.read(filename)
      end
    end
  end
end
