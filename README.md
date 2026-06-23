# doltlite (Ruby)

[DoltLite](https://github.com/dolthub/doltlite) for Ruby: SQLite with Dolt-style
version control — `dolt_commit`, `dolt_branch`, `dolt_merge`, `dolt_diff`, and
the rest. A thin [FFI](https://github.com/ffi/ffi) layer over a bundled
`libdoltlite`; the `dolt_*` functions are reached through SQL.

## Install

```bash
gem install doltlite
```

Precompiled gems bundle `libdoltlite` for common platforms (Linux x86_64/arm64,
macOS arm64/x86_64), so no compiler is needed. The plain-Ruby gem falls back to
a system-installed `libdoltlite`.

## Usage

```ruby
require "doltlite"

db = Doltlite.open("app.db")   # or ":memory:"

db.execute("CREATE TABLE notes(id INTEGER PRIMARY KEY, body TEXT)")
db.execute("INSERT INTO notes(body) VALUES (?)", "first note")

hash = db.commit(message: "add first note")
puts "committed #{hash}"

db.query("SELECT commit_hash, message FROM dolt_log").each do |commit_hash, message|
  puts "#{commit_hash}  #{message}"
end

db.close
```

`execute`/`query` take positional bind values (`?`) and return rows as arrays of
column values. The `dolt_*` functions and virtual tables (`dolt_log`,
`dolt_status`, `dolt_diff`, `dolt_branches`, ...) are invoked through SQL.

## License

Apache-2.0. The bundled engine is built from
[dolthub/doltlite](https://github.com/dolthub/doltlite); SQLite itself is public
domain.
