# frozen_string_literal: true

require 'pathname'
require 'ruby-graphviz'

module Pocky
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

      @packages = {}
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
        { fontsize: 26 * 2, margin: 0.2 }
      elsif file_size < 1000
        { fontsize: 26 * 4, margin: 0.4 }
      elsif file_size < 10_000
        { fontsize: 26 * 8, margin: 0.8 }
      else
        { fontsize: 26 * 16, margin: 1.0 }
      end
    end

    def draw_node(package)
      package_name = package_name_for_dependency(package.name)
      path = package.name == '.' ? @root_path : @root_path.join(package.name)
      file_size = @analyze_sizes ? RubyFileSize.compute(path.to_s) : 1
      node_label = "#{package_name}#{' (Þ)' if package.enforce_privacy}"

      @graph.add_nodes(
        package_name,
        **@node_options.merge(
          **node_overrides(file_size),
          label: node_label
        )
      )
    end

    def build_directed_graph
      @graph = GraphViz.new(:G, type: :digraph, dpi: @dpi)
      draw_packages
      @graph.output(png: @filename)
    end

    def draw_packages
      @packages.each do |_name, package|
        @nodes[package.name] ||= draw_node(package)

        package.dependencies.each do |dependency|
          @nodes[dependency] ||= draw_node(@packages[dependency])

          @graph.add_edges(
            @nodes[package.name],
            @nodes[dependency],
            **@dependency_edge_options
          )
        end

        package.deprecated_references.each do |provider_name, invocations|
          @nodes[provider_name] ||= draw_node(@packages[provider_name])

          @graph.add_edges(
            @nodes[package.name],
            @nodes[provider_name],
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
        package_name = parse_package_name(filename)
        @packages[package_name] ||= Pocky::Package.new(name: package_name, filename: filename)
      end
    end

    def load_deprecated_references
      return if deprecated_references_files.empty?

      deprecated_references_files.each do |filename|
        package_name = parse_package_name(filename)
        @packages[package_name] ||= Pocky::Package.new(name: package_name)
        @packages[package_name].add_deprecated_references(filename)

        # Walk the references to create referenced packages
        @packages[package_name].deprecated_references.each do |provider_name, _violations|
          @packages[provider_name] ||= Pocky::Package.new(name: provider_name)
        end
      end
    end

    def parse_package_name(filename)
      name = File.dirname(filename).gsub(@root_path.to_s, '')
      name == '' ? '.' : name.gsub(/^\//, '')
    end

    def package_name_for_dependency(name)
      name == '.' ? @default_package : name
    end
  end
end
