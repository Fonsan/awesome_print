# Copyright (c) 2010 Michael Dvorkin
#
# Awesome Print is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AwesomePrintActiveRecord

  def self.included(base)
    base.send :alias_method, :printable_without_active_record, :printable
    base.send :alias_method, :printable, :printable_with_active_record
    
  end

  # Add ActiveRecord class names to the dispatcher pipeline.
  #------------------------------------------------------------------------------
  def printable_with_active_record(object)
    printable = printable_without_active_record(object)
    if printable == :self
      if object.is_a?(ActiveRecord::Base)
        printable = :active_record_instance
      elsif object.is_a?(ActiveSupport::OrderedHash)
        printable = :active_support_ordered_hash
      end
    elsif printable == :class and object.ancestors.include?(ActiveRecord::Base)
      printable = :active_record_class
    end
    printable
  end


  def awesome_active_support_ordered_hash object
    awesome_hash(object)
  end

  # Format ActiveRecord instance object.
  #------------------------------------------------------------------------------
  def awesome_active_record_instance_to_hash object
    object.class.column_names.inject(ActiveSupport::OrderedHash.new) do |hash, name|
      hash[name.to_sym] = object.send(name) if object.has_attribute?(name) || object.new_record?
      hash
    end rescue {}
  end

  # Format ActiveRecord instance object with recursive printing.
  #------------------------------------------------------------------------------
  def awesome_active_record_instance(object)
    data = awesome_active_record_instance_to_hash object
    object.class.reflect_on_all_associations.each do |r|
      res = object.send(r.name)
      if res.is_a?(Array)
        if res.length > 5 #@base.options[:ar_collection_limit]
          res = res[0..5].map do |record|
            awesome_active_record_instance_to_hash(record)
          end + ["Only printing first five records out of (#{res.length}) records"]
        end
      else
        res =  awesome_active_record_instance_to_hash(res)
      end
      data[r.name.to_sym] = res
    end
    "#{object} " + awesome_hash(data)
  end

  # Format ActiveRecord class object.
  #------------------------------------------------------------------------------
  def awesome_active_record_class(object)
    if object.respond_to?(:columns)
      data = object.columns.inject(ActiveSupport::OrderedHash.new) do |hash, c|
        hash[c.name.to_sym] = c.type
        hash
      end
      "class #{object} < #{object.superclass} " << awesome_hash(data)
    else
      object.inspect
    end
  end
 
  
end

AwesomePrint.send(:include, AwesomePrintActiveRecord)
