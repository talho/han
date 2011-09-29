require 'dispatcher'

module HAN
  module Jurisdiction
    def self.included(base)
      base.send :extend, ClassMethods

      ::Jurisdiction.class_eval do
        has_many :han_alerts, :foreign_key => 'from_jurisdiction_id'
      end
    end

    module ClassMethods
    end

    def han_coordinators
      users.with_role(::Role.han_coordinator)
    end

    def deliver(alert)
      raise "#{self.name} is not foreign jurisdiction" unless foreign?
      #Dir.ensure_exists(Agency[:phin_ms_path])
      #File.open(File.join(Agency[:phin_ms_path], "#{cascade_alert.distribution_id}.edxl"), 'w') {|f| f.write cascade_alert.to_edxl }
      CDCFileExchange.new.send_alert(alert)
    end

     def to_dsml(builder=nil)
      builder=Builder::XmlMarkup.new( :indent => 2) if builder.nil?
      builder.dsml(:entry, :dn => dn) do |entry|
        entry.dsml(:objectclass) do |oc|
          ocv="oc-value".to_sym
          oc.dsml ocv, "top"
          oc.dsml ocv, "organizationalUnit"
          oc.dsml ocv, "Organization"
        end
        entry.dsml(:attr, :name => :cn) {|a| a.dsml :value, cn}
        entry.dsml(:attr, :name => :externalUID) {|a| a.dsml :value, externalUID}
        entry.dsml(:attr, :name => :description) {|a| a.dsml :value, description}
        entry.dsml(:attr, :name => :fax) {|a| a.dsml :value, facsimileTelephoneNumber}
        entry.dsml(:attr, :name => :l) {|a| a.dsml :value, l}
        entry.dsml(:attr, :name => :postalCode) {|a| a.dsml :value, postalCode}
        entry.dsml(:attr, :name => :st) {|a| a.dsml :value, st}
        entry.dsml(:attr, :name => :street) {|a| a.dsml :value, street}
        entry.dsml(:attr, :name => :telephoneNumber) {|a| a.dsml :value, telephoneNumber}
        entry.dsml(:attr, :name => :primaryOrganizationType) {|pot| pot.dsml :value, primaryOrganizationType}
        entry.dsml(:attr, :name => :county) {|a| a.dsml :value, county}
        if alertingJurisdictions.is_a?(Array)
          entry.dsml(:attr, :name => :alertingJurisdictions) do |aj|
            alertingJurisdictions.each do |jur|
              aj.dsml(:value, jur)
            end
          end
        else
          entry.dsml(:attr, :name => :alertingJurisdictions) {|a| a.dsml :value, alertingJurisdictions}
        end
      end
    end
  end

  Dispatcher.to_prepare do
    ::Jurisdiction.send(:include, HAN::Jurisdiction)
  end
end