require 'rubygems'
require 'spec'
require 'active_record'
require 'active_support'

ROOT       = File.join(File.dirname(__FILE__), '..')
RAILS_ROOT = ROOT

$LOAD_PATH << File.join(ROOT, 'lib')
$LOAD_PATH << File.join(ROOT, 'lib', 'scribe')

require File.join(ROOT, 'lib', 'scribe.rb')

ENV['RAILS_ENV'] ||= 'test'

# FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures") 
config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['RAILS_ENV'] || 'test'])

ActiveRecord::Base.connection.create_table :lhurgoyfs, :force => true do |table|
  table.column :name, :string
  table.column :description, :string
  table.column :power, :integer
  table.column :toughness, :integer
  table.column :created_at, :datetime
  table.column :updated_at, :datetime
end

ActiveRecord::Base.connection.create_table :sharp_claws, :force => true do |table|
  table.column :lhurgoyf_id, :integer
  table.column :length, :integer
  table.column :sharpness, :integer
  table.column :notes, :text
  table.column :created_at, :datetime
  table.column :updated_at, :datetime
end

ActiveRecord::Base.connection.create_table :changes, :force => true do |table|
  table.column :model_id, :integer
  table.column :model_type, :string
  table.column :diff, :text
  table.column :created_at, :datetime
end

class Lhurgoyf < ActiveRecord::Base
  records_changes :attributes => [:name, :description, :power, :toughness],
                  :associations => [:sharp_claws]
  has_many :sharp_claws
end

class SharpClaw < ActiveRecord::Base
  records_changes :attributes => [:length, :sharpness, :notes]
end
