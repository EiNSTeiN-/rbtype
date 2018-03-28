require 'digest'

module Rbtype
  class Cache
    def initialize(path)
      @path = path
    end

    def with_cache(key, modified, &block)
      hash = Digest::SHA1.hexdigest(key)
      filename = @path.join(hash)
      if File.exist?(filename)
        if expired?(filename, modified)
          puts "#{self.class}: cache expired for #{key}"
        else
          #puts "#{self.class}: reading cache for #{key}"
          data = File.read(filename)
          object = Marshal.load(data) if data != ""
        end
      end

      unless object
        object = yield
        #puts "#{self.class}: populating cache for #{key} with #{object.inspect}"
        File.open(filename, 'wb') do |f|
          data = Marshal.dump(object)
          f.write(data)
        end
      end

      object
    end

    private

    def expired?(filename, source_modified)
      source_modified > File.mtime(filename)
    end
  end
end
