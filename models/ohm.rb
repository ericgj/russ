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
  attribute :title
  attribute :author
  attribute :updated, Type::Time
  collection :entries, :Entry
  
  unique :identity
  index :readers
  index :tags

  def identity; uri;                  end
  def readers;  @readers ||= Set.new; end
  def tags;     @tags ||= Set.new;    end

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
  attribute :title
  attribute :author
  attribute :updated, Type::Time
  reference :source, :Feed
  
end

