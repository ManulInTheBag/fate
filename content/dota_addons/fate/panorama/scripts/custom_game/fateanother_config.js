var g_GameConfig = FindCustomUIRoot($.GetContextPanel());
var transport = null;
var bIsMounted = false;
var bRenderCamera = false;

function OnFateConfigButtonPressed()
{
    var configPanel = $("#FateConfigBoard");
    if (!configPanel)
        return;
    configPanel.visible = !configPanel.visible;

    var buffBar = GameUI.CustomUIConfig().buffBar;
    configPanel.FindChildTraverse("option6").enabled = buffBar.visible;
    if (buffBar.visible) {
        configPanel.FindChildTraverse("option6").checked = buffBar.enabled;
    }
}
function CameraDistanceSlider(bFirstInition)
{
    const hCameraDistanceSlider = $("#CameraDistanceSlider");
    
    const fMin = 0;
    const fMax = 1;

    if ( bFirstInition )
    {
        hCameraDistanceSlider.value = 1900
    }

    const fDistance = AnimeLerp(hCameraDistanceSlider.value, fMin, fMax);

    GameUI.SetCameraDistance(fDistance);
    if (hCameraDistanceSlider.BHasHoverStyle() || bFirstInition)
    {
        $.Schedule(1/30, CameraDistanceSlider);
    }
};

(function()
{
    CameraDistanceSlider(true);
})();

function AnimeLerp(percent, a, b)
{
    return a + percent * (b - a);
}


function OnConfig1Toggle()
{
    g_GameConfig.bIsConfig1On = !g_GameConfig.bIsConfig1On;
    var localPlayerId = Game.GetLocalPlayerID();
    if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
        GameEvents.SendCustomGameEventToServer("config_option_1_checked", {player: Players.GetLocalPlayer(), bOption: g_GameConfig.bIsConfig1On})
    }
}

function OnConfig2Toggle()
{
    g_GameConfig.bIsConfig2On = !g_GameConfig.bIsConfig2On;
    var localPlayerId = Game.GetLocalPlayerID();
    if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
        GameEvents.SendCustomGameEventToServer("config_option_2_checked", {player: Players.GetLocalPlayer(), bOption: g_GameConfig.bIsConfig2On})
    }
}


function OnConfig3Toggle()
{
    g_GameConfig.bIsConfig3On = !g_GameConfig.bIsConfig3On;
}


function OnConfig4Toggle()
{
    g_GameConfig.bIsConfig4On = !g_GameConfig.bIsConfig4On;
    var localPlayerId = Game.GetLocalPlayerID();
    if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
        GameEvents.SendCustomGameEventToServer("config_option_4_checked", {player: Players.GetLocalPlayer(), bOption: g_GameConfig.bIsConfig4On})
    }
}

function OnConfig5Toggle()
{
    var panel = GetHUDRootUI().FindChildTraverse("MasterStatusPanel");
    panel.ToggleClass("Hidden");
}

function OnConfig6Toggle() {
    var configPanel = $.GetContextPanel();
    var option6 = configPanel.FindChildTraverse("option6");
    var buffBar = GameUI.CustomUIConfig().buffBar;
    if (option6.checked) {
        buffBar.Enable();
    } else {
        buffBar.Disable();
    }
}

function OnConfig7Toggle(){
    var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
    panel.ToggleClass("Hidden");
}

function OnConfig9Toggle()
{
    g_GameConfig.bIsConfig9On = !g_GameConfig.bIsConfig9On;
    var localPlayerId = Game.GetLocalPlayerID();
    if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
        GameEvents.SendCustomGameEventToServer("config_option_9_checked", {player: Players.GetLocalPlayer(), bOption: g_GameConfig.bIsConfig9On})
    }
}

function Nill() 
{
}

function OnConfig8Toggle()
{
    //if someone will read this - don't ever use RNG when you need unique values, use current time
    //by the way, this code is very bad, i'll rewrite it later
    const RNG = Date.now();
    
    var configPanel = $.GetContextPanel();
    var option8 = configPanel.FindChildTraverse("option8");
    
    if (option8.checked) {
    for (var i = 0; i < 6; i++) {
        var hotkey = i + 1;
        var seal = i;
        var num = RNG + hotkey;
        if (i == 0) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys1(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+1", "+FATEB_SEAL_" + num );
        } else if (i == 1) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys2(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+2", "+FATEB_SEAL_" + num );
        } else if (i == 2) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys3(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+3", "+FATEB_SEAL_" + num );
        } else if (i == 3) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys4(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+4", "+FATEB_SEAL_" + num );
        } else if (i == 4) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys5(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+5", "+FATEB_SEAL_" + num );
        } else if (i == 5) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys6(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+6", "+FATEB_SEAL_" + num );
        };
    //Game.CreateCustomKeyBind( "2", "+FATE_SEAL_2" );
    //Game.CreateCustomKeyBind( "3", "+FATE_SEAL_3" );
    //Game.CreateCustomKeyBind( "4", "+FATE_SEAL_4" );
    //Game.CreateCustomKeyBind( "5", "+FATE_SEAL_5" );
    };
    } else {
    for (var i = 0; i < 6; i++) {
        var hotkey = i + 1;
        var seal = i;
        var num = RNG + hotkey;
        if (i == 0) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys1(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind("ALT+1", "-FATEB_SEAL_" + num );
        } else if (i == 1) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys2(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+2", "-FATEB_SEAL_" + num );
        } else if (i == 2) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys3(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+3", "-FATEB_SEAL_" + num );
        } else if (i == 3) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys4(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+4", "-FATEB_SEAL_" + num );
        } else if (i == 4) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys5(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+5", "-FATEB_SEAL_" + num );
        } else if (i == 5) {
            Game.AddCommand("+FATEB_SEAL_" + num, RegisterSealHotkeys6(seal), "" + num, 512);
            Game.AddCommand("-FATEB_SEAL_" + num, Nill, "" + num, 512);
            Game.CreateCustomKeyBind( "ALT+6", "-FATEB_SEAL_" + num );
        };
    }
    }
    //AddHotkey("cmd_seal_2", 2);
    //AddHotkey("cmd_seal_3", 3);
    //AddHotkey("cmd_seal_4", 4);
    //AddHotkey("cmd_seal_5", 5);
}

function RegisterSealHotkeys1(Seal)
{
    return function () 
    {
        //$.Msg('Set is Press or Release');
        //$.Msg( Hotkey + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();
         var ability = Seal;

        if (Players.IsSpectator(iPID)) {
            return;
        };

        if (Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            var hero = Players.GetPlayerHeroEntityIndex( iPID );
            var name = Entities.GetUnitName(hero);
            if (name !== "npc_dota_hero_wisp") {
                GameEvents.SendCustomGameEventToServer("player_seal_1", {player: Players.GetLocalPlayer(), iAbility: ability});
            };
        };
    }
}

function RegisterSealHotkeys2(Seal)
{
    return function () 
    {
        //$.Msg('Set is Press or Release');
        //$.Msg( Hotkey + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();
         var ability = Seal;

        if (Players.IsSpectator(iPID)) {
            return;
        };

        if (Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            var hero = Players.GetPlayerHeroEntityIndex( iPID );
            var name = Entities.GetUnitName(hero);
            if (name !== "npc_dota_hero_wisp") {
                GameEvents.SendCustomGameEventToServer("player_seal_2", {player: Players.GetLocalPlayer(), iAbility: ability});
            };
        };
    }
}

function RegisterSealHotkeys3(Seal)
{
    return function () 
    {
        //$.Msg('Set is Press or Release');
        //$.Msg( Hotkey + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();
         var ability = Seal;

        if (Players.IsSpectator(iPID)) {
            return;
        };

        if (Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            var hero = Players.GetPlayerHeroEntityIndex( iPID );
            var name = Entities.GetUnitName(hero);
            if (name !== "npc_dota_hero_wisp") {
                GameEvents.SendCustomGameEventToServer("player_seal_3", {player: Players.GetLocalPlayer(), iAbility: ability});
            };
        };
    }
}

function RegisterSealHotkeys4(Seal)
{
    return function () 
    {
        //$.Msg('Set is Press or Release');
        //$.Msg( Hotkey + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();
         var ability = Seal;

        if (Players.IsSpectator(iPID)) {
            return;
        };

        if (Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            var hero = Players.GetPlayerHeroEntityIndex( iPID );
            var name = Entities.GetUnitName(hero);
            if (name !== "npc_dota_hero_wisp") {
                GameEvents.SendCustomGameEventToServer("player_seal_4", {player: Players.GetLocalPlayer(), iAbility: ability});
            };
        };
    }
}

function RegisterSealHotkeys5(Seal)
{
    return function () 
    {
        //$.Msg('Set is Press or Release');
        //$.Msg( Hotkey + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();
         var ability = Seal;

        if (Players.IsSpectator(iPID)) {
            return;
        };

        if (Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            var hero = Players.GetPlayerHeroEntityIndex( iPID );
            var name = Entities.GetUnitName(hero);
            if (name !== "npc_dota_hero_wisp") {
                GameEvents.SendCustomGameEventToServer("player_seal_5", {player: Players.GetLocalPlayer(), iAbility: ability});
            };
        };
    }
}

function RegisterSealHotkeys6(Seal)
{
    return function () 
    {
        //$.Msg('Set is Press or Release');
        //$.Msg( Hotkey + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();
         var ability = Seal;

        if (Players.IsSpectator(iPID)) {
            return;
        };

        if (Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            var hero = Players.GetPlayerHeroEntityIndex( iPID );
            var name = Entities.GetUnitName(hero);
            if (name !== "npc_dota_hero_wisp") {
                GameEvents.SendCustomGameEventToServer("player_seal_6", {player: Players.GetLocalPlayer(), iAbility: ability});
            };
        };
    }
}

function RegisterSealHotkeys(Seal)
{
    return function () 
    {
        //$.Msg('Set is Press or Release');
        //$.Msg( Hotkey + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();
         var ability = Seal;

        if (Players.IsSpectator(iPID)) {
            return;
        };

        if (panel.visible == true && Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            var hero = Players.GetPlayerHeroEntityIndex( iPID );
            var name = Entities.GetUnitName(hero);
            if (name !== "npc_dota_hero_wisp") {
                GameEvents.SendCustomGameEventToServer("player_cast_seal", {iUnit: MasterUnit, iAbility: ability});
            };
        };
    }
}

function PlayerChat(event)
{
    var txt = event.text;
    var id = event.playerid;
    var playerID = Players.GetLocalPlayer();
    //$.Msg(txt);
    if (playerID == id)
    {
        if (txt == "-bgmoff" && g_GameConfig.bIsBGMOn) {
            StopBGM();
            g_GameConfig.bIsBGMOn = false;
            //$.Msg("BGM off by " + playerID)
        }
        if (txt == "-bgmon" && !g_GameConfig.bIsBGMOn) {
            PlayBGM();
            g_GameConfig.bIsBGMOn = true;
            //$.Msg("BGM on by " + playerID)
        }
    }
    //GameEvents.SendCustomGameEventToServer("player_chat_panorama", {pID: playerID, text: txt})
}

function TurnBGMOff(event)
{
    StopBGM();
    g_GameConfig.bIsBGMOn = false;
}

function TurnBGMOn(event)
{
   
    PlayBGM();
    g_GameConfig.bIsBGMOn = true;
}

function CheckTransportSelection(data)
{
    if (g_GameConfig.bIsConfig3On) { return 0; }
    var playerID = Players.GetLocalPlayer();
    var mainSelected = Players.GetLocalPlayerPortraitUnit();
    var hero = Players.GetPlayerHeroEntityIndex( playerID )

    if (mainSelected == hero && transport && bIsMounted)
    {
        // check if transport is currently carrying Caster inside
        if (Entities.IsAlive( transport ))
        {
            GameUI.SelectUnit(transport, false);
        }
    }

}
function RegisterTransport(data)
{
    transport = data.transport;
}
function UpdateMountStatus(data)
{
    bIsMounted = data.bIsMounted;
    //$.Msg(bIsMounted);
}

function RegisterMasterUnit(data) {
    var config = GameUI.CustomUIConfig()
    var hero = data.hero;
    var masterUnit = data.shardUnit;
    config.masterUnits[hero] = masterUnit;
}

function RegisterAllMasterUnits(data) {
    var config = GameUI.CustomUIConfig()
    config.masterUnits = data;
}

(function()
{
   // $("#FateConfigBoard").visible = false;
    //$("#FateConfigBGMList").SetSelected(1);
    //GameEvents.Subscribe( "player_chat", PlayerChat);
    GameEvents.Subscribe( "player_bgm_on", TurnBGMOn);
    GameEvents.Subscribe( "player_bgm_off", TurnBGMOff);
    GameEvents.Subscribe( "dota_player_update_selected_unit", CheckTransportSelection );
    GameEvents.Subscribe( "player_summoned_transport", RegisterTransport);
    GameEvents.Subscribe( "player_mount_status_changed", UpdateMountStatus);

    var config = GameUI.CustomUIConfig()
    if (!config.masterUnits) {
        config.masterUnits = {}
    }

    GameEvents.Subscribe( "player_register_master_unit", RegisterMasterUnit);
    GameEvents.Subscribe( "player_register_all_master_units", RegisterAllMasterUnits);
})();
