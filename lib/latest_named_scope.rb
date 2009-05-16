# Copyright 2009 Roger Nesbitt.  Licensed under MIT license.

module IncludeLatestNamedScope
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    #
    # Defines a named_scope that, when used, will only load the latest record for each parent key.
    # By default, the latest record is the one with the latest created_at time, but that can be changed.
    #
    # Note!  Currently, if there are two records with the same created_at time, they will both be returned.
    # This should probably be fixed.
    #
    # You must pass the parent key.  All other keys are optional.
    #   :parent => :some_model specifies the parent model
    #   :order => :some_field  use a field other than +created_at+ to find the latest record
    #   :name => :scope_name   name of the scope.  By default it is "latest_only"
    #
    # Sample usage:
    #
    # class Comment < ActiveRecord::Base
    #   belongs_to :post
    #   latest_named_scope :parent => :post
    # end
    #
    # >> Comment.all.collect {|c| [c.post_id, c.created_at.to_s(&:db)]}
    # => [[1, "2007-11-22 11:51:54"], [1, "2007-11-22 12:25:30"], [2, "2007-11-22 21:12:05"]]
    #
    # >> Comment.latest_only.all.collect {|c| [c.post_id, c.created_at.to_s(&:db)]}
    # => [[1, "2007-11-22 12:25:30"], [2, "2007-11-22 21:12:05"]]
    #
    def latest_named_scope(opts)
      raise ArgumentError, "must specify a parent association that this model belongs_to" unless opts[:parent]
      parent = opts[:parent]
      order = opts[:order] || "created_at"

      parent_key = connection.quote_column_name(reflect_on_association(parent).association_foreign_key)
      table_name = quoted_table_name
      duplicate = connection.quote_table_name("#{name.underscore}_duplicate")

      scope_name = opts[:name] || "latest_only"
      
      named_scope scope_name,      
        :joins => "LEFT JOIN #{table_name} #{duplicate} ON (#{table_name}.#{order} < #{duplicate}.#{order} AND #{table_name}.#{parent_key} = #{duplicate}.#{parent_key})",
        :conditions => "#{duplicate}.#{primary_key} IS null"
    end
  end
end
