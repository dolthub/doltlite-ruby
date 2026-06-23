require_relative "lib/doltlite/version"

Gem::Specification.new do |spec|
  spec.name = "doltlite"
  spec.version = Doltlite::VERSION
  spec.summary = "SQLite with Dolt-style version control (branches, commits, merge, diff)"
  spec.description = "DoltLite for Ruby: a drop-in SQLite engine with Dolt " \
                     "version control, via a thin FFI layer over a bundled " \
                     "libdoltlite. The dolt_* functions are reached through SQL."
  spec.authors = ["DoltHub, Inc."]
  spec.email = ["support@dolthub.com"]
  spec.homepage = "https://github.com/dolthub/doltlite-ruby"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "bug_tracker_uri" => "https://github.com/dolthub/doltlite/issues",
  }

  # Precompiled platform gems set GEM_PLATFORM (e.g. x86_64-linux) and stage the
  # matching libdoltlite into vendor/libdoltlite/. A plain `gem build` produces
  # the ruby-platform source gem (no bundled library; falls back to a
  # system-installed libdoltlite).
  platform = ENV["GEM_PLATFORM"]
  spec.platform = platform if platform && !platform.empty?

  spec.files = Dir[
    "lib/**/*.rb",
    "vendor/libdoltlite/*.so",
    "vendor/libdoltlite/*.dylib",
    "vendor/libdoltlite/*.dll",
    "README.md",
    "LICENSE.md",
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.15"
end
