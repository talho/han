# Require HAN models
require 'inflections'

Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each do |f|
  require f
end

Dir[File.join(File.dirname(__FILE__), 'controllers', '*.rb')].each do |f|
  require f
end

Dir[File.join(File.dirname(__FILE__), 'presenters', '*.rb')].each do |f|
  require f
end

# Add PLUGIN_NAME vendor/plugins/*/lib to LOAD_PATH
Dir[File.join(File.dirname(__FILE__), '../vendor/plugins/*/lib')].each do |path|
  $LOAD_PATH << path
end

# Load view helpers
ActionView::Base.send :include, HanAlertsHelper

# Load model overrides
Rails.configuration.after_initialize do
  ::Jurisdiction.send(:include, HAN::Jurisdiction)
  ::Role.send(:include, HAN::Role)
  ::Target.send(:include, HAN::Target)
  ::Audience.send(:include, HAN::Audience)
  ::User.send(:include, HAN::User)
  ::Organization.send(:include, HAN::Organization)
end

# Require any submodule dependencies here
# For example, if this depended on open_flash_chart you would require init.rb as follows:
#   require File.join(File.dirname(__FILE__), '..', 'vendor', 'plugins', 'open_flash_chart', 'init.rb')

# Register the plugin expansion in the $expansion_list global variable
$expansion_list = [] unless defined?($expansion_list)
$expansion_list.push(:han) unless $expansion_list.index(:han)

$menu_config = {} unless defined?($menu_config)
$menu_config[:han] = <<EOF
  nav = "{name: 'HAN', items:[{name: 'HAN Alerts', tab:{id: 'han_home', title:'HAN Alerts', url:'\#{ hud_path }.ext', initializer: 'Talho.Alerts'}}"
  if current_user.alerter?
    nav += ",{name: 'Send an Alert', tab:{id: 'new_han_alert', title:'Send Alert', url:'\#{ new_han_alert_path }', initializer: 'Talho.SendAlert'}},"
    nav += "{name: 'Alert Log and Reporting', tab:{id: 'han_alert_log', title:'Alert Log and Reporting', url:'\#{ han_alerts_path }', initializer: 'Talho.Alerts'}}"
  end
  nav += "]}"
EOF

# Register any required javascript or stylesheet files with the appropriate
# rails expansion helper
ActionView::Helpers::AssetTagHelper.register_javascript_expansion(
  :han => [ "han/script_config" ])
ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion(
  :han => [ "han/han" ])

