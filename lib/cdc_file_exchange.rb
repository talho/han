
class CDCFileExchange
  
  class ExchangeLogger < Logger
    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"
    end
  end
  
  def initialize
    # load environment/config data from configuration yml
    @config = {}
    begin
      @config = YAML.load_file("#{Rails.root}/config/cascade.yml")[RAILS_ENV]
    rescue
    end
    
    url = @config['url']
    @client = Savon::Client.new do
      wsdl.document = url
    end
    
    unless @config['uname'].blank? || @config['pass'].blank?
      @client.http.auth.basic @config['uname'], @config['pass']
    end
    unless @config['org_key'].blank?
      @client.http.headers["ORG-KEY"] = @config['org_key']
    end
    unless @config['ssl_cert'].blank?
      @client.http.auth.ssl.cert_file = @config['ssl_cert']
    end
  end
  
  def logger
    @logger ||= ExchangeLogger.new("#{RAILS_ROOT}/log/cdc_file_exchange.log", 3, 10 * 1024**2)
  end
  
  def client
    @client
  end
  
  def send_alert(alert)
    cascade = CascadeHanAlert.new(alert)
    receivers = get_receivers(cascade)
    begin
      @client.request :tns, :send do |soap|
        soap.body = {:arg0 => {:activity => {:id => 4}, :receiver => receivers, :name => alert.distribution_id, :payload_file => {:binary => Base64.encode64(cascade.to_edxl) } } }
      end
    rescue Exception => e
      logger.error "Could not send alert id #{alert.id}. Server returned error \"#{e.to_hash[:fault][:faultstring]}\""#log this exception
      raise e # pass it on out of this method for flow control
    end
  end
  
  def get_destinations_for_alert
    begin
      @client.request :tns, :get_destinations do |soap|
        soap.body = {:arg0 => 'CascadeAlerting_alert'}
      end
    rescue Exception => e
      logger.error "Could not find alert destinations. Server returned error \"#{e.to_hash[:fault][:faultstring]}\""#log this exception
      raise e # pass it on out of this method for flow control
    end
  end
  
  def find_incoming_alerts(page = 0)
    begin
      @client.request :tns, :query do |soap|
        soap.body = {:arg0 => {:direction => 'RECEIVED', :page_number => page} }
      end
    rescue Exception => e
      logger.error "Could not find incoming alerts. Server returned error \"#{e.to_hash[:fault][:faultstring]}\""#log this exception
      raise e # pass it on out of this method for flow control
    end
  end
  
  def find_outgoing_alerts
    begin
      @client.request :tns, :query do |soap|
        soap.body = {:arg0 => {:direction => 'SENT'} }
      end
    rescue Exception => e
      logger.error "Could not find outgoing alerts. Server returned error \"#{e.to_hash[:fault][:faultstring]}\""#log this exception
      raise e # pass it on out of this method for flow control
    end
  end
  
  def receive_alert(id)
    begin
      @client.request :tns, :receive do |soap|
        soap.body = { :arg0 => id }
      end
    rescue Exception => e
      logger.error "Could not receive alert for message id #{id}. Server returned error \"#{e.to_hash[:fault][:faultstring]}\""#log this exception
      raise e # pass it on out of this method for flow control
    end
  end
  
  def mark_alert_read(id)
    begin
      @client.request :tns, :mark_read do |soap|
        soap.body = { :arg0 => id }
      end
    rescue Exception => e
      logger.error "Could not mark alert as read for message id #{id}. Server returned error \"#{e.to_hash[:fault][:faultstring]}\""#log this exception
      raise e # pass it on out of this method for flow control
    end
  end
  
  def receive_all_incoming_alerts
    begin
      ret = find_incoming_alerts[:query_response][:return]
    rescue
      return [] #if the find incoming alerts call bombs out, we don't want to continue at all, we'll get it next time
    end
    
    zeroed_pages = ret[:page_size].to_i != 0 ? ret[:result_size].to_i / ret[:page_size].to_i : 0
    alerts = []
    0.upto(zeroed_pages) do |i| 
      ret[:results].each do |result|
        begin
          alerts << receive_alert(result[:id])[:receive_response][:return]
        rescue
          next # move on to processing the next message. This one will be there next time through.
        end
        #mark_alert_read(result[:id])
      end
      begin
        ret = find_incoming_alerts(i + 1)[:query_response][:return] if i < zeroed_pages
      rescue
        break # we've reached the end of the line, let the method return what we have and we'll get the rest later
      end
    end
    
    alerts
  end
  
  private
  def get_receivers(cascade_han_alert)
    [{:id => 33}, {:id => 34}]
  end
end