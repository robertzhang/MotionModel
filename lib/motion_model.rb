require 'motion-require'
require 'motion-support'

%w(*.rb model/*.rb adapters/*.rb adapters/array/*.rb adapters/sql/*.rb adapters/sql/sqlite3/*.rb adapters/sql/sqlite3/fmdb/*.rb).each do |path|
  Motion::Require.all(Dir.glob(File.expand_path("../../motion/#{path}", __FILE__)))
end
