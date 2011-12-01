require 'dispatcher'

module HAN
  module Audience
    def self.included(base)
      base.send :extend, ClassMethods

      ::Audience.class_eval do
        alias_method_chain :refresh_recipients, :han

        has_and_belongs_to_many :recipients_default, :join_table => 'audiences_recipients', :class_name => "User", :uniq => true, :conditions => ["audiences_recipients.is_hacc = ?", false] do
          def with_hacc(options={})
            options[:joins] = "JOIN \"audiences_recipients\" ON \"audiences_recipients\".user_id = \"users\".id"
            options[:conditions] = "" if options[:conditions].blank?
            options[:conditions] += " #{options[:conditions].blank? ? '' : 'AND'} audiences_recipients.audience_id = #{proxy_owner.id}"
            ::User.send(:with_exclusive_scope) do
              ::User.find(:all, options)
              #scoped(options)
            end
          end
        end
        
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

    def refresh_recipients_with_han(options = {}, &block)
      refresh_recipients_without_han(options) do
        target = ::Target.find_by_audience_id(self.id)
        if (target && target.item.class.to_s == "HanAlert") || options[:from_jurisdiction]
          primary_audience_jurisdictions = determine_primary_audience_jurisdictions # determine primary audience is keyed off of from jurisdiction, which isn't something in the base alert. Wrap to ensure it only happens in HanAlert
          jur = target && target.item.class.to_s == "HanAlert" ? target.item.from_jurisdiction : options[:from_jurisdiction]
          (update_han_coordinators_recipients(primary_audience_jurisdictions, jur) ? true : raise(ActiveRecord::Rollback))
        end 
      end
    end

    def  update_han_coordinators_recipients(jurs, from_jurisdiction)
      unless (jurs == [from_jurisdiction] || jurs.blank? )           # only sending within the originating jurisdiction? no need for coordinators to be notified
        unless ( jurs.include?(from_jurisdiction)) then    # otherwise we need to include the originating jurisdiction for the calculations to work properly.
          jurs << from_jurisdiction if from_jurisdiction
        end
        # grab all jurisdictions we're sending to, plus the from jurisdiction and get their ancestors
        jurs = if from_jurisdiction.nil?
          jurs.map(&:self_and_ancestors).flatten.uniq - (::Jurisdiction.federal)
        else
          selves_and_ancestors =  jurs.flatten.compact.uniq.map(&:self_and_ancestors)

          # union them all, but that may give us too many ancestors
          unioned = selves_and_ancestors[1..-1].inject(selves_and_ancestors.first){|union, list| list | union}

          # intersecting will give us all the ancestors in common
          intersected = selves_and_ancestors[1..-1].inject(selves_and_ancestors.first){|intersection, list| list & intersection}

          # So we grab the lowest common ancestor; ancestry at the lowest level
          ((unioned - intersected) + [intersected.max{|x, y| x.level <=> y.level }]).compact
        end
        db = ActiveRecord::Base.connection()
        sql = "INSERT INTO audiences_recipients (audience_id, user_id, is_hacc)"
        sql += " SELECT DISTINCT #{id}, rm.user_id, true FROM role_memberships AS rm LEFT OUTER JOIN audiences_recipients AS ar ON ar.user_id = rm.user_id AND ar.audience_id = #{id}"
        sql += " WHERE rm.role_id = #{::Role.han_coordinator.id}"
        sql += " AND rm.jurisdiction_id IN (#{jurs.map(&:id).join(',')})"
        sql += " AND ar.user_id IS NULL"

        begin
          db.execute sql
        rescue
          return false
        end
        true
      else
        return false
      end
    end
  end

  Dispatcher.to_prepare do
    ::Audience.send(:include, HAN::Audience)
  end
end