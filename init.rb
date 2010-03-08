require File.dirname( __FILE__ ) + "/lib/select_extra_columns"

ActiveRecord::Base.send(:extend, SelectExtraColumns) unless ActiveRecord::Base.respond_to?(:select_extra_columns) 
