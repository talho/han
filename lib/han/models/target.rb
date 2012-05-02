module Han
  module Models
    module Target
      def self.included(base)
        base.send :extend, ClassMethods
  
        base.alias_method_chain :save_snapshot_of_users, :han unless base.method_defined?(:save_snapshot_of_users_without_han)
      end
  
    def save_snapshot_of_users_with_han &block
      save_snapshot_of_users_without_han do
        if item.class.to_s == 'HanAlert'
          if item.not_cross_jurisdictional
            audience.recipients.map(&:id)
          else
            audience.recipients.with_hacc(item.from_jurisdiction).map(&:id)
          end
        end
      end
    end
  
      module ClassMethods
      end
    end
  end
end
