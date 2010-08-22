module MemcachedTags
  def self.included(base)
    base.send :alias_method_chain, :read, :tags
    base.send :alias_method_chain, :write, :tags
    
    unless base.method_defined? :read_multy
      base.class_eval do
        def read_multi(*keys)
          @data.get_multi(*keys)
        end
      end
    end
  end

  def read_with_tags key, options = nil
    # Data is saved in form of: [tagsWithVersionArray, anyData].
    serialized = read_without_tags(key, options)
    return nil unless serialized

    combined = Marshal::load(serialized)
    return nil unless combined.is_a?(Array)

    # Test if all tags has the same version as when the slot was created
    # (i.e. still not removed and then recreated).
    if combined.first.is_a?(Hash) && !combined.first.empty?
      all_tag_values = read_multi(combined.first.keys)
      combined.first.each_pair do |tag, saved_tag_version|
        actual_tag_version = all_tag_values[tag]
        return nil if actual_tag_version != saved_tag_version
      end
    end

    combined.last
  end

  def write_with_tags key, value, options = nil
    tags = options.is_a?(Hash) ? options.delete(:tags) : []
    tags = tags.to_a.map{|item| "#{item[0]}:#{item[1]}"} if tags.is_a?(Hash)

    # Save/update tags as usual infinite keys with value of tag version.
    # If the tag already exists, do not rewrite it.
    tags_with_version = {}
    tags.each do |tag|
      tag_key = tag.to_s
      tag_version = read_without_tags tag_key
      if tag_version.nil?
        tag_version = generate_new_tag_version
        write_without_tags tag_key, tag_version
      end
      tags_with_version[tag_key] = tag_version
    end if tags.is_a?(Array) && !tags.empty?

    write_without_tags key, Marshal::dump([tags_with_version, value]), options
  end

  def delete_by_tags tags, options = nil
    return nil if tags.blank?
    tags = tags.to_a.map{|item| "#{item[0]}:#{item[1]}"} if tags.is_a?(Hash)
    tags.each{|tag| delete(tag, options)}
  end

  def generate_new_tag_version
    @@tag_version_counter ||= 0
    @@tag_version_counter += 1
    Digest::SHA1.hexdigest("#{Time.now.to_f}_#{rand}_#{@@tag_version_counter}" )
  end
end
