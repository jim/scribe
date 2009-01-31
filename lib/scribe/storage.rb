module Scribe::Storage
  
  def self.included(base)
    base.class_eval do
      belongs_to :model, :polymorphic => true

      validates_presence_of :model_id
      validates_presence_of :diff

      serialize :diff
      
      def self.new_from_attribute_diff(model, diff)
        self.new(:model => model, :diff => diff)
      end
      
    end
  end

  def save_unless_empty!
    self.save! unless self.empty?
  end

  def attributes_empty?
    diff['attributes']['new'].nil? && diff['attributes']['old'].nil?
  end
  
  def associations_empty?
    !diff['associations'].any? do |association,values|
      values.any? do |key, change|
        !change['new'].blank? || !change['old'].blank?
      end
    end
  end
  
  def empty?
    attributes_empty? && associations_empty?
  end

end