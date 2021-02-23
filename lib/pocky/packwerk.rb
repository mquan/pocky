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
      @graph = GraphViz.new(:G, type: :digraph, dpi: @dpi)
      draw_packages
      @graph.output(png: @filename)
    end

    private

    def packages
      @packages ||= PackwerkLoader.load(@root_path, @package_paths)
    end

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

    def draw_packages
      packages.each do |_name, package|
        @nodes[package.name] ||= draw_node(package)

        package.dependencies.each do |dependency|
          draw_dependency(package, dependency)
        end

        package.deprecated_references.each do |provider_name, invocations|
          draw_dependency(package, provider_name, invocations)
        end
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
        node_styles.merge!(
          fillcolor: @secondary_package_color,
          color: @secondary_package_color
        )
      end

      @graph.add_nodes(package_name, **node_styles)
    end

    def draw_dependency(package, dependency, invocations = nil)
      # Do not draw dependencies of secondary packages (depencies of primary packages)
      # when visualizing partial system
      return if !package.primary && !packages[dependency]&.primary

      @nodes[dependency] ||= draw_node(packages[dependency])

      edge_options = invocations ?
        @deprecated_references_edge_options.merge(
          penwidth: edge_width(invocations.length),
        ) :
        @dependency_edge_options

      @graph.add_edges(
        @nodes[package.name],
        @nodes[dependency],
        **edge_options
      )
    end

    def edge_width(count)
      [
        [(count / 5).to_i, 1].max,
        MAX_EDGE_WIDTH
      ].min
    end

    def package_name_for_dependency(name)
      name == '.' ? @default_package : name
    end
  end
end
