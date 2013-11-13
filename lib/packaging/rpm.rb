module Pkg
  class Rpm

    require 'FileUtils'

    attr_accessor :tarball, :defines, :spec_template
    attr_reader :rpm

    def initialize
      @rpm = Pkg::Util::Tool.find_tool("rpm", :required => true)
    end

    def setup_buildroot_in(workdir)
      FileUtils.mkdir_p(File.join(workdir, "SPECS"))
      FileUtils.mkdir_p(File.join(workdir, "SOURCES"))
    end

    def install_tarball_to(workdir)
      FileUtils.cp_p(@tarball, File.join(workdir, "SOURCES"))
    end

    def template_spec(spec_template, workdir)
      spec = File.basename(spec_template.sub(File.extname(spec_template), ""))
      Pkg::Util::File.erb_file(spec_template, File.join(workdir, "SPECS", spec), nil, :binding => Pkg::Util.get_binding)
    end

    def pkg!(tarball)
      workdir = File.join(Pkg::Util::File.mktemp, "#{@project}-#{@version}")
      self.setup_buildroot_in(workdir)
      self.install_tarball_to(workdir)
      self.template_spec(@spec_template, workdir)
      self.rpm(workdir)
      self.cleanup(workdir)
    end
  end
end

