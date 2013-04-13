require 'capistrano/cli'

module Capistrano
  module Chocopoche
    class SyncCLI
      def prompt(default, *args)
        print(*args)
        result = STDIN.gets.strip
        return result.empty? ? default : result
      end

      def ensure_stages
        show_error("The DATATYPE is missing.")       if @args[0].nil?
        show_error("The DATATYPE is incorrect.") unless @args[0] =~ /^files|mysql$/
        show_error("The SOURCE is missing.")         if @args[1].nil?
        show_error("The DEST is missing.")           if @args[2].nil?
        @data   = @args[0]
        @source = @args[1]
        @dest   = @args[2]
      end

      def ensure_confirmation
        unless @options[:no_confirmation] == false
          confirm = prompt('y', "Sync from #{@source} to #{@dest}? [Y/n] ").downcase
          unless confirm == "y"
            abort("Cancelled")
          end
        end
      end

      def show_error(msg)
        puts @parser.help
        abort("\n[ERROR] #{msg}")
      end

      def initialize(args)
        @args    = args
        @options = {}
        @parser  = OptionParser.new do |opts|
          opts.banner  = "Usage: files-sync [options] DATATYPE SOURCE DEST \n"
          opts.banner += "Sync DATATYPE from the SOURCE stage to the DEST stage.\n"
          opts.on("-y", "--no-confirmation", "Don't prompt for confirmation") do |v|
            @options[:no_confirmation] = v
          end

          opts.on("--no-backup", "Dont backup databases before importing") do |v|
            @options[:no_backup] = v
          end
        end
      end

      def execute
        @parser.parse!
        ensure_stages
        ensure_confirmation
        if @data == 'mysql'
          Capistrano::CLI.parse([@dest,   "mysql:dump"]).execute! unless @options[:no_backup]
          Capistrano::CLI.parse([@source, "mysql:dump",   "mysql:download"]).execute!
          Capistrano::CLI.parse([@dest,   "mysql:upload", "mysql:import"]).execute!
        elsif @data == 'files'
          Capistrano::CLI.parse([@source, "files:download"]).execute!
          Capistrano::CLI.parse([@dest,   "files:upload"]).execute!
        end
      end
    end
  end
end
