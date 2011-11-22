
require 'stringio'
require 'test/unit'

require 'solaris/contents'

# Unit tests for Solaris::Contents.
class TestContents < Test::Unit::TestCase #:nodoc:

  def test_sum_from_string
    assert_equal( 64, Solaris::Contents.sum( '@' ) )
    assert_equal( 128, Solaris::Contents.sum( '@@' ) )
    assert_equal( 64_000, Solaris::Contents.sum( '@' * 1_000 ) )
    assert_equal( 65_472, Solaris::Contents.sum( '@' * 1_023 ) )
    assert_equal( 0, Solaris::Contents.sum( '@' * 1_024 ) )
    assert_equal( 64, Solaris::Contents.sum( '@' * 1_025 ) )
  end

  def test_sum_from_io
    assert_equal( 97, Solaris::Contents.sum( StringIO.new( 'a' ) ) )
    assert_equal( 194, Solaris::Contents.sum( StringIO.new( 'aa' ) ) )
  end

  def test_block_device
    skip 'No block device example found'
  end

  def test_character_device
    line = '/devices/pseudo/arp@0:arp c none 44 0 0666 root sys SUNWcsd'
    contents = Solaris::Contents.from_line( line )
    assert_equal( :c, contents.ftype )
    assert_equal( '/devices/pseudo/arp@0:arp', contents.path )
    assert_equal( nil, contents.rpath )
    assert_equal( 'none', contents.install_class )
    assert_equal( 438, contents.mode )
    assert_equal( 44, contents.major )
    assert_equal( 0, contents.minor )
    assert_equal( nil, contents.mtime )
    assert_equal( 'root', contents.owner )
    assert_equal( 'sys', contents.group )
    assert_equal( 'SUNWcsd', contents.package.to_s )
    assert_equal( %w{ SUNWcsd }, contents.packages.map(&:to_s) )
    assert_equal( nil, contents.size )
    assert_equal( nil, contents.sum )
    assert_equal( line, contents.to_s )
    assert( contents.valid? )
  end

  def test_directory
    line = '/dev d none 0755 root sys SUNWcsr SUNWcsd'
    contents = Solaris::Contents.from_line( line )
    assert_equal( :d, contents.ftype )
    assert_equal( '/dev', contents.path )
    assert_equal( nil, contents.rpath )
    assert_equal( 'none', contents.install_class )
    assert_equal( 493, contents.mode )
    assert_equal( nil, contents.major )
    assert_equal( nil, contents.minor )
    assert_equal( nil, contents.mtime )
    assert_equal( 'root', contents.owner )
    assert_equal( 'sys', contents.group )
    assert_raise RuntimeError do
      contents.package
    end
    assert_equal( %w{ SUNWcsr SUNWcsd }, contents.packages.map(&:to_s) )
    assert_equal( nil, contents.size )
    assert_equal( nil, contents.sum )
    assert_equal( line, contents.to_s )
    assert( contents.valid? )
  end

  def test_editable
    line = '/etc/passwd e passwd 0644 root sys 580 48299 1077177419 SUNWcsr'
    contents = Solaris::Contents.from_line( line )
    assert_equal( :e, contents.ftype )
    assert_equal( '/etc/passwd', contents.path )
    assert_equal( nil, contents.rpath )
    assert_equal( 'passwd', contents.install_class )
    assert_equal( 420, contents.mode )
    assert_equal( nil, contents.major )
    assert_equal( nil, contents.minor )
    assert_equal( 1077177419, contents.mtime )
    assert_equal( 'root', contents.owner )
    assert_equal( 'sys', contents.group )
    assert_equal( %w{ SUNWcsr }, contents.packages.map(&:to_s) )
    assert_equal( 'SUNWcsr', contents.package.to_s )
    assert_equal( 580, contents.size )
    assert_equal( 48299, contents.sum )
    assert_equal( line, contents.to_s )
    assert( contents.valid? )
  end

  def test_file
    line = '/boot/grub/bin/grub f none 0555 root sys 378124 54144 1281112186 SUNWgrub'
    contents = Solaris::Contents.from_line( line )
    assert_equal( :f, contents.ftype )
    assert_equal( '/boot/grub/bin/grub', contents.path )
    assert_equal( nil, contents.rpath )
    assert_equal( 'none', contents.install_class )
    assert_equal( 365, contents.mode )
    assert_equal( nil, contents.major )
    assert_equal( nil, contents.minor )
    assert_equal( 1281112186, contents.mtime )
    assert_equal( 'root', contents.owner )
    assert_equal( 'sys', contents.group )
    assert_equal( %w{ SUNWgrub }, contents.packages.map(&:to_s) )
    assert_equal( 'SUNWgrub', contents.package.to_s )
    assert_equal( 378124, contents.size )
    assert_equal( 54144, contents.sum )
    assert_equal( line, contents.to_s )
    assert( contents.valid? )
  end

  def test_link
    line = '/etc/crypto/certs/SUNWObjectCA=../../../etc/certs/SUNWObjectCA l none SUNWcsr'
    contents = Solaris::Contents.from_line( line )
    assert_equal( :l, contents.ftype )
    assert_equal( '/etc/crypto/certs/SUNWObjectCA', contents.path )
    assert_equal( '../../../etc/certs/SUNWObjectCA', contents.rpath )
    assert_equal( 'none', contents.install_class )
    assert_equal( nil, contents.mode )
    assert_equal( nil, contents.major )
    assert_equal( nil, contents.minor )
    assert_equal( nil, contents.mtime )
    assert_equal( nil, contents.owner )
    assert_equal( nil, contents.group )
    assert_equal( 'SUNWcsr', contents.package.to_s )
    assert_equal( %w{ SUNWcsr }, contents.packages.map(&:to_s) )
    assert_equal( nil, contents.size )
    assert_equal( nil, contents.sum )
    assert_equal( line, contents.to_s )
    assert( contents.valid? )
  end

  def test_symlink
    line = '/bin=./usr/bin s none SUNWcsr'
    contents = Solaris::Contents.from_line( line )
    assert_equal( :s, contents.ftype )
    assert_equal( '/bin', contents.path )
    assert_equal( './usr/bin', contents.rpath )
    assert_equal( 'none', contents.install_class )
    assert_equal( nil, contents.mode )
    assert_equal( nil, contents.major )
    assert_equal( nil, contents.minor )
    assert_equal( nil, contents.mtime )
    assert_equal( nil, contents.owner )
    assert_equal( nil, contents.group )
    assert_equal( %w{ SUNWcsr }, contents.packages.map(&:to_s) )
    assert_equal( nil, contents.size )
    assert_equal( nil, contents.sum )
    assert_equal( line, contents.to_s )
    assert( contents.valid? )
  end

  def test_volatile
    line = '/boot/x86.miniroot-safe v failsafe 0644 root sys 65 5585 1279140915 SUNWcsd'
    contents = Solaris::Contents.from_line( line )
    assert_equal( :v, contents.ftype )
    assert_equal( '/boot/x86.miniroot-safe', contents.path )
    assert_equal( nil, contents.rpath )
    assert_equal( 'failsafe', contents.install_class )
    assert_equal( 420, contents.mode )
    assert_equal( nil, contents.major )
    assert_equal( nil, contents.minor )
    assert_equal( 1279140915, contents.mtime )
    assert_equal( 'root', contents.owner )
    assert_equal( 'sys', contents.group )
    assert_equal( 'SUNWcsd', contents.package.to_s )
    assert_equal( %w{ SUNWcsd }, contents.packages.map(&:to_s) )
    assert_equal( 65, contents.size )
    assert_equal( 5585, contents.sum )
    assert_equal( line, contents.to_s )
    assert( contents.valid? )
  end

  def test_exclusive
    skip 'No exclusive example found'
  end

  def test_unknown_ftype
    line = '/boot/grub/bin/grub Z none 0555 root sys 378124 54144 1281112186 SUNWgrub'
    assert_raise ArgumentError do
      Solaris::Contents.from_line( line )
    end
  end

  def test_unparseable_line
    line = '/boot/grub/bin/grub f nonsense'
    assert_raise ArgumentError do
      Solaris::Contents.from_line( line )
    end
  end

  def test_valid
    line = '/boot/grub/bin/grub f none 0555 root sys 378124 54144 1281112186 SUNWgrub'
    proto = Solaris::Contents.from_line( line )
    assert( proto.valid? )
    proto.ftype = :invalid
    assert( ! proto.valid? )
    proto.ftype = :f
    assert( proto.valid? )
  end

end

