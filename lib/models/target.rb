require 'dispatcher'

module HAN
  module Target
    def self.included(base)
      base.send :extend, ClassMethods

      ::Target.class_eval do
        alias_method_chain :save_snapshot_of_users, :han
      end
    end

  def save_snapshot_of_users_with_han &block
    save_snapshot_of_users_without_han do
      if item(true).class.to_s == 'HanAlert'
        if item(true).not_cross_jurisdictional
          audience.recipients(:force => true, :select => "id", :conditions => "users.deleted_at IS NULL").map(&:id)
        else
          audience.recipients(:force => true).with_hacc(:select => "id", :conditions => "users.deleted_at IS NULL").map(&:id)
        end
      end
    end
  end

    module ClassMethods
    end
  end

  Dispatcher.to_prepare do
    ::Target.send(:include, HAN::Target)
  end
end
