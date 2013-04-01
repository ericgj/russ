require 'set'
require 'ohm/datatypes'

class Reader < Ohm::Model
  
  attribute :email
  attribute :nick
  set :feeds, :Feed

  unique :identity

  def identity; nick; end

  # Note: subscription is initiated through Reader
  def subscribe(feed,tags=[])
    feed.subscribe self, tags
    feeds.add feed
  end

  # TODO unsubscribe

  def feeds_tagged(*tags)
    feeds.find Feed.tagged_by(self,tags)
  end

end

class Feed < Ohm::Model
  include Ohm::DataTypes

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
  index :updated
  index :readers
  index :tags

  def identity; uri;                  end
  def readers;  @readers ||= Set.new; end
  def tags;     @tags ||= Set.new;    end

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
    @attributes[:generator] ||= SerializedHash.new
    @attributes[:rights] ||= SerializedHash.new
  end


  class << self
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

end

