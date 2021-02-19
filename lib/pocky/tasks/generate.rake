require 'pocky'

namespace :pocky do
  desc 'Generate dependency graph for packwerk packages'
  task :generate, [:package_path, :default_package, :filename, :analyze_sizes, :dpi, :package_color, :secondary_package_color, :dependency_edge, :deprecated_reference_edge, :deprecated_reference_ranking] do |_task, args|
    params = args.to_h
    params.merge!(package_path: args[:package_path].split(/\s+/)) if args[:package_path]
    Pocky::Packwerk.generate(params)
  end
end
