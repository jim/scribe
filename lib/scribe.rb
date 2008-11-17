module Scribe
  
  VERSION = "0.1"
  
  class << self
    def included(base)
      base.extend ClassMethods
    end
  end
  
  module ClassMethods
    
    attr_accessor :scribe_options
    
    def records_changes(options={})
      include InstanceMethods
      extend DiffMethods
      self.scribe_options = {
        :attributes => (options[:attributes] || []).map(&:to_s),
        :associations => (options[:associations] || []).map(&:to_s)
      }
    end
  end
  
  module InstanceMethods
    def record(options={}, &block)
      old_attributes = self.recordable_attributes
      yield
      new_attributes = self.recordable_attributes
      record_changes(diff_attributes(old_attributes, new_attributes))
    end
    
    def recordable_attributes
      data = { :attributes => attributes.delete_if{|k,v| !self.class.scribe_options[:attributes].include?(k)},
               :associations => {} }
      self.class.scribe_options[:associations].each do |association|
        data[:associations][association] = {}
        self.send(association, true).each do |model|
          data[:associations][association][model.id] = model.respond_to?(:recordable_attributes) ? model.recordable_attributes : model.attributes
        end
      end
      data
    end
  end
  
  module DiffMethods
    def diff_attributes(old_attributes, new_attributes) 
      diff = { :attributes => { :old => {}, :new => {} }, :associations => {}}
      self.scribe_options[:attributes].each do |key|
        if new_attributes[:attributes][key] != old_attributes[:attributes][key]
          diff[:attributes][:old][key] = old_attributes[:attributes][key]
          diff[:attributes][:new][key] = new_attributes[:attributes][key]
        end
      end
      self.scribe_options[:associations].each do |association|
        (new_attributes[:associations][association].keys + old_attributes[:associations][association].keys).uniq.each do |id|
          diff[:associations][association][id] = {}
          if !new_attributes[:associations][association][id]
            diff[:associations][association][id][:old] = old_attributes[:associations][association][id]
          elsif !old_attributes[:associations][association][id]
            diff[:associations][association][id][:new] = new_attributes[:associations][association][id]
          else
            diff[:associations][association][id] = { :old => {}, :new => {} }
            old_attributes[:associations][association][id].each do |key, value|
              if new_attributes[:associations][association][id][key] != value
                diff[:associations][association][id][:old][key] = value
                diff[:associations][association][id][:new][key] = new_attributes[:associations][association][key]
              end
            end
          end
        end
      end
      diff
    end
  end
  
end

# if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, Scribe)
# end