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
