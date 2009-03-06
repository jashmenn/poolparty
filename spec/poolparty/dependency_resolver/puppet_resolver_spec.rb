require File.dirname(__FILE__) + '/../spec_helper'

describe "PuppetResolver" do
  before :all do
    @cloud_reference_hash = {
      :options => {:name => "dog", :keypair => "bob", :users => ["ari", "michael"]},
      :resources => {
        :file =>  [
                    {:name => "/etc/motd", :content => "Welcome to the cloud"},
                    {:name => "/etc/profile", :content => "profile info"}
                  ],
        :directory => [
                        {:name => "/var/www"}
                      ]    
      },
      :services => {
        :apache => {
          :options => {:listen => "8080"},
          :resources => {
                          :file => [
                              {:name => "/etc/apache2/apache2.conf", :template => "/absolute/path/to/template", :content => "rendered template string"}
                            ]
                        },
          :services => {}
        }
      }
    }
  end
  
  it "throw an exception if not given a hash" do
    lambda { PuppetResolver.compile()}.should raise_error
  end
  it "accept a hash" do
    lambda { PuppetResolver.compile({})}.should_not raise_error
  end
  
  describe "when passed a valid cloud hash" do
    
    before(:all) do
      @dr = PuppetResolver.new(@cloud_reference_hash)
      @compiled = @dr.compile
    end
    
    describe "variables" do
      it "output options as puppet variables" do
        @compiled.should match(/bob/)
        @compiled.instance_of?(String).should == true
        @compiled.should match(/\$users = \[ \".* \]/)
      end
    end
    
    describe "resources" do
      it "should print resources in the proper layout" do        
        @compiled.should match(/file \{ "\/etc\/motd"/)
      end
    end
    
    describe "services" do
      it "should print apache into a class definition" do
        # puts "<pre>#{@compiled.to_yaml}</pre>"
        @compiled.should match(/class apache \{/)
      end
    end
    
  end
  
  describe "with a cloud" do
    before(:each) do
      class PuppetResolverSpec
        plugin :apache do
        end
      end
      @cloud = cloud :dog do
        keypair "bob"
        has_file :name => "/etc/motd", :content => "Welcome to the cloud"        
        has_file :name => "/etc/profile", :content => "profile info"
        has_directory :name => "/var/www"
        # has_package :name => "bash"        
        # parent == cloud
        apache do
          # parent == apache
          listen "8080"
          has_file :name => "/etc/apache2/apache2.conf", :template => "#{::File.dirname(__FILE__)}/../fixtures/test_template.erb", :friends => "bob"
        end
      end
      @properties = cloud(:dog).to_properties_hash
      
      # puts "<pre>#{cloud(:dog).resources.to_yaml}</pre>"
      # puts "<pre>#{@cloud_refer/ence_hash.to_yaml}\n\n#{@properties.to_yaml}</pre>"
      @dr = PuppetResolver.new(@properties)
      @compiled = @dr.compile
    end
    it "should compile to a string" do
      # puts "<pre>#{@compiled.to_yaml}</pre>"
      @compiled.class.should == String
    end
    it "should include apache class" do
      @compiled.should match(/class apache \{/)
    end
  end
  
end