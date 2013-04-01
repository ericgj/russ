require 'delegate'
require 'json'

module Russ
  module Json
    
    module Utils

      def rfc3339(dt)
        dt.strftime('%Y-%m-%dT%H:%M:%S%:z') if dt
      end
 
      # Note: casting to hash done in model

      def text_element(e={})
        e
      end

      def link_element(e={})
        e
      end

      def person_element(e={})
        e
      end

      def category_element(e={})
        e
      end

      def generator_element(e={})
        e
      end

      def source_element(e={})
        e['id'] ||= e.delete('uri')
        e
      end

    end

    class Feed < SimpleDelegator
      include Utils

      def to_hash
        metadata_hash.merge({entries: _entries_array})
      end

      def metadata_hash  
        {
          id:           uri,
          title:        text_element(title),
          updated:      rfc3339(updated),
          link:         link_element(primary_link),
          links:        _links_array,
          authors:      _authors_array,
          categories:   _categories_array,
          contributors: _contribs_array
        }.merge( _optional_tags ) 
      end

      def to_s
        JSON.dump(to_hash)
      end

      private

      def _optional_tags
        h = {}
        h[:generator] = generator_element(generator) if generator
        h[:icon]      = icon if icon
        h[:logo]      = logo if logo
        h[:rights]    = text_element(rights) if rights
        h[:subtitle]  = subtitle if subtitle
        h
      end

      def _authors_array
        (authors || []).map {|a| person_element(a)}
      end

      def _links_array
        (links || []).map {|l| link_element(l)}
      end

      def _categories_array
        (categories || []).map {|c| category_element(c)}
      end

      def _contribs_array
        (contributors || []).map {|c| person_element(c)}
      end

      def _entries_array
        entries.map {|e| Entry.new(e).to_hash}
      end

    end

    class Entry < SimpleDelegator
      include Utils

      def to_hash
        {
          id:           uri,
          title:        text_element(title),
          updated:      rfc3339(updated),
          link:         link_element(primary_link),
          links:        _links_array,
          authors:      _authors_array,
          categories:   _categories_array,
          contributors: _contribs_array,
          summary:      text_element(summary),
          content:      text_element(content)
        }.merge( _optional_tags )
      end

      def to_s
        JSON.dump(to_hash)
      end

      private
      
      def _optional_tags
        h = {}
        h[:published] = rfc3339(published) 
        h[:rights]    = text_element(rights) if rights
        h[:source]    = source_element(source) if source 
        h
      end

      def _authors_array
        (authors || []).map {|a| person_element(a)}
      end

      def _links_array
        (links || []).map {|l| link_element(l)}
      end

      def _categories_array
        (categories || []).map {|c| category_element(c)}
      end

      def _contribs_array
        (contributors || []).map {|c| person_element(a)}
      end

    end

  end
end
