module Scribe
  module ModelExtensions
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      attr_accessor :scribe_options

      def records_changes(options={})
        include InstanceMethods
        extend DiffMethods
        
        after_create :save_state_as_change
        
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
        record_change(self.class.diff_attributes(old_attributes, new_attributes))
      end

      def record_change(attributes)
        Scribe::Change.create_from_attribute_diff(self, attributes)
      end

      def recordable_attributes
        data = { 'attributes' => attributes.delete_if{|k,v| !self.class.scribe_options[:attributes].include?(k)},
                 'associations' => {} }
        self.class.scribe_options[:associations].each do |association|
          data['associations'][association] = {}
          self.send(association, true).each do |model|
            data['associations'][association][model.id] = model.respond_to?(:recordable_attributes) ? model.recordable_attributes : model.attributes
          end
        end
        data
      end
      
      def save_state_as_change
        record_change(self.class.diff_attributes({'attributes' => {}, 'associations' => {}}, self.recordable_attributes))
      end
    end

    module DiffMethods
      def diff_attributes(old_attributes, new_attributes)
        diff = { 'attributes' => { 'old' => {}, 'new' => {} }, 'associations' => {}}
        self.scribe_options[:attributes].each do |key|
          if new_attributes['attributes'][key] != old_attributes['attributes'][key]
            diff['attributes']['old'][key] = old_attributes['attributes'][key]
            diff['attributes']['new'][key] = new_attributes['attributes'][key]
          end
        end
        self.scribe_options[:associations].each do |association|
          diff['associations'][association] = {}
          new_attr = new_attributes['associations'][association] || {}
          old_attr = old_attributes['associations'][association] || {}
          (new_attr.keys + old_attr.keys).uniq.each do |id|
            diff['associations'][association][id] = {}
            if !new_attr[id]
              diff['associations'][association][id]['old'] = old_attr[id]
            elsif !old_attr[id]
              diff['associations'][association][id]['new'] = new_attr[id]
            else
              diff['associations'][association][id] = { 'old' => {}, 'new' => {} }
              old_attr[id].each do |key, value|
                if new_attributes['associations'][association][id][key] != value
                  diff['associations'][association][id]['old'][key] = value
                  diff['associations'][association][id]['new'][key] = new_attr[key]
                end
              end
            end
          end
        end
        diff
      end
    end

  end
end