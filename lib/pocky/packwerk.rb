# frozen_string_literal: true

require 'yaml'
require 'ruby-graphviz'

module Pocky
  class Packwerk
    MAX_EDGE_WIDTH = 5

    def self.generate(params)
      new(**params).generate
    end

    private_class_method :new
    def initialize(
      root_path:,
      default_package: 'Default',
      package_prefix: '',
      output_filename: 'pocky-graph.png',
      output_dpi: 150
    )
      @root_path = root_path
      @default_package = default_package
      @package_prefix = package_prefix
      @output_filename = output_filename
      @output_dpi = output_dpi
      @deprecated_references = {}
      @nodes = {}
    end

    def generate
      load_package_dependencies
      build_directed_graph
    end

    private

    def build_directed_graph
      graph = GraphViz.new(:G, type: :digraph, dpi: @output_dpi)
      @deprecated_references.each do |package, references|
        @nodes[package] ||= graph.add_nodes(package)
        references.each do |provider, dependencies|
          provider_package = package_name_for_dependency(provider)
          @nodes[provider_package] ||= graph.add_nodes(provider_package)

          graph.add_edges(
            @nodes[provider_package],
            @nodes[package],
            penwidth: edge_width(dependencies.length)
          )
        end
      end

      graph.output(png: @output_filename)
    end

    def edge_width(count)
      [
        [(count / 5).to_i, 1].max,
        MAX_EDGE_WIDTH
      ].min
    end

    def load_package_dependencies
      Dir.each_child(@root_path) do |elem|
        if Dir.exist?(File.join(@root_path, elem))
          load_deprecated_references_for_package(elem)
        end
      end
    end

    def load_deprecated_references_for_package(package)
      @deprecated_references[package] ||= begin
        filename = deprecated_references_file_for(package)
        if File.exist?(filename)
          YAML.load_file(filename) || {}
        else
          {}
        end
      end
    end

    def deprecated_references_file_for(package)
      File.join(@root_path, package, 'deprecated_references.yml')
    end

    def package_name_for_dependency(name)
      return @default_package if name == '.'

      name.gsub(@package_prefix, '').gsub(/^\//, '')
    end
  end
end