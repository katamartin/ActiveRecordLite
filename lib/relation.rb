require_relative 'db_connection'

class Relation
  attr_reader :params, :model_class, :executed, :results
  def initialize(class_name = nil)
    @evaluated = false
    @results = nil
    @model_class = class_name
    @params = {}
  end

  def where(new_params = {})
    raise "Already executed" if executed
    @params = params.merge(new_params)
  end

  def execute_query
    raise "Already executed" if executed
    eqs = params.keys.map { |attr_name| "#{attr_name} = ?" }.join(" AND ")
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{model_class.table_name}
      WHERE
        #{eqs}
    SQL


    @results = results.map { |result| model_class.new(result) }
    @executed = true
  end

  def first
    return results.first if evaluated

    execute_query
    results.first
  end
end
