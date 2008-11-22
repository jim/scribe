require 'scribe/model_extensions'
require 'scribe/change'

module Scribe
  VERSION = "0.1"
end

# if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, Scribe::ModelExtensions)
# end