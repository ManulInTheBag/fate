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
      //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );      //Courier controls.
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

        //fucking courier
        var gabenuebanUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("shop_launcher_block").FindChildTraverse("quickbuy").FindChildTraverse("ShopCourierControls").FindChildTraverse("CourierControls");
        gabenuebanUI.style.visibility = "collapse";

        var overallshopUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("shop").FindChildTraverse("Main");
        overallshopUI.style.width = "350px";

        //teamitems
        var teamitemsUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("shop").FindChildTraverse("Main").FindChildTraverse("HeightLimiter").FindChildTraverse("GridMainShop").FindChildTraverse("GridHeaderAndMainContent").FindChildTraverse("GridMainContent").FindChildTraverse("MainShopContentsVersionContainer").FindChildTraverse("FilterContainer");
        teamitemsUI.style.visibility = "collapse";

        // Team Container
        var teamScoreUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("scoreboard");

        // roshtimer
        var roshantimerUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("minimap_container").FindChildTraverse("RoshanTimerContainer");
        roshantimerUI.style.visibility = "collapse";
        //tormentimer
        var tormentimerUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("minimap_container").FindChildTraverse("TormentorTimerContainer");
        tormentimerUI.style.visibility = "collapse";

        // neutraltimer
        var neutraltimerUI = UIRoot.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block").FindChildTraverse("inventory_composition_layer_container").FindChildTraverse("inventory_neutral_craft_holder");
        neutraltimerUI.style.visibility = "collapse";

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


// ---------------------------------------------------------------------------
// Диагностика лавки. Дерево плиток создаётся в C++ на лету, статически его не
// увидеть — снимаем в рантайме. Открыть лавку и ввести в консоль: fb_shop_dump
// ---------------------------------------------------------------------------
function FateBalanceShopDump() {
    var root = GetDotaHud();
    var shop = root.FindChildTraverse("HUDElements");
    shop = shop ? shop.FindChildTraverse("shop") : null;
    if (!shop) {
        $.Msg("[FBShopDump] панель shop не найдена");
        return;
    }
    var printed = 0;

    function walk(panel, depth) {
        if (!panel) {
            return;
        }
        var pad = "";
        for (var d = 0; d < depth; d++) {
            pad += "  ";
        }

        var line = pad + "<" + panel.paneltype + "> id='" + panel.id + "'";
        if (!panel.visible) {
            line += " [hidden]";
        }

        // главное: читается ли привязка плитки к предмету и что в ней лежит
        if (panel.paneltype === "DOTAShopItem" || panel.paneltype === "DOTAItemImage") {
            try {
                line += " itemname='" + panel.itemname + "'";
            } catch (e) {
                line += " itemname=<НЕЧИТАЕМО>";
            }
        }

        $.Msg("[FBShopDump] " + line);
        printed++;

        var n = panel.GetChildCount();
        for (var i = 0; i < n; i++) {
            walk(panel.GetChild(i), depth + 1);
        }
    }

    $.Msg("[FBShopDump] ===== начало дампа (вся панель shop) =====");
    walk(shop, 0);
    $.Msg("[FBShopDump] ===== конец, панелей: " + printed + " =====");
}

Game.AddCommand("fb_shop_dump", FateBalanceShopDump, "Выгрузить дерево панелей лавки в консоль", 0);

// ---------------------------------------------------------------------------
// Починка лавки. На холодном старте клиент собирает сетку раньше, чем у него
// появляется таблица предметов аддона, и первые 14 слотов занимают ванильные
// consumables. Порядок и состав берём из scripts/shops.txt.
// ---------------------------------------------------------------------------
// имя предмета + имя файла иконки (AbilityTextureName из npc_items_custom.txt,
// без префикса custom/). Из имени предмета оно НЕ выводится.
// имя предмета -> имя файла иконки (AbilityTextureName без префикса custom/).
// Из имени предмета оно НЕ выводится, половина не совпадает.
// Раскладывать по ПОРЯДКУ нельзя: состав сетки зависит от common_items.txt
// (например item_berserk_scroll стоит там с нулём и в лавку не попадает),
// поэтому смотрим, что в плитке уже лежит, и меняем только картинку.
var FB_ICONS = {
    "item_mana_essence":           "mana_essence",
    "item_condensed_mana_essence": "bottle_haste",
    "item_c_scroll":               "c_scroll",
    "item_b_scroll":               "b_scroll",
    "item_a_scroll":               "a_scroll",
    "item_s_scroll":               "s_scroll",
    "item_ex_scroll":              "ex_scroll",
    "item_a_plus_scroll":          "a_plus_scroll",
    "item_ward_familiar":          "observer_ward",
    "item_sentry_familiar":        "item_sentry_familiar",
    "item_scout_familiar":         "scout_familiar",
    "item_berserk_scroll":         "berserk_scroll",
    "item_gem_of_speed":           "gem_of_speed",
    "item_spirit_link":            "spirit_link",
    "item_healing_scroll":         "healing_scroll",
    "item_teleport_scroll":        "teleport_scroll",
    "item_a_plus_recipe":          "item_recipe_scroll",
    "item_attack_familiar":        "attack_familiar",
    "item_relic_of_the_king":      "relic_of_the_king",
    "item_blink_scroll":           "blink_scroll",
    "item_gem_of_resonance":       "gem_of_resonance",
    "item_all_seeing_orb":         "all_seeing_orb",
    "item_shard_of_replenishment": "shard_of_replenishment",
    "item_shard_of_anti_magic":    "shard_of_anti_magic",
    "item_caster_5th_mount":       "caster_5th_mount"
};

// Состав сетки слот в слот: список из scripts/shops.txt МИНУС то, что выключено
// в scripts/npc/common_items.txt (сейчас это item_berserk_scroll — там ноль).
// Меняешь shops.txt или common_items.txt — правь и здесь.
var FB_SHOP_ITEMS = [
    ["item_mana_essence",           "mana_essence",         400],
    ["item_condensed_mana_essence", "bottle_haste",         800],
    ["item_c_scroll",               "c_scroll",             150],
    ["item_b_scroll",               "b_scroll",             300],
    ["item_a_scroll",               "a_scroll",             600],
    ["item_s_scroll",               "s_scroll",            1200],
    ["item_ex_scroll",              "ex_scroll",           2400],
    ["item_a_plus_scroll",          "a_plus_scroll",       1000],
    ["item_ward_familiar",          "observer_ward",        400],
    ["item_sentry_familiar",        "item_sentry_familiar", 200],
    ["item_scout_familiar",         "scout_familiar",       200],
    ["item_gem_of_speed",           "gem_of_speed",         300],
    ["item_spirit_link",            "spirit_link",         1500],
    ["item_healing_scroll",         "healing_scroll",       800],
    ["item_teleport_scroll",        "teleport_scroll",      400],
    ["item_a_plus_recipe",          "item_recipe_scroll",   400],
    ["item_attack_familiar",        "attack_familiar",      600],
    ["item_relic_of_the_king",      "relic_of_the_king",   1200]
];

// Клик и тултип у захваченной плитки остаются привязаны к ванильному предмету —
// запись itemname их не переучивает. Кладём сверху прозрачную кнопку: она
// перехватывает мышь, а покупка уходит строкой в HotkeyPurchaseItem (util.lua).
// Геометрию задаём явно: без position кнопка ложится по потоку, а не поверх
// плитки, и попасть по ней можно только краем.
function FateBalanceAttachBuy(tile, name, cost) {
    var old = tile.FindChild("FBBuyOverlay");
    if (old) {
        old.DeleteAsync(0);
    }
    var ov = $.CreatePanel("Button", tile, "FBBuyOverlay");
    ov.style.position = "0px 0px 0px";
    ov.style.align = "left top";
    ov.style.width = "100%";
    ov.style.height = "100%";
    ov.style.zIndex = "100";
    ov.style.backgroundColor = "#00000001";

    // Покупка на ПКМ — как в лавке было до правок. ЛКМ намеренно пустой.
    // Шлём в hotkey_purchase_item (libraries/util.lua). НЕ пытаться слать в
    // panorama_shop_item_buy: модуль modules/panorama_shop ОТКЛЮЧЁН —
    // в modules/index.lua его require закомментирован, слушателя нет, покупка
    // просто уходит в никуда.
    ov.SetPanelEvent("oncontextmenu", function () {
        var pid = Game.GetLocalPlayerID();
        if (!Players.IsValidPlayerID(pid) || Players.IsSpectator(pid)) {
            return;
        }
        GameEvents.SendCustomGameEventToServer("hotkey_purchase_item", { item: name });
        Game.EmitSound("General.Buy");
    });

    ov.SetPanelEvent("onmouseover", function () {
        // Ванильная плитка показывает тултип своего исходного предмета: наша
        // кнопка лежит ВНУТРИ неё, поэтому плитка тоже считается наведённой.
        // Гасим её тултип и показываем свой текстом. Полноценный тултип предмета
        // тут не годится — на холодном старте у клиента нет KV наших предметов,
        // он выведет UNKNOWN. Строки локализации при этом доступны.
        $.DispatchEvent("DOTAHideAbilityTooltip");
        $.DispatchEvent("DOTAHideTextTooltip");

        var title = $.Localize("#DOTA_Tooltip_ability_" + name);
        var desc = $.Localize("#DOTA_Tooltip_ability_" + name + "_Description");
        if (title.indexOf("DOTA_Tooltip") >= 0) {
            title = name;
        }
        var text = "";
        if (desc.indexOf("DOTA_Tooltip") < 0) {
            text = desc;
        }
        $.DispatchEvent("DOTAShowTitleTextTooltip", ov,
                        title + "  —  " + cost, text);
    });
    ov.SetPanelEvent("onmouseout", function () {
        $.DispatchEvent("DOTAHideTitleTextTooltip");
        $.DispatchEvent("DOTAHideTextTooltip");
    });
}

function FateBalanceFindShopGrids() {
    var found = [];
    var shop = GetDotaHud().FindChildTraverse("HUDElements");
    shop = shop ? shop.FindChildTraverse("shop") : null;
    if (!shop) {
        return found;
    }
    var grid = shop.FindChildTraverse("GridMainShop");
    if (!grid) {
        return found;
    }
    // сеток две — GridMainShopContents и GridMainShopContentsV2, id контейнера
    // с плитками у обеих одинаковый, поэтому собираем обходом
    function walk(panel) {
        if (!panel) {
            return;
        }
        if (panel.id === "ShopItemsContainer") {
            found.push(panel);
            return;
        }
        var n = panel.GetChildCount();
        for (var i = 0; i < n; i++) {
            walk(panel.GetChild(i));
        }
    }
    walk(grid);
    return found;
}

function FateBalanceShopFix(quiet) {
    var grids = FateBalanceFindShopGrids();
    if (grids.length === 0) {
        if (!quiet) {
            $.Msg("[FBShopFix] ShopItemsContainer не найден");
        }
        return 0;
    }
    var totalFixed = 0;

    for (var g = 0; g < grids.length; g++) {
        var box = grids[g];
        var n = box.GetChildCount();
        var fixedCount = 0;
        var okCount = 0;

        for (var i = 0; i < n && i < FB_SHOP_ITEMS.length; i++) {
            var tile = box.GetChild(i);
            var was = tile.id;

            // Плитка, в которой уже лежит наш предмет, работает штатно: своя
            // иконка, свой тултип, своя покупка. Такую не трогаем вообще —
            // любая правка делает только хуже.
            if (FB_ICONS.hasOwnProperty(was)) {
                okCount++;
                continue;
            }

            // Уже починена на прошлом проходе. Проверка идёт по наличию нашей
            // кнопки: id плитки так и остаётся ванильным, по нему повтор не
            // отличить. Если лавку пересоберут — кнопка исчезнет вместе со
            // старой плиткой, и починка произойдёт заново.
            if (tile.FindChild("FBBuyOverlay")) {
                okCount++;
                continue;
            }

            // Слот захвачен ванильным предметом. Чиним по позиции: состав сетки
            // совпадает с нашим списком слот в слот.
            var want = FB_SHOP_ITEMS[i][0];
            var tex = FB_SHOP_ITEMS[i][1];
            var cost = FB_SHOP_ITEMS[i][2];

            var img = tile.FindChildTraverse("ItemImage");
            if (img) {
                // ВАЖНО: расширение .vtex, движок сам дописывает _c.
                // С .vtex_c получается ..._c_c и File not found.
                try {
                    img.SetImage("s2r://panorama/images/items/custom/" + tex + "_png.vtex");
                } catch (e1) {
                    $.Msg("[FBShopFix] SetImage упал: " + e1);
                }
            }
            FateBalanceAttachBuy(tile, want, cost);

            if (!quiet) {
                $.Msg("[FBShopFix] слот " + i + ": захвачен '" + was + "' -> ставим '" +
                      want + "', иконка custom/" + tex + ", цена " + cost);
            }
            fixedCount++;
        }

        totalFixed += fixedCount;
        if (!quiet || fixedCount > 0) {
            $.Msg("[FBShopFix] сетка " + (g + 1) + ": плиток " + n +
                  ", своих и так " + okCount + ", починено " + fixedCount);
        }
    }
    return totalFixed;
}

Game.AddCommand("fb_shop_fix", function () { FateBalanceShopFix(false); },
                "Пересобрать плитки лавки под предметы Fate", 0);

// Автопочинка. Лавку клиент пересобирает по ходу загрузки не один раз (в консоли
// это видно по повторяющимся "No shop category named"), поэтому одного вызова
// мало — крутим проверку постоянно. Она дешёвая: если у плиток уже стоит наша
// кнопка, проход просто ничего не делает и молчит.
function FateBalanceShopWatch() {
    FateBalanceShopFix(true);
    FateBalanceUpdateStocks();
    $.Schedule(2.0, FateBalanceShopWatch);
}
$.Schedule(2.0, FateBalanceShopWatch);

// Подпись стока на плитке. Ванильный StockAmount показывает сток чужого
// предмета, к которому плитка привязана, поэтому пишем его сами из нет-таблицы
// fb_stock (её наполняет PushItemStocksToClients в libraries/util.lua).
function FateBalanceUpdateStocks() {
    var pid = Game.GetLocalPlayerID();
    if (!Players.IsValidPlayerID(pid)) {
        return;
    }
    var team = Players.GetTeam(pid);
    var grids = FateBalanceFindShopGrids();

    for (var g = 0; g < grids.length; g++) {
        var box = grids[g];
        var n = box.GetChildCount();
        for (var i = 0; i < n && i < FB_SHOP_ITEMS.length; i++) {
            var tile = box.GetChild(i);
            // только починенные нами плитки: у своих сток рисует сам движок
            if (!tile.FindChild("FBBuyOverlay")) {
                continue;
            }
            var name = FB_SHOP_ITEMS[i][0];
            var row = CustomNetTables.GetTableValue("fb_stock", name);
            var label = tile.FindChildTraverse("StockAmount");
            if (!label) {
                continue;
            }
            if (!row || row[team] === undefined) {
                label.visible = false;
                continue;
            }
            label.text = row[team];
            label.visible = true;
        }
    }
}

    //WORK WITH COMBINE REMOVING ITEMS ON HERO PICKS AKA SPAWNED
let pInnatesPanel = GetDotaHud().FindChildrenWithClassTraverse("RootInnateDisplay");
if (pInnatesPanel)
{
    pInnatesPanel.forEach((pChild, nIndex, tIterated) =>
    {
        if (pChild && pChild.paneltype == "DOTAInnateDisplay") pChild.visible = false;
    });
};