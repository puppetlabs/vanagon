require 'vanagon/common/user'

describe 'Vanagon::Common::User' do
  describe 'initialize' do
    it 'group defaults to the name of the user' do
      user = Vanagon::Common::User.new('willamette')
      expect(user.group).to eq('willamette')
    end
  end

  describe 'equality' do
    it 'is not equal if the names differ' do
      user1 = Vanagon::Common::User.new('willamette')
      user2 = Vanagon::Common::User.new('columbia')
      expect(user1).not_to eq(user2)
    end

    it 'is not equal if there are different attributes set' do
      user1 = Vanagon::Common::User.new('willamette', 'group1')
      user2 = Vanagon::Common::User.new('willamette', 'group2')
      expect(user1).not_to eq(user2)
    end

    it 'is equal if there are the same attributes set to the same values' do
      user1 = Vanagon::Common::User.new('willamette', 'group')
      user2 = Vanagon::Common::User.new('willamette', 'group')
      expect(user1).to eq(user2)
    end

    it 'is equal if the name are the same and the only attribute set' do
      user1 = Vanagon::Common::User.new('willamette')
      user2 = Vanagon::Common::User.new('willamette')
      expect(user1).to eq(user2)
    end
  end
end
