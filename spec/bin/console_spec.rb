require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/helpers/console'

describe "Console" do
  describe "load_pool" do
    before(:each) do
      reset!
      @string =<<-EOS
      pool :app do
        maximum_instances 2
        cloud :rawr do          
        end
      end
      EOS
      self.stub!(:open).and_return @string
      @string.stub!(:read).and_return @string
    end
    it "should give you the load_pool method" do
      self.respond_to?(:load_pool).should == true
    end
    it "should call script inflate on the filename" do
      PoolParty::Script.should_receive(:inflate).with(@string).and_return "pop"
      load_pool("pop")
    end
    describe "calling" do
      before(:each) do
        load_pool("pop")
      end
      it "should instance_eval the string" do
        pool(:app).should_not be_nil
      end
      it "should store the cloud inside the pool after inflating" do
        pool(:app).cloud(:rawr).should_not be_nil
      end
      it "should say that the cloud inside the pool's parent is the containing parent" do      
        pool(:app).cloud(:rawr).parent.should == pool(:app)
      end
      it "should say that the maximum_instances on the cloud is the containing pool's option" do
        pool(:app).cloud(:rawr).maximum_instances.should == 2
      end
    end
  end  
end