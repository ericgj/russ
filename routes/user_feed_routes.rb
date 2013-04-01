
class UserFeedRoutes < Cuba
  define do

    on ':nick/:tag' do |nick,tag|
    
      on get do
        reader = Reader.with(:identity,nick)
        feed = reader.virtual_feed(tag, 
                 :uri => "/u/feed/#{nick}/#{tag}",
                 :title => "Aggregate feed: #{tag}",
                 :contributors => [{'name' => reader.fullname}],
                 :categories   => [nick, tag]
               )

        rep = Russ::Json::Feed.new(feed)

        on accept('application/json') do
          res['Content-Type'] = "application/json"
          res.write rep.to_s
        end
      end

    end

    on ':nick' do |nick|

    end

  end
end

