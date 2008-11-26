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
        
        association_options = {}
        (options[:associations] || {}).each_pair do |association, attrs|
          association_options[association.to_s] = attrs.map(&:to_s)
        end
        
        self.scribe_options = {
          :attributes => (options[:attributes] || []).map(&:to_s),
          :associations => association_options
        }
        
      end
    end

    module InstanceMethods
      def recordable_attributes
        data = { 'attributes' => {}, 'associations' => {} }
        self.class.scribe_options[:attributes].each do |attribute|
          data['attributes'][attribute] = self.send(attribute)
        end
        self.class.scribe_options[:associations].each_pair do |association, keys|
          data['associations'][association] = {}
          self.send(association, true).each do |model|
            data['associations'][association][model.id] = {}
            keys.each do |key|
              data['associations'][association][model.id][key] = model.send(key)
            end
          end
        end
        data
      end
      
      def cache_recordable_attributes!
        @cached_recordable_attributes = recordable_attributes
      end
        
      def write_changes!(&block)
        raise 'Attributes must be cached before calling write_changes!' if @cached_recordable_attributes.nil?
        diff = self.class.diff_attributes(@cached_recordable_attributes, recordable_attributes)
        change = Scribe::Change.new_from_attribute_diff(self, diff)
        unless change.empty?
          change.save!
          yield if block_given?
        end
        @cached_recordable_attributes = nil
      end 
      
      def save_state_as_change
        @cached_recordable_attributes = { 'attributes' => {}, 'associations' => {} }
        self.write_changes!
      end
    end

    module DiffMethods
      def diff_attributes(old_attributes, new_attributes)
        raise 'diff_attributes requires two diff hashes' if old_attributes.nil? || new_attributes.nil?
        diff = { 'attributes' => {}, 'associations' => {}}
        self.scribe_options[:attributes].each do |key|
          if new_attributes['attributes'][key] != old_attributes['attributes'][key]
            diff['attributes']['old'] ||= {}
            diff['attributes']['new'] ||= {}            
            diff['attributes']['old'][key] = old_attributes['attributes'][key]
            diff['attributes']['new'][key] = new_attributes['attributes'][key]
          end
        end
        self.scribe_options[:associations].each_pair do |association,attrs|
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
              old_attr[id].each do |key, value|
                if new_attributes['associations'][association][id][key] != value
                  diff['associations'][association][id] ||= {'old' => {}, 'new' => {}}  
                  diff['associations'][association][id]['old'][key] = value
                  diff['associations'][association][id]['new'][key] = new_attr[key]
                end
              end
            end
          end
          diff['associations'][association].each_key do |id|
            diff['associations'][association].delete(id) if diff['associations'][association][id].empty?
          end
        end
        diff
      end
    end

  end
end