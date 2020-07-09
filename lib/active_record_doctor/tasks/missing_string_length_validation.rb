require "active_record_doctor/tasks/base"

module ActiveRecordDoctor
  module Tasks
    class MissingStringLengthValidation < Base
      @description = 'Detect unlimited character varying columns without length/inclusion validators'

      def run
        eager_load!

        success(hash_from_pairs(models.reject do |model|
          model.table_name.nil? || model.table_name == 'schema_migrations' || !model.table_exists?
        end.map do |model|
          [
            model.name,
            connection.columns(model.table_name).select do |column|
              validator_needed?(column) &&
                !sti_type_column?(model, column) &&
                !polymorphic_type_column?(model, column) &&
                !validator_present?(model, column)
            end.map(&:name)
          ]
        end.reject do |model_name, columns|
          columns.empty?
        end))
      end

      private

      def validator_needed?(column)
        column.type == :string && column.limit.nil?
      end

      def sti_type_column?(model, column)
        column.name == model.inheritance_column
      end

      def polymorphic_type_column?(model, column)
        model.reflect_on_all_associations(:belongs_to).any? do |reflection|
          reflection.options.fetch(:polymorphic, false) && reflection.foreign_type == column.name
        end
      end

      def validator_present?(model, column)
        length_validator_present?(model, column) ||
          inclusion_validator_present?(model, column)
      end

      def length_validator_present?(model, column)
        model.validators.any? do |validator|
          validator.is_a?(ActiveModel::Validations::LengthValidator) &&
            validator.attributes.include?(column.name.to_sym) &&
            (!validator.options.key?(:minimum) ||
              validator.options.key?(:minimum) && validator.options.key?(:maximum))
        end
      end

      def inclusion_validator_present?(model, column)
        model.validators.any? do |validator|
          validator.is_a?(ActiveModel::Validations::InclusionValidator) &&
            validator.attributes.include?(column.name.to_sym)
        end
      end
    end
  end
end
