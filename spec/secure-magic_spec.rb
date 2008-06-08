require File.dirname(__FILE__) + '/spec_helper'

describe "SecureMagic (module)" do
  
  it "should have proper specs"
  
  # Feel free to remove the specs below
  
  it "should be registered in Merb::Slices.slices" do
    Merb::Slices.slices.should include(SecureMagic)
  end
  
  it "should be registered in Merb::Slices.paths" do
    Merb::Slices.paths[SecureMagic.name].should == current_slice_root
  end
  
  it "should have an :identifier property" do
    SecureMagic.identifier.should == "secure-magic"
  end
  
  it "should have an :identifier_sym property" do
    SecureMagic.identifier_sym.should == :secure_magic
  end
  
  it "should have a :root property" do
    SecureMagic.root.should == Merb::Slices.paths[SecureMagic.name]
    SecureMagic.root_path('app').should == current_slice_root / 'app'
  end
  
  it "should have a :file property" do
    SecureMagic.file.should == current_slice_root / 'lib' / 'secure-magic.rb'
  end
  
  it "should have metadata properties" do
    SecureMagic.description.should == "SecureMagic is a chunky Merb slice!"
    SecureMagic.version.should == "0.0.1"
    SecureMagic.author.should == "YOUR NAME"
  end
  
  it "should have a config property (Hash)" do
    SecureMagic.config.should be_kind_of(Hash)
  end
  
  it "should have bracket accessors as shortcuts to the config" do
    SecureMagic[:foo] = 'bar'
    SecureMagic[:foo].should == 'bar'
    SecureMagic[:foo].should == SecureMagic.config[:foo]
  end
  
  it "should have a :layout config option set" do
    SecureMagic.config[:layout].should == :secure_magic
  end
  
  it "should have a dir_for method" do
    app_path = SecureMagic.dir_for(:application)
    app_path.should == current_slice_root / 'app'
    [:view, :model, :controller, :helper, :mailer, :part].each do |type|
      SecureMagic.dir_for(type).should == app_path / "#{type}s"
    end
    public_path = SecureMagic.dir_for(:public)
    public_path.should == current_slice_root / 'public'
    [:stylesheet, :javascript, :image].each do |type|
      SecureMagic.dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should have a app_dir_for method" do
    root_path = SecureMagic.app_dir_for(:root)
    root_path.should == Merb.root / 'slices' / 'secure-magic'
    app_path = SecureMagic.app_dir_for(:application)
    app_path.should == root_path / 'app'
    [:view, :model, :controller, :helper, :mailer, :part].each do |type|
      SecureMagic.app_dir_for(type).should == app_path / "#{type}s"
    end
    public_path = SecureMagic.app_dir_for(:public)
    public_path.should == Merb.dir_for(:public) / 'slices' / 'secure-magic'
    [:stylesheet, :javascript, :image].each do |type|
      SecureMagic.app_dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should have a public_dir_for method" do
    public_path = SecureMagic.public_dir_for(:public)
    public_path.should == '/slices' / 'secure-magic'
    [:stylesheet, :javascript, :image].each do |type|
      SecureMagic.public_dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should keep a list of path component types to use when copying files" do
    (SecureMagic.mirrored_components & SecureMagic.slice_paths.keys).length.should == SecureMagic.mirrored_components.length
  end
  
end