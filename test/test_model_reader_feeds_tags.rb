require_relative 'test_helper_server'

describe 'Reader feed tags model' do

  let(:feeds) { [
    Feed.create(:uri => 'abc'),
    Feed.create(:uri => 'def'),
    Feed.create(:uri => 'ghi'),
    Feed.create(:uri => 'jkl')
  ]}

  let(:tags) { [
    %w[ one three ],
    %w[ three ],
    %w[ two four ],
    []
  ]}

  describe '#subscribe' do

    subject { Reader.create :nick => 'testy' }

    before do
      feeds.each_with_index do |feed, i|
        subject.subscribe feed, tags[i]
      end
    end

    it 'feeds should return all subscribed feeds' do
      feeds.each do |feed|
        assert_includes subject.feeds, feed
      end
    end

    it 'feeds_tagged should return correct list of feeds tagged with tag one' do
      assert_includes subject.feeds_tagged('one'), feeds[0]
      assert_equal 1, subject.feeds_tagged('one').count
    end

    it 'feeds_tagged should return correct list of feeds tagged with tag two' do
      assert_includes subject.feeds_tagged('two'), feeds[2]
      assert_equal 1, subject.feeds_tagged('two').count
    end

    it 'feeds_tagged should return correct list of feeds tagged with tag three' do
      assert_includes subject.feeds_tagged('three'), feeds[0]
      assert_includes subject.feeds_tagged('three'), feeds[1]
      assert_equal 2, subject.feeds_tagged('three').count
    end

    it 'feeds_tagged should return correct list of feeds tagged with tag four' do
      assert_includes subject.feeds_tagged('four'), feeds[2]
      assert_equal 1, subject.feeds_tagged('four').count
    end

  end

  describe '#unsubscribe' do

    subject { Reader.create :nick => 'testy' }

    before do
      feeds.each_with_index do |feed, i|
        subject.subscribe feed, tags[i]
      end
      subject.unsubscribe feeds[0]
    end

    it 'feeds should return all subscribed feeds except unsub' do
      feeds.each_with_index do |feed,i|
        if i == 0
          refute_includes subject.feeds, feed
        else
          assert_includes subject.feeds, feed
        end
      end
    end

    it 'feeds_tagged should return correct list of feeds tagged with tag one, after unsub' do
      refute_includes subject.feeds_tagged('one'), feeds[0]
      assert_equal 0, subject.feeds_tagged('one').count
    end
    
    it 'feeds_tagged should return correct list of feeds tagged with tag two, after unsub' do
      assert_includes subject.feeds_tagged('two'), feeds[2]
      assert_equal 1, subject.feeds_tagged('two').count
    end

    it 'feeds_tagged should return correct list of feeds tagged with tag three, after unsub' do
      refute_includes subject.feeds_tagged('three'), feeds[0]
      assert_includes subject.feeds_tagged('three'), feeds[1]
      assert_equal 1, subject.feeds_tagged('three').count
    end
    
    it 'feeds_tagged should return correct list of feeds tagged with tag four, after unsub' do
      assert_includes subject.feeds_tagged('four'), feeds[2]
      assert_equal 1, subject.feeds_tagged('four').count
    end
    
  end
  
end
