class Scribe::Change < ActiveRecord::Base
  belongs_to :model, :polymorphic => true
  
  validates_presence_of :model_id
  validates_presence_of :diff
  
  serialize :diff
  
  def self.new_from_attribute_diff(model, diff)
    self.new(:model => model, :diff => diff)
  end

  def save_unless_empty!
    self.save! unless self.empty?
  end

  def empty?
    diff['attributes'].empty? && diff['associations'].all?{|association,values| values.empty?}
  end
  
end