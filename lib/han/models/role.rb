
module Han
  module Models
    module Role
      def self.included(base)
        base.send :extend, ClassMethods
        
        ::Role::Defaults[:han_coordinator] = 'Health Alert and Communications Coordinator'
      end
  
      module ClassMethods
        def han_coordinator
          find_or_create_by_name ::Role::Defaults[:han_coordinator]
        end
      end
    end
  end
end