require 'pocky'

namespace :pocky do
  desc 'Generate dependency graph for packwerk packages'
  task :generate, [:root_path, :default_package, :filename, :dpi] do |_task, args|
    Pocky::Packwerk.generate(args.merge(
      root_path: arg[:root_path].split(/\s+/)
    ))
  end
end
