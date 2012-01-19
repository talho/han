require 'dispatcher'

module HAN
  module Audience
    def self.included(base)
      base.send :extend, ClassMethods

      ::Audience.class_eval do
        
        has_and_belongs_to_many :recipients, :class_name => "User", :finder_sql => 'select distinct u.*
          from users u
          join sp_recipients(#{self.id}) r on u.id = r.id' do
          def with_hacc(from_jurisdiction = nil) 
            self |
            ::User.find_by_sql(
              ["select distinct u.*
              from  users u
              join sp_cross_jurisdiction_recipients(?, ?, ?) sp on u.id = sp.id",
                proxy_owner.id, from_jurisdiction, ::Role.han_coordinator.id]
             )
          end
        end
      end
    end

    module ClassMethods
    end

  end

  Dispatcher.to_prepare do
    ::Audience.send(:include, HAN::Audience)
  end
end