require File.dirname(__FILE__) + '/spec_helper'
require 'pp'

describe Scribe::Change do
  
  it "should report as being empty when there are no attribute or association values" do
    hash = {'attributes' => {}, 'associations' => {'object_names' => {}}}
    
    @change = Scribe::Change.new(:diff => hash)
    
    @change.should be_empty
    
  end
  
end