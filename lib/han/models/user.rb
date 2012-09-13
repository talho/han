
module Han
  module Models
    module User
      def self.included(base)
        base.send :extend, ClassMethods
  
        ::User.class_eval do
          has_many :recent_han_alerts, :through => :alert_attempts, :source => "alert", :order => "created_at DESC", :conditions => {alert_type: 'HanAlert'}, :include => [:alert_device_types, :from_jurisdiction, :original_alert, :author]
        end
      end
  
      module ClassMethods
      end
  
      def han_alerts_within_jurisdictions(page=nil)
        jurs=alerting_jurisdictions.sort_by(&:lft)
        jurs=jurs.map{|j1| jurs.detect{|j2| j2.is_ancestor_of?(j1)} || j1}.uniq
        return [] if jurs.empty?
        ors=jurs.map{|j| "(jurisdictions.lft >= #{j.lft} AND jurisdictions.lft <= #{j.rgt})"}.join(" OR ")
  
        HanAlert.paginate(:conditions => ors,
                       :joins => "inner join jurisdictions on from_jurisdiction_id=jurisdictions.id",
                       :include => [:original_alert, :cancellation, :author, :from_jurisdiction],
                       :order => "created_at DESC",
                       :page => page,
                       :per_page => 10)
      end
    end
  end
end