
Ext.ns('Talho');

Talho.HanTutorial = Ext.extend(Ext.Panel, {
  border:false,
  constructor: function(config){

    Talho.HanTutorial.superclass.constructor.call(this, config);
  }


});

Talho.HanTutorial.initialize = function(config){

  Ext.apply(config, {
    items:[new Talho.HanTutorial({
      alertId: config.alertId
    })],
    autoScroll: true,
    closable: true,
    padding: '10'
  });

  return new Ext.Panel(config);
};

Talho.ScriptManager.reg('Talho.HanTutorial', Talho.HanTutorial, Talho.HanTutorial.initialize);
