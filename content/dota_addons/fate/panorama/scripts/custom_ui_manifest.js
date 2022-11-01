'use strict';
GameUI.CustomUIConfig().team_colors = {};
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = '#008000';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS] = '#FF0000';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = '#FFFB00';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = '#FC00E9';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = '#260071';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = '#094CF1';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = '#FCB300';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = '#FF0000';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = '#5F5409';
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = '#00FF87';

GameUI.CustomUIConfig().team_names = {};
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_GOODGUYS] = $.Localize('#DOTA_GoodGuys');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_BADGUYS] = $.Localize('#DOTA_BadGuys');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = $.Localize('#DOTA_Custom1');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = $.Localize('#DOTA_Custom2');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = $.Localize('#DOTA_Custom3');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_4] =$.Localize('#DOTA_Custom4');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_5] =  $.Localize('#DOTA_Custom5');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = $.Localize('#DOTA_Custom6');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = $.Localize('#DOTA_Custom7');
GameUI.CustomUIConfig().team_names[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = $.Localize('#DOTA_Custom8');

Game.MouseEvents = {
  OnLeftPressed: [],
};
Game.DisableWheelPanels = [];
GameUI.SetMouseCallback(function(eventName, arg) {
  var result = false;
  var ClickBehaviors = GameUI.GetClickBehaviors();
  if (eventName === 'pressed') {
    if (arg === 0) {
      if (Game.MouseEvents.OnLeftPressed.length > 0) {
        for (var k in Game.MouseEvents.OnLeftPressed) {
          var r = Game.MouseEvents.OnLeftPressed[k](ClickBehaviors, eventName, arg);
          if (r === true) result = r;
        }
      }
    } else if (
      ClickBehaviors === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE &&
      (arg === 5 || arg === 6)
    ) {
      for (var index in Game.DisableWheelPanels) {
        if (IsCursorOnPanel(Game.DisableWheelPanels[index])) {
          return true;
        }
      }
    }
  }
  return result;
});

GameUI.CustomUIConfig().custom_entity_values = GameUI.CustomUIConfig().custom_entity_values || {};
DynamicSubscribeNTListener('custom_entity_values', function(tableName, key, value) {
  GameUI.CustomUIConfig().custom_entity_values[key] = value;
});
