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

GameUI.CustomUIConfig().multiteam_top_scoreboard =
    {
      reorder_team_scores: true,
      LeftInjectXMLFile: "file://{resources}/layout/custom_game/fateanother_scoreboard_left.xml"
    };
      // Uncomment any of the following lines in order to disable that portion of the default UI

      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );      //Time of day (clock).
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );     //Heroes and team score at the top of the HUD.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, true );      //Lefthand flyout scoreboard.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false );     //Hero actions UI.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false );     //Minimap.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false );      //Entire Inventory UI
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );     //Shop portion of the Inventory.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, false );      //Player items.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );     //Quickbuy.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );      //Courier controls.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );      //Glyph.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );     //Gold display.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );      //Suggested items shop panel.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false );     //Hero selection Radiant and Dire player lists.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false );     //Hero selection game mode name display.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );     //Hero selection clock.
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false );     //Top-left menu buttons in the HUD.
      GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );      //Endgame scoreboard. 
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false );
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false );
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_AGHANIMS_STATUS, false );

    // Talent
    var UIRoot = $.GetContextPanel().GetParent().GetParent()

    /*var hudRoot;
    var panel;
    for( panel = $.GetContextPanel(); panel != null; panel = panel.GetParent())
    {
      hudRoot = panel;
    }
    if (hudRoot != null)
    {
      var statBranch = hudRoot.FindChildTraverse("StatBranch");
      if (statBranch != null)
      {
        statBranch.style.visibility = "collapse";
      }

      var statLevel = hudRoot.FindChildTraverse("level_stats_frame");
      if (statLevel != null)
      {
        statLevel.style.visibility = "collapse";
      }
    }*/

    
    var talentButton = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block").FindChildTraverse("AbilitiesAndStatBranch").FindChildTraverse("StatBranch");
    //talentButton.style.visibility = "collapse";
    
    var talentButtonOverlay = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block").FindChildTraverse("level_stats_frame");
    talentButtonOverlay.style.visibility = "collapse";
    
    var talentStatFrame = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("StatBranchDrawer");
    talentStatFrame.style.visibility = "collapse";
    
    var glyphUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("minimap_container").FindChildTraverse("GlyphScanContainer");
    glyphUI.style.visibility = "collapse";
    
    
        // startegy
        var strategyUI = UIRoot.FindChildTraverse("MainContents").FindChildTraverse("ScreenContainer").FindChildTraverse("StrategyScreen").FindChildTraverse("RightContainer");
        strategyUI.style.visibility = "collapse";

        // DOTA minimap
        var minimapUI = UIRoot.FindChildTraverse("PreGame").FindChildTraverse("BottomPanelsContainer").FindChildTraverse("PreMinimapContainer");
        minimapUI.style.visibility = "collapse";

        // Current Active Quest
        var activeQuestUI = UIRoot.FindChildTraverse("PreGame").FindChildTraverse("BottomPanelsContainer").FindChildTraverse("BottomPanels").FindChildTraverse("BattlePassContainer");
        activeQuestUI.style.visibility = "collapse";

        // Available Item Container
        //var itemContainerUI = UIRoot.FindChildTraverse("PreGame").FindChildTraverse("BottomPanelsContainer").FindChildTraverse("AvailableItemsContainer");
        //itemContainerUI.style.visibility = "collapse";

        // KDA
        var KDAUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("quickstats").FindChildTraverse("QuickStatsContainer");
        UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("quickstats").style.width = "400px";
        UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("quickstats").style.marginTop = "0px";
      //KDAUI.style.visibility = "collapse";
        KDAUI.style.marginTop = "4px";
        KDAUI.style.marginLeft = "190px";
        KDAUI.style.backgroundColor = "#00000000"

        // backpack
        var backpackUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block").FindChildTraverse("inventory").FindChildTraverse("inventory_items").FindChildTraverse("InventoryContainer").FindChildTraverse("inventory_backpack_list");
        backpackUI.style.visibility = "collapse";

        // tpscroll
        var tpscrollUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block").FindChildTraverse("inventory_composition_layer_container").FindChildTraverse("inventory_tpscroll_container");
        tpscrollUI.style.visibility = "collapse";

        // talent picture
        var talentpictureUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block").FindChildTraverse("AbilitiesAndStatBranch").FindChildTraverse("StatBranchBGBranchWell");
        talentpictureUI.style.visibility = "collapse";

        // Glyph, Scan
        var glyphScanUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("GlyphScanContainer");
    //glyphScanUI.style.visibility = "collapse";

        // Common item search
        var commonItemSearchUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("shop").FindChildTraverse("Main").FindChildTraverse("HeightLimiter").FindChildTraverse("SearchContainer");
        commonItemSearchUI.style.visibility = "collapse";

        // Pinned items
        var pinnedItemsUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("shop").FindChildTraverse("Main").FindChildTraverse("ItemCombinesAndBasicItemsContainer").FindChildTraverse("CommonItems");
        //pinnedItemsUI.style.visibility = "collapse";

        // Guide
        var guideUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("shop").FindChildTraverse("GuideFlyout");
        guideUI.style.height = "800px";

        // Neutrals container
        var neutralItemsUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("shop").FindChildTraverse("Main").FindChildTraverse("HeightLimiter").FindChildTraverse("GridMainShop").FindChildTraverse("GridShopHeaders").FindChildTraverse("GridMainTabs").FindChildTraverse("GridNeutralsTab");
        neutralItemsUI.style.visibility = "collapse";

        // Combat events(kill etc)
        var combatEventUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("combat_events");
        //combatEventUI.style.visibility = "collapse";

        // Quickbuy
        var quickbuyUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("shop_launcher_block").FindChildTraverse("quickbuy").FindChildTraverse("QuickBuyRows");

        // Team Container
        var teamScoreUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("scoreboard");

        teamScoreUI.style.height = "800px";
        teamScoreUI.style.marginLeft =  "60%";
        teamScoreUI.FindChildTraverse("Background").style.height = "800px";
        //teamScoreUI.FindChildTraverse("LocalTeamInventory").style.visibility = "collapse";

        var radiantScoreUI = teamScoreUI.FindChildTraverse("Background").FindChildTraverse("RadiantTeamContainer");
        var direScoreUI = teamScoreUI.FindChildTraverse("Background").FindChildTraverse("DireTeamContainer");
        var direScoreHeaderUI = teamScoreUI.FindChildTraverse("Background").FindChildTraverse("DireHeader");
        direScoreHeaderUI.style.marginTop = "-18px";
        direScoreHeaderUI.style.marginBottom = "-4px";

        radiantScoreUI.style.height = "330px";
        direScoreUI.style.height = "330px";

        for (var i=0; i<radiantScoreUI.GetChildCount(); i++)
        {
          radiantScoreUI.GetChild(i).style.height = "15%";
        }
        for (var i=0; i<direScoreUI.GetChildCount(); i++)
        {
          direScoreUI.GetChild(i).style.height = "15%";
        }

    GameUI.CustomUIConfig().team_colors = {}
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#3dd296;"; // { 61, 210, 150 }  --    Teal
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#F3C909;"; // { 243, 201, 9 } --    Yellow
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = "#c54da8;"; // { 197, 77, 168 }  --    Pink
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = "#FF6C00;"; // { 255, 108, 0 } --    Orange
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = "#8c2af4;"; // { 140, 42, 244 }  --    Purple
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = "#3455FF;"; // { 52, 85, 255 } --    Blue
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = "#c7e40d;"; // { 199, 228, 13 }  --    Olive
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = "#815336;"; // { 129, 83, 54 } --    Brown
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = "#1bc0d8;"; // { 27, 192, 216 }  --    Light Blue
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = "#65d413;"; // { 101, 212, 19 }  --  

    var hud = $.GetContextPanel().GetParent().GetParent();
    GameUI.CustomUIConfig().hud = hud;


    //WORK WITH COMBINE REMOVING ITEMS ON HERO PICKS AKA SPAWNED
let pInnatesPanel = GetDotaHud().FindChildrenWithClassTraverse("RootInnateDisplay");
if (pInnatesPanel)
{
    pInnatesPanel.forEach((pChild, nIndex, tIterated) =>
    {
        if (pChild && pChild.paneltype == "DOTAInnateDisplay") pChild.visible = false;
    });
};