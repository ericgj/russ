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

  # Note: subscription is initiated through Reader
  def subscribe(feed,tags=[])
    feed.subscribe self, tags
    feeds.add feed
  end

  # TODO unsubscribe

  def feeds_tagged(*tags)
    feeds.find Feed.tagged_by(self,tags)
  end

  def aggregate_feed(attrs={})
    attrs[:uri] ||= nick
    Feed.aggregate( Feed.subscribed_by(self), attrs )
  end

  def aggregate_feed_for_tag(tag, attrs={})
    attrs[:uri] ||= Feed.build_tag(self,tag)
    Feed.aggregate( Feed.tagged_by(self,tag), attrs )
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
  
  unique :identity
  unique :slug
  index :updated
  index :readers
  index :tags

  def identity; uri;                      end
  def slug;     _slugify;                 end
  def readers;  @readers ||= Set.new; end
  def tags;     @tags ||= Set.new;    end

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
    "#{id}-#{self.class.slug( title_text || '' )}"
  end

  class << self

    def aggregate(pred,attrs={})
      f = FeedStruct.new(attrs)
      find(pred).each do |source|
        source.entries.each do |entry|
          e = Entry.new(entry.attributes)
          e.source = source.source_metadata
          f.entries << e
        end
      end
      f.entries.sort!
      f
    end

    def find_subscribed_by(readers)
      find subscribed_by(readers)
    end

    def find_tagged_by(reader,tags)
      find tagged_by(reader,tags)
    end

    def subscribed_by(readers)
      {:readers => Array(readers).map {|r| r.id} }
    end

    def tagged_by(reader,tags)
      {:tags => build_tags(reader,Array(tags))}
    end

    def build_tags(reader,tags)
      tags.map {|tag| build_tag(reader,tag) }
    end

    def build_tag(reader,tag)
      [reader.identity,tag].compact.join('/')
    end
  end


  def subscribe(reader,tags=[])
    readers.add reader.id
    Array(tags).each do |tag| 
      self.tags.add self.class.build_tag(reader, tag) 
    end
    self.save
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

