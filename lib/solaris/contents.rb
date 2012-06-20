
require 'etc'

require 'solaris/contents/pkg'

module Solaris

  # Class to represent Solaris package file contents.
  # A contents line contains information regarding file
  # type, location, ownership, permisions.
  #
  # See Solaris' contents(4) man-page for information on
  # attributes.
  class Contents

    # The file type of the contents entry: one of the symbols
    # :b, :c, :d, :e, :f, :v, :x, :l, :s.
    attr_accessor :ftype

    # The installation class of the file.
    attr_accessor :install_class

    # The path of the file.
    attr_accessor :path

    # The relative path for a linked file.
    attr_accessor :rpath

    # The major mode (integer), for device files (ftype :b or :c).
    attr_accessor :major

    # The minor mode (integer), for device files (ftype :b or :c).
    attr_accessor :minor

    # The mode of the file, as an integer. This is usually presented
    # as an octal number.
    attr_accessor :mode

    # The file user (string).
    attr_accessor :owner

    # The file's group (string).
    attr_accessor :group

    # The file modification time (seconds from the start of 1970).
    attr_accessor :mtime

    # Array of package names to which this file belongs.
    attr_accessor :packages

    # The size of the file in bytes.
    attr_accessor :size

    # The size of the file in bytes modulo 65535. (See Contents#sum).
    attr_accessor :sum

    # Install class to use if not specified.
    DEFAULT_INSTALL_CLASS = 'none'

    # Default system contents(4) path.
    DEFAULT_CONTENTS_PATH = '/var/sadm/install/contents'

    # Regular expression for filetype.
    RE_FTYPE = '([bcdefvxls])'

    # Regular expression for install class.
    # Solaris documentation states that this parameter is at most 12 characters
    # but there are counterexamples in the wild from Sun/Oracle's own hand
    # (eg class "pkcs11confbase").
    RE_INSTALL_CLASS = '(\w+)'

    # Regular expression for path.
    RE_PATH = '(\S+)'

    # Regular expression for major device mode.
    RE_MAJOR = '(\d+)'

    # Regular expression for minor device mode.
    RE_MINOR = '(\d+)'

    # Regular expression for octal file mode.
    RE_MODE = '([0-7]{4})'

    # Regular expression for file modification time.
    RE_MTIME = '(\d+)'

    # Regular expression for user name.
    RE_OWNER = '(\S+)'

    # Regular expression for group name.
    RE_GROUP = '(\S+)'

    # Regular expression for a package.
    RE_PACKAGE = '(\S+)'

    # Regular expression for file size.
    RE_SIZE = '(\d+)'

    # Regular expression for file sum.
    RE_SUM = '(\d+)'

    # Create a Contents object from a line from a contents(4) file. If line
    # is empty or a comment (starts with a hash character) then return nil.
    def self.from_line(line)
      return nil if line.empty? || line =~ /^#/
      ftype = $2.to_sym if line =~ /^#{RE_PATH} #{RE_FTYPE} /
      re = case ftype
           when :s, :l
             /^#{RE_PATH}=#{RE_PATH} #{ftype} #{RE_INSTALL_CLASS} (#{RE_PACKAGE}( #{RE_PACKAGE})*)$/
           when :d
             /^#{RE_PATH} #{ftype} #{RE_INSTALL_CLASS} #{RE_MODE} #{RE_OWNER} #{RE_GROUP} (#{RE_PACKAGE}( #{RE_PACKAGE})*)$/
           when :x
             /^#{RE_PATH} #{ftype} #{RE_INSTALL_CLASS} #{RE_MODE} #{RE_OWNER} #{RE_GROUP} #{RE_PACKAGE}$/
           when :b, :c
             /^#{RE_PATH} #{ftype} #{RE_INSTALL_CLASS} #{RE_MAJOR} #{RE_MINOR} #{RE_MODE} #{RE_OWNER} #{RE_GROUP} #{RE_PACKAGE}$/
           when :f, :v, :e
             /^#{RE_PATH} #{ftype} #{RE_INSTALL_CLASS} #{RE_MODE} #{RE_OWNER} #{RE_GROUP} #{RE_SIZE} #{RE_SUM} #{RE_MTIME} (#{RE_PACKAGE}( #{RE_PACKAGE})*)$/
           else
             raise ArgumentError, "Unknown filetype in line #{line.inspect}"
           end
      if line =~ re
        contents = self.new
        contents.ftype = ftype
        contents.path = $1
        case ftype
        when :s, :l
          contents.rpath = $2
          contents.install_class = $3
          contents.packages = $4.split( /\s+/ ).map { |pkg| Pkg.new(pkg) }
        when :d, :x
          contents.install_class = $2
          contents.mode = $3.to_i( 8 )
          contents.owner = $4
          contents.group = $5
          contents.packages = $6.split( /\s+/ ).map { |pkg| Pkg.new(pkg) }
        when :b, :c
          contents.install_class = $2
          contents.major = $3.to_i
          contents.minor = $4.to_i
          contents.mode = $5.to_i( 8 )
          contents.owner = $6
          contents.group = $7
          contents.packages = $8.split( /\s+/ ).map { |pkg| Pkg.new(pkg) }
        when :f, :v, :e
          contents.install_class = $2
          contents.mode = $3.to_i( 8 )
          contents.owner = $4
          contents.group =$5
          contents.size = $6.to_i
          contents.sum = $7.to_i
          contents.mtime = $8.to_i
          contents.packages = $9.split( /\s+/ ).map { |pkg| Pkg.new(pkg) }
        end
      else
        raise ArgumentError, "Could not parse line #{line.inspect}"
      end
      contents
    end

    # Create a Contents entry from the file at the +path+ on the local
    # filesystem.
    #
    # If +actual+ is provided then this is the path that is used for the
    # object's pathname property although all other properties are
    # created from the +path+ argument. The process must be able to
    # stat(2) the file at +path+ to determine these properties.
    def self.from_path(path, actual=nil)
      contents = self.new
      # Use #lstat since we are always interested in the link source,
      # not the target.
      stat = File.lstat( path )
      raise RuntimeError, 'Unknown file type' if stat.ftype == 'unknown'
      # Stat returns "link" for symlink, not "symlink"
      contents.ftype = stat.symlink? ? :s : stat.ftype[0].to_sym
      case contents.ftype
      when :f
        contents.sum = sum( path )
        contents.size = stat.size
        contents.mtime = stat.mtime.to_i
      when :s
        contents.rpath = File.realpath( path )
      when :b, :c
        contents.major = stat.dev_major
        contents.minor = stat.dev_minor
      when :d
        #
      else
        raise RuntimeError, "Unknown ftype #{contents.ftype.inspect}"
      end
      contents.path = actual || path
      contents.install_class = DEFAULT_INSTALL_CLASS
      contents.mode = stat.mode & 07777
      contents.owner = Etc.getpwuid( stat.uid ).name
      contents.group = Etc.getgrgid( stat.gid ).name
      contents
    end

    # Read a contents(4) file (default /var/sadm/install/contents)
    # and return an array of package contents entries.
    def self.read(path=DEFAULT_CONTENTS_PATH)
      File.open( path ).lines.map do |line|
        from_line( line )
      end.compact
    end

    # Return the sum of the byte values of the file, modulo 65535. This is 
    # the value returned by Solaris' sum(1) and based on the ATT SysV
    # algorithm (NB. not cksum(1) or sum(1B) or the sum(1) BSD algorithm).
    # This is a weak checksum and should not be used for security purposes.
    def self.sum(io_or_string)
      s = io_or_string.each_byte.inject { |r, v| (r + v) & 0xffffffff }
      r = (s & 0xffff) + ((s & 0xffffffff) >> 16)
      (r & 0xffff) + (r >> 16)
    end

    # Create a new contents(4) object.
    def initialize
      @packages = []
    end

    # Return nil if no package has been specified for this contents entry.
    # If only one package has been specified for this contents entry
    # (all cases except, possibly, directory) then return that package.
    # Otherwise throw a RuntimeError.
    def package
      raise RuntimeError, 'Ambiguous: contains more than one package' if @packages.size > 1
      @packages[0]
    end

    # Convert the object to a contents(4) line (string).
    def to_s
      case @ftype
      when :b, :c
        [ @path, @ftype, @install_class, @major, @minor, mode_s, @owner, @group ] + @packages
      when :d
        [ @path, @ftype, @install_class, mode_s, @owner, @group ] + @packages
      when :x
        [ @path, @ftype, @install_class, mode_s, @owner, @group ] + @packages
      when :e, :f, :v
        [ @path, @ftype, @install_class, mode_s, @owner, @group, @size, @sum, @mtime ] + @packages
      when :l, :s
        [ "#{@path}=#{@rpath}", @ftype, @install_class ] + @packages
      else
        raise RuntimeError, "Unknown ftype #{@ftype.inspect}"
      end.join( ' ' )
    end

    # Returns true if the object is a valid contents specification, false
    # otherwise.
    def valid?
      begin
        self.class.from_line( to_s )
      rescue ArgumentError, RuntimeError
        false
      else
        true
      end

    end

    private

    # Convert the file mode to a 4-digit octal string.
    def mode_s
      '%04o' % @mode
    end

  end # Contents

end # Solaris

