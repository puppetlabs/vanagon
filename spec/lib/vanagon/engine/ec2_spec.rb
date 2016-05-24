begin
  require 'aws-sdk'
rescue LoadError
  $stderr.puts "Unable to load AWS SDK; skipping optional EC2 engine spec tests"
end

if defined? ::Aws
  require 'vanagon/engine/ec2'
  require 'vanagon/platform'

  describe 'Vanagon::Engine::Ec2' do
    let(:platform_ec2) do
      plat = Vanagon::Platform::DSL.new('el-7-x86_64')
      plat.instance_eval(<<-END)
        platform 'el-7-x86_64' do |plat|
          plat.aws_ami 'ami'
          plat.target_user 'root'
          plat.aws_subnet_id 'subnet_id'
          plat.aws_user_data 'user_data'
          plat.aws_region 'us-west-1'
          plat.aws_key_name 'vanagon'
          plat.aws_instance_type 't1.micro'
          plat.ssh_port '22'
        end
      END
      plat._platform
    end

    it 'returns "ec2" name' do
      expect(Vanagon::Engine::Ec2.new(platform_ec2).name).to eq('ec2')
    end
  end
end
