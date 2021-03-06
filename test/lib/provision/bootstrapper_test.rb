require "#{File.dirname(__FILE__)}/../../test_helper"

class BootstrapperTest < Test::Unit::TestCase
  
  context "bootstrap_script" do
    should "get the script for ubuntu" do
      bootstrap_dir = File.dirname(__FILE__)/"../../../lib/provision/bootstrap_scripts"
      ubuntu_script = File.expand_path(bootstrap_dir/"build_ubuntu.sh")
      assert_equal ubuntu_script, Provision::Bootstrapper.bootstrap_script(:os=>:ubuntu)
    end
    
    should "raise an exception if the os isn't supported yet" do
      assert_raises StandardError do
        Provision::Bootstrapper.bootstrap_script(:os=>:non_existant_os)
      end
    end
  end
  
end