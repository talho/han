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
      if item.class == HanAlert
        if item.not_cross_jurisdictional
          audience.recipients(:force => true, :select => "id").map(&:id)
        else
          audience.recipients_with_hacc(:force => true, :select => "id").map(&:id)
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
