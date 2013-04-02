require 'set'
require 'nokogiri'
require 'ohm/datatypes'

# TODO: move to lib
module Ohm
  class Model
    def self.get_attributes; attributes; end
  end

  module Slug
    def slug(str = to_s)
      str.gsub("'","").gsub(/\p{^Alnum}/u, " ").strip.gsub(/\s+/,"-").downcase
    end
  end

end

class Reader < Ohm::Model
  
  attribute :email
  attribute :nick
  attribute :name
  set :feeds, :Feed

  unique :identity

  def identity; nick; end

  def fullname; name || nick; end

  def tags
    self.key[:tags].smembers
  end

  def feeds_tagged(tag)
    self.feeds.fetch self.key[:feedtags][tag].smembers
  end
  
  def tag(feed, tag)
    self.key[:tags].sadd(tag)
    self.key[:feedtags][tag].sadd(feed.id)
  end

  def untag(feed, tag)
    self.key[:feedtags][tag].srem(feed.id)
  end

  # Note: subscription is initiated through Reader
  def subscribe(feed,tags=[])
    Array(tags).each do |t| self.tag(feed,t) end
    feeds.add feed
  end

  def unsubscribe(feed)
    self.tags.each do |t| self.untag(feed,t) end    # non-optimized
    feeds.delete feed
  end

  def aggregate(attrs={})
    aggregate_feeds self.feeds, attrs
  end

  def aggregate_for_tag(tag, attrs={})
    aggregate_feeds self.feeds_tagged(tag), attrs
  end

  # TODO do the inner entry dup in Feed, yielding new entry?

  def aggregate_feeds(feeds, attrs={})
    attrs[:uri] ||= nick
    f = FeedStruct.new(attrs)
    feeds.each do |source|
      source.entries.each do |entry|
        e = Entry.new(entry.attributes)
        e.source = source.source_metadata
        f.entries << e
      end
    end
    f.entries.sort!
    f
  end
    
end

class Feed < Ohm::Model
  include Ohm::DataTypes
  extend Ohm::Slug

  attribute :uri
  attribute :title,        Type::Hash
  attribute :updated,      Type::Time
  attribute :links,        Type::Array
  attribute :authors,      Type::Array
  attribute :categories,   Type::Array
  attribute :contributors, Type::Array
  attribute :generator,    Type::Hash
  attribute :icon
  attribute :logo
  attribute :rights,       Type::Hash
  attribute :subtitle

  collection :entries,     :Entry
  
  unique :id
  unique :identity
  unique :slug
  index :updated

  def identity; uri;                      end
  def slug;     _slugify;                 end

  def primary_link
    links.find {|link| link['rel'] == 'self'}
  end

  # TODO: move this to parser?
  def title_text
    return if title.empty? || !title['content']
    if title['type'] && /html/i =~ title['type']
      Nokogiri::HTML.fragment(title['content']).inner_text
    else
      title['content']
    end
  end

  # Note string keys to preserve identity before/after serialization
  def metadata(opts = {})
    excl = opts.fetch(:excl,[:entries])
    (attributes.keys - excl).inject({}) { |m,k|
      m[k.to_s] = attributes[k]
      m
    }
  end

  def source_metadata
    metadata :excl => [:entries,:categories,:generator,:icon,:logo,:subtitle]
  end

  def initialize(attrs={})
    super
    @attributes[:title] ||= SerializedHash.new
    @attributes[:links] ||= SerializedArray.new
    @attributes[:authors] ||= SerializedArray.new
    @attributes[:categories] ||= SerializedArray.new
    @attributes[:contributors] ||= SerializedArray.new
    @attributes[:generator] ||= SerializedHash.new
    @attributes[:rights] ||= SerializedHash.new
  end

  private

  def _slugify
    "#{id}-#{self.class.slug( title_text || uri || '' )}"
  end

end

class FeedStruct 
  attr_accessor *Feed.get_attributes
 
  def links;        @links ||= [];        end
  def authors;      @authors ||= [];      end
  def categories;   @categories ||= [];   end
  def contributors; @contributors ||= []; end
  def entries;      @entries ||= [];      end

  def primary_link
    links.find {|link| link['rel'] == 'self'}
  end
    
  def initialize(attrs={})
    attrs.each do |k,v| self.send("#{k}=",v) end
  end
end

class Entry < Ohm::Model
  include Ohm::DataTypes

  attribute :uri
  attribute :title,        Type::Hash
  attribute :updated,      Type::Time
  attribute :links,        Type::Array
  attribute :authors,      Type::Array
  attribute :categories,   Type::Array
  attribute :contributors, Type::Array
  attribute :summary,      Type::Hash
  attribute :content,      Type::Hash
  attribute :published,    Type::Time
  attribute :rights,       Type::Hash
  attribute :source,       Type::Hash
  
  reference :feed,   :Feed

  index :uri
  index :updated

  def primary_link
    links.find {|link| link['rel'] == 'self'}
  end

  def initialize(attrs={})
    super
    @attributes[:title] ||= SerializedHash.new
    @attributes[:links] ||= SerializedArray.new
    @attributes[:authors] ||= SerializedArray.new
    @attributes[:categories] ||= SerializedArray.new
    @attributes[:contributors] ||= SerializedArray.new
    @attributes[:summary] ||= SerializedHash.new
    @attributes[:content] ||= SerializedHash.new
    @attributes[:rights] ||= SerializedHash.new
    @attributes[:source] ||= SerializedHash.new
  end

  # Note: default reverse sort by date
  def <=>(other)
    return other.updated <=> self.updated
  end

end

