# frozen_string_literal: true

require 'yaml'

module Pocky
  class Package
    DEPENDENCIES_FILENAME = 'package.yml'
    DEPRECATED_REFERENCES_FILENAME = 'deprecated_references.yml'

    attr_reader :name, :dependencies, :enforce_privacy, :deprecated_references, :primary

    # TODO: take the path and this class automatically figure out the ymls inside the package
    def initialize(name:, primary:, filename: nil)
      @name = name
      @filename = filename
      @primary = primary
      @dependencies = yml['dependencies'] || []
      @enforce_privacy = yml['enforce_privacy'] || false
      @deprecated_references = {}
    end

    def add_deprecated_references(reference_filename)
      @deprecated_references = YAML.load_file(reference_filename) || {}
    end

    private

    def yml
      @yml ||= begin
        if @filename
          YAML.load_file(@filename) || {}
        else
          {}
        end
      end
    end
  end
end
