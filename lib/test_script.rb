require 'json'
require 'pry-byebug'

class Person
  attr_accessor :name, :age

  def initialize(name, age)
    @name = name
    @age = age
  end

  def to_json
    JSON.dump({
      :name => @name,
      :age => @age
    })
  end

  def self.from_json(string)
    data = JSON.load string
    self.new(data['name'], data['age'])
  end
end

binding.pry

puts "End of test"