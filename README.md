# Active Record Lite

## Summary

A pared down clone of Rails' ActiveRecord::Base class, which represents and
accesses data in the database. Through this implementation, models inherit from
the SQLObject class, thus inheriting its features, including:
  * Saving and updating entries in the database
  * Search for entries in the database using `find` and `where` methods
  * Define `has_many`, `belongs_to`, `has_one_through` associations
  * Inferring conventional association and table parameters, while allowing for
    configuration
  * Uses instance of `SQLite3::Database` to execute queries, updates, and
    insertions

## Convention Over configuration
```
def self.table_name
  @table_name ||= self.to_s.tableize
  @table_name
end
```
  A model's `table_name` is inferred using ActiveSupport's `String#tableize`
  method.

  However, a model's `table_name` may be configured by the user:
```
def self.table_name=(table_name)
  @table_name = table_name
end
```

## Query Execution

Using `SQLite3::Database`'s `#execute` method and a heredoc with interpolated
query parameters, the database is queried for entries with column entries
matching each of the key-value pairs in the params hash:
```
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
```

## Screenshots

### Retrieve `all` entries in table
![all]

### Association for a particular entry
![where_and_assoc]

[all]: ./docs/all.png
[where_and_assoc]: ./docs/where_and_assoc.png
