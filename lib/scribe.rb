require 'scribe/model_extensions'
require 'scribe/change'

module Scribe
  VERSION = "0.1"
  
  def self.record(model, options={}, &block)
    old_attributes = model.recordable_attributes
    yield model
    new_attributes = model.recordable_attributes
    Scribe::Change.new_from_attribute_diff(model, model.class.diff_attributes(old_attributes, new_attributes))
  end
  
end

# if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, Scribe::ModelExtensions)
# end