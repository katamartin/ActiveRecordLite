# Active Record Lite

## Summary

A pared down clone of Ruby's Active Record, which represents and accesses data
in the database. Through this implementation, models inherit from the SQLObject
class, thus inheriting its features, including:
  * Saving and updating entries in the database
  * Search for entries in the database using `find` and `where` methods
  * Define `has_many`, `belongs_to`, `has_one_through` associations
  * Inferring conventional association and table parameters, while allowing for
    configuration
  * Uses instance of `SQLite3::Database` to execute queries, updates, and
    insertions

## Convention Over configuration
`
  def self.table_name \n
    @table_name ||= self.to_s.tableize \n
    @table_name \n
  end
`
  A model's `table_name` is inferred using ActiveSupport's `String#tableize`
  method.

  However, a model's table_name may be configured by the user:
`
  def self.table_name=(table_name)
    @table_name = table_name
  end
`

## Screenshots

### Retrieve `all` entries in table
![all]

### Association for a particular entry
![where_and_assoc]

[all]: ./docs/all.png
[where_and_assoc]: ./docs/where_and_assoc.png
