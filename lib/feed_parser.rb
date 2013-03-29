require 'nokogiri'

module Russ

  class AtomParser < Nokogiri::XML::SAX::Document

    class TextElement < Struct.new(:type, :content)
      unless self.methods.respond_to?(:to_h)
        def to_h
          self.members.inject({}) {|h,k|
            h[k]= self.send(k)
            h
          }
        end
      end
    end

    attr_accessor :tag, :attrs
    attr_accessor :feed, :entry, :el, :target_meth

    def current
      entry || feed
    end
 
    def tree
      @tree ||= []
    end

    def parent
      tree.last[0] unless tree.empty?
    end

    def parent_attrs
      tree.last[1] unless tree.empty?
    end

    def ancestors
      tree.map {|(t,a)| t}
    end

    def within_feed?
      ancestors == [:feed]
    end

    def within_entry?
      ancestors == [:feed,:entry]
    end

    def within_feed_or_entry?
      (a = ancestors) == [:feed] || a == [:feed,:entry] 
    end

    def within_el?
      !!self.el
    end

    def start_element(name,attrs=[])
      self.tag = name.to_sym; self.attrs = attrs
      handler = "on_start_#{name}"
      self.__send__(handler) if respond_to?(handler) 
      tree.push [self.tag, self.attrs]
    end

    def end_element(name)
      tree.pop
      handler = "on_end_#{name}"
      self.__send__(handler) if respond_to?(handler) 
    end
  
    def characters(chars)
      return unless (c = (self.el || self.current)) and (m = self.target_meth)
      log "#{self.tag}: #{chars[0..30]}"
      c.__send__("#{m}=", (c.__send__(m) || '') + chars)
    end

def log(msg)
  $stderr.puts msg
end

    def on_start_feed
      self.feed = Feed.new
    end

    def on_end_feed
      self.feed.save
      self.feed = nil
    end

    def on_start_entry
      self.entry = Entry.new
    end

    def on_end_entry
      self.feed.save
      self.entry.feed = feed
      self.entry.save
      self.entry = nil
    end

    def on_start_id
      self.target_meth = :uri
    end

    def on_end_id
      self.target_meth = nil 
    end

    def on_start_title
      self.el = TextElement.new(Hash[self.attrs]['type'])
      self.target_meth = :content
    end

    def on_end_title
      self.current.title = self.el.to_h
      self.el = nil; self.target_meth = nil
    end

    def on_start_updated
      self.target_meth = :updated
    end

    def on_end_updated
      self.target_meth = nil
    end

    def on_start_link
    end

    def on_end_link
      links = self.current.links
      self.current.links = links + [Hash[self.attrs]]
      self.el = nil
    end

    

#  attribute :uri
#  attribute :title,        Type::Hash
#  attribute :updated,      Type::Time
#  attribute :primary_link
#  attribute :links,        Type::Array
#  attribute :authors,      Type::Array
#  attribute :categories,   Type::Array
#  attribute :contributors, Type::Array
#  attribute :generator,    Type::Hash
#  attribute :icon
#  attribute :rights,       Type::Hash
#  attribute :subtitle
#
#  collection :entries,     :Entry
 
  end

end
