require_relative 'db_connection'
require 'active_support/inflector'
require_relative 'searchable'
require_relative 'associatable'

class ActiveModel
  extend Searchable
  extend Associatable

  def self.columns
    return @columns if @columns
    result = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      LIMIT 0
    SQL
    @columns = result.fields.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end

      define_method("#{column}=") do |val|
        self.attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.pluralize.underscore
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT #{self.table_name}.*
      FROM #{self.table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map {|result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT #{self.table_name}.*
      FROM #{self.table_name}
      WHERE #{self.table_name}.id = ?
      LIMIT 1
    SQL

    self.parse_all(results).first
  end

  def initialize(params = {})
    params.each do |key, val|
      key = key.to_sym
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key)
      self.send("#{key}=", val)
    end
  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    self.class.columns.map { |column| self.send(column) }
  end

  def insert
    cols = self.class.columns.drop(1)
    col_names = cols.map(&:to_s).join(", ")
    question_marks = (["?"] * cols.count).join(", ")

    id = DBConnection.execute(<<-SQL, attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
      RETURNING
        id
    SQL

    self.id = id
    self
  end

  def update
    cols = self.class.columns.drop(1)
    values = cols.map { |col| "#{col} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, attribute_values.rotate)
      UPDATE
        #{self.class.table_name}
      SET
        #{values}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
