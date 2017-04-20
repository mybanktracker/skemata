# skemata

A lightweight schema.org object DSL written in Ruby. This library is currently under active development and is missing many features, including validation. See the [contributing](#contributing) section for more information. 

[![Code Climate](https://codeclimate.com/github/mybanktracker/skemata.png)](https://codeclimate.com/github/mybanktracker/skemata) ![CircleCI](https://circleci.com/gh/mybanktracker/skemata.svg?style=shield&circle-token=11b5d953bf45ab8237fe2eb5091a2c320c358417) [![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/mybanktracker/skemata/master) [![Gem Version](https://badge.fury.io/rb/skemata.svg)](https://badge.fury.io/rb/skemata)



## Getting Started
Developed against MRI 2.4.0

Add the following line to your `Gemfile`:
```ruby
gem 'skemata'
```

...or this to your `*.gemspec`:
```ruby
gem.add_dependency 'skemata'
```

...and then `bundle`

## Basic Usage
Invoke `Skemata.draw` with a [schema.org](http://schema.org/docs/schemas.html) type and a PORO that you wish to serialize. If an attribute isn't present, it will default to `null`. Provide a block to an attribute key to draw a child object. That's it!

```ruby
require 'skemata'

schema_json = Skemata.draw :Thing, Dog.last do
  name
  description
  # You can also provide any kind of Ruby PORO 
  some_custom_attribute_not_in_the_object 'woop woop'
end
```

`schema_json` looks like this: 
```json
{
  "@type": "Thing",
  "@context": "https://schema.org",
  "name": "Fido",
  "description": "Cute and adorable!",
  "some_custom_attribute_not_in_the_object": "woop woop"
}
```

## Advanced Usage

### Defining attributes explicitly

- `different_key :attribute_name_on_object` can be used to specify a different field name in the output JSON (for presentation), while `:attribute_name_on_object` will be the attribute that is retrieved from the object being serialized. 

```ruby
car = OpenStruct.new(
  brand: 'Mercedes-Benz',
  model: 'E550',
  next_model_up: OpenStruct.new(brand: 'Mercedes-Benz', model: 'E63 AMG')
)

car_json = Skemata.draw :Vehicle, car do
  brand_name :brand
  model
  next_model_up :Vehicle, :next_model_up do 
    model
  end
end
```

`car_json` looks like this:

```json
{
  "@type": "Vehicle",
  "@context": "https://schema.org",
  "brand_name": "Mercedes-Benz",
  "model": "E550",
  "next_model_up": {
    "@type": "Vehicle",
    "model": "E63 AMG"
  }
}
```

### Resolving attributes implicitly
After defining a few objects, it may become apparent that a lot of the schema entries for keys may match attributes on your objects. Skemata can infer field names by using the schema object type or the field name. 

#### Fields
- `attribute_name` is short for `attribute_name :attribute_name`. If these two match, the `:attribute_name` symbol does not need to be specified.

#### Objects
```ruby
object_key :Type, :attribute_key do 
  # attributes
end
```

Shown above is the explicit way to specify a new child object with `object_key` under the parent (`:attribute_key` is the key containing another object to serialize in the block provided), with type `:Type`. It has happened frequently that either the `object_key` or `:Type` are actually fields in objects that we wish to serialize. The DSL will attempt to resolve both `object_key` and `:Type` by seeing if the `root_object` has either attribute before falling back on the explicit definition of `:attribute_key` if present. 

##### Even less explicit!
If you know that the `root_object` has an attribute with the same name as `:type`, you do not need to provide any other arguments (other than the block).

```ruby
object_key :type do 
  # attributes
end
```

### Hashes
Specify attributes as Hash keys.

```ruby
Skemata.draw :Foo, { bar: 'baz' } do
  bar
  bar_with_another_name :bar
end
```

```json
{"@type":"Foo","@context":"https://schema.org","bar":"baz","bar_with_another_name":"baz"}
```

### Distant attributes
Sometimes it is necessary to retrieve attributes from relational data (e.g. an `ActiveRecord` model) without serializing the whole object as a new child. Assuming a `Student` model with a `Parent` that has a `name` field. 

```ruby
Skemata.draw :Person, Student.last do
  parent_name nested(:parent, :name)
end
```

```json
{"@type":"Person","@context":"https://schema.org","parent_name":"Some Name"}
```

#### Applying transformations
If this was not already apparent, since we effectively fold into one object for presentation, you can use any method that each successive object will respond to. Using the previous example, it would be valid to do this:

```ruby
nested(:parent, :name, :upcase)
```

## Contributing
This library is being built incrementally with features that are of immediate need. That being said, there is a plan to build:
- schema.org type validations
- Mapping support
	- Define a map for a certain object type and automatically marshal those objects without explicitly drawing it each time

### How to contribute
- Fork
- Make a new branch
- Write tests / ensure there are no linting errors
- Pull request

## Credits
Copyright (c) [David Stancu](https://davidstancu.me), contributors, MBTMedia LLC 2017.

[MIT License](https://github.com/mybanktracker/skemata/blob/master/LICENSE.txt)
