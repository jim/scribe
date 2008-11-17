require File.dirname(__FILE__) + '/spec_helper'

describe Lhurgoyf do
  
  it "should have scribe options defined on its class" do
    Lhurgoyf.scribe_options.should == { :attributes => [ 'name', 'description', 'power', 'toughness' ], :associations => [ 'sharp_claws' ] }
  end
  
  it "should know which attributes are recordable" do
    lhurgoyf = Lhurgoyf.new(:name => 'Scary Lhurgoyf',
                            :description => 'A Terrifying Beast',
                            :power => 5,
                            :toughness => 6)
    lhurgoyf.recordable_attributes[:attributes].should == { 'name' => 'Scary Lhurgoyf',
                                                            'description' => 'A Terrifying Beast',
                                                            'power' => 5,
                                                            'toughness' => 6 }
  end
  
  it "should track changes to attributes" do
    old_attributes = { 'name' => 'Scary Lhurgoyf',
                       'description' => nil,
                       'power' => 5,
                       'toughness' => 6 }
    new_attributes = { 'name' => 'Not So Scary Lhurgoyf',
                       'description' => 'A milder beast',
                       'power' => 1,
                       'toughness' => 2 }
    
    expected_result = { :new => new_attributes, :old => old_attributes}

    Lhurgoyf::diff_attributes({:attributes => old_attributes, :associations => { 'sharp_claws' => {} }},
                              {:attributes => new_attributes, :associations => { 'sharp_claws' => {} }})[:attributes].should eql(expected_result)
  end
  
  it "should know which associations are trackable" do
    lhurgoyf = Lhurgoyf.new
    lhurgoyf.recordable_attributes[:associations].should == {'sharp_claws' => {} }
  end
  
  it "should track changes to associations with defined attributes to track" do
    sharp_claw_attributes = {'length' => 8, 'sharpness' => 3, 'notes' => "Somewhat dangerous"}
    
    lhurgoyf = Lhurgoyf.create!
    sharp_claw = lhurgoyf.sharp_claws.create!(sharp_claw_attributes)
    lhurgoyf.recordable_attributes[:associations]['sharp_claws'][sharp_claw.id][:attributes].should == sharp_claw_attributes
  end
  
end