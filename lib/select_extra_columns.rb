module SelectExtraColumns
  def select_extra_columns
    return if self.respond_to?(:find_every_with_extra_columns)
    self.extend ClassMethods
  end

  module ClassMethods    
    def self.extended(active_record_class)
      class << active_record_class
        class_inheritable_array(:klasses_with_extra_columns)
        alias_method_chain :find_every, :extra_columns
      end
    end
    
    def find_every_with_extra_columns options
      extra_columns = options.delete(:extra_columns)
      return super if extra_columns.empty? 
      klass_with_extra_columns(extra_columns).find_every(options)   
    end
    
    def validate_find_options(options)
      extra_columns = options.delete(:extra_columns)
      super
    ensure
      options[:extra_columns]= extra_columns  if extra_columns
    end
        
    def klass_with_extra_columns extra_columns
      # look for the class in the cache.
      p "1.0"
      self.klasses_with_extra_columns.select do | class_details |
        return class_details[1] if class_details[0] == extra_columns 
      end
      p "1.1"
      self.columns # load the column definition
      self.clone.tap do |klass|
        extra_columns.each do |col_name, col_type|
          # add the new column to `columns` list and `columns_hash` hash.
          klass.columns << (klass.columns_hash[col_name.to_s] = ActiveRecord::ConnectionAdapters::Column.new(col_name.to_s, nil, col_type.to_s))
        end
        self.klasses_with_extra_columns = [[extra_columns, klass]] # add the class to the cache
      end
    end
  end
end