select_extra_columns
====================

Enhances the ActiveRecord finders to return join/aggregate/calculated columns along with standard table columns.  

Installation
============
Use either the plugin or the gem installation method depending on your preference. If you're not sure, the plugin method is simpler. 

    ./script/plugin install git://github.com/kandadaboggu/select_extra_column.git 

### Via gem
Add the following to your application's environment.rb:
    config.gem "select_extra_column", :source => "http://gemcutter.org"

Install the gem:
    rake gems:install


Usage
=====

## Getting Started

### Enable select_extra_column in your ActiveRecord model.


    class User < ActiveRecord::Base
 	  select_extra_columns
 	  has_many :posts 
 	  has_one :address
    end

    class Address < ActiveRecord::Base
 	  belongs_to :user 
    end

    class Post < ActiveRecord::Base
 	  belongs_to :user 
    end


### Now return the extra columns in your finders.

    user = User.first(:joins => :address, :select => "*, addresses.street as street",
                    :extra_columns => :street)
    user.city 				# returns the street
	
    users = User.find(:all, :joins => :posts, :select => "users.*, count(posts.id) as post_count",
                    :extra_columns => {:post_count => :integer} )
    users.first.post_count 	# returns the post count

    user = User.first(:joins => :address, :select => "users.*, addresses.street as street, addresses.city as city",
                    :extra_columns => [:street, :city] )
    user.street 			# returns the street
    user.city 				# returns the city

    users = User.all(:joins => :address, :select => "*, addresses.active as active, addresses.city as city",
                    :extra_columns => [:city, [:active, :boolean]]
    users.first.street 		# returns the street
    users.first.active 		# returns true/false

### Input format for `:extra_options` 

Option accepts String/Symbol/Array/Hash as input.

Example:

	#String,Symbol format
	:extra_columns => :first_name    # Single string field: `first_name`
	
	:extra_columns => "first_name"   # Single string field: `first_name`
	
	# Hash format
	:extra_columns => {              # Two string fields and a boolean field
	                       :first_name => :string, 
	                       :last_name  => :string, 
	                       :has_flag   => :boolean
	                  }
	
	:extra_columns => {              # Two string fields and a boolean field
	                       "first_name" => :string, 
	                       "last_name"  => :string, 
	                       "has_flag"   => :boolean
	                  }
	
	# Array format
	:extra_columns => [              # Two string fields and a boolean field
						[:first_name, :string], 
						[:last_name,  :string], 
						[:has_flag,   :boolean]
						]
	
	:extra_columns => [:first_name, :last_name] # Two string fields
	
	:extra_columns => [              # Two string fields and a boolean field
						:first_name, :last_name, # type is inferred as string
						[:has_flag,   :boolean]
						]

### Valid data types of fields in `:extra_columns`   
	:binary
	:boolean
	:date
	:datetime
	:decimal
	:float
	:integer
	:string
	:text
	:time
	:timestamp

Copyright (c) 2010 Kandada Boggu, released under the MIT license

