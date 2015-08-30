require_relative 'sql_object.rb'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.underscore + "s"
  end
end

# provides default values for belongs_to options or parses values from options
# hash
class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options.each do |attr_name, value|
      send("#{attr_name}=", value)
    end
    self.class_name ||= name.to_s.camelcase
    self.foreign_key ||= (name.to_s + "_id").to_sym
    self.primary_key ||= :id
  end
end

# provides default values for has_many options or parses values from options
# hash
class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options.each do |attr_name, value|
      send("#{attr_name}=", value)
    end
    self.class_name ||= name.to_s.singularize.camelcase
    self.foreign_key ||= (self_class_name.underscore.downcase + "_id").to_sym
    self.primary_key ||= :id
  end
end
