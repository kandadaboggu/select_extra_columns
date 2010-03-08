module SelectExtraColumns
  def select_extra_columns
    return if self.respond_to?(:find_every_with_extra_columns)
    self.extend ClassMethods
  end

  module ClassMethods    
    def self.extended(active_record_class)
      class << active_record_class
        alias_method_chain :find_every, :extra_columns
      end
      active_record_class.class_inheritable_array(:klasses_with_extra_columns)
      active_record_class.klasses_with_extra_columns ||= []
    end
    
    def find_every_with_extra_columns options
      extra_columns = options.delete(:extra_columns)
      return find_every_without_extra_columns options if extra_columns.empty? 
      klass_with_extra_columns(extra_columns).send(:find_every, options)   
    end
    
    def validate_find_options(options)
      extra_columns = options.delete(:extra_columns)
      super
    ensure
      options[:extra_columns]= extra_columns  if extra_columns
    end
        
    def klass_with_extra_columns extra_columns
      # look for the class in the cache.
      self.klasses_with_extra_columns.select do | class_details |
        return class_details[1] if class_details[0] == extra_columns 
      end
      # load the column definition
      cols, cols_hash = self.columns, self.columns_hash
      self.clone.tap do |klass|
        prepare_extra_column_klass(klass, cols, cols_hash, extra_columns)
      end
    end
    
    def prepare_extra_column_klass klass, cols, cols_hash, extra_columns
        class << klass
          attr_accessor :extra_columns
          # over ride readonly_attributes to include the extra_columns
          def readonly_attributes
            (super || []) + self.extra_columns.keys(&:to_s)
          end
        end
        #Make new copy of @columns, and @columns_hash and @extra_columns variables
        klass.instance_variable_set("@columns", cols.clone)   
        klass.instance_variable_set("@columns_hash", cols_hash.clone)
        klass.extra_columns = extra_columns.clone
        extra_columns.each do |col_name, col_type|
          # add the new column to `columns` list and `columns_hash` hash.
          klass.columns << (klass.columns_hash[col_name.to_s] = ActiveRecord::ConnectionAdapters::Column.new(col_name.to_s, nil, col_type.to_s))
        end
        self.klasses_with_extra_columns = [[extra_columns, klass]] # add the class to the cache
    end
  end
end