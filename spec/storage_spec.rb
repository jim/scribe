require File.dirname(__FILE__) + '/spec_helper'

describe Change do
  
  it "reports being empty when there are no attribute values" do
    hash = {'attributes' => {}, 'associations' => {}}
    Change.new(:diff => hash).should be_attributes_empty
  end
  
  it "reports being not empty when there are attribute values" do
    hash = {'attributes' => {
      'new' => {
        'name' => 'facemask'
      }
    }, 'associations' => {}}
    Change.new(:diff => hash).should_not be_attributes_empty
  end
  
  it "reports being not empty when there are association values" do
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
  
  it "reports being empty when there are association values" do
    hash = { 'attributes' => {},
             'associations' => {}
           }
    Change.new(:diff => hash).should be_associations_empty
  end

  it "knows it represents an object creation" do
    hash = { 'attributes' => {
                'new' => { 'one' => 'two'}
           },
             'associations' => {}
           }
    Change.new(:diff => hash).should be_creation
    Change.new(:diff => hash).should_not be_destruction
    Change.new(:diff => hash).should_not be_modification
  end
  
  it "knows it represents an object destruction" do
    hash = { 'attributes' => {
                'old' => { 'one' => 'two'}
           },
             'associations' => {}
           }
    Change.new(:diff => hash).should_not be_creation
    Change.new(:diff => hash).should be_destruction
    Change.new(:diff => hash).should_not be_modification
  end

  it "knows it represents an object destruction" do
    hash = { 'attributes' => {
                'new' => { 'one' => 'two' },
                'old' => { 'one' => 'two' }
           },
             'associations' => {}
           }
    Change.new(:diff => hash).should_not be_creation
    Change.new(:diff => hash).should_not be_destruction
    Change.new(:diff => hash).should be_modification
  end

end