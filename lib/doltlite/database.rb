module Doltlite
  class Error < StandardError; end

  # A doltlite database connection: SQLite with Dolt version control.
  #
  #   db = Doltlite::Database.new("app.db")   # or ":memory:"
  #   db.execute("CREATE TABLE t(id INTEGER PRIMARY KEY, v TEXT)")
  #   db.execute("INSERT INTO t(v) VALUES (?)", "hello")
  #   db.commit(message: "first commit")
  #   db.query("SELECT commit_hash, message FROM dolt_log")
  class Database
    def initialize(path = ":memory:")
      handle_ptr = FFI::MemoryPointer.new(:pointer)
      flags = C::OPEN_READWRITE | C::OPEN_CREATE
      rc = C.sqlite3_open_v2(path, handle_ptr, flags, nil)
      @handle = handle_ptr.read_pointer
      if rc != C::OK
        message = @handle.null? ? "unable to open #{path}" : C.sqlite3_errmsg(@handle)
        C.sqlite3_close_v2(@handle) unless @handle.null?
        @handle = nil
        raise Error, "open failed (#{rc}): #{message}"
      end
      @open = true
      ObjectSpace.define_finalizer(self, self.class.finalizer(@handle))
    end

    # Run SQL with optional positional bind values. Returns an array of rows
    # (each row an array of column values); empty for non-SELECT statements.
    def execute(sql, *binds)
      stmt_ptr = FFI::MemoryPointer.new(:pointer)
      rc = C.sqlite3_prepare_v2(@handle, sql, -1, stmt_ptr, nil)
      raise Error, "prepare failed: #{C.sqlite3_errmsg(@handle)}" if rc != C::OK
      stmt = stmt_ptr.read_pointer
      begin
        bind_all(stmt, binds)
        collect_rows(stmt)
      ensure
        C.sqlite3_finalize(stmt)
      end
    end
    alias query execute

    # Make a Dolt version-control commit: SELECT dolt_commit(...). This is the
    # version-control operation (a new entry in dolt_log), NOT a SQL
    # transaction COMMIT. Stages everything when all is true. Returns the new
    # commit hash.
    def dolt_commit(message:, all: true)
      args = all ? ["-A", "-m", message] : ["-m", message]
      placeholders = (["?"] * args.length).join(", ")
      rows = execute("SELECT dolt_commit(#{placeholders})", *args)
      rows.dig(0, 0)
    end

    def version
      C.sqlite3_libversion
    end

    def close
      return unless @open
      C.sqlite3_close_v2(@handle)
      @open = false
      @handle = nil
    end

    def closed?
      !@open
    end

    def self.finalizer(handle)
      proc { C.sqlite3_close_v2(handle) unless handle.nil? || handle.null? }
    end

    private

    def bind_all(stmt, binds)
      binds.each_with_index do |value, i|
        index = i + 1
        case value
        when nil
          C.sqlite3_bind_null(stmt, index)
        when Integer
          C.sqlite3_bind_int64(stmt, index, value)
        when Float
          C.sqlite3_bind_double(stmt, index, value)
        else
          str = value.to_s
          C.sqlite3_bind_text(stmt, index, str, str.bytesize, C::TRANSIENT)
        end
      end
    end

    def collect_rows(stmt)
      rows = []
      ncols = C.sqlite3_column_count(stmt)
      loop do
        rc = C.sqlite3_step(stmt)
        break if rc == C::DONE
        raise Error, "step failed: #{C.sqlite3_errmsg(@handle)}" if rc != C::ROW
        rows << (0...ncols).map { |c| column_value(stmt, c) }
      end
      rows
    end

    def column_value(stmt, col)
      case C.sqlite3_column_type(stmt, col)
      when C::INTEGER then C.sqlite3_column_int64(stmt, col)
      when C::FLOAT then C.sqlite3_column_double(stmt, col)
      when C::NULL then nil
      when C::BLOB
        n = C.sqlite3_column_bytes(stmt, col)
        C.sqlite3_column_blob(stmt, col).read_bytes(n)
      else
        C.sqlite3_column_text(stmt, col)
      end
    end
  end
end
