var g_GameConfig = FindCustomUIRoot($.GetContextPanel());

g_GameConfig.bIsConfig1On = false;
g_GameConfig.bIsConfig2On = false;
g_GameConfig.bIsConfig3On = false;
g_GameConfig.bIsConfig4On = false;

// badges on the customize button: unspent grail shards / enough master mana to buy stats
var MASTER_MANA_INDICATOR_THRESHOLD = 20;
var g_MasterManaUnit = -1;
var g_UnclaimedShards = 0;
var g_GrailIndicator = null;
var g_GrailIndicatorCount = null;
var g_ManaIndicator = null;
var g_IndicatorPulseOn = false;

function GetTalentButton()
{
	var root = GetHUDRootUI();
	var talentButton = root.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block").FindChildTraverse("AbilitiesAndStatBranch").FindChildTraverse("StatBranch");
	return talentButton;
}

function OnCustomizeButtonPressed()
{
    var customizePanel = $("#CustomizationBoard");
	var customizePanelLabel = $("#CustomizationBoardLabel");
    if (!customizePanel)
        return;

    customizePanel.visible = !customizePanel.visible;
	customizePanelLabel.visible = customizePanel.visible;
	UpdateCustomizeIndicators();

	// Test lobby: opening the board with another hero selected shows THAT hero's
	// upgrades. The server listener only exists in cheat mode (demo_core.lua), so
	// in a normal game this event goes nowhere and the board stays as-is.
	if (customizePanel.visible) {
		var selected = Players.GetLocalPlayerPortraitUnit();
		GameEvents.SendCustomGameEventToServer("demo_request_customization", { unit: selected });
	}
}

function CreateFateTalentButton(){
	var fateButton = GetTalentButton()
	fateButton.style.height = "64px";
	fateButton.style.width = "64px";
	
	fateButton.SetPanelEvent("onmouseover", OnCustomizeButtonShowTooltip);
	fateButton.SetPanelEvent("onmouseout", OnCustomizeButtonHideTooltip);
	fateButton.SetPanelEvent("onactivate", OnCustomizeButtonPressed);
	
	var statBranchGraphics = fateButton.FindChildTraverse("StatBranchGraphics")
	statBranchGraphics.style.visibility = "collapse";
	
	var statBranchBG = fateButton.FindChildTraverse("StatBranchBG")
	statBranchBG.style.visibility = "collapse";
	
    fateButton.style.backgroundImage = "url(\"file://{images}/misc/customize.png\")";
    
    var fateButtonOverlay = $.CreatePanel("Panel", fateButton, "FateTalentButtonOverlay");
    fateButtonOverlay.style.width = "100%";
    fateButtonOverlay.style.height = "100%";
    fateButtonOverlay.style.backgroundImage = "url(\"file://{images}/misc/customize_active.png\")";
    fateButtonOverlay.style.opacity = "0";
    fateButtonOverlay.style.transition = "opacity 0.3s ease-in-out 0.0s";

    CreateCustomizeIndicators(fateButton);
}

function CreateCustomizeIndicators(fateButton)
{
    g_GrailIndicator = $.CreatePanel("Panel", fateButton, "FateGrailIndicator");
    g_GrailIndicator.hittest = false;
    g_GrailIndicator.style.width = "26px";
    g_GrailIndicator.style.height = "26px";
    g_GrailIndicator.style.horizontalAlign = "right";
    g_GrailIndicator.style.verticalAlign = "top";
    g_GrailIndicator.style.marginTop = "1px";
    g_GrailIndicator.style.marginRight = "1px";
    g_GrailIndicator.style.backgroundImage = "url(\"file://{images}/spellicons/shard_of_holy_grail.png\")";
    g_GrailIndicator.style.backgroundSize = "100% 100%";
    g_GrailIndicator.style.border = "1px solid #c8a24b";
    g_GrailIndicator.style.borderRadius = "4px";
    g_GrailIndicator.style.boxShadow = "0px 0px 8px 2px #c8a24b88";
    g_GrailIndicator.style.transition = "opacity 0.9s ease-in-out 0.0s";
    g_GrailIndicator.style.visibility = "collapse";

    g_GrailIndicatorCount = $.CreatePanel("Label", g_GrailIndicator, "FateGrailIndicatorCount");
    g_GrailIndicatorCount.hittest = false;
    g_GrailIndicatorCount.style.horizontalAlign = "right";
    g_GrailIndicatorCount.style.verticalAlign = "bottom";
    g_GrailIndicatorCount.style.marginBottom = "-4px";
    g_GrailIndicatorCount.style.fontSize = "15px";
    g_GrailIndicatorCount.style.fontWeight = "bold";
    g_GrailIndicatorCount.style.color = "#ffffff";
    g_GrailIndicatorCount.style.textShadow = "1px 1px 2px 3 #000000";

    g_ManaIndicator = $.CreatePanel("Panel", fateButton, "FateManaIndicator");
    g_ManaIndicator.hittest = false;
    g_ManaIndicator.style.width = "14px";
    g_ManaIndicator.style.height = "14px";
    g_ManaIndicator.style.horizontalAlign = "left";
    g_ManaIndicator.style.verticalAlign = "top";
    g_ManaIndicator.style.marginTop = "1px";
    g_ManaIndicator.style.marginLeft = "1px";
    g_ManaIndicator.style.backgroundColor = "#59c1ff";
    g_ManaIndicator.style.border = "1px solid #dff2ff";
    g_ManaIndicator.style.borderRadius = "50%";
    g_ManaIndicator.style.boxShadow = "0px 0px 10px 3px #59c1ffcc";
    g_ManaIndicator.style.transition = "opacity 0.9s ease-in-out 0.0s";
    g_ManaIndicator.style.visibility = "collapse";

    CustomizeIndicatorThink();
}

function UpdateCustomizeIndicators()
{
    if (!g_GrailIndicator || !g_ManaIndicator)
        return;
    // the badges are a nudge to open the board; once it is open they said their piece
    var customizePanel = $("#CustomizationBoard");
    var boardOpen = customizePanel && customizePanel.visible;

    var showGrail = !boardOpen && g_UnclaimedShards > 0;
    g_GrailIndicator.style.visibility = showGrail ? "visible" : "collapse";
    g_GrailIndicatorCount.text = String(g_UnclaimedShards);

    var showMana = !boardOpen && g_MasterManaUnit != -1 &&
        Entities.GetMana(g_MasterManaUnit) > MASTER_MANA_INDICATOR_THRESHOLD;
    g_ManaIndicator.style.visibility = showMana ? "visible" : "collapse";
}

function CustomizeIndicatorThink()
{
    $.Schedule(0.9, CustomizeIndicatorThink);
    UpdateCustomizeIndicators();
    // slow breathing so the badges catch the eye without flashing
    g_IndicatorPulseOn = !g_IndicatorPulseOn;
    var opacity = g_IndicatorPulseOn ? "1.0" : "0.55";
    g_GrailIndicator.style.opacity = opacity;
    g_ManaIndicator.style.opacity = opacity;
}

function RemoveChilds(panel)
{
	for (i=0;i<panel.GetChildCount(); i++)
	{
		panel.GetChild(i).RemoveAndDeleteChildren();
	}
}

function UpdateAttributeList(data)
{
	$.Msg("updating attribute list")
	var attributePanel = $("#CustomizationAttributeLayout");
	var statPanel = $("#CustomizationStatLayout");
	var cooldownPanel = $("#CustomizationCooldownLayout");
	var shardPanel = $("#CustomizationShardLayout");
	if (!attributePanel || !statPanel || !shardPanel)
		return;

	//$.Msg("panels present. linking abilities...")
	var queryUnit = data.masterUnit; //Players.GetLocalPlayerPortraitUnit();
	var queryUnit2 = data.shardUnit;

	// the event can arrive more than once (initial pick resends it, and the test
	// lobby rebuilds the board for the selected hero) - clear the old panels first
	attributePanel.RemoveAndDeleteChildren();
	statPanel.RemoveAndDeleteChildren();
	shardPanel.RemoveAndDeleteChildren();
	if (cooldownPanel)
		cooldownPanel.RemoveAndDeleteChildren();

	for(i=0; i<5; i++) {
		CreateAbilityPanel(attributePanel, queryUnit, i, true);
	}
	CreateAbilityPanel(cooldownPanel, queryUnit, 5, true);
	for(i=6; i<13; i++) {
		CreateAbilityPanel(statPanel, queryUnit, i, true);
	}

	for(i=6; i<10; i++) {
		CreateAbilityPanel(shardPanel, queryUnit2, i, true);
	}
}


// create an ability context button, which does not reference existing ability of unit
function CreateContextAbilityPanel(panel)
{
	var abilityPanel = $.CreatePanel("Panel", panel, "");
	abilityPanel.BLoadLayout("file://{resources}/layout/custom_game/fateanother_context_ability.xml", false, false );
}

function UpdateStatPanel(data)
{
	$("#STRAmount").text = (data.STR || 0) + " / 30";
	$("#AGIAmount").text = (data.AGI || 0) +  " / 30";
	$("#INTAmount").text = (data.INT || 0) +  " / 30";
	$("#DMGAmount").text = (data.DMG || 0) +  " / 30";
	//$("#ARMORAmount").text = (data.ARMOR || 0) +  " / 30";
	$("#GPSAmount").text = (data.GPS || 0) +  " / 10";
	$("#HPREGAmount").text = (data.HPREG || 0) +  " / 30";
	$("#MPREGAmount").text = (data.MPREG || 0) +  " / 30";
	//$("#MSAmount").text = (data.MS || 0) +  " / 30";
	$("#CustomizationShardNumber").text = (data.ShardAmount || 0);
	g_UnclaimedShards = data.ShardAmount || 0;
	UpdateCustomizeIndicators();
}

function OnCustomizeButtonShowTooltip()
{
    var panel = GetTalentButton();
    var overlay = panel.FindChildTraverse("FateTalentButtonOverlay");
    overlay.style.opacity = "1.0";
	$.DispatchEvent('DOTAShowTextTooltip', panel, "#Fateanother_Customize_Button");
}

function OnCustomizeButtonHideTooltip(panel)
{
    var panel = GetTalentButton();
    var overlay = panel.FindChildTraverse("FateTalentButtonOverlay");
    overlay.style.opacity = "0.0";
	$.DispatchEvent( 'DOTAHideTextTooltip', panel );
}


function AttributeShowTooltip()
{
	var attrText = $("#CustomizationAttributeText");
	$.DispatchEvent('DOTAShowTextTooltip', attrText, "#Fateanother_Customize_Attributes_Tooltip");
}

function AttributeHideTooltip()
{
	var attrText = $("#CustomizationAttributeText"); 
	$.DispatchEvent( 'DOTAHideTextTooltip', attrText );
}

function StatShowTooltip()
{
	var statText = $("#CustomizationStatText"); 
	$.DispatchEvent( 'DOTAShowTextTooltip', statText, "#Fateanother_Customize_Stats_Tooltip");
}

function StatHideTooltip()
{
	var statText = $("#CustomizationStatText"); 
	$.DispatchEvent( 'DOTAHideTextTooltip', statText );
}

function ComboShowTooltip()
{
	var comboText = $("#CustomizationComboText"); 
	$.DispatchEvent( 'DOTAShowTextTooltip', comboText, "#Fateanother_Customize_Special_Cooldowns_Tooltip");
}

function ComboHideTooltip()
{
	var comboText = $("#CustomizationComboText"); 
	$.DispatchEvent( 'DOTAHideTextTooltip', comboText );
}

function ShardShowTooltip()
{
	var shardText = $("#CustomizationShardText"); 
	$.DispatchEvent( 'DOTAShowTextTooltip', shardText, "#Fateanother_Customize_Special_Shards_Tooltip");
}
function ShardHideTooltip()
{
	var shardText = $("#CustomizationShardText"); 
	$.DispatchEvent( 'DOTAHideTextTooltip', shardText );
}
function PrintToClient(data)
{
	$.Msg(data.text);
}

function CreateErrorMessage(msg){
    var reason = msg.reason || 80;
    if (msg.message){
        GameEvents.SendEventClientSide("dota_hud_error_message", {"splitscreenplayer":0,"reason":reason ,"message":msg.message} );
    }
    else{
        GameEvents.SendEventClientSide("dota_hud_error_message", {"splitscreenplayer":0,"reason":reason} );
    }
}

(function()
{
    //$.RegisterForUnhandledEvent( "DOTAAbility_LearnModeToggled", OnAbilityLearnModeToggled);

	//GameEvents.Subscribe( "dota_portrait_ability_layout_changed", UpdateAbilityList );
	//GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateAbilityList );
	//GameEvents.Subscribe( "dota_player_update_query_unit", UpdateAbilityList );
	//GameEvents.Subscribe( "dota_ability_changed", UpdateAbilityList );
	//GameEvents.Subscribe( "dota_hero_ability_points_changed", UpdateAbilityList );
	GameUI.SetCameraDistance(1900);
	GameEvents.Subscribe( "player_selected_hero", UpdateAttributeList);
	// mana badge watches our own master (MasterUnit carries the stat-upgrade mana pool);
	// deliberately not demo_customization_data, which may point at someone else's master
	GameEvents.Subscribe( "player_selected_hero", function(data) {
		g_MasterManaUnit = data.shardUnit;
	});
	// test lobby: board contents for the currently selected hero (see demo_core.lua)
	GameEvents.Subscribe( "demo_customization_data", UpdateAttributeList);
	GameEvents.Subscribe( "servant_stats_updated", UpdateStatPanel );
	GameEvents.Subscribe( "error_message_fired", CreateErrorMessage)
	GameEvents.Subscribe( "player_chat_lua", PrintToClient );
	OnCustomizeButtonPressed();
	CreateFateTalentButton();
})();