require_relative 'searchable'
require_relative 'assoc_options'
require 'active_support/inflector'

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name.to_s, options)
    assoc_options[name] = options

    define_method(name) do
      foreign_key = options.foreign_key
      model_class = options.model_class

      model_class.find(self.send("#{foreign_key}"))
    end

  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name.to_s, self.name, options)
    assoc_options[name] = options

    define_method(name) do
      foreign_key = options.foreign_key
      model_class = options.model_class

      model_class.where("#{foreign_key}": self.id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options =
        through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_primary_key = through_options.primary_key
      through_foreign_key = through_options.foreign_key

      source_table = source_options.table_name
      source_primary_key = source_options.primary_key
      source_foreign_key = source_options.foreign_key

      val = self.send(through_foreign_key)
      results = DBConnection.execute(<<-SQL, val)
        SELECT #{source_table}.*
        FROM #{source_table}
        JOIN #{through_table}
        ON #{source_table}.#{source_primary_key} = #{through_table}.#{source_foreign_key}
        WHERE #{through_table}.#{through_primary_key} = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end

  def has_many_through(name, through_name, source_name)
    define_method(name) do

      through_options = self.class.assoc_options[through_name]
      source_options =
        through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_primary_key = through_options.primary_key
      through_foreign_key = through_options.foreign_key

      source_table = source_options.table_name
      source_primary_key = source_options.primary_key
      source_foreign_key = source_options.foreign_key

      case
      when through_options.is_a?(BelongsToOptions) &&
        source_options.is_a?(HasManyOptions)

        val = self.send(through_foreign_key)
        results = DBConnection.execute(<<-SQL, val)
          SELECT #{source_table}.*
          FROM #{source_table}
          JOIN #{through_table}
          ON #{source_table}.#{source_foreign_key} = #{through_table}.#{source_primary_key}
          WHERE #{through_table}.#{through_primary_key} = ?
        SQL

      when through_options.is_a?(HasManyOptions) &&
        source_options.is_a?(BelongsToOptions)

        val = self.id
        results = DBConnection.execute(<<-SQL, val)
          SELECT #{source_table}.*
          FROM #{source_table}
          JOIN #{through_table}
          ON #{source_table}.#{source_primary_key} = #{through_table}.#{source_foreign_key}
          WHERE #{through_table}.#{through_foreign_key} = ?
        SQL

      when through_options.is_a?(HasManyOptions) &&
        source_options.is_a?(HasManyOptions)

        val = self.id
        results = DBConnection.execute(<<-SQL, val)
          SELECT #{source_table}.*
          FROM #{source_table}
          JOIN #{through_table}
          ON #{source_table}.#{source_foreign_key} = #{through_table}.#{source_primary_key}
          WHERE #{through_table}.#{through_foreign_key} = ?
        SQL
      end

      source_options.model_class.parse_all(results)
    end
  end
end
