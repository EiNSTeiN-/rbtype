# frozen_string_literal: true
require 'digest'

module Rbtype
  module Cache
    extend self

    def setup(cache_directory)
      @cache_directory = cache_directory
      @objects = {}
      @metadata_by_key = load_metadata || {}
      puts "metadata in cache: #{@metadata_by_key.size}"
    end

    class MetadataEntry
      attr_reader :klass, :metadata
      def initialize(klass, metadata)
        @klass = klass
        @metadata = metadata
      end

      def changed?(metadata)
        @metadata != metadata
      end
    end

    def register(object)
      @objects ||= {}
      key = object.class.cache_key(**object.cache_metadata)
      @objects[key] = object
    end

    def load_object_by_key(key)
      return unless @metadata_by_key
      return unless (entry = @metadata_by_key[key])
      if entry.klass.cache_stale?(**entry.metadata)
        delete_by_key(key)
        nil
      else
        filename = cache_filename(key)
        object = load_object(entry.klass, filename)
        delete_by_key(key) unless object
        object
      end
    end

    def load_metadata
      return unless File.exist?(metadata_filename)
      return unless (data = File.read(metadata_filename))
      return if data == nil || data == ""
      measure(:load_metadata) do
        Marshal.load(data)
      end
    end

    def save_metadata
      return unless @metadata_by_key
      measure(:save_metadata) do
        dump = Marshal.dump(@metadata_by_key)
        File.open(metadata_filename, 'wb') do |f|
          f.write(dump)
        end
      end
    end

    def metadata_filename
      @cache_directory&.join('metadata')
    end

    def save
      save_objects
      save_metadata
    end

    def save_objects
      @objects&.each do |_, object|
        save_object(object)
      end
      true
    end

    def save_object(object)
      metadata = object.cache_metadata
      key = object.class.cache_key(**metadata)
      entry = @metadata_by_key[key]
      if object.cacheable?
        if entry == nil || entry.changed?(metadata)
          measure(:save_object) do
            filename = cache_filename(key)
            File.open(filename, 'wb') do |f|
              f.write(object.cache_dump)
            end
            @metadata_by_key[key] = MetadataEntry.new(object.class, metadata)
          end
        end
        true
      else
        delete_by_key(key)
        false
      end
    end

    def delete_object(object)
      key = object.class.cache_key(**object.cache_metadata)
      delete_by_key(key)
    end

    def delete_by_key(key)
      filename = cache_filename(key)
      File.delete(filename) if File.exist?(filename)
      @metadata_by_key[key] = nil
    end

    def load_object(klass, filename)
      return unless File.exist?(filename)
      return unless (data = File.read(filename))
      return if data == ""
      measure(:load_object) do
        klass.cache_load(data)
      end
    end

    def cache_filename(key)
      hash = Digest::SHA1.hexdigest(key)
      @cache_directory.join(hash)
    end

    def measure(action)
      @stats ||= {}
      @stats[action] ||= 0
      start = Time.now.to_f
      yield
    ensure
      @stats[action] += Time.now.to_f - start
    end

    def stats
      @stats
    end
  end
end
