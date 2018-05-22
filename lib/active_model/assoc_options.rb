require 'active_support/inflector'

class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = "#{name}_id".to_sym
    self.primary_key = :id
    self.class_name = name.singularize.camelcase

    options.each do |option, val|
      self.send("#{option}=", val)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.primary_key = :id
    self.foreign_key = "#{self_class_name.downcase}_id".to_sym
    self.class_name = name.singularize.camelcase

    options.each do |option, val|
      self.send("#{option}=", val)
    end
  end
end
