
class CDCExchange
  
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
      @client.wsse.credentials @config['uname'], @config['pass']
    end
    unless @config['org_key'].blank?
      @client.http.headers["ORG-KEY"] = @config['org_key']
    end
    unless @config['ssl_cert'].blank?
      client.http.auth.ssl.cert_file = @config['ssl_cert']
    end
  end
  
  def client
    @client
  end
  
  def send_alert(body)
    @client.request :send_alert do |soap|
      soap.body body
    end
  end
  
  def get_alert_list
    @client.request :query do |soap|
      soap.body = {
        :days => 10,
        :direction => "IN",
        :seen => false,
        :type => "ALERT"
      }
    end
  end
  
  def mark_as_read(alert_id)
    @client.request :mark_read do |soap|
      soap.body = alert_id
    end
  end
  
  def get_alert(alert_id)
    @client.request :get_alert do |soap|
      soap.body = alert_id
    end
  end
  
end