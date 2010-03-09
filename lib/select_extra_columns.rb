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
      return find_every_without_extra_columns options if extra_columns.nil? 
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
      self.klasses_with_extra_columns.find{|k| k.extra_columns == extra_columns} or
        prepare_extra_column_klass(extra_columns)
    end
    
    def prepare_extra_column_klass extra_columns
      extra_column_definitions = prepare_extra_column_definitions(extra_columns)
      return self if extra_column_definitions.empty?      
      cols, cols_hash = self.columns, self.columns_hash
      self.clone.tap do |klass|
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
        klass.extra_columns = extra_columns.is_a?(Symbol) ? extra_columns : extra_columns.clone
        extra_column_definitions.each do |ecd|
          klass.columns << (klass.columns_hash[ecd.name] = ecd)
        end
        self.klasses_with_extra_columns = [klass] # add the class to the cache
      end
    end
    
    def prepare_extra_column_definitions extra_columns
      extra_columns = [extra_columns] if extra_columns.is_a?(Symbol) or extra_columns.is_a?(String) 
      extra_columns = extra_columns.to_a if extra_columns.is_a?(Hash)
      return [] unless extra_columns.is_a?(Array)
      [].tap do |result|
        extra_columns.each do |col_detail|
          col_detail = [col_detail] if col_detail.is_a?(Symbol) or col_detail.is_a?(String)
          next unless col_detail.is_a?(Array)
          col_name, col_type = col_detail[0], (col_detail[1] || "string") 
          # ignore if not valid type
          next unless [String, Symbol].include?(col_name.class) and [String, Symbol].include?(col_type.class)
          result << ActiveRecord::ConnectionAdapters::Column.new(col_name.to_s, nil, col_type.to_s)
        end
      end
    end
  end
end