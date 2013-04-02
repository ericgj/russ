
class SourceFeedRoutes < Cuba
  define do
  

    on ':slug' do |slug|

      feed = Feed.with(:slug,slug)

      on get do

        rep = Russ::Json::Feed.new(feed)

        on accept('application/json') do
          res['Content-Type'] = "application/json"
          res.write rep.to_s
        end

        on default do
          res['Content-Type'] = "text/plain"
          res.write [ 'application/json', 
                      'application/atom+xml',
                      'application/xml'
                    ].join("\n")
          res.status = 406
        end

      end

      on put do
        
        tags = Array(params['tag'])
        reader = Reader.with(:identity, current_user.nick)
        reader.subscribe(feed,tags)

      end

    end

  end
end
