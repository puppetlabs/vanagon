require 'vanagon/platform'

describe "Vanagon::Platform" do
  let(:deb_platform_just_servicedir) { "platform 'debian-test-fixture' do |plat|
                                       plat.servicedir '/etc/init.d'
                                       end
                                       "}
  let(:deb_platform_just_servicetype) { "platform 'debian-test-fixture' do |plat|
                                       plat.servicetype 'sysv'
                                       end
                                       "}
  let(:deb_platform_multi_servicetypes) { "platform 'debian-test-fixture' do |plat|
                                       plat.servicetype 'sysv', servicedir: '/etc/init.d'
                                       plat.servicetype 'systemd', servicedir: '/lib/systemd/system'
                                       end
                                       "}
  let(:deb_platform_no_service) { "platform 'debian-test-fixture' do |plat|
                                       end
                                       "}
  let(:deb_platform_servicetype) { "platform 'debian-test-fixture' do |plat|
                                       plat.servicetype 'sysv'
                                       plat.servicedir '/etc/init.d'
                                       end
                                       "}
  let(:deb_platform_bad_servicedir_block) { "platform 'debian-test-fixture' do |plat|
                                            plat.servicetype 'sysv', servicedir: '/etc/init.d'
                                            plat.servicetype 'sysv', servicedir: '/etc/rc.d'
                                            end
                                            "}

  let(:platforms) do
    [
      {
        :name                           => "debian-6-i386",
        :os_name                        => "debian",
        :os_version                     => "6",
        :architecture                   => "i386",
        :output_dir                     => "deb/lucid/",
        :output_dir_with_target         => "deb/lucid/thing",
        :output_dir_empty_string        => "deb/lucid/",
        :source_output_dir              => "deb/lucid/",
        :source_output_dir_with_target  => "deb/lucid/thing",
        :source_output_dir_empty_string => "deb/lucid/",
        :is_rpm                         => false,
        :is_el                          => false,
        :block                          => %Q[
          platform "debian-6-i386" do |plat|
            plat.codename "lucid"
          end ],
      },
      {
        :name                           => "el-5-i386",
        :os_name                        => "el",
        :os_version                     => "5",
        :architecture                   => "i386",
        :output_dir                     => "el/5/products/i386",
        :output_dir_with_target         => "el/5/thing/i386",
        :output_dir_empty_string        => "el/5/i386",
        :source_output_dir              => "el/5/products/SRPMS",
        :source_output_dir_with_target  => "el/5/thing/SRPMS",
        :source_output_dir_empty_string => "el/5/SRPMS",
        :is_rpm                         => true,
        :is_el                          => true,
        :block                          => %Q[ platform "el-5-i386" do |plat| end ],
      },
      {
        :name                           => "redhat-7-x86_64",
        :os_name                        => "redhat",
        :os_version                     => "7",
        :architecture                   => "x86_64",
        :output_dir                     => "redhat/7/products/x86_64",
        :output_dir_with_target         => "redhat/7/thing/x86_64",
        :output_dir_empty_string        => "redhat/7/x86_64",
        :source_output_dir              => "redhat/7/products/SRPMS",
        :source_output_dir_with_target  => "redhat/7/thing/SRPMS",
        :source_output_dir_empty_string => "redhat/7/SRPMS",
        :is_rpm                         => true,
        :is_el                          => true,
        :block                          => %Q[ platform "redhat-7-x86_64" do |plat| end ],
      },
      {
        :name                           => "debian-6-i386",
        :os_name                        => "debian",
        :os_version                     => "6",
        :codename                       => "lucid",
        :architecture                   => "i386",
        :output_dir                     => "updated/output",
        :output_dir_with_target         => "updated/output",
        :output_dir_empty_string        => "updated/output",
        :source_output_dir              => "updated/sources",
        :source_output_dir_with_target  => "updated/sources",
        :source_output_dir_empty_string => "updated/sources",
        :is_rpm                         => false,
        :is_el                          => false,
        :block                          => %Q[
          platform "debian-6-i386" do |plat|
            plat.codename "lucid"
            plat.output_dir "updated/output"
            plat.source_output_dir "updated/sources"
          end ],
      },
    ]
  end

  describe "#os_name" do
    it "returns the os_name for the platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.os_name).to eq(plat[:os_name])
      end
    end
  end

  describe "#os_version" do
    it "returns the the os_version for the platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.os_version).to eq(plat[:os_version])
      end
    end
  end

  describe "#output_dir" do
    it "returns correct output dir" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.output_dir).to eq(plat[:output_dir])
      end
    end

    it "adds the target repo in the right way" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.output_dir('thing')).to eq(plat[:output_dir_with_target])
      end
    end

    it "does the right thing with empty strings" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.output_dir('')).to eq(plat[:output_dir_empty_string])
      end
    end
  end

  describe "#source_output_dir" do
    it "returns correct source dir" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.source_output_dir).to eq(plat[:source_output_dir])
      end
    end

    it "adds the target repo in the right way" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.source_output_dir('thing')).to eq(plat[:source_output_dir_with_target])
      end
    end

    it "does the right thing with empty strings" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.source_output_dir('')).to eq(plat[:source_output_dir_empty_string])
      end
    end
  end


  describe "#architecture" do
    it "returns the architecture for the platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.architecture).to eq(plat[:architecture])
      end
    end
  end

  describe "#is_rpm?" do
    it "returns true if this is an rpm platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.is_rpm?).to eq(plat[:is_rpm])
      end
    end
  end

  describe "#is_el?" do
    it "returns true if this is an el platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.is_el?).to eq(plat[:is_el])
      end
    end
  end

  describe "#get_service_type" do
    it "returns plat.servicetype if that's the only thing set" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_just_servicetype)
      expect(plat._platform.get_service_types).to include('sysv')
    end

    it "returns from servicetypes if that's set" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_servicetype)
      expect(plat._platform.get_service_types).to include('sysv')
    end

    it "returns multiples if there's more than one" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_multi_servicetypes)
      expect(plat._platform.get_service_types).to include('sysv')
      expect(plat._platform.get_service_types).to include('systemd')
    end

    it "returns an empty array if nothing is set" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_no_service)
      expect(plat._platform.get_service_types.size).to eq(0)
    end
  end

  describe "#get_service_dir" do
    it "returns plat.servicedir if that's the only thing set" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_just_servicedir)
      expect(plat._platform.get_service_dir).to eq('/etc/init.d')
    end

    it "returns servicedirs set via servicetype" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_servicetype)
      expect(plat._platform.get_service_dir).to eq('/etc/init.d')
    end

    it "returns the servicedir based on servicetype" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_multi_servicetypes)
      expect(plat._platform.get_service_dir('systemd')).to eq('/lib/systemd/system')
    end

    it "fails if there are >1 servicedir for a service type" do
      plat = Vanagon::Platform::DSL.new('debian-8-x86_64')
      plat.instance_eval(deb_platform_bad_servicedir_block)
      expect { plat._platform.get_service_dir('sysv') }.to raise_error(Vanagon::Error)
    end
  end
end
