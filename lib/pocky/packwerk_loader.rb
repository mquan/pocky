# frozen_string_literal: true

module Pocky
  class PackwerkLoader
    def self.load(root_path, package_paths)
      new(root_path, package_paths).load
    end

    private_class_method :new
    def initialize(root_path, package_paths)
      @root_path = root_path
      @package_paths = package_paths
      @packages = {}
    end

    def load
      load_primary_packages
      load_secondary_packages

      @packages
    end

    private

    def deprecated_references_files
      @deprecated_references_files ||= begin
        return Dir[@root_path.join('**', Pocky::Package::DEPRECATED_REFERENCES_FILENAME).to_s] unless @package_paths

        @package_paths.flat_map do |path|
          Dir[@root_path.join(path, '**', Pocky::Package::DEPRECATED_REFERENCES_FILENAME).to_s]
        end
      end
    end

    def dependencies_files
      @dependencies_files ||= begin
        return Dir[@root_path.join('**', Pocky::Package::DEPENDENCIES_FILENAME).to_s] unless @package_paths

        @package_paths.flat_map do |path|
          Dir[@root_path.join(path, '**', Pocky::Package::DEPENDENCIES_FILENAME).to_s]
        end
      end
    end

    def init_package(package_name, primary)
      Pocky::Package.new(
        name: package_name,
        path: @root_path.join(package_name).to_s,
        primary: primary
      )
    end

    def load_primary_packages
      filenames = dependencies_files + deprecated_references_files
      primary_package_names = filenames.map { |filename| parse_package_name(filename) }.uniq
      primary_package_names.each do |name|
        @packages[name] ||= init_package(name, true)
      end
    end

    def load_secondary_packages
      secondary_packages = {}
      @packages.each do |_, package|
        package.dependencies.each do |dependency|
          secondary_packages[dependency] ||= init_package(dependency, false) unless @packages[dependency]
        end

        package.deprecated_references.each do |reference, _violations|
          secondary_packages[reference] ||= init_package(reference, false) unless @packages[reference]
        end
      end

      @packages.merge!(secondary_packages)
    end

    def parse_package_name(filename)
      name = File.dirname(filename).gsub(@root_path.to_s, '')
      name == '' ? '.' : name.gsub(/^\//, '')
    end
  end
end
