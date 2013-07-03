module Resourceful
  module Base
    def self.included(base)
      base.extend ClassMethods
    end

    module InstanceMethods
      def resource
        get_resource_ivar
      end

      def collection
        get_collection_ivar || begin
          set_collection_ivar class_name.all
        end
      end

      protected
      def resource_ivar
        "@#{class_name.to_s.demodulize.underscore}"
      end

      def collection_ivar
        resource_ivar.pluralize
      end

      def get_resource_ivar
        instance_variable_get resource_ivar
      end

      def set_resource_ivar(object)
        instance_variable_set resource_ivar, object
      end

      def get_collection_ivar
        instance_variable_get collection_ivar
      end

      def set_collection_ivar(objects)
        instance_variable_set collection_ivar, objects
      end

      def build_resource
        get_resource_ivar || begin
          set_resource_ivar class_name.new
        end
      end

      def create_resource
        class_name.new(secure_params).tap do |model|
          model.save
          set_resource_ivar model
        end
      end

      def secure_params
        return params unless strong_params.present?

        if strong_params.is_a?(Symbol) || strong_params.is_a?(String)
          return self.send strong_params
        end

        strong_params.call(params)
      end

      def collection_path
        self.send "#{model_name.to_s.pluralize}_path"
      end

      def respond_with_dual(*resources, &block)
        respond_with *resources, &block
      end

      def find_resource
        set_resource_ivar class_name.find(params[:id])
      end

      def find_and_update_resource
        model = class_name.find(params[:id])
        model.tap do |m|
          m.update_attributes secure_params
          set_resource_ivar m
        end
      end

    end

    module ClassMethods
      def resourceful(model: nil, strong_params: nil)
        self.class_attribute :model_name, :class_name, :strong_params,
          instance_writer: false

        self.model_name = model
        self.strong_params = strong_params
        self.class_name = class_from_name

        include InstanceMethods
        include Resourceful::Actions

        helper_method :collection, :resource
      end

      protected
      def class_from_name
        if model_name.to_s.include? '_'
          ns, *klass = model_name.to_s.split('_').collect(&:camelize)
          begin
            "#{ns}::#{klass.join('')}".constantize
          rescue NameError
            "#{ns}#{klass.join('')}".constantize
          end
        else
          model_name.to_s.camelize.constantize
        end
      end
    end
  end
end