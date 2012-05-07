require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Edxl::Message do
  before do
    root = FactoryGirl.create(:jurisdiction, :foreign => false)
    node = FactoryGirl.create(:jurisdiction, :foreign => false)
    Role.find_or_create_by_name('Chief Epidemiologist')
    node.move_to_child_of(root)
    @message = Edxl::Message.parse(File.read("#{fixture_path}/PCAMessageAlert.xml"))
  end
  
  it "should have alerts" do
    @message.alerts.size.should == 1
  end
  
  it "should map distribution_id" do
    @message.distribution_id.should == 'CDC-2009-183'
    end
end
