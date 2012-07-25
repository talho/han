require 'fileutils'

class HanAlertsController < ApplicationController
  before_filter :alerter_required, :only => [:index, :new, :create, :edit, :update, :calculate_recipient_count]
  before_filter :can_view_alert, :only => [:show]
  skip_before_filter :authorize, :only => [:token_acknowledge, :upload, :playback]
  protect_from_forgery :except => [:upload, :playback]

  app_toolbar "han"

  def index
    @alerts = current_user.han_alerts_within_jurisdictions(params[:page])
  end

  def recent
    require 'will_paginate/array'
    per_page = ( params[:per_page].to_i > 0 ? params[:per_page].to_i : 10 )
    @alerts = (defined?(current_user.recent_han_alerts) && current_user.recent_han_alerts.size > 0) ?
        current_user.recent_han_alerts.paginate(:page => params[:page], :per_page => per_page) :
        (defined?(HanAlert) ? [HanAlert.default_alert] : []).paginate(:page => 1)
    respond_to do |format|
      format.html
      format.ext
      format.json do
        unless @alerts.nil? || @alerts.empty? || ( @alerts.map(&:id) == [nil] ) # for dummy default alert
          jsonObject = @alerts.collect{ |alert| alert.iphone_format(update_alert_path(alert.id),alert.acknowledged_by_user?(current_user)) }
          headers["Access-Control-Allow-Origin"] = "*"
          render :json => jsonObject
        else
          headers["Access-Control-Allow-Origin"] = "*"
          render :json => []
        end
      end
    end
  end

  def show
    alert = HanAlert.find(params[:id])
    @alert = alert
    respond_to do |format|
      format.html
      format.pdf do
        prawnto :inline => false
        alerter_required
      end
      format.xml { render :xml => @alert.to_xml( :include => [:author, :from_jurisdiction] , :dasherize => false)}
      format.json do
        original_included_root = ActiveRecord::Base.include_root_in_json
        ActiveRecord::Base.include_root_in_json = false
        audiences = {:roles => [], :groups => [], :jurisdictions => [], :users => []}
        alert.audiences.each do |audience|
          if audience.name.nil?
            audiences[:roles] = audiences[:roles] | audience.roles.map {|role| role.as_json(:only => ["id", "name"])}
            audiences[:jurisdictions] = audiences[:jurisdictions] | audience.jurisdictions.map {|jurisdiction| jurisdiction.as_json(:only => ["id", "name"])}
            audiences[:users] = audiences[:users] | audience.users.map {|user| {:id => user.id, :name => user.display_name } }
          else
            audiences[:groups].push(audience.as_json(:only => ["id", "name"]))
          end
        end
        render :json => {:alert => alert.as_json(:include => {:alert_device_types => {:only => ['device']}, :author => {:only => ["display_name"]} },
                                                 :only => ['acknowledge', 'call_down_messages', 'created_at', 'delivery_time', 'message', 'not_cross_jurisdictional', 'severity', 'short_message', 'status', 'sensitive', 'title', 'from_jurisdiction_id']),
                         :alert_attempts => alert.alert_attempts,
                         :audiences => audiences,
                         :recipient_count => @alert.recipients.count
        }
        ActiveRecord::Base.include_root_in_json = original_included_root
      end
      format.csv do
        alerter_required
        @filename = "alert-#{@alert.identifier}.csv"
        @output_encoding = 'UTF-8'
      end
    end

  end

  def new
    @alert = HanAlert.new_with_defaults
    @acknowledge_options = HanAlert::Acknowledgement
  end

  def create
    remove_blank_call_downs unless params[:han_alert][:call_down_messages].nil?
    set_acknowledge
    params[:han_alert][:author_id] = current_user.id
    @alert = HanAlert.new(params[:han_alert])
    @acknowledge = if @alert.acknowledge
      @alert.call_down_messages.blank? || @alert.call_down_messages["1"] == "Please press one to acknowledge this alert." ? 'Normal' : 'Advanced'
    else
      'None'
    end
    @acknowledge_options = HanAlert::Acknowledgement

    if params[:send]
      if @alert.valid?

        @alert.save
        #@alert.integrate_voice
        #@alert.batch_deliver
        respond_to do |format|
          format.html {
            flash[:notice] = "Successfully sent the alert."
            redirect_to han_alerts_path
          }
          format.json { render :json => {:success => true, :alert_path => alert_path(@alert), :id => @alert.id, :title => @alert.title}}
        end
      else
        if @alert.errors['message_recording']
          flash[:error] = "Attached message recording is not a valid wav formatted file."
          @preview = true
        end
        respond_to do |format|
          format.html { render :new }
          format.json { render :json => @alert.errors, :status => :unprocessable_entity}
        end
      end
    else
      @preview = true
      @token = current_user.token
      @num_recipients = 0
      render :new
    end
  end

  def edit
    alert = HanAlert.find params[:id]

    error = false
    msg = nil

    if alert.nil?
      msg = "You do not have permission to update or cancel this alert."
      error = true
    end

    unless error
      @acknowledge_options = HanAlert::Acknowledgement #.reject{|x| x=="Advanced"}
      # TODO : Remove when devices refactored
      @device_types = []
      alert.device_types.each do |device_type|
        @device_types << device_type
      end
      @acknowledge = if alert.acknowledge?
        alert.call_down_messages.blank? || alert.call_down_messages["1"] == "Please press one to acknowledge this alert." ? 'Normal' : 'Advanced'
      else
        'None'
      end
    end

    unless alert.is_updateable_by?(current_user)
      msg = "You do not have permission to update or cancel this alert."
      error = true
    end

    unless alert.original_alert.nil?
      msg = "You cannot make changes to updated or cancelled alerts."
      error = true
    end

    if alert.cancelled?
      msg = "You cannot update or cancel an alert that has already been cancelled."
      error = true
    end

    if error
      respond_to do |format|
        format.html do
          flash[:error] = msg
          redirect_to han_alerts_path
        end
        format.json {render :json => {'success' => false, 'msg' => msg}, :status => 401}
      end
      return
    end

    respond_to do |format|
      format.html do
        @alert = alert
        @update = true if params[:_action].downcase == "update"
        @cancel = true if params[:_action].downcase == "cancel"
      end
      format.json do
        audiences = {:roles => [], :groups => [], :jurisdictions => [], :users => []}
        alert.audiences.each do |audience|
          if audience.name.nil?
            audiences[:roles] = audiences[:roles] | audience.roles
            audiences[:jurisdictions] = audiences[:jurisdictions] | audience.jurisdictions
            audiences[:users] = audiences[:users] | audience.users
          else
            audiences[:groups].push(audience)
          end
        end
        render :json => {'alert' => alert, 'devices' => @device_types, 'audiences' => audiences, 'success' => true, 'recipient_count' => alert.recipients.count}
      end
    end
  end

  def update
    original_alert = HanAlert.find params[:id]
    # TODO : Remove when devices refactored
    @device_types = []
    original_alert.device_types.each do |device_type|
      @device_types << device_type
    end

    unless original_alert.is_updateable_by?(current_user)
      msg = "You do not have permission to update or cancel this alert."
      respond_to do |format|
        format.html do
          flash[:error] = msg
          redirect_to han_alerts_path
        end
        format.json {render :json => {'message' => msg, 'success' => false}, :status => 401}
      end
    end

    if original_alert.cancelled?
      msg = "You cannot update or cancel an alert that has already been cancelled."
      respond_to do |format|
        format.html do
          flash[:error] = msg
          redirect_to han_alerts_path
        end
        format.json {render :json => {'message' => msg, 'success' => false}, :status => 401}
      end
      return
    end
    reduce_call_down_messages_from_responses(original_alert)
    set_acknowledge
    @alert = if params[:_action].downcase == 'cancel'
      @cancel = true
      original_alert.build_cancellation(params[:han_alert])
    elsif params[:_action].downcase == 'update'
      @update = true
      original_alert.build_update(params[:han_alert])
    end
    @acknowledge = if @alert.acknowledge
      'Normal'
    else
      'None'
    end
     @acknowledge_options = HanAlert::Acknowledgement #.reject{|x| x=="Advanced"}
    if params[:send]
      @alert.save
      if @alert.valid?
        #@alert.integrate_voice
        #@alert.batch_deliver
        respond_to do |format|
          format.html do
            flash[:notice] = "Successfully sent the alert."
            redirect_to han_alerts_path
          end
          format.json {render :json => {'success' => true}}
        end
      else
        if @alert.errors['message_recording']
          msg = "Attached message recording is not a valid wav formatted file."
          respond_to do |format|
            format.html do
              flash[:error] = msg
              @preview = true
              render :new
            end
            format.json {render :json => {'message' => msg, 'success' => false}, :status => 406}
          end
        end
      end
    else
      @alert = @alert
      @preview = true
      render :edit
    end
  end

  def calculate_recipient_count
    parms = { :audience => {:jurisdiction_ids => params[:jurisdiction_ids], :user_ids => params[:user_ids], 
              :role_ids => params[:role_ids], :group_ids => params[:group_ids]},
              :not_cross_jurisdictional => params[:not_cross_jurisdictional],
              :from_jurisdiction_id => params[:from_jurisdiction_id]}
    respond_to do |format|
        format.json { render :json => HanAlert.preview_recipients_size(parms) }
    end
  end

  def upload
    # Takes uploaded file info from JavaSonicRecorderUploader, copies to permanent location, and returns SUCCESS or ERROR
    user = User.find_by_token(params[:token]) if !params[:token].blank?
    if user.blank? || user.token_expires_at.blank? || user.token_expires_at < Time.zone.now || !user.alerter? || params[:userfile].blank?
      render :upload_error, :layout => false
      return
    end
    temp = params[:userfile]
    if(!File.exists?(temp.path))
      render :upload_error, :layout => false
    end
    if(File.size(temp.path) > 7000000) # sufficiently below 10Meg (21CC attachment limitation) after Base64 encoding
      render :upload_error, :layout => false
    end

    newpath = "#{Rails.root.to_s}/message_recordings/tmp/#{user.token}.wav"
    FileUtils.copy(temp.path,newpath)
    if(!File.exists?(newpath))
      render :upload_error, :layout => false
    end
    render :upload_success, :layout => false
  end

  def playback
    filename = "#{Rails.root.to_s}/message_recordings/tmp/#{params[:token]}.wav"
    if File.exists?(filename)
      @file = File.open(filename)
    end
    response.headers["Content-Type"] = 'audio/x-wav'
    render :play, :layout => false
  end

  def acknowledgements
    alert = HanAlert.find(params[:id])
    respond_to do |format|
      format.json { render :json => {:attempts => alert.alert_attempts.paginate(:page => (params[:start].to_i||0)/(params[:limit].to_i||10) + 1, :per_page => params[:limit] || 10).map do |attempt|
                      { :name => attempt.user.display_name,
                        :email => attempt.user.email,
                        :device => attempt.acknowledged_alert_device_type ? attempt.acknowledged_alert_device_type.device : "",
                        :response => attempt.call_down_response ? ( attempt.call_down_response == 0 ? "Acknowledged" : alert.call_down_messages[attempt.call_down_response.to_s] ) : "",
                        :acknowledged_at => attempt.acknowledged_at
                      }
                  end, :total => alert.alert_attempts.count } 
                }
    end
  end
  
private

  def can_view_alert
    alert = HanAlert.find(params[:id])
    jurs=current_user.alerting_jurisdictions.sort_by(&:lft)
    jurs=jurs.map{|j1| jurs.detect{|j2| j2.is_ancestor_of?(j1)} || j1}.uniq
    ors=jurs.map{|j| "(jurisdictions.lft >= #{j.lft} AND jurisdictions.lft <= #{j.rgt})"}.join(" OR ")
    jurs=Jurisdiction.find(:all, :conditions => ors)

    unless !alert.nil? &&
        (alert.targets.map{|t| t.users.find_by_id(current_user.id)}.flatten.compact.present? ||
          jurs.map(&:id).include?(alert.from_jurisdiction.id))
      error = "That resource does not exist or you do not have access to it."
      if request.xhr?
        respond_to do |format|
            format.html {render :text => error, :status => 404}
            format.json {render :json => {:message => error}, :status => 404}
        end
      else
        flash[:error] = error
        redirect_to root_path
      end
    end
  end

  def alerter_required
    unless current_user.alerter?
      respond_to do |format|
        format.json {render :json => {:message => "You do not have permission to send an alert."}, :status => 400}
        format.html do
          flash[:error] = "You do not have permission to send an alert."
          redirect_to root_path
        end
      end
    end
  end

  def set_acknowledge
    if params[:han_alert][:acknowledge] == 'Advanced' || params[:han_alert][:acknowledge] == 'Normal'
      params[:han_alert][:acknowledge] = true
    else
      params[:han_alert][:acknowledge] = false
    end
  end

  def remove_blank_call_downs
    call_down = params[:han_alert][:call_down_messages].sort{|a,b| b[0]<=>a[0]}
    call_down.each do |key, value|
      params[:han_alert][:call_down_messages].delete(key) if value.blank?
      break unless value.blank?
    end
  end

  def reduce_call_down_messages_from_responses(original_alert)
    if params[:han_alert][:call_down_messages].nil? && original_alert.acknowledge? && !params[:han_alert][:responders].blank?
      params[:han_alert][:call_down_messages] = {}

      msgs = original_alert.call_down_messages.select{|key, value| params[:han_alert][:responders].include?(key)}

      msgs.each do |key, value|
        params[:han_alert][:call_down_messages][key] = value
      end
    end
    params[:han_alert].delete("responders")
  end

end
