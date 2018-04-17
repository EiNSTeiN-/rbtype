# frozen_string_literal: true
module Rbtype
  module Cacheable
    def cacheable?
      raise "child class must implement this method"
    end

    def cache_metadata
      raise "child class must implement this method"
    end

    def cache_dump
      Marshal.dump(self)
    end

    def self.included(base)
      def base.cache_load(data)
        Marshal.load(data)
      end

      def base.cache_key(**)
        raise "child class must implement this method"
      end

      def base.cache_stale?(**)
        raise "child class must implement this method"
      end

      def base.initialize_from_cache(*, **)
        raise "child class must implement this method"
      end
    end

    private

    def cache_register!
      Cache.register(self)
    end
  end
end
