class Scribe::Change < ActiveRecord::Base
  belongs_to :model, :polymorphic => true
  
  validates_presence_of :model_id
  validates_presence_of :diff
  
  def self.new_from_attribute_diff(model, diff)
    self.new(:model => model, :diff => diff.to_yaml)
  end
  
end