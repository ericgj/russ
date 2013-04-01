
class SourceFeedRoutes < Cuba
  define do
  
    on ':uri' do |uri|

      on get do

        feed = Feed.with(:identity,uri)
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

      end

    end

  end
end
