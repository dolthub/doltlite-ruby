require "doltlite/version"
require "doltlite/library"
require "doltlite/database"

# DoltLite for Ruby: SQLite with Dolt-style version control (branches, commits,
# merge, diff). A thin FFI layer over a bundled libdoltlite; the dolt_*
# functions are reached through SQL.
module Doltlite
  # Open (creating if needed) a database. Use ":memory:" for in-memory.
  def self.open(path = ":memory:")
    Database.new(path)
  end
end
