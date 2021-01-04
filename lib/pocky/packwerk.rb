# frozen_string_literal: true

require 'yaml'
require 'ruby-graphviz'

module Pocky
  class InvalidRootPathError < StandardError
  end

  class Packwerk
    REFERENCE_FILE_NAME = 'deprecated_references.yml'
    MAX_EDGE_WIDTH = 5

    def self.generate(params)
      new(**params).generate
    end

    private_class_method :new
    def initialize(
      root_path:,
      default_package: 'Default',
      filename: 'packwerk-viz.png',
      dpi: 150
    )
      @root_paths = [*root_path]
      raise InvalidRootPathError, 'root_path is required' if @root_paths.empty?

      @default_package = default_package
      @filename = filename
      @dpi = dpi.to_i
      @deprecated_references = {}
      @nodes = {}
    end

    def generate
      load_package_references
      build_directed_graph
    end

    private

    def build_directed_graph
      graph = GraphViz.new(:G, type: :digraph, dpi: @dpi)
      @deprecated_references.each do |package, references|
        @nodes[package] ||= graph.add_nodes(package)
        references.each do |provider, dependencies|
          provider_package = package_name_for_dependency(provider)
          @nodes[provider_package] ||= graph.add_nodes(provider_package)

          graph.add_edges(
            @nodes[package],
            @nodes[provider_package],
            penwidth: edge_width(dependencies.length)
          )
        end
      end

      graph.output(png: @filename)
    end

    def edge_width(count)
      [
        [(count / 5).to_i, 1].max,
        MAX_EDGE_WIDTH
      ].min
    end

    def package_references
      @package_references ||= @root_paths.flat_map do |path|
        Dir["#{path}/**/#{REFERENCE_FILE_NAME}"]
      end
    end

    def load_package_references
      if package_references.empty?
        raise InvalidRootPathError, "Cannot find any #{REFERENCE_FILE_NAME} in provided root_path"
      end

      package_references.each do |filename|
        package = parse_package_name(filename)
        @deprecated_references[package] ||= YAML.load_file(filename) || {}
      end
    end

    def parse_package_name(filename)
      File.basename(File.dirname(filename))
    end

    def package_name_for_dependency(name)
      return @default_package if name == '.'

      reference_filename = package_references.find do |ref|
        ref.match(/#{name}\/#{REFERENCE_FILE_NAME}$/)
      end

      if reference_filename
        parse_package_name(reference_filename)
      else
        name
      end
    end
  end
end
