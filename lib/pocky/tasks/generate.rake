require 'pocky'

namespace :pocky do
  desc 'Generate dependency graph for packwerk packages'
  task :generate, [:root_path, :default_package, :package_prefix, :filename, :dpi] do |_task, args|
    Pocky::Packwerk.generate(args)
  end
end
