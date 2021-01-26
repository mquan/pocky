require 'pocky'

namespace :pocky do
  desc 'Generate dependency graph for packwerk packages'
  task :generate, [:package_path, :default_package, :filename, :dpi, :package_color, :deprecated_reference_edge, :dependency_edge] do |_task, args|
    params = args.to_h.merge(package_path: args[:package_path].split(/\s+/)) if args[:package_path]
    Pocky::Packwerk.generate(params)
  end
end
