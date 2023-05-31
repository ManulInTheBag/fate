var PlayerTables = GameUI.CustomUIConfig().PlayerTables;

function OnFatepediaButtonShowTooltip()
{
	var attrText = $("#FatepediaOpenButton");
	$.DispatchEvent('DOTAShowTextTooltip', attrText, "#FA_Fatepedia_Button");
}

function OnFatepediaButtonHideTooltip()
{
	var attrText = $("#FatepediaOpenButton"); 
	$.DispatchEvent( 'DOTAHideTextTooltip', attrText );
}

function OnFatepediaButtonPressed()
{
    var fatepediaPanel = $("#FatepediaBoard");
    if (!fatepediaPanel)
        return;
    fatepediaPanel.visible = !fatepediaPanel.visible;
}

function SetFatepediaHeroButtons()
{	
	var hero_table = PlayerTables.GetAllTableValues("hero_selection_available_heroes")
	if (hero_table) {
		var directory = "url('file://{images}/heroes/";
		var heroesx = hero_table.HeroTabs[1]
		for (i=0; i<Object.keys(heroesx).length; i++) {
			var heroButton = $.CreatePanel("Panel", $("#FatepediaHeroesPanel"), "");
			heroButton.BLoadLayout("file://{resources}/layout/custom_game/fateanother_fatepedia_herobutton.xml", false, false );
			heroButton.SetAttributeString("heroname", heroesx[i+1]);
	        heroButton.style["background-image"] = "url('s2r://panorama/images/custom_game/portrait/" + heroesx[i+1] + "_png.vtex')"
		}
	} else {
		$.Schedule(0.1, function() {
			SetFatepediaHeroButtons();
		});
	}
}


(function()
{
	$("#FatepediaHeroInfoPanel").visible = false;
	//GameEvents.Subscribe( "fatepedia_kv_sent", GetKV);
	SetFatepediaHeroButtons();
	//for (i=0; i<6; i++) {
	//	CreateContextAbilityPanel($("#FatepediaHeroSkillPanel"), "saber_invisible_air");
	//}
	//for (i=0; i<4; i++) {
	//	CreateContextAbilityPanel($("#Fate pediaHeroAttrPanel"), "saber_invisible_air");
	//}
	//CreateContextAbilityPanel($("#FatepediaBoard"), "saber_invisible_air");
})();
