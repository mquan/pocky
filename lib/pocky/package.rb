# frozen_string_literal: true

require 'yaml'

module Pocky
  class Package
    DEPENDENCIES_FILENAME = 'package.yml'
    DEPRECATED_REFERENCES_FILENAME = 'deprecated_references.yml'

    attr_reader :name, :dependencies, :enforce_privacy, :primary

    def initialize(name:, path:, primary:)
      @name = name
      @path = path
      @primary = primary
      @dependencies = dependencies_yml['dependencies'] || []
      @enforce_privacy = dependencies_yml['enforce_privacy'] || false
    end

    def deprecated_references
      @deprecated_references ||= load_yml(deprecated_references_filename)
    end

    private

    def load_yml(filename)
      if File.file?(filename)
        YAML.load_file(filename) || {}
      else
        {}
      end
    end

    def dependencies_yml
      @dependencies_yml ||= load_yml(dependecies_filename)
    end

    def dependecies_filename
      File.join(@path, DEPENDENCIES_FILENAME)
    end

    def deprecated_references_filename
      File.join(@path, DEPRECATED_REFERENCES_FILENAME)
    end
  end
end
