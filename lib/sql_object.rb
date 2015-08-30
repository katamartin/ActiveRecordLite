require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  # returns table's column names as array of symbols
  def self.columns
    return @columns if @columns
    data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns = data.first.map(&:to_sym)
  end

  # defines getter and setter methods for each column, storing data in
  # attributes hash
  def self.finalize!
    columns.each do |column|
      define_method("#{column}") do
        attributes[column]
      end
      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
    @table_name
  end

  # queries the db, turning all rows of data into instances of SQLObjects
  # using parse_all
  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  # parse_all instantiates instances of SQLObjects, passing in attributes hash
  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  # returns single instance of SQLObject matching id, otherwise returns nil
  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
      LIMIT
        1
    SQL

    return nil if result.empty?

    self.new(result.first)
  end

  # constructs db query for rows that match params, returning SQLObjects or an
  # empty array
  def self.where(params)
    eqs = params.keys.map { |attr_name| "#{attr_name} = ?" }.join(" AND ")
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{eqs}
    SQL

    self.parse_all(results)
  end

  # takes an array of params, calling appropriate attribute setter methods
  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name_sym = attr_name.to_sym

      unless self.class.columns.include?(attr_name_sym)
        raise "unknown attribute \'#{attr_name_sym}\'"
      end
      attr_setter = (attr_name.to_s + "=").to_sym
      send(attr_setter, value)
    end
  end

  # instantiates or returns attributes hash
  def attributes
    @attributes ||= {}
  end

  # returns array of column values
  def attribute_values
    self.class.columns.map { |column| send(column) }
  end

  # adds row to table with attributes matching instance of SQLObject, updating
  # the instance with the row id
  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.length).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  # sets all column values in db equal to those in db for an instance that has
  # been saved to db
  def update
    eqs = self.class.columns.map { |column| "#{column} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{eqs}
      WHERE
        id = ?
    SQL
  end

  # updates or inserts row depending on whether or not model has been persisted
  # to db
  def save
    id ? update : insert
  end

  # uses values in options hash to call model_class#where passing in foreign_key,
  # to return an instance of model_class or nil
  def self.belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name.to_s) do
      model_class = options.model_class
      f_key_value = self.send(options.foreign_key)
      model_class.where(options.primary_key => f_key_value).first
    end
    assoc_options[name] = options
  end

  # uses values in options hash to call model_class#where passing in foreign_key,
  # to return an array of instances of model_class
  def self.has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name.to_s) do
      model_class = options.model_class
      p_key_value = self.send(options.primary_key)
      model_class.where(options.foreign_key => p_key_value)
    end
  end

  # returns/initializes a hash which saves assocations
  def self.assoc_options
    @assoc_options ||= {}
  end

  # uses existing associations to make a join query for row in source_table,
  # making a function that returns an instance of model_class
  def self.has_one_through(name, through_name, source_name)
    define_method(name.to_s) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      model_class = source_options.model_class
      source_table = model_class.table_name
      through_table = through_options.model_class.table_name

      result = DBConnection.execute(<<-SQL)
        SELECT
          #{source_table}.*
        FROM
          #{source_table}
        JOIN
          #{through_table}
        ON
          #{source_table}.#{source_options.primary_key} =
          #{through_table}.#{source_options.foreign_key}
        JOIN
          #{self.class.table_name}
        ON
          #{through_table}.#{through_options.primary_key} =
          #{self.class.table_name}.#{through_options.foreign_key}
        WHERE
          #{self.class.table_name}.id = #{self.id}
      SQL

      model_class.new(result.first)
    end
  end
end
