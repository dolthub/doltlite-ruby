require "minitest/autorun"
require "doltlite"

class DoltliteTest < Minitest::Test
  def test_commit_round_trip
    db = Doltlite.open(":memory:")

    assert_equal "prolly", db.query("SELECT doltlite_engine()").dig(0, 0)

    db.execute("CREATE TABLE t(id INTEGER PRIMARY KEY, v TEXT)")
    db.execute("INSERT INTO t(id, v) VALUES (?, ?)", 1, "a")

    hash = db.dolt_commit(message: "c1")
    refute_nil hash

    # Initial commit plus c1 => 2 rows in dolt_log.
    assert_equal 2, db.query("SELECT count(*) FROM dolt_log").dig(0, 0)
  ensure
    db&.close
  end

  def test_bind_types
    db = Doltlite.open(":memory:")
    db.execute("CREATE TABLE t(i INTEGER, f REAL, s TEXT, n TEXT)")
    db.execute("INSERT INTO t VALUES (?, ?, ?, ?)", 42, 3.5, "hi", nil)
    row = db.query("SELECT i, f, s, n FROM t").first
    assert_equal [42, 3.5, "hi", nil], row
  ensure
    db&.close
  end
end
