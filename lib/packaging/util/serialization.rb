# Utility methods for dealing with serialization of Config params

module Pkg::Util::Serialization
  class << self
    require 'yaml'

    # Given the path to a yaml file, load the yaml file into an object and return the object.
    def load_yaml(file)
      file = File.expand_path(file)
      begin
        input_data = YAML.load_file(file) || {}
      rescue
        fail "There was an error loading data from #{file}."
      end
      input_data
    end
  end
end

