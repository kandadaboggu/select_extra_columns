select_extra_columns
====================

Enhances the ActiveRecord finders to return join/aggregate/calculated columns along with standard table columns.  

Installation
============
Use either the plugin or the gem installation method depending on your preference. If you're not sure, the plugin method is simpler. 

## As a Plugin

    ./script/plugin install git://github.com/kandadaboggu/select_extra_column.git 

## As a Gem
Add the following to your application's environment.rb:
    config.gem "select_extra_column", :source => "http://gemcutter.org"

Install the gem:
    rake gems:install


Getting Started
===============

## Enable select_extra_column in your ActiveRecord model.


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


## Use the extra columns in your finders.

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


Dynamically added column fields are read only. Any value set to these fields are ignored during save.

    user = User.first(:joins => :address, :select => "*, addresses.street as street",
                    :extra_columns => :street)
    user.city  # => "San Francisco"
    ...
    user.city = "Houston" # change the value
    user.save

    user = User.first(:joins => :address, :select => "*, addresses.street as street",
                    :extra_columns => :street)
    user.city  # => "San Francisco"
    
 
	
### Input format for `:extra_columns` 

This option accepts `String`/`Symbol`/`Array`/`Hash` as input.


#### String,Symbol format
	:extra_columns => :first_name    # Single string field: `first_name`(type is inferred as string)
	
	:extra_columns => "first_name"   # Single string field: `first_name`(type is inferred as string)
	
#### Hash format
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
	
#### Array format
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

## Sharing `extra_columns` definition across finders
You can declare the extra columns in your model and use them across finders
    class User < ActiveRecord::Base
 	  select_extra_columns
 	  
 	  extra_columns :address_info, :street, :city
 	  extra_columns :post_info, [:post_count, :integer], :last_post_at => :datetime
 	  
 	  has_many :posts 
 	  has_one :address
    end

Now `:user_info` and `:post_info` can be used in finders.

    users = User.find(:all, :joins => :posts, :select => "users.*, count(posts.id) as post_count, max(posts.created_at) as last_post_at",
                    :extra_columns => :post_info)

    user = User.first(:joins => :address, :select => "users.*, addresses.street as street, addresses.city as city",
                    :extra_columns => :address_info )

## Naming conflicts
When a symbol/string is passed as input to `:extra_columns` option, the finder uses cached `extra_columns` definition by the given name.
If no definition is found, then finder creates a new `extra_columns` definition with the input as a column.
 
    class User < ActiveRecord::Base
 	  select_extra_columns
 	  
 	  extra_columns :post_count, [:post_count, :integer], :last_post_at => :datetime
 	end

The finder call below,  `post_count` maps on to a column in the select list and a `extra_columns` definition. Finder chooses the `extra_columns` definition. 
    users = User.find(:all, :joins => :posts, :select => "users.*, count(posts.id) as post_count, max(posts.created_at) as last_post_at",
                    :extra_columns => :post_count)


## Valid data types for column fields in `:extra_columns`   
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

