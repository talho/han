dominoes.property('han', '/javascripts/han');
dominoes.rule('AlertDetail', 'AudienceDisplayPanel $(ext_extensions)/CenterLayout.js $(han)/AlertDetail.js');

Talho.ScriptManager.addInitializer('Talho.SendAlert', {js:'$(ext_extensions)/CenterLayout.js $(ext_extensions)/BreadCrumb.js AlertDetail AudiencePanel > $(han)/SendAlert.js'})
Talho.ScriptManager.addInitializer('Talho.AlertDetail', {js:'AlertDetail'})
Talho.ScriptManager.addInitializer('Talho.Alerts', {js: "AjaxPanel > $(han)/alerts.js"})
