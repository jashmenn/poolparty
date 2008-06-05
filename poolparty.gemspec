
# Gem::Specification for Poolparty-0.0.6
# Originally generated by Echoe

Gem::Specification.new do |s|
  s.name = %q{poolparty}
  s.version = "0.0.6"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ari Lerner"]
  s.date = %q{2008-06-05}
  s.description = %q{Run your entire application off EC2, managed and auto-scaling}
  s.email = %q{ari.lerner@citrusbyte.com}
  s.executables = ["instance", "pool", "poolparty"]
  s.extra_rdoc_files = ["bin/instance", "bin/pool", "bin/poolparty", "CHANGELOG", "lib/core/array.rb", "lib/core/exception.rb", "lib/core/hash.rb", "lib/core/kernel.rb", "lib/core/module.rb", "lib/core/object.rb", "lib/core/proc.rb", "lib/core/string.rb", "lib/core/time.rb", "lib/modules/callback.rb", "lib/modules/ec2_wrapper.rb", "lib/modules/safe_instance.rb", "lib/pool_party/application.rb", "lib/pool_party/init.rb", "lib/pool_party/master.rb", "lib/pool_party/monitors/cpu.rb", "lib/pool_party/monitors/memory.rb", "lib/pool_party/monitors/web.rb", "lib/pool_party/monitors.rb", "lib/pool_party/optioner.rb", "lib/pool_party/plugin.rb", "lib/pool_party/remote_instance.rb", "lib/pool_party/remoting.rb", "lib/pool_party/scheduler.rb", "lib/pool_party/tasks.rb", "lib/pool_party.rb", "lib/s3/s3_object_store_folders.rb", "README.txt"]
  s.files = ["bin/instance", "bin/pool", "bin/poolparty", "CHANGELOG", "config/cloud_master_takeover", "config/config.yml", "config/create_proxy_ami.sh", "config/haproxy.conf", "config/heartbeat.conf", "config/heartbeat_authkeys.conf", "config/installers/ubuntu_install.sh", "config/monit/haproxy.monit.conf", "config/monit/nginx.monit.conf", "config/monit.conf", "config/nginx.conf", "config/reconfigure_instances_script.sh", "config/scp_instances_script.sh", "lib/core/array.rb", "lib/core/exception.rb", "lib/core/hash.rb", "lib/core/kernel.rb", "lib/core/module.rb", "lib/core/object.rb", "lib/core/proc.rb", "lib/core/string.rb", "lib/core/time.rb", "lib/modules/callback.rb", "lib/modules/ec2_wrapper.rb", "lib/modules/safe_instance.rb", "lib/pool_party/application.rb", "lib/pool_party/init.rb", "lib/pool_party/master.rb", "lib/pool_party/monitors/cpu.rb", "lib/pool_party/monitors/memory.rb", "lib/pool_party/monitors/web.rb", "lib/pool_party/monitors.rb", "lib/pool_party/optioner.rb", "lib/pool_party/plugin.rb", "lib/pool_party/remote_instance.rb", "lib/pool_party/remoting.rb", "lib/pool_party/scheduler.rb", "lib/pool_party/tasks.rb", "lib/pool_party.rb", "lib/s3/s3_object_store_folders.rb", "Manifest", "misc/basics_tutorial.txt", "plugins/logging/init.rb", "plugins/logging/logging.rb", "Rakefile", "README.txt", "spec/application_spec.rb", "spec/callback_spec.rb", "spec/core_spec.rb", "spec/helpers/ec2_mock.rb", "spec/kernel_spec.rb", "spec/master_spec.rb", "spec/monitor_spec.rb", "spec/optioner_spec.rb", "spec/plugin_spec.rb", "spec/plugins/logging_spec.rb", "spec/poolparty_spec.rb", "spec/remote_instance_spec.rb", "spec/remoting_spec.rb", "spec/spec_helper.rb", "spec/string_spec.rb", "test/test_pool_party.rb", "web/static/conf/nginx.conf", "web/static/site/images/balloon.png", "web/static/site/images/cb.png", "web/static/site/images/clouds.png", "web/static/site/images/railsconf_preso_img.png", "web/static/site/index.html", "web/static/site/javascripts/application.js", "web/static/site/javascripts/corner.js", "web/static/site/javascripts/jquery-1.2.6.pack.js", "web/static/site/misc.html", "web/static/site/storage/pool_party_presentation.pdf", "web/static/site/stylesheets/application.css", "web/static/site/stylesheets/reset.css", "web/static/src/layouts/application.haml", "web/static/src/pages/index.haml", "web/static/src/pages/misc.haml", "web/static/src/stylesheets/application.sass", "poolparty.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://blog.citrusbyte.com}
  s.post_install_message = %q{For more information, check http://poolpartyrb.com
*** Ari Lerner @ <ari.lerner@citrusbyte.com> ***}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Poolparty", "--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{poolparty}
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{Run your entire application off EC2, managed and auto-scaling}
  s.test_files = ["test/test_pool_party.rb"]

  s.add_dependency(%q<aws-s3>, [">= 0"])
  s.add_dependency(%q<amazon-ec2>, [">= 0"])
  s.add_dependency(%q<aska>, [">= 0"])
end


# # Original Rakefile source (requires the Echoe gem):
# 
# require 'rubygems'
# require 'echoe'
# require 'lib/pool_party'
# 
# task :default => :test
# 
# Echoe.new("poolparty") do |p|
#   p.author = "Ari Lerner"
#   p.email = "ari.lerner@citrusbyte.com"
#   p.summary = "Run your entire application off EC2, managed and auto-scaling"
#   p.url = "http://blog.citrusbyte.com"
#   p.dependencies = %w(aws-s3 amazon-ec2 aska)
#   p.install_message = "For more information, check http://poolpartyrb.com\n*** Ari Lerner @ <ari.lerner@citrusbyte.com> ***"
#   p.include_rakefile = true
# end
# 
# PoolParty.include_tasks