# frozen_string_literal: true

require 'pathname'
require 'yaml'
require 'ruby-graphviz'

module Pocky
  class InvalidRootPathError < StandardError
  end

  class RubyFileSize
    def self.compute(directory)
      # Sum up all ruby source except for specs
      package_size = Dir[File.join(directory, '**', '*.rb').to_s].reduce(0) do |size, filename|
        size += File.size(filename) unless filename.match(/spec\.rb$/)
        size
      end

      # to kB
      (package_size / 1024).ceil
    end
  end

  class Packwerk
    DEPENDENCIES_FILENAME = 'package.yml'
    DEPRECATED_REFERENCES_FILENAME = 'deprecated_references.yml'
    MAX_EDGE_WIDTH = 5

    def self.generate(params = {})
      new(**params).generate
    end

    private_class_method :new
    def initialize(
      package_path: nil,
      default_package: 'root',
      filename: 'packwerk.png',
      analyze_sizes: false,
      dpi: 100,
      package_color: '#5CC8FF',
      dependency_edge: 'darkgreen',
      deprecated_reference_edge: 'black',
      deprecated_reference_ranking: true
    )
      @package_paths = [*package_path] if package_path
      @root_path = defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)

      @default_package = default_package
      @filename = filename
      @analyze_sizes = analyze_sizes

      @dpi = dpi.to_i
      @deprecated_references = {}
      @package_dependencies = {}
      @nodes = {}

      @node_options = {
        fontsize: 26.0,
        fontcolor: 'white',
        fillcolor: package_color,
        color: package_color,
        height: 1.0,
        style: 'filled, rounded',
        shape: 'box'
      }

      @dependency_edge_options = {
        color: dependency_edge
      }

      @deprecated_references_edge_options = {
        color: deprecated_reference_edge,
      }
      @deprecated_references_edge_options.merge!(constraint: false) unless deprecated_reference_ranking
    end

    def generate
      load_dependencies
      load_deprecated_references
      build_directed_graph
    end

    private

    def node_overrides(file_size)
      if file_size < 10
        { fontsize: 26 }
      elsif file_size < 100
        { fontsize: 26 * 4, margin: 0.2 }
      elsif file_size < 1000
        { fontsize: 26 * 8, margin: 0.4 }
      elsif file_size < 10_000
        { fontsize: 26 * 16, margin: 0.8 }
      else
        { fontsize: 26 * 32, margin: 1.0 }
      end
    end

    def draw_node(package)
      package_name = package_name_for_dependency(package)
      path = package == '.' ? @root_path : @root_path.join(package)
      file_size = @analyze_sizes ? RubyFileSize.compute(path.to_s) : 1
      @graph.add_nodes(package_name, **@node_options.merge(node_overrides(file_size)))
    end

    def build_directed_graph
      @graph = GraphViz.new(:G, type: :digraph, dpi: @dpi)
      draw_dependencies
      draw_deprecated_references
      @graph.output(png: @filename)
    end

    def draw_dependencies
      @package_dependencies.each do |package, file|
        @nodes[package] ||= draw_node(package)
        file.each do |provider|
          @nodes[provider] ||= draw_node(provider)

          @graph.add_edges(
            @nodes[package],
            @nodes[provider],
            **@dependency_edge_options
          )
        end
      end
    end

    def draw_deprecated_references
      @deprecated_references.each do |package, references|
        @nodes[package] ||= draw_node(package)
        references.each do |provider, invocations|
          @nodes[provider] ||= draw_node(provider)

          @graph.add_edges(
            @nodes[package],
            @nodes[provider],
            **@deprecated_references_edge_options.merge(
              penwidth: edge_width(invocations.length),
            ),
          )
        end
      end
    end

    def edge_width(count)
      [
        [(count / 5).to_i, 1].max,
        MAX_EDGE_WIDTH
      ].min
    end

    def deprecated_references_files
      @deprecated_references_files ||= begin
        return Dir[@root_path.join('**', DEPRECATED_REFERENCES_FILENAME).to_s] unless @package_paths

        @package_paths.flat_map do |path|
          Dir[@root_path.join(path, '**', DEPRECATED_REFERENCES_FILENAME).to_s]
        end
      end
    end

    def dependencies_files
      @dependencies_files ||= begin
        return Dir[@root_path.join('**', DEPENDENCIES_FILENAME).to_s] unless @package_paths

        @package_paths.flat_map do |path|
          Dir[@root_path.join(path, '**', DEPENDENCIES_FILENAME).to_s]
        end
      end
    end

    def load_dependencies
      return if dependencies_files.empty?

      dependencies_files.each do |filename|
        package = parse_package_name(filename)
        @package_dependencies[package] ||= begin
          yml = YAML.load_file(filename) || {}
          yml['dependencies'] || []
        end
      end
    end

    def load_deprecated_references
      return if deprecated_references_files.empty?

      deprecated_references_files.each do |filename|
        package = parse_package_name(filename)
        @deprecated_references[package] ||= YAML.load_file(filename) || {}
      end
    end

    def parse_package_name(filename)
      name = File.dirname(filename).gsub(@root_path.to_s, '')
      name == '' ? @default_package : name.gsub(/^\//, '')
    end

    def package_name_for_dependency(name)
      name == '.' ? @default_package : name
    end
  end
end
