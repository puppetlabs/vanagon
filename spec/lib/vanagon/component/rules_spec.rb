require 'vanagon/component'
require 'vanagon/component/dsl'
require 'vanagon/component/rules'
require 'vanagon/platform/osx'
require 'vanagon/project'
require 'vanagon/patch'
require 'ostruct'

RSpec.shared_examples "a rule that touches the target file" do
  it "touches the target file as the last step of the recipe" do
    expect(rule.recipe.last).to eq "touch #{rule.target}"
  end
end

describe Vanagon::Component::Rules do
  let(:platform) do
    OpenStruct.new(:patch => "/usr/bin/patch", :make => '/usr/bin/make')
  end

  let(:project) do
    Vanagon::Project.new("cpp-project", platform)
  end

  let(:component) do
    Vanagon::Component.new("leatherman", {}, platform).tap do |c|
      c.dirname = "/foo/bar"
    end
  end

  subject { described_class.new(component, project, platform) }

  describe "the component rule" do
    it "depends on the component-install rule" do
      rule = subject.component_rule
      expect(rule.dependencies).to eq(["leatherman-install"])
    end
  end

  describe "the unpack rule" do
    let(:rule) { subject.unpack_rule }

    it { expect(rule.dependencies).to eq(["file-list-before-build"]) }

    it "extracts the source" do
      component.extract_with = "/usr/bin/tar"
      expect(rule.recipe.first).to eq "/usr/bin/tar"
    end

    it "sets environment variables before running the unpack steps" do
      component.extract_with = "/usr/bin/tar"
      component.environment.merge({"PATH" => "/opt/pl-build-tools/bin:$(PATH)"})

      expect(rule.recipe.first)
        .to eq %(export PATH="/opt/pl-build-tools/bin:$(PATH)" && \\\n/usr/bin/tar)
    end

    it_behaves_like "a rule that touches the target file"
  end

  describe "the patch rule" do
    let(:rule) { subject.patch_rule }

    it { expect(rule.dependencies).to eq(["leatherman-unpack"]) }

    it "does nothing when there are no patches" do
      expect(rule.recipe.size).to eq 1
    end

    it "applies each listed patch in order when patches are set" do
      component.patches = [
        Vanagon::Patch.new('/foo/patch0', '1', '0', 'unpack', '/foo/bar'),
        Vanagon::Patch.new('/foo/patch1', '2', '1', 'unpack', '/foo/bar'),
        Vanagon::Patch.new('/foo/postinstall/patch1', '2', '1', 'install', '/foo/bar')
      ]
      expect(rule.recipe.first).to eq(
        [
          "cd /foo/bar",
          "/usr/bin/patch --strip=1 --fuzz=0 --ignore-whitespace < $(workdir)/patches/patch0",
          "/usr/bin/patch --strip=2 --fuzz=1 --ignore-whitespace < $(workdir)/patches/patch1"
        ].join(" && \\\n")
      )
    end

    it_behaves_like "a rule that touches the target file"
  end

  describe "the configure rule" do
    let(:rule) { subject.configure_rule }

    # TODO: cross-component dependencies
    it { expect(rule.dependencies).to eq(['leatherman-patch']) }

    describe "when a build directory is set" do
      before do
        component.build_dir = "build"
      end

      it "creates the build directory" do
        expect(rule.recipe.first).to eq("[ -d /foo/bar/build ] || mkdir -p /foo/bar/build")
      end
    end

    it "runs all of the configure commands when given" do
      component.configure = ["./configure", "cmake .."]
      expect(rule.recipe[1]).to eq(
        [
          "cd /foo/bar",
          "./configure",
          "cmake .."
        ].join(" && \\\n")
      )
    end

    it "sets environment variables before running the configure steps" do
      component.configure = ["./configure", "cmake .."]
      component.environment.merge({"PATH" => "/opt/pl-build-tools/bin:$(PATH)"})
      expect(rule.recipe[1]).to eq(
        [
          'export PATH="/opt/pl-build-tools/bin:$(PATH)"', 
          "cd /foo/bar",
          "./configure",
          "cmake .."
        ].join(" && \\\n")
      )
    end

    it_behaves_like "a rule that touches the target file"
  end

  describe "the build rule" do
    let(:rule) { subject.build_rule }

    it { expect(rule.dependencies).to eq(['leatherman-configure']) }

    it "does nothing when the build step is empty" do
      expect(rule.recipe.size).to eq 1
    end

    it "runs all of the build commands when given" do
      component.build = ["make", "make test"]
      expect(rule.recipe.first).to eq(
        [
          "cd /foo/bar",
          "make",
          "make test",
        ].join(" && \\\n")
      )
    end

    it "sets environment variables before running the build steps" do
      component.build = ["make", "make test"]
      component.environment.merge({"PATH" => "/opt/pl-build-tools/bin:$(PATH)"})
      expect(rule.recipe.first).to eq(
        [
          'export PATH="/opt/pl-build-tools/bin:$(PATH)"',
          "cd /foo/bar",
          "make",
          "make test"
        ].join(" && \\\n")
      )
    end

    it_behaves_like "a rule that touches the target file"
  end

  describe "the check rule" do
    let(:rule) { subject.check_rule }

    it { expect(rule.dependencies).to eq(['leatherman-build']) }

    it "does nothing when the check step is empty" do
      expect(rule.recipe.size).to eq 1
    end

    it "does nothing when the project skipcheck flag is set" do
      component.check = ["make cpplint", "make test"]
      project.settings[:skipcheck] = true
      expect(rule.recipe.size).to eq 1
    end

    it "runs all of the check commands when given" do
      component.check = ["make cpplint", "make test"]
      expect(rule.recipe.first).to eq(
        [
          "cd /foo/bar",
          "make cpplint",
          "make test",
        ].join(" && \\\n")
      )
    end

    it "sets environment variables before running the check steps" do
      component.check = ["make cpplint", "make test"]
      component.environment.merge({"PATH" => "/opt/pl-build-tools/bin:$(PATH)"})
      expect(rule.recipe.first).to eq(
        [
          'export PATH="/opt/pl-build-tools/bin:$(PATH)"',
          "cd /foo/bar",
          "make cpplint",
          "make test"
        ].join(" && \\\n")
      )
    end

    it_behaves_like "a rule that touches the target file"
  end

  describe "the install rule" do
    let(:rule) { subject.install_rule }

    it { expect(rule.dependencies).to eq(['leatherman-check']) }

    it "does nothing when the install step is empty" do
      expect(rule.recipe.size).to eq 1
    end

    it "runs all of the install commands when given" do
      component.install = ["make install", "make reallyinstall"]
      expect(rule.recipe.first).to eq(
        [
          "cd /foo/bar",
          "make install",
          "make reallyinstall",
        ].join(" && \\\n")
      )
    end

    it "sets environment variables before running the install steps" do
      component.install = ["make install", "make reallyinstall"]
      component.environment.merge({"PATH" => "/opt/pl-build-tools/bin:$(PATH)"})
      expect(rule.recipe.first).to eq(
        [
          'export PATH="/opt/pl-build-tools/bin:$(PATH)"',
          "cd /foo/bar",
          "make install",
          "make reallyinstall"
        ].join(" && \\\n")
      )
    end

    it "applies any after-install patches" do
      component.install = ["make install"]
      component.patches = [
        Vanagon::Patch.new('/foo/patch0', 1, 0, 'unpack', '/foo/bar'),
        Vanagon::Patch.new('/foo/postinstall/patch0', 3, 9, 'install', '/foo/baz'),
        Vanagon::Patch.new('/foo/postinstall/patch1', 4, 10, 'install', '/foo/quux'),
      ]

      expect(rule.recipe[1]).to eq("cd /foo/baz && /usr/bin/patch --strip=3 --fuzz=9 --ignore-whitespace < $(workdir)/patches/patch0")
      expect(rule.recipe[2]).to eq("cd /foo/quux && /usr/bin/patch --strip=4 --fuzz=10 --ignore-whitespace < $(workdir)/patches/patch1")
    end

    it_behaves_like "a rule that touches the target file"
  end

  describe "the cleanup rule" do
    let(:rule) { subject.cleanup_rule }

    it { expect(rule.dependencies).to eq(['leatherman-install']) }

    it "runs the component source cleanup step" do
      component.cleanup_source = "rm -rf leatherman"
      expect(rule.recipe.first).to eq "rm -rf leatherman"
    end

    it_behaves_like "a rule that touches the target file"
  end

  describe "the clean rule" do
    let(:rule) { subject.clean_rule }

    it { expect(rule.dependencies).to be_empty }

    it "runs a `make clean` in the build dir" do
      expect(rule.recipe.first).to eq '[ -d /foo/bar ] && cd /foo/bar && /usr/bin/make clean'
    end

    it "remotes the touch files for the configure, build, and install steps" do
      %w[configure build install].each_with_index do |type, i|
        touchfile = "leatherman-#{type}"
        expect(rule.recipe[i + 1]).to eq "[ -e #{touchfile} ] && rm #{touchfile}"
      end
    end
  end

  describe "the clobber rule" do
    let(:rule) { subject.clobber_rule }

    it { expect(rule.dependencies).to eq(['leatherman-clean']) }

    it "removes the source directory and unpack touchfile" do
      expect(rule.recipe).to eq(["[ -d /foo/bar ] && rm -r /foo/bar", "[ -e leatherman-unpack ] && rm leatherman-unpack"])
    end
  end
end
