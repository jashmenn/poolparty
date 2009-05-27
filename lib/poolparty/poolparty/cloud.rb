require File.dirname(__FILE__) + "/plugin_model"
require File.dirname(__FILE__) + "/resource"

module PoolParty    
  module Cloud
    # Instantiate a new cloud
    def cloud(name, &block)
      clouds[name] ||= Cloud.new(name, &block)
    end

    # Global hash of clouds
    def clouds
      $clouds ||= {}
    end
    
    # TODO: Deprecate
    def with_cloud(cl, opts={}, &block)
      raise CloudNotFoundException.new("Cloud not found") unless cl
      cl.dsl_options.merge!(opts) if opts
      cl.run_in_context &block if block
    end
    
    class Cloud < PoolParty::PoolPartyBaseClass
      attr_reader :templates, :cloud_name, :remote_base
      attr_accessor :started_instance
      
      # Default set of options. Most take the Default options from the default class
      default_options(
        {
        :expand_when          => Default.expand_when,
        :contract_when        => Default.contract_when,
        :minimum_instances    => 2,
        :maximum_instances    => 5,
        :ec2_dir              => ENV["EC2_HOME"],
        :minimum_runtime      => Default.minimum_runtime,
        # :dependency_resolver  => ChefResolver,
        :remoter_base         => Default.remoter_base,
        :keypair              => nil,
        :keypair_path         => nil,
        :keypair_name         => nil
        }.merge(Remote::Ec2.default_options)
      )

      include CloudResourcer
      include ::PoolParty::PluginModel
      include PoolParty::Resources
      include PoolParty::Callbacks
      include PoolParty::DependencyResolverCloudExtensions
      include PrettyPrinter

      # Net methods
      include ::PoolParty::Remote
      include PoolParty::CloudDsl
      include PoolParty::Verification
      # include PoolParty::Monitors

      def self.immutable_methods
        [:name]
      end
      
      # Redefining methods are not allowed
      def self.method_added sym        
        raise "Exception: #{sym.to_s.capitalize} method has been redefined" if immutable_methods.include?(sym) && !respond_to?(sym)
      end
      
      alias :name :cloud_name
      
      # Call the remoter commands on the remoter_base if they don't exist on the cloud itself.
      # This gives the cloud access to the remote_base's methods.
      def method_missing(m, *args, &block)
        if remote_base.respond_to?(m)
          remoter_opts = dsl_options.merge(remote_base.dsl_options).choose do |k,v|
             remote_base.dsl_options.has_key?(k)
          end
          if args.size==1 && args.first.respond_to?(:merge)
            new_args = [remoter_opts.merge(args.first)]
          else
            new_args = args.push(remoter_opts)
          end
          remote_base.send(m, *(new_args), &block)
        else
          super
        end
      end
      
      additional_callbacks [
        "after_launch_instance"
      ]
      
      # Freeze the cloud_name so we can't modify it at all, set the plugin_directory
      # call and run instance_eval on the block and then call the after_create callback
      def initialize(name, &block)
        @cloud_name = name
        @cloud_name.freeze
        
        setup_callbacks
        
        plugin_directory "#{pool_specfile ? ::File.dirname(pool_specfile) : Dir.pwd}/plugins"        
        before_create
        super
        after_create
      end
      
      # Fetch the name of the cloud
      def name(*args)
        @cloud_name ||= @cloud_name ? @cloud_name : (args.empty? ? :default_cloud : args.first)
      end
      
      def before_create
        add_poolparty_base_requirements
      end
      
      # Callback
      # called after the cloud has been created, everything has run and is set at this point
      # here the base requirements are added as well as an empty chef recipe is called
      # Also, the after_create hook on the plugins used by the cloud are called here
      def after_create
        ::FileUtils.mkdir_p("#{tmp_path}/dr_configure")
        
        run_in_context do
          add_optional_enabled_services
          chef do
          end
        end
        
        plugin_store.each {|a| a.call_after_create_callbacks }
        setup_defaults
      end
      
      # CALLBACKS
      # To hook into the chain of processes that PoolParty uses
      # when launching, bootstrapping, configuring tasks, call
      # these methods in your clouds.rb.
      # Example:
      # 
      #   after :bootstrap do
      #     stuff
      #   end
      # 
      # These store the blocks into the after/before_blocks on self
      # and are called as appropriate at the runtime
      def after time, &block 
        (after_blocks[time.to_sym] ||= []) << block
      end      
      def before time, &block
        (before_blocks[time.to_sym] ||= []) << block
      end
      
      # setup defaults for the cloud
      def setup_defaults
        set_vars_from_options(:keypair_name => key.basename, :keypair_path => key.full_filepath) rescue nil
        
        dsl_options[:rules] = {:expand   => "#{dsl_options[:expand_when]}", 
                               :contract => dsl_options[:contract_when]}        
        
        dependency_resolver 'chef'
        using Default.remoter_base unless @remote_base
      end
      
      def after_launch_instance(inst=nil)
        remote_base.send :after_launch_instance, inst
      end
      
      # Keypairs
      # Use the keypair path
      def keypair(*args)
        if args && !args.empty?
          args.each do |arg|
            unless arg.nil? || _keypair_filepaths.include?(arg)
              k = arg.is_a?(Key) ? arg : Key.new(arg)
              _keypairs.unshift k
            end
          end
          self.keypair
        else
          unless @keypair
            @keypair = _keypairs.select {|key| key.exists? }.first
            self.keypair_path = @keypair.full_filepath
            self.keypair_name = @keypair.basename
            self.keypair = @keypair
          end
          @keypair
        end
      end

      alias :set_keypairs :keypair
      alias :key :keypair

      def _keypairs
        @keypairs ||= [Key.new]
      end

      # Collect the filepaths of the already loaded keypairs
      def _keypair_filepaths
        _keypairs.map {|a| a.filepath }
      end

      #TODO: deprecate: use key.full_filepath    
      def full_keypair_path
        @full_keypair_path ||= keypair.full_filepath
      end
      
      # provide list of public ips to get into the cloud
      def ips
        nodes(:status => "running").map {|ri| ri.ip }
      end
      
      def ip
        ips.first
      end
            
      # Build the new poolparty manifest
      # Wrapping all of these requirements into the one 
      # poolparty class.
      # 
      # TODO: Consider the benefits of moving all the manifest
      # classes to separate files and keeping the containing
      # references in the include
      def build_and_store_new_config_file(filepath=nil, force=false)
        filepath ||= ::File.join(Default.storage_directory, "poolparty.pp")
        # write_properties_hash if debugging
        vputs "Building new manifest configuration file (forced: #{force})"
        manifest = force ? rebuild_manifest : build_manifest
        ::File.open(filepath, "w") do |file|
          file << manifest
        end
      end
      
      # If there is a directory named monitors in the same directory
      # as the pool specification file is in,
      # then create a monitors directory in the storage directory
      # and mirror the two. When PoolParty "boots" up, it scans
      # the monitors directory for any custom monitors
      # that are in known locations, these are included
      def copy_custom_monitors
        unless Default.custom_monitor_directories.empty?
          Default.custom_monitor_directories.each do |dir|
            Dir["#{dir}/*.rb"].each {|f| ::Suitcase::Zipper.add(f, "monitors")}
          end
        end
      end

      #FIXME MOVE TO DEPENDENCY RESOLVER
      # Configuration files
      def build_manifest
        vputs "Building manifest"
        @build_manifest ||= build_from_existing_file
        unless @build_manifest
          props = to_properties_hash
          
          @build_manifest = dependency_resolver.send(:compile, props, self)
        end
        dputs "Finished creating manifest"
        @build_manifest
      end
      
      # Force rebuilding of the manifest
      def rebuild_manifest
        @build_manifest = nil
        build_manifest
      end
      
      # If the pp already exists, then let's not recreate it
      # TODO: Abstract
      def build_from_existing_file
        ::FileTest.file?("#{Default.base_config_directory}/poolparty.pp") ? open("#{Default.base_config_directory}/poolparty.pp").read : nil
      end
      
      def write_properties_hash(filename=::File.join(tmp_path, Default.properties_hash_filename) )
        file_path = ::File.dirname(filename)
        file_name = "#{::File.basename(filename, ::File.extname(filename))}_#{name}#{::File.extname(filename)}"
        output = to_properties_hash.to_json
        ::File.open("#{file_path}/#{file_name}", "w") {|f| f.write output }
        true
      end
      
      def to_hash
        hsh = to_properties_hash
        hsh[:options].merge!({:remote_base => remote_base.to_hash})  
        # hsh.reject{|k,v| k == :remote_base || k == :cloud}
        hsh
      end
      
      def to_h
        to_hash
      end
      
      # TODO: test
      # ruby -rrubygems -e 'require "poolparty";puts Cloud.load_from_json(open("/etc/poolparty/clouds.json").read).minimum_instances'      
      def self.load_from_json(str, o={})
        if ::File.file?(str)
          str = open(str).read
        end
        parsed = JSON.parse(str).symbolize_keys!
        opts = parsed.options
        opts["keypair"] = opts["keypair_path"] = opts["keypair_name"]

        cld = Cloud.new opts.cloud_name.to_sym
        cld.dsl_options.merge! opts
        cld.using opts.remoter_base.to_sym, opts.remote_base
        cld.dependency_resolver opts[:dependency_resolver]
        
        #TODO: will never run
        unless true || o[:full_stack]
          context_stack.push cld
          cld.ordered_resources = parsed.resources.map do |r|
            case typ = r.delete(:pp_type)
            when "plugin"
              # This may become a problem on the server where the plugins
              # cannot be found. TODO: Fix?!? How? Uh... fake plugin maybe?            
              cld.send(r[:name].gsub(/_class/, '').to_sym) do              
                set_vars_from_options(r)
              end            
            else
              cld.send("has_#{typ}".to_sym, r)
            end
            context_stack.pop
          end
        else
          cld.ordered_resources = parsed.resources
        end
        cld
      end
      
      def remote_base(n=nil)
        if n.nil?
          @remote_base
        else
          @remote_base = n
        end
      end
      
      def tmp_path
        Default.tmp_path / pool.name / name
      end
            
      # Reset the entire cloud
      def reset!
        reset_remoter_base!
        @build_manifest = @describe_instances = @remote_instances_list = nil
      end
      
      # Call before and after configure callbacks
      # on the cloud.
      # These are called from the dynamically defined callback method
      #   call_before/after_configure/bootstrap_callbacks
      # from within callbacks.rb
      # If there is a callback block defined for the specific runtime
      # method being called, then the appropriate callback blocks
      # will be accessed and called from within the before/after_ callback
      def before_bootstrap
        before_blocks[:bootstrap].each {|b| b.call(self) } if before_blocks.has_key?(:bootstrap)
      end
      def after_bootstrap
        after_blocks[:bootstrap].each {|b| b.call(self) } if after_blocks.has_key?(:bootstrap)
      end
      def before_configure
        before_blocks[:configure].each {|b| b.call(self) } if before_blocks.has_key?(:configure)
      end
      def after_configure
        after_blocks[:configure].each {|b| b.call(self) } if after_blocks.has_key?(:configure)
      end
      
      private
      
      # Storage for the after and before callback blocks
      # when calling the callbacks in the cloud. They are stored as hashes with
      # and are filled with arrays of blocks during load-time
      def after_blocks
        @after_blocks ||= {}
      end
      def before_blocks
        @before_blocks ||= {}
      end
      
      def pool
        parent && parent.is_a?(Pool) ? parent : self
      end
      
      # Add all the poolparty requirements here
      # NOTE: These are written as plugins in the lib/poolparty/base_packages directory
      # for examples. 
      # Also note that there is no block associated. This is because we have written
      # all that is necessary in a method called enable
      # which is called when there is no block
      def add_poolparty_base_requirements
        # poolparty_base_heartbeat
        poolparty_base_ruby
        poolparty_base_packages
      end
                
    end
  end 
end
