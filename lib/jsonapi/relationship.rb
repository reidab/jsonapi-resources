module JSONAPI
  class Relationship
    attr_reader :acts_as_set, :foreign_key, :type, :options, :name,
                :class_name, :polymorphic, :always_include_linkage_data

    def initialize(name, options = {})
      @name = name.to_s
      @options = options
      @acts_as_set = options.fetch(:acts_as_set, false) == true
      @foreign_key = options[:foreign_key] ? options[:foreign_key].to_sym : nil
      @module_path = options[:module_path] || ''
      @relation_name = options.fetch(:relation_name, @name)
      @polymorphic = options.fetch(:polymorphic, false) == true
      @always_include_linkage_data = options.fetch(:always_include_linkage_data, false) == true
    end

    alias_method :polymorphic?, :polymorphic

    def primary_key
      @primary_key ||= resource_klass._primary_key
    end

    def resource_klass
      @resource_klass ||= Resource.resource_for(@module_path + @class_name)
    end

    def relation_name(options)
      case @relation_name
        when Symbol
          # :nocov:
          @relation_name
          # :nocov:
        when String
          @relation_name.to_sym
        when Proc
          @relation_name.call(options)
      end
    end

    def type_for_source(source)
      if polymorphic?
        resource = source.public_send(name)
        resource.class._type if resource
      else
        type
      end
    end

    class ToOne < Relationship
      attr_reader :foreign_key_on

      def initialize(name, options = {})
        super
        @class_name = options.fetch(:class_name, name.to_s.camelize)
        @type = class_name.underscore.pluralize.to_sym
        @foreign_key ||= "#{name}_id".to_sym
        @foreign_key_on = options.fetch(:foreign_key_on, :self)
      end

      def belongs_to?
        foreign_key_on == :self
      end

      def polymorphic_type
        "#{type.to_s.singularize}_type" if polymorphic?
      end
    end

    class ToMany < Relationship
      def initialize(name, options = {})
        super
        @class_name = options.fetch(:class_name, name.to_s.camelize.singularize)
        @type = class_name.underscore.pluralize.to_sym
        @foreign_key ||= "#{name.to_s.singularize}_ids".to_sym
      end
    end
  end
end
