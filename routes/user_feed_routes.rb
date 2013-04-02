
class UserFeedRoutes < Cuba
  define do

    on ':nick/:tag' do |nick,tag|
    
      reader = Reader.with(:identity,nick)

      on get do
        feed = reader.aggregate_for_tag( tag, 
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
    
      reader = Reader.with(:identity,nick)

      on get do
        feed = reader.aggregate(  
                 :uri => "/u/feed/#{nick}",
                 :title => "Aggregate feed: #{reader.fullname}",
                 :contributors => [{'name' => reader.fullname}],
                 :categories   => [nick]
               )

        rep = Russ::Json::Feed.new(feed)

        on accept('application/json') do
          res['Content-Type'] = "application/json"
          res.write rep.to_s
        end
      end

    end

  end
end

