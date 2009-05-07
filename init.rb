require 'latest_named_scope'

ActiveRecord::Base.class_eval do
  include IncludeLatestNamedScope
end
