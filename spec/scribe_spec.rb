require File.dirname(__FILE__) + '/spec_helper'
require 'pp'

describe Lhurgoyf do
  
  it "should have scribe options defined on its class" do
    Lhurgoyf.scribe_options.should == { :attributes => [ 'name', 'description', 'power', 'toughness' ],
                                        :associations => { 'sharp_claws' => %w(length sharpness notes) },
                                        :storage_model => Change }
  end
  
  it "should know which attributes are recordable" do
    lhurgoyf = Lhurgoyf.new(:name => 'Scary Lhurgoyf',
                            :description => 'A Terrifying Beast',
                            :power => 5,
                            :toughness => 6)
    lhurgoyf.recordable_attributes['attributes'].should == { 'name' => 'Scary Lhurgoyf',
                                                            'description' => 'A Terrifying Beast',
                                                            'power' => 5,
                                                            'toughness' => 6 }
  end
  
  it "should track changes to attributes" do
    old_attributes = { 'name' => 'Scary Lhurgoyf',
                       'description' => nil,
                       'power' => 5,
                       'toughness' => 2 }
    new_attributes = { 'name' => 'Not So Scary Lhurgoyf',
                       'description' => 'A milder beast',
                       'power' => 1,
                       'toughness' => 2 }
    
    expected_result = { 'new' => { 'name' => 'Not So Scary Lhurgoyf',
                                   'description' => 'A milder beast',
                                   'power' => 1},
                        'unchanged' => {
                          'toughness' => 2
                        },
                        'old' => { 'name' => 'Scary Lhurgoyf',
                                   'power' => 5}
                      }

    diff = Lhurgoyf::diff_attributes({'attributes' => old_attributes, 'associations' => { 'sharp_claws' => {} }},
                                     {'attributes' => new_attributes, 'associations' => { 'sharp_claws' => {} }})

    diff['attributes'].should eql(expected_result)
    
  end
  
  it "should know which associations are trackable" do
    lhurgoyf = Lhurgoyf.new
    lhurgoyf.recordable_attributes['associations'].should == {'sharp_claws' => {} }
  end
  
  it "should track changes to associations with defined attributes to track" do
    sharp_claw_attributes = {'length' => 8, 'sharpness' => 3, 'notes' => "Somewhat dangerous"}
    
    lhurgoyf = Lhurgoyf.create!
    sharp_claw = lhurgoyf.sharp_claws.create!(sharp_claw_attributes)
    lhurgoyf.recordable_attributes['associations']['sharp_claws'][sharp_claw.id].should == sharp_claw_attributes
  end
  
  it "should track the addition of new members to associations" do
    sharp_claw_attributes = {'length' => 8, 'sharpness' => 3, 'notes' => "Somewhat dangerous"}
    
    lhurgoyf = Lhurgoyf.create!
    before_attributes = lhurgoyf.recordable_attributes
    sharp_claw = lhurgoyf.sharp_claws.create!(sharp_claw_attributes)
    after_attributes = lhurgoyf.recordable_attributes
    
    expected = {'length' => 8, 'sharpness' => 3, 'notes' => 'Somewhat dangerous'}

    result = Lhurgoyf::diff_attributes(before_attributes, after_attributes)
    
    result['associations']['sharp_claws'][sharp_claw.id]['new'].should == expected
    result['associations']['sharp_claws'][sharp_claw.id]['old'].should be_nil
  end

  it "should track the removal of members from associations" do
    sharp_claw_attributes = {'length' => 8, 'sharpness' => 3, 'notes' => "Somewhat dangerous"}
    
    lhurgoyf = Lhurgoyf.create!
    sharp_claw = lhurgoyf.sharp_claws.create!(sharp_claw_attributes)
    before_attributes = lhurgoyf.recordable_attributes
    lhurgoyf.sharp_claws.delete(sharp_claw)
    after_attributes = lhurgoyf.recordable_attributes
    
    expected = {'length' => 8, 'sharpness' => 3, 'notes' => 'Somewhat dangerous'}
    
    result = Lhurgoyf::diff_attributes(before_attributes, after_attributes)
    
    result['associations']['sharp_claws'][sharp_claw.id]['old'].should == expected
    result['associations']['sharp_claws'][sharp_claw.id]['new'].should be_nil
  end
  
  it "should track changes made to members of an associations" do
    sharp_claw_attributes = {'length' => 8, 'sharpness' => 3, 'notes' => "Somewhat dangerous"}
    
    lhurgoyf = Lhurgoyf.create!
    sharp_claw = lhurgoyf.sharp_claws.create!(sharp_claw_attributes)
    before_attributes = lhurgoyf.recordable_attributes
    sharp_claw.update_attributes('length' => 15, 'notes' => '')
    after_attributes = lhurgoyf.recordable_attributes
    
    expected = {'new' => {'length' => 15},
                'old' => {'length' => 8, 'notes' => 'Somewhat dangerous'},
                'unchanged' => {'sharpness' => 3}}
    
    result = Lhurgoyf::diff_attributes(before_attributes, after_attributes)
    
    result['associations']['sharp_claws'][sharp_claw.id].should == expected
  end
  
  it "save_state_as_change should create a change object" do
    lambda {
      lhurgoyf = Lhurgoyf.create(:name => 'Scary Lhurgoyf',
                                 :description => 'A Terrifying Beast',
                                 :power => 5,
                                 :toughness => 6)
      lhurgoyf.save_state_as_change!
    }.should change(Change, :count).by(1)
  end
  
  it "should create change objects" do
    lhurgoyf = Lhurgoyf.create(:name => 'Scary Lhurgoyf',
                               :description => 'A Terrifying Beast',
                               :power => 5,
                               :toughness => 6)
    lambda {
      lhurgoyf.cache_recordable_attributes!
      lhurgoyf.description = 'Native to Dominaria. Large, reptilian creatures, Lhurgoyf are primarily scavengers.'
      lhurgoyf.write_changes!
    }.should change(Change, :count).by(1)
  end
  
end