
# Tell the main app that this extension exists
$extensions = [] unless defined?($extensions)
$extensions << :han

$extensions_css = {} unless defined?($extensions_css)
$extensions_css[:han] = [ "han/han.css" ]
$extensions_js = {} unless defined?($extensions_js)
$extensions_js[:han] = [ "han/script_config.js" ]
  
$menu_config = {} unless defined?($menu_config)
$menu_config[:han] = <<EOF
  if current_user.has_app?('han')
    nav = "{name: 'HAN', items:[{name: 'HAN Alerts', tab:{id: 'han_home', title:'HAN Alerts', url:'\#{ recent_han_alerts_path }.ext', initializer: 'Talho.Alerts'}}"
    if current_user.alerter?
      nav += ",{name: 'Send an Alert', tab:{id: 'new_han_alert', title:'Send Alert', url:'\#{ new_han_alert_path }', initializer: 'Talho.SendAlert'}}"
      nav += ",{name: 'Alert Log and Reporting', tab:{id: 'han_alert_log', title:'Alert Log and Reporting', url:'\#{ han_alerts_path }', initializer: 'Talho.Alerts'}}"
    end
    nav += ",{name: 'Tutorial', tab:{id: 'han_tutorial', title:'HAN Tutorial', url:'\#{ han_alerts_path }', initializer: 'Talho.HanTutorial'}}"
    nav += "]}"
  end
EOF

module Han
  module Models
    autoload :Audience, 'han/models/audience'
    autoload :Jurisdiction, 'han/models/jurisdiction'
    autoload :Organization, 'han/models/organization'
    autoload :Role, 'han/models/role'
    autoload :Target, 'han/models/target'
    autoload :User, 'han/models/user'
  end
end

require 'han/engine'