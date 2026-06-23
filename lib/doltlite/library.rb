require "ffi"
require "rbconfig"

module Doltlite
  # Locates and binds the doltlite shared library. Precompiled platform gems
  # bundle the library under vendor/libdoltlite/; otherwise we fall back to a
  # system-installed libdoltlite on the loader path.
  module Library
    module_function

    def library_name
      case RbConfig::CONFIG["host_os"]
      when /darwin/ then "libdoltlite.dylib"
      when /mswin|mingw|cygwin/ then "doltlite.dll"
      else "libdoltlite.so"
      end
    end

    # Path to the bundled library inside the gem, or nil if not present.
    def bundled_path
      path = File.expand_path("../../vendor/libdoltlite/#{library_name}", __dir__)
      File.exist?(path) ? path : nil
    end

    # What FFI should load: the bundled library if present, else the bare name
    # so the system loader resolves an installed libdoltlite.
    def target
      bundled_path || library_name
    end
  end

  # FFI bindings to the doltlite C API (the SQLite C API; dolt_* functions are
  # reached through SQL).
  module C
    extend FFI::Library
    ffi_lib Doltlite::Library.target

    # Result codes
    OK = 0
    ROW = 100
    DONE = 101

    # Column types
    INTEGER = 1
    FLOAT = 2
    TEXT = 3
    BLOB = 4
    NULL = 5

    # open flags
    OPEN_READWRITE = 0x00000002
    OPEN_CREATE = 0x00000004

    # SQLITE_TRANSIENT tells the engine to copy bound buffers.
    TRANSIENT = FFI::Pointer.new(-1)

    attach_function :sqlite3_open_v2, [:string, :pointer, :int, :string], :int
    attach_function :sqlite3_close_v2, [:pointer], :int
    attach_function :sqlite3_errmsg, [:pointer], :string
    attach_function :sqlite3_errcode, [:pointer], :int
    attach_function :sqlite3_exec, [:pointer, :string, :pointer, :pointer, :pointer], :int
    attach_function :sqlite3_prepare_v2, [:pointer, :string, :int, :pointer, :pointer], :int
    attach_function :sqlite3_step, [:pointer], :int
    attach_function :sqlite3_reset, [:pointer], :int
    attach_function :sqlite3_finalize, [:pointer], :int
    attach_function :sqlite3_column_count, [:pointer], :int
    attach_function :sqlite3_column_name, [:pointer, :int], :string
    attach_function :sqlite3_column_type, [:pointer, :int], :int
    attach_function :sqlite3_column_int64, [:pointer, :int], :int64
    attach_function :sqlite3_column_double, [:pointer, :int], :double
    attach_function :sqlite3_column_text, [:pointer, :int], :string
    attach_function :sqlite3_column_bytes, [:pointer, :int], :int
    attach_function :sqlite3_column_blob, [:pointer, :int], :pointer
    attach_function :sqlite3_bind_int64, [:pointer, :int, :int64], :int
    attach_function :sqlite3_bind_double, [:pointer, :int, :double], :int
    attach_function :sqlite3_bind_text, [:pointer, :int, :string, :int, :pointer], :int
    attach_function :sqlite3_bind_null, [:pointer, :int], :int
    attach_function :sqlite3_libversion, [], :string
  end
end
