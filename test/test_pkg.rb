
require 'test/unit'

require 'solaris/contents'

# Unit tests for Solaris::Contents::Pkg.
class TestPkg < Test::Unit::TestCase #:nodoc:

  def test_inst_rdy
    pkg = Solaris::Contents::Pkg.new( '+mypackage' )
    assert_equal( :inst_rdy, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '+mypackage', pkg.to_s )
    assert( pkg.inst_rdy? )
  end

  def test_rm_rdy
    pkg = Solaris::Contents::Pkg.new( '-mypackage' )
    assert_equal( :rm_rdy, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '-mypackage', pkg.to_s )
    assert( pkg.rm_rdy? )
  end

  def test_not_fnd
    pkg = Solaris::Contents::Pkg.new( '!mypackage' )
    assert_equal( :not_fnd, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '!mypackage', pkg.to_s )
    assert( pkg.not_fnd? )
  end

  def test_served_file
    pkg = Solaris::Contents::Pkg.new( '%mypackage' )
    assert_equal( :served_file, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '%mypackage', pkg.to_s )
    assert( pkg.served_file? )
  end

  def test_stat_next
    pkg = Solaris::Contents::Pkg.new( '@mypackage' )
    assert_equal( :stat_next, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '@mypackage', pkg.to_s )
    assert( pkg.stat_next? )
  end

  def test_dup_entry
    pkg = Solaris::Contents::Pkg.new( '#mypackage' )
    assert_equal( :dup_entry, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '#mypackage', pkg.to_s )
    assert( pkg.dup_entry? )
  end

  def test_confirm_cont
    pkg = Solaris::Contents::Pkg.new( '*mypackage' )
    assert_equal( :confirm_cont, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '*mypackage', pkg.to_s )
    assert( pkg.confirm_cont? )
  end

  def test_confirm_attr
    pkg = Solaris::Contents::Pkg.new( '~mypackage' )
    assert_equal( :confirm_attr, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( '~mypackage', pkg.to_s )
    assert( pkg.confirm_attr? )
  end

  def test_entry_ok
    pkg = Solaris::Contents::Pkg.new( 'mypackage' )
    assert_equal( :entry_ok, pkg.status )
    assert_equal( 'mypackage', pkg.name )
    assert_equal( 'mypackage', pkg.to_s )
    assert( pkg.entry_ok? )
  end

end

