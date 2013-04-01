require 'nokogiri'

class Struct
  unless self.methods.respond_to?(:to_h)
    def to_h
      self.members.inject({}) {|h,k|
        h[k] = self.send(k) if self.send(k)
        h
      }
    end
  end
end

#TODO: source element
#TODO: deal with case of embedded (unescaped) xhtml in content tags

module Russ

  class AtomParser < Nokogiri::XML::SAX::Document

    class Error < StandardError
      
      attr_reader :underlying_error, :parser 

      def initialize(e,parser)
        @underlying_error = e
        @parser = parser
      end

      def to_s
        [ "Parse error at /#{parser.ancestors.join('/')}/#{parser.tag}",
          parser.entry_count == 0 ? 
            "(in feed metadata)" : 
            "(in entry #{parser.entry_count})",
          "Underlying error:",
          underlying_error.to_s
        ].join("\n")
      end

    end

    class TextElement
      attr_accessor :type, :content
      
      def initialize(type)
        self.type = type
      end

      def to_h
        [:type, :content].inject({}) {|h,k|
          h[k] = self.send(k) if self.send(k)
          h
        }
      end
    end

    class PersonElement < Struct.new(:name, :uri, :email); end

    class ContentElement
      attr_accessor :type, :src, :content

      def initialize(attrs={})
        self.type = attrs['type']
        self.src  = attrs['src']
      end

      def to_h
        [:type, :src, :content].inject({}) {|h,k|
          h[k] = self.send(k) if self.send(k)
          h
        }
      end

    end

    class GeneratorElement
      attr_accessor :uri, :version, :content

      def initialize(attrs={})
        self.version = attrs['version']
        self.uri  = attrs['uri']
      end

      def to_h
        [:uri, :version, :content].inject({}) {|h,k|
          h[k] = self.send(k) if self.send(k)
          h
        }
      end
    end
    
    attr_accessor :tag, :attrs
    attr_accessor :feed, :entry, :el, :target_meth, :entry_count

    def initialize(feed=nil)
      self.feed = feed if feed
      self.entry_count = 0
    end

    def wrap_error(e)
      raise Error.new(e, self)
    end

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

    def within_feed_or_entry_element?
      [:title,:link,:category,:author,:contributor,
       :content,:summary,:rights].map {|tag|
         [:feed,:entry,tag]
      }.include?(ancestors)
    end

    def start_element(name,attrs=[])
      @buf = nil
      self.tag = name.to_sym; self.attrs = attrs
      handler = "on_start_#{name}"
      self.__send__(handler) if respond_to?(handler) 
      tree.push [self.tag, self.attrs]
    rescue StandardError => e
      wrap_error e
    end

    def end_element(name)
      if @buf && /^\s*$/ !~ @buf
        if (c = (self.el || self.current)) and (m = self.target_meth)
          c.__send__("#{m}=",@buf)
        end
      end
      @buf = nil
      tree.pop
      handler = "on_end_#{name}"
      self.__send__(handler) if respond_to?(handler) 
    rescue StandardError => e
      wrap_error e
    end
  
    def characters(chars)
      @buf = (@buf || '') + chars
    rescue StandardError => e
      wrap_error e
    end

    def on_start_feed
      self.feed ||= Feed.new
    end

    def on_end_feed
      self.feed.save
      self.feed = nil
    end

    def on_start_entry
      self.entry = Entry.new
      self.entry_count += 1
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

    def on_start_published
      self.target_meth = :published
    end

    def on_end_published
      self.target_meth = nil
    end

    def on_end_link
      links = self.current.links
      self.current.links = links + [Hash[self.attrs]]
      self.el = nil
    end

    def on_end_category
      categories = self.current.categories
      self.current.categories = categories + [Hash[self.attrs]]
      self.el = nil
    end

    def on_start_author
      self.el = PersonElement.new
      self.target_meth = :content
    end

    def on_end_author
      authors = self.current.authors
      self.current.authors = authors + [self.el.to_h]
      self.el = nil; self.target_meth = nil
    end

    def on_start_contributor
      self.el = PersonElement.new
      self.target_meth = :content
    end

    def on_end_contributor
      contributors = self.current.contributors
      self.current.contributors = contributors + [self.el.to_h]
      self.el = nil; self.target_meth = :content
    end

    def on_start_content
      self.el = ContentElement.new(Hash[self.attrs])
      self.target_meth = :content
    end

    def on_end_content
      self.current.content = self.el.to_h
      self.el = nil; self.target_meth = nil
    end

    def on_start_generator
      self.el = GeneratorElement.new(Hash[self.attrs])
      self.target_meth = :content
    end

    def on_end_generator
      self.current.generator = self.el.to_h
      self.el = nil; self.target_meth = nil
    end

    def on_start_summary
      self.el = TextElement.new(Hash[self.attrs]['type'])
      self.target_meth = :content
    end

    def on_end_summary
      self.current.summary = self.el.to_h
      self.el = nil; self.target_meth = nil
    end

    def on_start_rights
      self.el = TextElement.new(Hash[self.attrs]['type'])
      self.target_meth = :content
    end

    def on_end_rights
      self.current.rights = self.el.to_h
      self.el = nil; self.target_meth = nil
    end

    #---- PersonElement tags

    def on_start_name
      self.target_meth = :name
    end

    def on_end_name
      self.target_meth = nil
    end

    def on_start_email
      self.target_meth = :email
    end

    def on_end_email
      self.target_meth = nil
    end

    def on_start_uri
      self.target_meth = :uri
    end

    def on_end_uri
      self.target_meth = nil
    end

  end

end
