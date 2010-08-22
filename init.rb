require 'memcached_tags'
ActiveSupport::Cache::MemCacheStore.send(:include, MemcachedTags)


module ActionController
  module Caching
    module Fragments
      def expire_fragments_by_tags *args
        return unless cache_configured?
        tags = args.extract_options!
        cache_store.delete_by_tags tags
      end
    end
  end
end
