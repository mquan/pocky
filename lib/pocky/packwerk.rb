# frozen_string_literal: true

require 'pathname'
require 'ruby-graphviz'

module Pocky
  class Packwerk
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
      secondary_package_color: '#AAAAAA',
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
      @secondary_package_color = secondary_package_color

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
      load_primary_packages
      load_secondary_packages
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

      node_styles = @node_options.merge(
        **node_overrides(file_size),
        label: node_label
      )

      if @package_paths.present? && !package.primary
        node_styles.merge!(fillcolor: @secondary_package_color)
      end

      @graph.add_nodes(package_name, **node_styles)
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
          # Do not draw dependencies of secondary packages (depencies of primary packages)
          # when visualizing partial system
          next if !package.primary && !@packages[dependency]

          @nodes[dependency] ||= draw_node(@packages[dependency])

          @graph.add_edges(
            @nodes[package.name],
            @nodes[dependency],
            **@dependency_edge_options
          )
        end

        package.deprecated_references.each do |provider_name, invocations|
          # Do not draw deprecatd dependencies of secondary packages (depencies of primary packages)
          # when visualizing partial system
          next if !package.primary && !@packages[provider_name]

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

    def package_name_for_dependency(name)
      name == '.' ? @default_package : name
    end
  end
end
