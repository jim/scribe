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

  # Returns whether this change object represents the creation of a record
  def creation?
    self.diff['attributes']['new'] && !self.diff['attributes']['old']
  end

  # Returns whether this change object represents the destruction of a record
  def destruction?
    self.diff['attributes']['old'] && !self.diff['attributes']['new']
  end
  
  # Returns whether this change object represents the update of an object or its associations
  def modification?
    !self.creation? && !self.destruction?
  end
  
  # Returns whether the attribute attribute_name was altered as a part of this change
  def attribute_changed?(attribute_name)
    (self.diff['attributes']['new']||{})[attribute] != (self.diff['attributes']['old']||{})[attribute]
  end
  
  # Returns whether the association attribute_name was altered as a part of this change
  def association_changed?(associtaion_name) # :nodoc:
    raise 'Not implemented!'
  end

end