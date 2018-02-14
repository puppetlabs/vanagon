require 'git/rev_list'
include LibRevList

describe 'Git::LibRevList' do
  describe '#rev_list' do
    it 'calls command' do
      expect(LibRevList).to receive(:command).with('rev-list', [])
      LibRevList.rev_list
    end

    it 'calls command with commitish' do
      expect(LibRevList).to receive(:command).with('rev-list', ['HEAD'])
      LibRevList.rev_list('HEAD')
    end

    it 'calls command with commitish and a boolean option' do
      expect(LibRevList).to receive(:command).with('rev-list', ['--count', 'HEAD'])
      LibRevList.rev_list('HEAD', { :count => true })
    end

    it 'calls command with commitish and an option that uses a param' do
      expect(LibRevList).to receive(:command).with('rev-list', ['--max-age=200', 'HEAD'])
      LibRevList.rev_list('HEAD', { :max_age => 200 })
    end
  end
end