module SelectExtraColumns
  def select_extra_columns
    return if self.respond_to?(:find_every_with_extra_columns)
    self.extend ClassMethods
  end

  module ClassMethods    
    def self.extended(active_record_class) #:nodoc:
      class << active_record_class
        alias_method_chain :find_every, :extra_columns
        alias_method_chain :find_by_sql,:extra_columns
      end
      active_record_class.class_inheritable_array(:klasses_with_extra_columns)
      active_record_class.klasses_with_extra_columns ||= []
    end
    
    def find_every_with_extra_columns options #:nodoc:
      extra_columns = options.delete(:extra_columns)
      return find_every_without_extra_columns(options) if extra_columns.nil? 
      find_or_create_extra_columns_class(extra_columns).send(:find_every, options)   
    end
    
    def find_by_sql_with_extra_columns sql, options={}
      extra_columns = options.delete(:extra_columns)
      return find_by_sql_without_extra_columns(sql) if extra_columns.nil? 
      find_or_create_extra_columns_class(extra_columns).send(:find_by_sql, sql)         
    end
    
    def validate_find_options(options) #:nodoc:
      extra_columns = options.delete(:extra_columns)
      super
    ensure
      options[:extra_columns]= extra_columns  if extra_columns
    end
        
    def find_or_create_extra_columns_class extra_columns #:nodoc:
      # look for the class in the cache.
      find_extra_columns_class(extra_columns) || create_extra_columns_class(extra_columns)
    end
    
    # Returns cached extra_column model. The argument can take two forms:
    #
    # * extra_column key - Key used to register the model using the call to extra_columns
    # * extra_column key - Definition used in a prior query.
    #
    # ==== Examples
    #   class Person < ActiveRecord::Base
    #      select_extra_column
    #      extra_column :address_info, :street, :city, :zip 
    #   end
    #   klass = Person.find_extra_columns_class(:address_info)
    #   Person.find(:joins => :address, :select => "people.*, addresses.street, addresses.city, addresses.zip",
    #                    :extra_columns = [:street, :city, :zip])
    #   ...
    #   ...
    #   klass = Person.find_extra_columns_class([:street, :city, :zip])
    #   klass.find_by_sql("..")
    def find_extra_columns_class extra_columns
      # look for the class in the cache.
      [String, Symbol].include?(extra_columns.class) ? 
        self.klasses_with_extra_columns.find{|k| k.extra_columns_key == extra_columns.to_s} :
        self.klasses_with_extra_columns.find{|k| k.extra_columns == extra_columns}
    end

    # Creates and caches an extra_column model.
    #
    def extra_columns extra_columns_key, *args
      create_extra_columns_class args.concat(args.extract_options!.to_a), extra_columns_key 
    end    
        
    def create_extra_columns_class extra_columns, extra_columns_key=nil #:nodoc:
      extra_column_definitions = create_extra_columns(extra_columns)
      return self if extra_column_definitions.empty?      
      read_only_attrs = extra_column_definitions.collect{|cd| ":#{cd.name}" }.join(",")
      klass_name      = "#{self.name}#{Time.now.to_i}#{extra_columns.hash.abs}"
      class_eval(<<-RUBY, __FILE__, __LINE__)
        class ::#{klass_name} < #{self.name}
          set_table_name :#{self.table_name}
          attr_readonly #{read_only_attrs}
          class_inheritable_accessor :extra_columns, :extra_columns_key 
        end
      RUBY
      klass_name.constantize.tap do |klass|
        klass.extra_columns = extra_columns.is_a?(Symbol) ? extra_columns : extra_columns.clone
        klass.extra_columns_key = (extra_columns_key || klass_name).to_s
        extra_column_definitions.each do |ecd|
          klass.columns << (klass.columns_hash[ecd.name] = ecd)
        end
        self.klasses_with_extra_columns = [klass] # add the class to the cache
      end
    end
    
    def create_extra_columns extra_columns #:nodoc:
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