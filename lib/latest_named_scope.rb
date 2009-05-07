# Copyright 2009 Roger Nesbitt.  Licensed under MIT license.

module IncludeLatestNamedScope
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    #
    # Defines a named_scope that will include the specified has_many association and preload only
    # the most recent child record.
    #
    # The last argument can be a hash with the following options:
    #   :order => :some_field  use a field other than +created_at+ to find the latest record
    #   :name => :scope_name   create a scope name other than "include_latest_" followed by the association's name in the singular
    #
    # Sample usage:
    #
    # class Post < ActiveRecord::Base
    #   has_many :comments
    #   include_latest_named_scope :comments
    #
    #   def self.last_comment_from_all_posts
    #     include_latest_comment.all.collect(&:comments).flatten
    #   end
    # end
    #
    def include_latest_named_scope(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      order = opts[:order] || "created_at"

      args.each do |association|
        single_child_name = association.to_s.singularize
        child_model = single_child_name.camelize.constantize
        parent_key = connection.quote_column_name(child_model.reflect_on_association(name.underscore.to_sym).association_foreign_key)

        table_name = child_model.quoted_table_name
        duplicate = connection.quote_table_name("#{association}_duplicate")

        scope_name = opts[:name] || "include_latest_#{single_child_name}"
        
        named_scope scope_name,
          :include => association,
          :joins => "LEFT JOIN #{table_name} #{duplicate} ON (#{table_name}.#{order} < #{duplicate}.#{order} AND #{table_name}.#{parent_key} = #{duplicate}.#{parent_key})",
          :conditions => "(1 = 1 OR #{table_name}.id IS NOT NULL) AND #{duplicate}.#{primary_key} IS null"
      end
    end
  end
end
