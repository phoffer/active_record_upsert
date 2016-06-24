module ActiveRecordUpsert
  module ActiveRecord
    module PersistenceExtensions

      def upsert
        raise ::ActiveRecord::ReadOnlyRecord, "#{self.class} is marked as readonly" if readonly?
        raise ::ActiveRecord::RecordSavedError, "Can't upsert a record that has already been saved" if persisted?
        run_callbacks(:save) {
          run_callbacks(:create) {
            res = _upsert_record
            assign_attributes(res.first.to_h)
          }
        }
        self
      rescue ::ActiveRecord::RecordInvalid
        false
      end

      def _upsert_record(attribute_names = changed)
        attributes_values = arel_attributes_with_values_for_create(attribute_names)
        values = self.class.unscoped.upsert attributes_values
        @new_record = false
        values
      end

      module ClassMethods
        def upsert(attributes, &block)
          if attributes.is_a?(Array)
            attributes.collect { |hash| upsert(hash, &block) }
          else
            new(attributes, &block).upsert
          end
        end
      end
    end
  end
end
