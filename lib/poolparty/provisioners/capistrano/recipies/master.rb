# Cloud tasks
# Run each of these methods inside the Capistrano:Configuration context, dynamicly adding each method as a capistrano task.
Capistrano::Configuration.instance(:must_exist).load do
  # namespace(:master) do
    desc "Provision master"
    def master_provision_master_task
      # $stderr.puts "\nRETUNRING from master_provision_master_task without doing anything"
      # return 
      upgrade_system
      set_hostname_to_master
      create_local_hosts_entry
      setup_for_poolparty
      install_provisioner
      setup_basic_poolparty_structure
      setup_provisioner_filestore
      setup_provisioner_autosigning      
      install_rubygems
      fix_rubygems
      add_provisioner_configs
      setup_provisioner_config
      create_puppetrunner_command
      start_provisioner_base      
      # create_puppetrerun_command
      # download_base_gems
      unpack_dependencies_store
      install_base_gems
      copy_gem_bins_to_usr_bin
      write_erlang_cookie
      vputs "master_provision_master_task complete"
    end
    
    desc "Configure master"
    def master_configure_master_task
      create_local_node_entry_for_puppet
      put_provisioner_manifest
      # move_template_files
      ensure_provisioner_is_running
      run_provisioner
    end
    desc "Set hostname to master"
    def set_hostname_to_master
      run "hostname master"
    end
    desc "Add host entry into the master instance"
    def create_local_hosts_entry
      run "if [ -z \"$(grep -v '#' /etc/hosts | grep 'puppet')\" ]; then echo '#{cloud.master.ip}          master puppet localhost' >> /etc/hosts; fi"
    end
    desc "Download base gems"
    def download_base_gems
      run(returning(Array.new) do |arr|
        base_gems.each do |name, url|
          if url && !url.empty?
            arr << "curl -L -o #{Default.remote_storage_path}/#{name}.gem #{url} 2>&1; echo 'downloaded #{name}'"
            arr << "if test -s #{Default.remote_storage_path}/#{name}.gem; then echo ''; else rm #{Default.remote_storage_path}/#{name}.gem; fi; echo ''"
          end
        end
      end.join(" && "))
    end
    desc "Install base gems"
    def install_base_gems
      # run(returning(Array.new) do |arr|
      #   base_gems.each do |name, url|
      #     str = url.empty? ? "#{name}" : "#{Base.remote_storage_path}/#{name}.gem"
      #     arr << "/usr/bin/gem install --ignore-dependencies --no-ri --no-rdoc #{str}; echo 'insatlled #{name}'"
      #   end
      # end.join(" && "))
      run <<-EOR
        ruby -e 'Dir["#{Default.remote_storage_path}/vendor/dependencies/cache/*.gem"].each {|g| "/usr/bin/gem install --ignore-dependencies --no-ri --no-rdoc \#\{g\}; echo 'insatlled \#\{g\}'" }'
      EOR
    end
    
    desc "Start provisioner base"
    def start_provisioner_base
      # run "/etc/init.d/puppetmaster start"
      run "/usr/bin/puppetrunner"
    end
    desc "Restart provisioner base"
    def restart_provisioner_base #FIXME: should inherit from cloud dependency_resolver_command
      "/usr/bin/puppetrunner"
      # run "/etc/init.d/puppetmaster stop;rm -rf /etc/poolparty/ssl;start_provisioner_based --verbose;/etc/init.d/puppetmaster start"
    end
    desc "Ensure provisioner is running"
    def ensure_provisioner_is_running
      "/usr/bin/puppetrunner"
      # run "/usr/sbin/puppetmasterd --verbose 2>1 > /dev/null;echo ''"
    end
    desc "Create local node for puppet manifest"
    def create_local_node_entry_for_puppet
      # run ". /etc/profile && server-write-new-nodes"
      str = ["node default { include poolparty }"]
      list_of_running_instances.each do |ri| 
        str << "node \"#{ri.name}\" inherits default {}\n"
      end
      put( str.join("\n"), "#{manifest_path}/nodes/nodes.pp")
    end
    #DEPRECATED
    # desc "Move template files into place"
    # def move_template_files
    #   run <<-EOR
    #     mkdir -p #{template_path} &&
    #     cp -R #{remote_storage_path}/templates/* #{template_path}
    #   EOR
    # end
    desc "put manifest into place" 
    def put_provisioner_manifest
      put build_manifest, '/etc/puppet/manifests/classes/poolparty.pp'
    end
    desc "Put poolparty keys"
    def put_poolparty_keys
      put keypair.full_filepath, remote_keypair_path, :mode => 600
    end
  # end
end