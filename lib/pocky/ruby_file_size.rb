
module Pocky
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
end
