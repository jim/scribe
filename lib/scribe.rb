require 'scribe/model_extensions'
require 'scribe/storage'

module Scribe
  VERSION = "0.1"
  
  def self.record(model, options={}, &block)
    model.cache_recordable_attributes!
    yield model
    model.write_changes!
  end
  
end

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, Scribe::ModelExtensions)
end