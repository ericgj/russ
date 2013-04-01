
require 'json'
require_relative 'test_helper_server'

describe 'GET /u/feed/testy/tag, json response, controller' do

  def feed_entry_count(uri)
    Feed.with(:identity,uri).entries.count
  end

  before do
    create_reader reader_attr 
    load_feed 'feeds/atom-feed.xml'
    load_feed 'feeds/feedburner-atom.xml'
    load_feed 'feeds/bliki-atom.xml'
    sub_reader 'testy', 'atom-feed', ['tag']
    sub_reader 'testy', 'feedburner-atom', ['tag']
    sub_reader 'testy', 'bliki-atom', ['another']
    header 'Accept', 'application/json'
    get '/u/feed/testy/tag'
  end

  let(:reader_attr)             { {
    nick: 'testy',
    name: 'Tesla E. Sty'
  } }

  let(:json_response)           { JSON.load(last_response.body) }
  let(:feed_source_attributes)  { 
    Feed.get_attributes - 
      [:uri,:entries,:categories,:generator,:icon,:logo,:subtitle]
  }

  it 'should return status ok' do
    assert last_response.ok?, 
      "Expected OK response, got #{last_response.status} \n#{last_response.body}"
  end

  it 'body should parse as JSON' do
    json_response
  end

  it 'should have aggregate metadata' do
    act = json_response
    assert_equal "/u/feed/#{reader_attr[:nick]}/tag", act['id']
    assert_equal reader_attr[:name], act['contributors'][0]['name'] 
    refute_includes act['contributors'][0], 'email'   # reader has no email
    assert_match /\btag\b/i, act['title']
  end

  it 'should have entries equal to the sum of the aggregated feeds' do
    act = json_response['entries']
    refute_empty act
    assert_equal feed_entry_count('atom-feed') + feed_entry_count('feedburner-atom'),
                 act.count
  end

  it 'should have entries sorted by updated timestamp' do
    act = json_response['entries']
    act.each_slice(2) do |(a,b)|
      next unless a && b
      assert a['updated'] >= b['updated'], 
        "Expected #{a['updated']} >= #{b['updated']}" 
    end
  end

  it 'each entry should have a source key with original feed metadata' do
    act = json_response['entries']
    act.each do |entry|
      assert_includes entry, 'source'
      assert_includes entry['source'], 'id'
      assert_includes ['atom-feed','feedburner-atom'], 
                      entry['source']['id'], entry['source'].inspect
      feed_source_attributes.each do |attr|
        assert_includes entry['source'], attr.to_s
      end
    end
  end

end

describe 'GET /u/feed/testy, json response, controller' do

  def feed_entry_count(uri)
    Feed.with(:identity,uri).entries.count
  end

  before do
    create_reader reader_attr 
    load_feed 'feeds/atom-feed.xml'
    load_feed 'feeds/feedburner-atom.xml'
    load_feed 'feeds/bliki-atom.xml'
    sub_reader 'testy', 'atom-feed', ['tag']
    sub_reader 'testy', 'feedburner-atom', ['tag']
    sub_reader 'testy', 'bliki-atom', ['another']
    header 'Accept', 'application/json'
    get '/u/feed/testy'
  end

  let(:reader_attr)             { {
    nick: 'testy',
    name: 'Tesla E. Sty'
  } }

  let(:json_response)           { JSON.load(last_response.body) }
  let(:feed_source_attributes)  { 
    Feed.get_attributes - 
      [:uri,:entries,:categories,:generator,:icon,:logo,:subtitle]
  }

  it 'should return status ok' do
    assert last_response.ok?, 
      "Expected OK response, got #{last_response.status} \n#{last_response.body}"
  end

  it 'body should parse as JSON' do
    json_response
  end

  it 'should have aggregate metadata' do
    act = json_response
    assert_equal "/u/feed/#{reader_attr[:nick]}", act['id']
    assert_equal reader_attr[:name], act['contributors'][0]['name'] 
  end

  it 'should have entries equal to the sum of the aggregated feeds' do
    act = json_response['entries']
    refute_empty act
    assert_equal feed_entry_count('atom-feed') + 
                   feed_entry_count('feedburner-atom') + 
                   feed_entry_count('bliki-atom'),
                 act.count
  end

  it 'should have entries sorted by updated timestamp' do
    act = json_response['entries']
    act.each_slice(2) do |(a,b)|
      next unless a && b
      assert a['updated'] >= b['updated'], 
        "Expected #{a['updated']} >= #{b['updated']}" 
    end
  end

  it 'each entry should have a source key with original feed metadata' do
    act = json_response['entries']
    act.each do |entry|
      assert_includes entry, 'source'
      assert_includes entry['source'], 'id'
      assert_includes ['atom-feed','feedburner-atom','bliki-atom'], 
                      entry['source']['id'], entry['source'].inspect
      feed_source_attributes.each do |attr|
        assert_includes entry['source'], attr.to_s
      end
    end
  end

end

