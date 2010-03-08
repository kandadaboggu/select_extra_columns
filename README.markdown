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

    users = User.find(:all, :joins => :posts, :select => "users.*, count(posts.id) as post_count",
                    :extra_column => {:post_count => :integer} )
    users.first.post_count # returns the post count

    users = User.find(:all, :joins => :address, :select => "users.*, addresses.street as street, addresses.city as city",
                    :extra_column => {:street => :string, :city => :string } )
    users.first.street # returns the street
    users.first.city # returns the city



Copyright (c) 2010 Kandada Boggu, released under the MIT license

