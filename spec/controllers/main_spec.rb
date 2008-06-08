require File.dirname(__FILE__) + '/../spec_helper'

describe "SecureMagic::Main (controller)" do
  
  # Feel free to remove the specs below
  
  before :all do
    Merb::Router.prepare { |r| r.add_slice(:SecureMagic) } if standalone?
  end
  
  it "should have access to the slice module" do
    controller = dispatch_to(SecureMagic::Main, :index)
    controller.slice.should == SecureMagic
    controller.slice.should == SecureMagic::Main.slice
  end
  
  it "should have an index action" do
    controller = dispatch_to(SecureMagic::Main, :index)
    controller.status.should == 200
    controller.body.should contain('SecureMagic')
  end
  
  it "should work with the default route" do
    controller = get("/secure-magic/main/index")
    controller.should be_kind_of(SecureMagic::Main)
    controller.action_name.should == 'index'
  end
  
  it "should have helper methods for dealing with public paths" do
    controller = dispatch_to(SecureMagic::Main, :index)
    controller.public_path_for(:image).should == "/slices/secure-magic/images"
    controller.public_path_for(:javascript).should == "/slices/secure-magic/javascripts"
    controller.public_path_for(:stylesheet).should == "/slices/secure-magic/stylesheets"
  end
  
  it "should have a slice-specific _template_root" do
    SecureMagic::Main._template_root.should == SecureMagic.dir_for(:view)
    SecureMagic::Main._template_root.should == SecureMagic::Application._template_root
  end

end