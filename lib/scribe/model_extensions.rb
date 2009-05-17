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
        
        options.symbolize_keys!
        
        raise 'You must specify the model to store changes in using :as' unless options[:as]
        
        has_many :recorded_changes, :class_name => options[:as], :as => 'model', :order => 'created_at DESC'
        
        association_options = {}
        (options[:associations] || {}).each_pair do |association, attrs|
          association_options[association.to_s] = attrs.map(&:to_s)
        end
        
        self.scribe_options = {
          :attributes => (options[:attributes] || []).map(&:to_s),
          :associations => association_options,
          :storage_model => options[:as].constantize
        }
        
      end
    end

    module InstanceMethods
      
      # Returns a nested hash of values to be diffed or stored
      def recordable_attributes
        data = { 'attributes' => {}, 'associations' => {} }
        self.class.scribe_options[:attributes].each do |attribute|
          value = self.send(attribute)
          data['attributes'][attribute] = value unless value.blank?
        end
        self.class.scribe_options[:associations].each_pair do |association, keys|
          data['associations'][association] = {}
          assoc = self.send(association, true)
          assoc = [assoc] unless assoc.respond_to?(:each)
          assoc.each do |model|
            data['associations'][association][model.id] = {}
            keys.each do |key|
              value = model.send(key)
              data['associations'][association][model.id][key] = value unless value.blank?
            end
          end
        end
        data
      end
      
      # Executes a block, creating a new change object if any changes were made
      # This is the same sa calling cache_recordable_attributes! before a block of code and write_changes!
      # afterwards.
      def recording_changes(attributes={}, &block)
        self.cache_recordable_attributes!
        yield
        self.write_changes!(attributes)
      end
      
      # Saves the result of calling recordable_attributes internally. This must be done before calling write_changes, as
      # that method relied on this stored data to calculate what changes were made.
      def cache_recordable_attributes!
        @cached_recordable_attributes = recordable_attributes
      end
        
      # Created a new change object that encapsulates any applicable changes that were made. Must be called after cache_recordable_attributes!.
      #
      # Additional attributes to be saved into the change object can be passed in as attributes. A common use for this is a user_id to
      # associate the change object with
      def write_changes!(attributes={},&block)
        raise 'Attributes must be cached before calling write_changes!' if @cached_recordable_attributes.nil?
        diff = self.class.diff_attributes(@cached_recordable_attributes, recordable_attributes)
        change = self.class.scribe_options[:storage_model].new_from_attribute_diff(self, diff)
        change.attributes = attributes
        @cached_recordable_attributes = nil
        unless change.empty?
          change.save!
          yield if block_given?
          return true
        end
        false
      end 
      
      # Creates a change object, using totally empty attributes and association as the original state. Only designed to be
      # used when creating the initial change object for a new record.
      def save_state_as_change!(attributes={})
        @cached_recordable_attributes = { 'attributes' => {}, 'associations' => {} }
        self.write_changes!(attributes)
      end
    end

    module DiffMethods
      def diff_attributes(old_attributes, new_attributes)
        
        raise 'diff_attributes requires two diff hashes' if old_attributes.nil? || new_attributes.nil?
        diff = { 'attributes' => { 'new' => {}, 'old' => {}, 'unchanged' => {}  }, 'associations' => {}}
        self.scribe_options[:attributes].each do |key|
          if new_attributes['attributes'][key] == old_attributes['attributes'][key]
            unchanged = new_attributes['attributes'][key]
            diff['attributes']['unchanged'][key] = unchanged unless unchanged.blank?
          else
            diff['attributes']['old'][key] = old_attributes['attributes'][key] unless old_attributes['attributes'][key].blank?
            diff['attributes']['new'][key] = new_attributes['attributes'][key] unless new_attributes['attributes'][key].blank?
          end
        end
        
        %w(new old unchanged).each do |noc|
          diff['attributes'].delete(noc) if diff['attributes'][noc].empty?
        end
        
        self.scribe_options[:associations].each_pair do |association,attrs|
          diff['associations'][association] = {}
          new_attr = new_attributes['associations'][association] || {}
          old_attr = old_attributes['associations'][association] || {}
          
          (new_attr.keys + old_attr.keys).uniq.each do |id|
            diff['associations'][association][id] = {}
            if new_attr[id].blank?
              diff['associations'][association][id]['old'] = old_attr[id]
            elsif old_attr[id].blank?
              diff['associations'][association][id]['new'] = new_attr[id]
            else
              diff['associations'][association][id] = {'old' => {}, 'new' => {}, 'unchanged' => {}}
              attrs.each do |field|
                if new_attr[id][field] == old_attr[id][field]
                  unchanged = new_attr[id][field]
                  diff['associations'][association][id]['unchanged'][field] = unchanged unless unchanged.blank?
                else
                  diff['associations'][association][id]['old'][field] = old_attr[id][field] unless old_attr[id][field].blank?
                  diff['associations'][association][id]['new'][field] = new_attr[id][field] unless new_attr[id][field].blank?
                end
              end
              if diff['associations'][association][id]['new'].empty? && 
                  diff['associations'][association][id]['old'].empty? && 
                  diff['associations'][association][id]['unchanged'].empty?
                diff['associations'][association].delete(id)
              end
              diff['associations'][association][id].delete('new') if diff['associations'][association][id]['new'].empty?
              diff['associations'][association][id].delete('old') if diff['associations'][association][id]['old'].empty?
              diff['associations'][association][id].delete('unchanged') if diff['associations'][association][id]['unchanged'].empty?
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