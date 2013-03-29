
class UserRoutes < Cuba
  define do

    on 'u', 'feed' do
      run UserFeedRoutes
    end

    on 'u', 'subs' do
      run UserSubsRoutes
    end

    on 'feed' do
      run SourceFeedRoutes
    end

  end
end
