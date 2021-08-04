require 'vanagon/project/dsl'
require 'vanagon/driver'
require 'vanagon/common'
require 'vanagon/platform'

describe 'Vanagon::Project::DSL' do
  let (:project_block) {
"project 'test-fixture' do |proj|
end" }
  let(:configdir) { '/a/b/c' }
  let(:platform) do
    OpenStruct.new(:settings => {})
  end

  describe '#version_from_git' do
    it 'sets the version based on the git describe' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)

      # Lying is bad. You shouldn't lie. But sometimes when you're
      # working with gross abstractions piled into the shape of
      # an indescribable cyclopean obelisk, you might have to lie
      # a little bit. Instead of trying to mock an entire Git instance,
      # we'll just instantiate a Double and allow it to receive calls
      # to .describe like it was a valid Git instance.
      repo = double("repo")
      expect(::Git)
        .to receive(:open)
        .and_return(repo)

      allow(repo)
        .to receive(:describe)
        .and_return('1.2.3-1234')

      proj.version_from_git
      expect(proj._project.version).to eq('1.2.3.1234')
    end
    it 'sets the version based on the git describe with multiple dashes' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)

      # See previous description of "indescribable cyclopean obelisk"
      repo = double("repo")
      expect(::Git)
        .to receive(:open)
        .and_return(repo)

      expect(repo)
        .to receive(:describe)
        .and_return('1.2.3---1234')

      proj.version_from_git
      expect(proj._project.version).to eq('1.2.3.1234')
    end
  end

  describe '#release_from_git' do
    it 'sets the release based on commits since last tag' do
      repo = double
      tag = double
      log = double
      diff = double
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      repo = double("repo")
      expect(::Git)
        .to receive(:open)
        .and_return(repo)


      expect(repo)
        .to receive(:describe)
        .and_return('1.2.3')

      expect(repo)
        .to receive(:rev_list)
        .with('1.2.3..HEAD', { :count => true })
        .and_return('999')

      proj.release_from_git
      expect(proj._project.release).to eq('999')
    end
  end

  describe '#version_from_branch' do
    it 'parses out versions from branch names' do
      branches = {
        'maint/3.8.x/fix-bugs' => '3.8',
        '2017.1.2.3-prep' => '2017.1.2.3',
        '3.8' => '3.8',
      }

      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)

      branches.each do |branch, version|
        repo = double("repo")
        expect(::Git)
          .to receive(:open)
          .and_return(repo)

        allow(repo)
          .to receive(:current_branch)
          .and_return(branch)

        expect(proj.version_from_branch).to eq(version)
      end
    end

    it 'fails if there is none' do
      branches = [
        'PUP-12345',
        '200',
        'just-a-branch-name'
      ]

      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)

      branches.each do |branch|
        repo = double("repo")
        expect(::Git)
          .to receive(:open)
          .and_return(repo)

        allow(repo)
          .to receive(:current_branch)
          .and_return(branch)

        expect(proj).to receive(:fail)
        proj.version_from_branch
      end
    end
  end

  describe '#directory' do
    it 'adds a directory to the list of directories' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.directory('/a/b/c/d', mode: '0755')
      expect(proj._project.directories).to include(Vanagon::Common::Pathname.new('/a/b/c/d', mode: '0755'))
    end
  end

  describe '#user' do
    it 'sets a user for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.user('test-user')
      expect(proj._project.user).to eq(Vanagon::Common::User.new('test-user'))
    end
  end

  describe '#target_repo' do
    it 'sets the target_repo for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.target_repo "pc1"
      expect(proj._project.repo).to eq("pc1")
    end
  end

  describe '#noarch' do
    it 'sets noarch on the project to true' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.noarch
      expect(proj._project.noarch).to eq(true)
    end
  end

  describe '#generate_source_artifacts' do
    it 'defaults to false' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      expect(proj._project.source_artifacts).to eq(false)
    end

    it 'sets source_artifacts to true' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.generate_source_artifacts true
      expect(proj._project.source_artifacts).to eq(true)
    end

    it 'sets source_artifacts to false' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.generate_source_artifacts false
      expect(proj._project.source_artifacts).to eq(false)
    end
  end

  describe '#identifier' do
    it 'sets the identifier for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.identifier "com.example"
      expect(proj._project.identifier).to eq("com.example")
    end
  end

  describe '#cleanup_during_build' do
    it 'sets @cleanup to true' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.cleanup_during_build
      expect(proj._project.cleanup).to eq(true)
    end

    it 'defaults to nil' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      expect(proj._project.cleanup).to be_nil
    end
  end

  describe "#write_version_file" do
    let(:version_file) { '/opt/puppetlabs/puppet/VERSION' }

    it 'sets version_file for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.write_version_file(version_file)
      expect(proj._project.version_file.path).to eq(version_file)
    end
  end

  describe "#release" do
    it 'sets the release for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.release '12'
      expect(proj._project.release).to eq('12')
    end

    it 'defaults to 1' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      expect(proj._project.release).to eq('1')
    end
  end

  describe "#provides" do
    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      @el_plat = Vanagon::Platform::DSL.new('el-6-x86_64')
      @el_plat.instance_eval("platform 'el-6-x86_64' do |plat| end")
      @deb_plat = Vanagon::Platform::DSL.new('ubuntu-16.04-amd64')
      @deb_plat.instance_eval("platform 'ubuntu-16.04-amd64' do |plat| end")
    end

    it 'adds the package provide to the list of provides' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.provides('thing1')
      proj.provides('thing2')
      expect(proj._project.get_provides.count).to eq(2)
      expect(proj._project.get_provides.first.provide).to eq('thing1')
      expect(proj._project.get_provides.last.provide).to eq('thing2')
    end

    # we don't actually use deb versions for provides at this point, but
    # testing it works nonetheless
    it 'supports deb versioned provides' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @deb_plat._platform, [])
      proj.instance_eval(project_block)
      proj.provides('thing1', '1.2.3')
      expect(proj._project.get_provides.count).to eq(1)
      expect(proj._project.get_provides.first.provide).to eq('thing1')
      expect(proj._project.get_provides.first.version).to eq('>= 1.2.3')
    end

    # we don't actually use deb versions for provides at this point, but
    # testing it works nonetheless
    it 'munges deb* versions' do
      operators = {
        '<' => '<<',
        '>' => '>>',
        '<=' => '<=',
        '>=' => '>=',
        '=' => '='
      }
      operators.each do |initial, munged|
        proj = Vanagon::Project::DSL.new('test-fixture', configdir, @deb_plat._platform, [])
        proj.instance_eval(project_block)
        proj.provides('thing1', "#{initial}1.2.3")
        expect(proj._project.get_provides.count).to eq(1)
        expect(proj._project.get_provides.first.provide).to eq('thing1')
        expect(proj._project.get_provides.first.version).to eq("#{munged} 1.2.3")
      end
    end

    it 'adds whitespace for rpm versions' do
      operators=['<','>','<=','>=','=']
      operators.each do |operator|
        proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
        proj.instance_eval(project_block)
        proj.provides('thing1', "#{operator}1.2.3")
        expect(proj._project.get_provides.count).to eq(1)
        expect(proj._project.get_provides.first.provide).to eq('thing1')
        expect(proj._project.get_provides.first.version).to eq("#{operator} 1.2.3")
      end
    end

    it 'supports versioned provides' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
      proj.instance_eval(project_block)
      proj.provides('thing1', '1.2.3')
      expect(proj._project.get_provides.count).to eq(1)
      expect(proj._project.get_provides.first.provide).to eq('thing1')
      expect(proj._project.get_provides.first.version).to eq('>= 1.2.3')
     end

    it 'gets rid of duplicates' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
      proj.instance_eval(project_block)
      proj.provides('thing1', '1.2.3')
      proj.provides('thing1', '>=1.2.3')
      expect(proj._project.get_provides.count).to eq(1)
      expect(proj._project.get_provides.first.provide).to eq('thing1')
      expect(proj._project.get_provides.first.version).to eq('>= 1.2.3')
    end
  end

  describe "#replaces" do
    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      @el_plat = Vanagon::Platform::DSL.new('el-6-x86_64')
      @el_plat.instance_eval("platform 'el-6-x86_64' do |plat| end")
      @deb_plat = Vanagon::Platform::DSL.new('ubuntu-16.04-amd64')
      @deb_plat.instance_eval("platform 'ubuntu-16.04-amd64' do |plat| end")
    end

    it 'adds the package replacement to the list of replacements' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.replaces('thing1')
      proj.replaces('thing2')
      expect(proj._project.get_replaces.count).to eq(2)
      expect(proj._project.get_replaces.first.replacement).to eq('thing1')
      expect(proj._project.get_replaces.last.replacement).to eq('thing2')
     end

    it 'supports versioned replaces' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
      proj.instance_eval(project_block)
      proj.replaces('thing1', '1.2.3')
      expect(proj._project.get_replaces.count).to eq(1)
      expect(proj._project.get_replaces.first.replacement).to eq('thing1')
      expect(proj._project.get_replaces.first.version).to eq('< 1.2.3')
    end

    it 'supports deb versioned replaces' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @deb_plat._platform, [])
      proj.instance_eval(project_block)
      proj.replaces('thing1', '1.2.3')
      expect(proj._project.get_replaces.count).to eq(1)
      expect(proj._project.get_replaces.first.replacement).to eq('thing1')
      expect(proj._project.get_replaces.first.version).to eq('<< 1.2.3')
    end

    it 'munges deb* versions' do
      operators = {
        '<' => '<<',
        '>' => '>>',
        '<=' => '<=',
        '>=' => '>=',
        '=' => '='
      }
      operators.each do |initial, munged|
        proj = Vanagon::Project::DSL.new('test-fixture', configdir, @deb_plat._platform, [])
        proj.instance_eval(project_block)
        proj.replaces('thing1', "#{initial}1.2.3")
        expect(proj._project.get_replaces.count).to eq(1)
        expect(proj._project.get_replaces.first.replacement).to eq('thing1')
        expect(proj._project.get_replaces.first.version).to eq("#{munged} 1.2.3")
      end
    end

    it 'adds whitespace for rpm versions' do
      operators=['<','>','<=','>=','=']
      operators.each do |operator|
        proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
        proj.instance_eval(project_block)
        proj.replaces('thing1', "#{operator}1.2.3")
        expect(proj._project.get_replaces.count).to eq(1)
        expect(proj._project.get_replaces.first.replacement).to eq('thing1')
        expect(proj._project.get_replaces.first.version).to eq("#{operator} 1.2.3")
      end
    end

    it 'gets rid of duplicates' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
      proj.instance_eval(project_block)
      proj.replaces('thing1', '1.2.3')
      proj.replaces('thing1', '<1.2.3')
      expect(proj._project.get_replaces.count).to eq(1)
      expect(proj._project.get_replaces.first.replacement).to eq('thing1')
      expect(proj._project.get_replaces.first.version).to eq('< 1.2.3')
    end
  end

  describe "#conflicts" do
    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      @el_plat = Vanagon::Platform::DSL.new('el-6-x86_64')
      @el_plat.instance_eval("platform 'el-6-x86_64' do |plat| end")
      @deb_plat = Vanagon::Platform::DSL.new('ubuntu-16.04-amd64')
      @deb_plat.instance_eval("platform 'ubuntu-16.04-amd64' do |plat| end")
    end

    it 'adds the package conflict to the list of conflicts' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform)
      proj.instance_eval(project_block)
      proj.conflicts('thing1')
      proj.conflicts('thing2')
      expect(proj._project.get_conflicts.count).to eq(2)
      expect(proj._project.get_conflicts.first.pkgname).to eq('thing1')
      expect(proj._project.get_conflicts.last.pkgname).to eq('thing2')
     end

    it 'supports versioned conflicts' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
      proj.instance_eval(project_block)
      proj.conflicts('thing1', '1.2.3')
      expect(proj._project.get_conflicts.count).to eq(1)
      expect(proj._project.get_conflicts.first.pkgname).to eq('thing1')
      expect(proj._project.get_conflicts.first.version).to eq('< 1.2.3')
     end

    it 'supports deb versioned conflicts' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @deb_plat._platform, [])
      proj.instance_eval(project_block)
      proj.conflicts('thing1', '1.2.3')
      expect(proj._project.get_conflicts.count).to eq(1)
      expect(proj._project.get_conflicts.first.pkgname).to eq('thing1')
      expect(proj._project.get_conflicts.first.version).to eq('<< 1.2.3')
    end

    it 'munges deb* versions' do
      operators = {
        '<' => '<<',
        '>' => '>>',
        '<=' => '<=',
        '>=' => '>=',
        '=' => '='
      }
      operators.each do |initial, munged|
        proj = Vanagon::Project::DSL.new('test-fixture', configdir, @deb_plat._platform, [])
        proj.instance_eval(project_block)
        proj.conflicts('thing1', "#{initial}1.2.3")
        expect(proj._project.get_conflicts.count).to eq(1)
        expect(proj._project.get_conflicts.first.pkgname).to eq('thing1')
        expect(proj._project.get_conflicts.first.version).to eq("#{munged} 1.2.3")
      end
    end

    it 'adds whitespace for rpm versions' do
      operators=['<','>','<=','>=','=']
      operators.each do |operator|
        proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
        proj.instance_eval(project_block)
        proj.conflicts('thing1', "#{operator}1.2.3")
        expect(proj._project.get_conflicts.count).to eq(1)
        expect(proj._project.get_conflicts.first.pkgname).to eq('thing1')
        expect(proj._project.get_conflicts.first.version).to eq("#{operator} 1.2.3")
      end
    end

    it 'gets rid of duplicates' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
      proj.instance_eval(project_block)
      proj.conflicts('thing1', '1.2.3')
      proj.conflicts('thing1', '<1.2.3')
      expect(proj._project.get_conflicts.count).to eq(1)
      expect(proj._project.get_conflicts.first.pkgname).to eq('thing1')
      expect(proj._project.get_conflicts.first.version).to eq('< 1.2.3')
    end
  end

  describe "#package_override" do
    let(:project_block) {
"project 'test-fixture' do |proj|
  proj.package_override \"TEST_VAR='foo'\"
end"
    }

    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      @el_plat = Vanagon::Platform::DSL.new('el-6-x86_64')
      @el_plat.instance_eval("platform 'el-6-x86_64' do |plat| end")
      @osx_plat = Vanagon::Platform::DSL.new('osx-10.10-x86_64')
      @osx_plat.instance_eval("platform 'osx-10.10-x86_64' do |plat| end")

    end

    it 'adds package_overrides on supported platforms' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @el_plat._platform, [])
      proj.instance_eval(project_block)
      expect(proj._project.package_overrides).to include("TEST_VAR='foo'")
    end

    it 'fails on usupported platforms' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, @osx_plat._platform, [])
      expect{ proj.instance_eval(project_block) }.to raise_error(RuntimeError)
    end
  end

  describe "#component" do
    let(:project_block) {
"project 'test-fixture' do |proj|
  proj.component 'some-component'
end"
    }

    let(:component) { double(Vanagon::Component) }

    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      allow(Vanagon::Component).to receive(:load_component).with('some-component', any_args).and_return(component)
    end

    it 'stores the component in the project if the included components set is empty' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
      proj.instance_eval(project_block)
      expect(proj._project.components).to include(component)
    end

    it 'stores the component in the project if the component name is listed in the included components set' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, ['some-component'])
      proj.instance_eval(project_block)
      expect(proj._project.components).to include(component)
    end

    it 'does not store the component if the included components set is not empty and does not include the component name' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, ['some-different-component'])
      proj.instance_eval(project_block)
      expect(proj._project.components).to_not include(component)
    end
  end

  describe "#fetch_artifact" do
    let(:project_block) {
      "project 'test-fixture' do |proj|
        proj.fetch_artifact 'foo/bar/baz.file'
      end"
    }
    let(:project_block_multiple) {
      "project 'test-fixture' do |proj|
        proj.fetch_artifact 'foo/bar/baz.file'
        proj.fetch_artifact 'foo/foobar/foobarbaz.file'
      end"
    }
    let(:empty_project_block) {
      "project 'test-fixture' do |proj|
      end"
    }

    it 'has an empty project.fetch_artifact when fetch_artifact is not called' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
      proj.instance_eval(empty_project_block)
      expect(proj._project.artifacts_to_fetch).to eq([])
    end

    it 'Adds a path to project.fetch_artifact when fetch_artifact is called' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
      proj.instance_eval(project_block)
      expect(proj._project.artifacts_to_fetch).to eq(['foo/bar/baz.file'])
    end

    it 'Adds multiple paths to project.fetch_artifact when fetch_artifact is called more than once' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
      proj.instance_eval(project_block_multiple)
      expect(proj._project.artifacts_to_fetch).to eq(['foo/bar/baz.file', 'foo/foobar/foobarbaz.file'])
    end
  end

  describe "#no_packaging" do
    let(:project_block) {
      "project 'test-fixture' do |proj|
        proj.no_packaging true
      end"
    }
    let(:project_block_false) {
      "project 'test-fixture' do |proj|
        proj.no_packaging false
      end"
    }
    let(:empty_project_block) {
      "project 'test-fixture' do |proj|
      end"
    }

    it 'has no_packaging set to false by default' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
      proj.instance_eval(empty_project_block)
      expect(proj._project.no_packaging).to eq(false)
    end

    it 'sets no_packaging to true when proj.no_packaging true is called' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
      proj.instance_eval(project_block)
      expect(proj._project.no_packaging).to eq(true)
    end

    it 'sets no_packaging to false when proj.no_packaging false is called' do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
      proj.instance_eval(project_block_false)
      expect(proj._project.no_packaging).to eq(false)
    end
  end
end
