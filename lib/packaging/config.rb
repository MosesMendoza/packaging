module Pkg
  ##
  # This class is meant to encapsulate all of the data we know about a build invoked with
  # `rake package:<build>` or `rake pl:<build>`. It can read in this data via a yaml file,
  # have it set via accessors, and serialize it back to yaml for easy transport.
  #
  module Config
    require 'packaging/config/params.rb'

    class << self
      Pkg::Config::PARAMS.each do |v|
        attr_accessor v
      end

      @task = { :task => $*[0], :args => $*[1..-1] }
      @ref = Pkg::Util.git_sha_or_tag
    end
  end

    ##
    # Take a hash of parameters, and iterate over them,
    # setting each build param to the corresponding hash key,value.
    #
    def set_params_from_hash(data = {})
      data.each do |param, value|
        if @@build_params.include?(param.to_sym)
          self.instance_variable_set("@#{param}", value)
        else
          warn "Warning - No build data parameter found for '#{param}'. Perhaps you have an erroneous entry in your yaml file?"
        end
      end
    end

    ##
    # Load build parameters from a yaml file. Uses #data_from_yaml in
    # 00_utils.rake
    #
    def set_params_from_file(file)
      build_data = data_from_yaml(file)
      set_params_from_hash(build_data)
    end

    ##
    # Return a hash of all build parameters and their values, nil if unassigned.
    #
    def params
      data = {}
      @@build_params.each do |param|
        data.store(param, self.instance_variable_get("@#{param}"))
      end
      data
    end

    ##
    # Write all build parameters to a yaml file in a temporary location. Print
    # the path to the file and return it as a string. Accept an argument for
    # the write target directory. The name of the params file is the current
    # git commit sha or tag.
    #
    def params_to_yaml(output_dir=nil)
      dir = output_dir.nil? ? get_temp : output_dir
      File.writable?(dir) or fail "#{dir} does not exist or is not writable, skipping build params write. Exiting.."
      params_file = File.join(dir, "#{self.ref}.yaml")
      File.open(params_file, 'w') do |f|
        f.puts params.to_yaml
      end
      puts params_file
      params_file
    end

    ##
    # Print the names and values of all the params known to the build object
    #
    def print_params
      params.each { |k,v| puts "#{k}: #{v}" }
    end
end

# Perform a build exclusively from a build params file. Requires that the build
# params file include a setting for task, which is an array of the arguments
# given to rake originally, including, first, the task name. The params file is
# always loaded when passed, so these variables are accessible immediately.
namespace :pl do
  desc "Build from a build params file"
  task :build_from_params do
    check_var('PARAMS_FILE', ENV['PARAMS_FILE'])
    git_co(@build.ref)
    Rake::Task[@build.task[:task]].invoke(@build.task[:args])
  end
end
