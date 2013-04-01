require 'json'
require_relative 'test_helper_server'

describe 'GET /feed/:slug, json response, controller' do

  def feed_slug(uri)
    Feed.with(:identity,uri).slug
  end

  before do
    load_feed 'feeds/atom-feed.xml'
    header 'Accept', 'application/json'
    get "/feed/#{feed_slug('atom-feed')}"
  end

  it 'should return status ok' do
    assert last_response.ok?, 
      "Expected OK response, got #{last_response.status} \n#{last_response.body}"
  end

  it 'body should parse as JSON' do
    j= JSON.load(last_response.body)
    assert_equal 25, j['entries'].count
  end

end
