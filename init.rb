require 'memcached_tags'
require 'mem_cache_store'
require 'cache_fragments'

ActiveSupport::Cache::MemCacheStore.send(:include, MemcachedTags::MemCacheStore)
