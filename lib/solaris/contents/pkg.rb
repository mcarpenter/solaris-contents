
module Solaris

  class Contents

    # Class to represent a package in the contents(4) file. Package
    # names may be prefixed with a single character (and passed to
    # the constructor). The semantics of that single character are
    # not publicly supported but are described in
    # usr/src/cmd/svr4pkg/hdrs/libinst.h:
    #    #define INST_RDY    '+' /* entry is ready to installf -f */
    #    #define RM_RDY      '-' /* entry is ready for removef -f */
    #    #define NOT_FND     '!' /* entry (or part of entry) was not found */
    #    #define SERVED_FILE '%' /* using the file server's RO partition */
    #    #define STAT_NEXT   '@' /* this is awaiting eptstat */
    #    #define DUP_ENTRY   '#' /* there's a duplicate of this */
    #    #define CONFIRM_CONT    '*' /* need to confirm contents */
    #    #define CONFIRM_ATTR    '~' /* need to confirm attributes */
    #    #define ENTRY_OK    '\0'    /* entry is a confirmed file */
    class Pkg

      # The name of this package, without status indicator.
      attr_accessor :name

      # The status if this package as a symbol (see STATUS_BY_SYM).
      attr_accessor :status

      # Hash to map status symbols to their string representation.
      STATUS_BY_SYM = {
        :inst_rdy => '+',
        :rm_rdy => '-',
        :not_fnd => '!',
        :served_file => '%',
        :stat_next => '@',
        :dup_entry => '#',
        :confirm_cont => '*',
        :confirm_attr => '~',
        :entry_ok => ''
      }

      # Hash to map status strings to their symbolic representation.
      STATUS_BY_STR = STATUS_BY_SYM.invert

      def initialize(pkg)
        # Use #chr for ruby 1.8 compatibility
        status_char = pkg[0].chr
        if STATUS_BY_STR.keys.include?(status_char)
          @name = pkg[1..-1]
          @status = STATUS_BY_STR[status_char]
        else
          @name = pkg
          @status = :entry_ok
        end
      end

      def to_s
        STATUS_BY_SYM[@status] + @name
      end

      STATUS_BY_SYM.keys.each do |key|
        define_method("#{key}?") do
          @status == key
        end
      end

    end # Pkg

  end # Contents

end # Solaris

