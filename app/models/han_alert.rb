# == Schema Information
#
# Table name: alerts
#
#  id                             :integer(4)      not null, primary key
#  title                          :string(255)
#  message                        :text
#  severity                       :string(255)
#  status                         :string(255)
#  acknowledge                    :boolean(1)
#  author_id                      :integer(4)
#  created_at                     :datetime
#  updated_at                     :datetime
#  sensitive                      :boolean(1)
#  delivery_time                  :integer(4)
#  sent_at                        :datetime
#  message_type                   :string(255)
#  program_type                   :string(255)
#  from_organization_id           :integer(4)
#  from_organization_name         :string(255)
#  from_organization_oid          :string(255)
#  identifier                     :string(255)
#  scope                          :string(255)
#  category                       :string(255)
#  program                        :string(255)
#  urgency                        :string(255)
#  certainty                      :string(255)
#  jurisdiction_level             :string(255)
#  references                     :string(255)
#  from_jurisdiction_id           :integer(4)
#  original_alert_id              :integer(4)
#  short_message                  :string(255)     default("")
#  message_recording_file_name    :string(255)
#  message_recording_content_type :string(255)
#  message_recording_file_size    :integer(4)
#  distribution_reference         :string(255)
#  caller_id                      :string(255)
#  ack_distribution_reference     :string(255)
#  distribution_id                :string(255)
#  reference                      :string(255)
#  sender_id                      :string(255)
#  call_down_messages             :text
#  not_cross_jurisdictional       :boolean(1)     default(true)
#

require 'fileutils'

class HanAlert < Alert
  acts_as_MTI

  belongs_to :from_organization, :class_name => 'Organization'
  belongs_to :from_jurisdiction, :class_name => 'Jurisdiction'
  belongs_to :original_alert, :class_name => 'HanAlert'

  has_one :cancellation, :class_name => 'HanAlert', :foreign_key => :original_alert_id, :conditions => ['message_type = ?', "Cancel"], :include => [:original_alert, :cancellation, :updates, :author, :from_jurisdiction]
  has_many :updates, :class_name => 'HanAlert', :foreign_key => :original_alert_id, :conditions => ['message_type = ?', "Update"], :include => [:original_alert, :cancellation, :updates, :author, :from_jurisdiction]
  has_many :ack_logs, :class_name => 'AlertAckLog', :foreign_key => :alert_id
  has_many :recipients, :class_name => "User", :finder_sql => proc{"SELECT users.* FROM users, targets, targets_users WHERE targets.item_type='HanAlert' AND targets.item_id=#{id} AND targets_users.target_id=targets.id AND targets_users.user_id=users.id"}

  has_attached_file :message_recording, :path => ":rails_root/:attachment/:id.:extension"

  Statuses = ['Actual', 'Exercise', 'Test']
  Severities = ['Extreme', 'Severe', 'Moderate', 'Minor', 'Unknown']
  MessageTypes = { :alert => "Alert", :cancel => "Cancel", :update => "Update" }
  Acknowledgement = ['None', 'Normal', 'Advanced']
  DeliveryTimes = [15, 30, 45, 60, 75, 90, 1440, 4320]
  ExpirationGracePeriod = 240 # in minutes

  validates_inclusion_of :status, :in => Statuses
  validates_inclusion_of :severity, :in => Severities

  validates_inclusion_of :delivery_time, :in => DeliveryTimes
  validates_presence_of :from_jurisdiction_id, :unless => Proc.new { |alert| alert.author_id.nil? }
  validates_length_of :short_message, :maximum => 160, :allow_nil => true
  validates_length_of :caller_id, :is => 10, :allow_blank => true, :allow_nil => true
  validates_format_of :caller_id, :with => /^[0-9]*$/, :on => :create, :allow_blank => true, :allow_nil => true
  validates_attachment_content_type :message_recording, :content_type => ["audio/x-wav", "application/x-wav"]

  has_paper_trail :meta => { :item_desc  => Proc.new { |x| x.to_s }, :app => Proc.new { |x| x.app } }

  scope :active, :conditions => ["UNIX_TIMESTAMP(created_at) + ((delivery_time + #{ExpirationGracePeriod}) * 60) > UNIX_TIMESTAMP(UTC_TIMESTAMP())"]

  def app
    'phin'
  end
  
  def self.new_with_defaults(options={})
    defaults = {:delivery_time => 4320, :severity => 'Minor'}
    self.new(options.merge(defaults))
  end

  def alert_identifier
    self.distribution_id
  end

  def cancelled?
    if cancellation.nil?
      return false
    end
    true
  end

  def expired?
    if created_at.blank? || delivery_time.blank?
      return true
    else
      Time.now.to_i > (created_at.to_i + ((delivery_time + ExpirationGracePeriod) * 60) )
    end
  end
  
  def acknowledged_by_user?(user)
    if attempt = self.alert_attempts.find_by_user_id(user)
      attempt.acknowledged?
    end
  end

  def ask_for_acknowledgement?(user)
    self.acknowledge? && !self.new_record? && !acknowledged_by_user?(user)
  end
  
  def build_cancellation(attrs={})
    attrs = attrs.stringify_keys
    changeable_fields = ["message", "severity", "sensitive", "acknowledge", "delivery_time", "not_cross_jurisdictional","call_down_messages","short_message"]
    overwrite_attrs = attrs.slice(*changeable_fields)
    self.class.new attrs.merge(self.attributes).merge(overwrite_attrs) do |alert|
      alert.created_at = nil
      alert.updated_at = nil
      alert.identifier = nil
      alert.title = "[Cancel] - #{title}"
      alert.message_type = MessageTypes[:cancel]
      alert.original_alert = self

      if alert.acknowledge?
        self.audiences.each do |audience|
          attrs = audience.attributes
          ["id","updated_at","created_at"].each{|item| attrs.delete(item)}
          new_audience = Audience.new(attrs)
          new_audience.users << (self.targets.find_all_by_audience_id(audience.id).map(&:users).flatten & alert_response_users(alert))
          alert.audiences << new_audience
        end
      else
        self.audiences.each{ |audience| alert.audiences << audience.copy}
      end
    end
  end

  def build_update(attrs={})
    attrs = attrs.stringify_keys
    changeable_fields = ["message", "severity", "sensitive", "acknowledge", "delivery_time", "not_cross_jurisdictional","call_down_messages","short_message"]
    overwrite_attrs = attrs.slice(*changeable_fields)
    self.class.new attrs.merge(self.attributes).merge(overwrite_attrs) do |alert|
      alert.created_at = nil
      alert.updated_at = nil
      alert.identifier = nil
      alert.title = "[Update] - #{title}"
      alert.message_type = MessageTypes[:update]
      alert.original_alert = self

      if alert.acknowledge?
        self.audiences.each do |audience|
          attrs = audience.attributes
          ["id","updated_at","created_at"].each{|item| attrs.delete(item)}
          new_audience = Audience.new(attrs)
          new_audience.users << (self.targets.find_all_by_audience_id(audience.id).map(&:users).flatten & alert_response_users(alert))
          alert.audiences << new_audience
        end
      else
        self.audiences.each{ |audience| alert.audiences << audience.copy}
      end
    end
  end

  def iphone_format(path="",acknowledged_by_user=false)
    acknowledged_by_user = (acknowledged_by_user==false) ? false : true
    format =
      Hash[
      "header",h(title),
      "preview",
        Hash["pair",
          [
            Hash["key","Person from","value",author.try(:display_name)],
            Hash["key","Jurisdiction from","value",try(:sender)],
            Hash["key","Severity","value",severity]
          ]
        ],
      "detail",
        Hash["pair",
          [
            Hash["key","Posted on","value",created_at.strftime("%B %d, %Y %I:%M %p %Z")],
            Hash["key","By","value",author.try(:display_name)],
            Hash["key","Status","value",status.capitalize],
            Hash["key","Severity","value",severity],
            Hash["key","From","value",try(:sender)],
            Hash["key","ID","value",try(:identifier)]
          ],
          "content",URI.escape(message),
          "path",   (id && acknowledge && !acknowledged_by_user) ? path : ""
        ],
      ]
      if acknowledge?
        format["detail"]["response"] = call_down_messages
      end
      return format
  end

  def alert_response_users(alert)
    cdm = alert.call_down_messages.keys
    alert_attempts.compact.collect do |aa|
      aa.user if cdm.include?(aa.call_down_response.to_s)
    end.flatten.compact.uniq
  end

  def human_delivery_time
    self.class.human_delivery_time(delivery_time)
  end

  def self.human_delivery_time(minutes)
    minutes > 90 ? "#{minutes/60} hours" : "#{minutes} minutes"
  end

  def batch_deliver
    super do
      audiences(true).each do |audience|
        aas = audience.foreign_jurisdictions.map do |jurisdiction|
          alert_attempts.create!(:jurisdiction => jurisdiction)
        end
        aas.first.batch_deliver unless aas.blank?
      end
    end
  end

  handle_asynchronously :batch_deliver

  def is_updateable_by?(user)
    true if user.alerter_jurisdictions.include?(self.from_jurisdiction)
  end

  def integrate_voice
    original_file_name = "#{Rails.root.to_s}/message_recordings/tmp/#{self.author.token}.wav"
    if Rails.env == "test"
      new_file_name = "#{Rails.root.to_s}/message_recordings/test/#{id}.wav"
    else
      new_file_name = "#{Rails.root.to_s}/message_recordings/#{id}.wav"
    end
    if File.exists?(original_file_name)
      FileUtils.move(original_file_name, new_file_name)
      m = self
      m.message_recording = File.open(new_file_name)
      m.message_recording.save
      m.save
    end
  end

  def self.default_alert
    title = "Example Health Alert - please click More to see the alert contents"
    message = "This is an example of a health alert.  You can see the title above and this is the alert body.\n\nThe status lets you know if this is an actual alert or just a test alert.  The severity lets you know the level of severity from Minor to Extreme severity.  The sensitive indicator lets you know if the alert is of a sensitive nature.\n\nYou can also see if the alert requires acknowledgment.  If the alert does require acknowlegment, an acknowledge button will appear so you can acknowledge the alert."
    HanAlert.new(:title => title, :message => message, :severity => "Minor", :created_at => Time.zone.now, :status => "Test", :acknowledge => false, :sensitive => false)
  end

  def initialize_statistics
    self.reload
    aa_size = alert_attempts(true).size.to_f

    total_jurisdictions.each do |jur|
      ack_logs.create(:item_type => "jurisdiction", :item => jur.name, :total => attempted_users.with_jurisdiction(jur).size.to_f, :acks => 0)
    end

    call_down_messages.each do |key, value|
      ack_logs.create(:item_type => "alert_response", :item => value, :acks => 0, :total => aa_size)
    end if acknowledge?

    super
  end

  def update_statistics(options)
    aa_size = nil
    if options[:jurisdiction]
      options[:jurisdiction] = [options[:jurisdiction]].flatten
      options[:jurisdiction].map(&:name).each { |name|
        ack = ack_logs.find_by_item_type_and_item("jurisdiction", name)
        ack.update_attribute(:acks, ack[:acks] + 1) unless ack.nil?
      }
    end

    super
  end

  def sender
    from_jurisdiction.nil? ? from_organization_name : from_jurisdiction.name
  end

  def self.sender_id
    "#{Agency[:agency_identifer]}@#{Agency[:agency_domain]}"
  end

  def to_ack_edxl
    xml = ::Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    xml.EDXLDistribution(:xmlns => 'urn:oasis:names:tc:emergency:EDXL:DE:1.0') do
      xml.distributionID "#{identifier},#{Agency[:agency_identifier]}"
      xml.senderID "#{Agency[:agency_identifier]}@#{Agency[:agency_domain]}"
      xml.dateTimeSent Time.now.utc.iso8601(3)
      xml.distributionStatus status
      xml.distributionType "Ack"
      xml.combinedConfidentiality sensitive? ? "Sensitive" : "NotSensitive"
      xml.distributionReference ack_distribution_reference
    end

  end

  def total_jurisdictions
    total_jurisdictions = audiences.map(&:jurisdictions).flatten

    total_jurisdictions += User.find(required_han_coordinators).map(&:jurisdictions) if is_cross_jurisdictional?

    total_users = audiences.map(&:users).flatten.uniq.reject do |user|
      if user.jurisdictions.include?(from_jurisdiction)
        total_jurisdictions += [from_jurisdiction]
        true
      end
    end.flatten

    total_jurisdictions += total_users.map(&:jurisdictions) unless total_users.empty?

    total_jurisdictions.flatten.uniq
  end

  def is_cross_jurisdictional?
    jurs = audiences.map(&:jurisdictions).flatten.uniq
    return true if jurs.size > 1 || (jurs.size == 1 && jurs.first != from_jurisdiction)

    #audiences.map(&:users).flatten.uniq.each do |user|
    #  return true unless user.jurisdictions.empty? || user.jurisdictions.include?(from_jurisdiction)
    #end
    false
  end

  # used by Target to determine if public users should be included in recipients
  def include_public_users?
    true
  end

  def responders(responder_categories=[1,2,3,4,5])
    alert_attempts.find_all_by_call_down_response(responder_categories).map(&:user).uniq
  end

  def self.preview_recipients_size(params)
    temp_recipients_size = nil
    if ( params["action"] == "update" || params["action"] == "cancel")
      original_alert = HanAlert.find_by_id(params[:id])
      temp_recipients_size = original_alert.targets.first.users.size
    else
      ActiveRecord::Base.transaction do
        temp_aud = Audience.create(params[:audience])
        temp_recipients_size = params[:not_cross_jurisdictional] == '1' ? temp_aud.recipients.size : temp_aud.recipients.with_hacc(params[:from_jurisdiction_id]).size
        raise ActiveRecord::Rollback
      end
    end
    return temp_recipients_size
  end

  # cascade alerting
  def jurisdictions_per_level
    audiences.each do |audience|
      if audience.users.empty?
       if audience.jurisdictions.empty?
          if jurisdiction_level =~ /local/i
            audience.jurisdictions << Jurisdiction.root.children.nonforeign.first.descendants
          end
          if jurisdiction_level =~ /state/i
            audience.jurisdictions << Jurisdiction.root.children.nonforeign
          end
        end
        audience.roles = Role.all if audience.roles.empty?
      end
    end
  end

  def to_s
    title
  end

  def to_xml
    options = {:messageId => self.distribution_id}
    options[:Messages] = {}
    options[:Messages][:override] = Proc.new do |messages|
      messages.Message(:name => "title", :lang => "en/us", :encoding => "utf8", :content_type => "text/plain") do |message|
        message.Value "Health Alert \"#{self.title}\""
      end

      messages.Message(:name => "short_message", :lang => "en/us", :encoding => "utf8", :content_type => "text/plain") do |message|
        message.Value self.short_message
      end unless self.short_message.blank?

      messages.Message(:name => "email_message", :lang => "en/us", :enconding => "utf8", :content_type => "text/plain") do |message|
        message.Value self.construct_email_message
      end

      messages.Message(:name => "phone_message", :lang => "en/us", :enconding => "utf8", :content_type => "text/plain") do |message|
        message.Value self.construct_phone_message
      end
    end

    options[:Behavior] = {}
    options[:Behavior][:override] = Proc.new do |behavior|
      introOrganization = self.from_organization unless self.from_organization.blank?
      introOrganization = self.from_jurisdiction unless self.from_jurisdiction.blank?

      behavior.Delivery do |delivery|
        delivery.customAttributes do |customAttributes|
          customAttributes.customAttribute(:name => "introOrganization") do |customAttribute|
            customAttribute.Value introOrganization
          end unless introOrganization.blank?

          customAttributes.customAttribute(:name => "phone") do |customAttribute|
            customAttribute.Value self.caller_id
          end unless self.caller_id.blank?

          delivery.Providers do |providers|
            (self.alert_device_types.map{|device| device.device_type.display_name} & Service::Swn::Message::SUPPORTED_DEVICES.keys).each do |device|
              email = YAML.load(IO.read(Rails.root.to_s+"/config/email.yml"))[Rails.env] if device == 'E-mail'
              device_options = {:name => email.nil? ? 'swn' : email["alert"].to_s.downcase, :device => device}
              if self.acknowledge?
                device_options[:ivr] = "alert_responses" if (device == "Phone" && self.sensitive) || (!self.sensitive)
              end

              providers.Provider(device_options) do |provider|
                provider.Messages do |messages|
                  messages.ProviderMessage(:name => "title", :ref => "title")
                  messages.ProviderMessage(:name => "message", :ref => "short_message") if device == "Blackberry PIN" || device == "Fax" || device == "SMS"
                  messages.ProviderMessage(:name => "message", :ref => "email_message") if device == "E-mail"
                  messages.ProviderMessage(:name => "message", :ref => "phone_message") if device == "Phone"
                end
              end
            end
          end

        end
      end
    end

    super(options)
  end

  def construct_email_message
    Rails.application.routes.default_url_options[:host] = HOST
    header = "The following is an alert from the Texas Public Health Information Network.\r\n\r\n"
    footer = ""
    more = "... \r\n\r\nPlease visit the TXPhin website at #{Rails.application.routes.url_helpers.hud_url} to read the rest of this alert.\r\n\r\n"
    if self.acknowledge?
      header += "This alert requires acknowledgment.  Please follow the instructions below to acknowledge this alert.\r\n\r\n"
    end
    if self.sensitive?
      footer += "\r\n\r\nAlert ID: #{self.identifier}\r\n"
      footer += "Reference: #{self.original_alert_id}\r\n" unless self.original_alert_id.blank?
      footer += "Status: #{self.status}\r\n" unless self.status == "Actual"
      footer += "Sensitive: use secure means of retrieval\r\n\r\n"
      footer += "Please visit #{Rails.application.routes.url_helpers.url_for(:action => "hud", :controller => "dashboard", :escape => false, :only_path => false, :protocol => "https")} to securely view this alert.\r\n"
      output = header + footer
    else
      footer += "\r\n\r\nTitle: #{self.title}\r\n"
      footer += "Alert ID: #{self.identifier}\r\n"
      footer += "Reference: #{self.original_alert_id}\r\n" unless self.original_alert_id.blank?
      footer += "Agency: #{self.from_jurisdiction.nil? ? self.from_organization_name : self.from_jurisdiction.name}\r\n"
      footer += "Sender: #{self.author.display_name}\r\n" unless self.author.nil?
      footer += "Status: #{self.status}\r\n" unless self.status == "Actual"
      footer += "Time Sent: #{self.created_at.strftime("%B %d, %Y %I:%M %p %Z")}\r\n\r\n"
      if self.message.size + header.size + footer.size > 1000
        output = header + self.message[0..(1000 - header.size - more.size - footer.size)] + more + footer
      else
        output = header + self.message + footer
      end
    end
    output
  end


  def construct_phone_message
    output = "The following is an alert from the Texas Public Health Information Network.  "
    if output.size + self.message.size > 1000
      footer = ".  The rest of this message is unavailable.  Please visit the T X Fin website for the rest of this alert."
      output += self.message[0..(1000 - output.size - footer.size)] + footer
    else
      output += self.message
    end
    output
  end

  def as_report(options={})
    json_columns = attributes.keys.reject{|k| /^id$|_id$|_at$|^lock_version$/.match(k)}
    json = as_json(:only => json_columns)
    json["author"] = User.find(author_id).display_name
    audiences_report = []
    audiences.each do |audience|
      audience_report = {}
      audience_report["jurisdictions"] = audience.jurisdictions.map(&:name).to_sentence
      audience_report["roles"] = audience.roles.map(&:name).to_sentence
      audience_report["people"] = audience.users.map(&:name).to_sentence
      audiences_report.push(audience_report)
    end
    json["audiences"] = audiences_report
    options[:inject].each {|key,value| json[key] = value} if options[:inject]
    json
  end

  private

  def required_han_coordinators
    # Keith says: "Do not fuck with this method."
    jurisdictions = audiences.map(&:jurisdictions).flatten.uniq
    unless jurisdictions.empty?
      # grab all jurisdictions we're sending to, plus the from jurisdiction and get their ancestors
      if from_jurisdiction.nil?
        return (jurisdictions.compact.map(&:self_and_ancestors).flatten.uniq - (Jurisdiction.federal)).map{|jurisdiction| jurisdiction.han_coordinators.map(&:id)}.flatten
      else
        selves_and_ancestors = (jurisdictions + [from_jurisdiction]).compact.map(&:self_and_ancestors)
      end

      # union them all, but that may give us too many ancestors
      unioned = selves_and_ancestors[1..-1].inject(selves_and_ancestors.first){|union, list| list | union}

      # intersecting will give us all the ancestors in common
      intersected = selves_and_ancestors[1..-1].inject(selves_and_ancestors.first){|intersection, list| list & intersection}

      # So we grab the lowest common ancestor; ancestory at the lowest level
      good_ones = (unioned - intersected) + [intersected.max{|x, y| x.level <=> y.level }]

      # Finally, grab all those han coordinators
      good_ones.compact.map {|jurisdiction| jurisdiction.han_coordinators.map(&:id) }.flatten
    else
      []
    end
  end

  def verify_audiences_not_empty
    errors.add(:base, "The audience must have a least one role, jurisdiction, or user specified.") unless audiences.length > 0
  end

end
