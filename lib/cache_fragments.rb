ActionController::Base.class_eval do
  def expire_fragments_by_tags *args
    return unless cache_configured?
    tags = args.extract_options!
    cache_store.delete_by_tags tags
  end

  def fragment_cache_key_with_md5(key)
    Digest::MD5.hexdigest(fragment_cache_key_without_md5(key))
  end
  alias_method_chain :fragment_cache_key, :md5
end