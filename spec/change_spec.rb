require File.dirname(__FILE__) + '/spec_helper'

describe Change do
  
  it "should report as being empty when there are no attribute values" do
    hash = {'attributes' => {}, 'associations' => {}}
    Change.new(:diff => hash).should be_attributes_empty
  end
  
  it "should not report as being empty when there are attribute values" do
    hash = {'attributes' => {
      'new' => {
        'name' => 'facemask'
      }
    }, 'associations' => {}}
    Change.new(:diff => hash).should_not be_attributes_empty
  end
  
  it "should not report as being empty when there are association values" do
    hash = { 'attributes' => {},
             'associations' => {
               'somethings' => {
                 1 => {
                   'new' => { 'name' => 'a new name' }
                 }
               }
             }
           }
    Change.new(:diff => hash).should_not be_associations_empty
  end
  
  it "should not report as being empty when there are association values" do
    hash = { 'attributes' => {},
             'associations' => {}
           }
    Change.new(:diff => hash).should be_associations_empty
  end

end