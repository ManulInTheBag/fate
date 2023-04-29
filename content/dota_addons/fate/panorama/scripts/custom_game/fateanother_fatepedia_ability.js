var PlayerTables = GameUI.CustomUIConfig().PlayerTables;

var guidelinks = [
	"http://fa-d2.wikia.com/wiki/Saber#Gameplay",
	"http://fa-d2.wikia.com/wiki/Saber_Alter#Gameplay",
	"http://fa-d2.wikia.com/wiki/Lancer#Gameplay",
	"http://fa-d2.wikia.com/wiki/Archer#Gameplay",
	"http://fa-d2.wikia.com/wiki/Rider#Gameplay",
	"http://fa-d2.wikia.com/wiki/Caster#Gameplay",
	"http://fa-d2.wikia.com/wiki/False_Assassin#Gameplay",
	"http://fa-d2.wikia.com/wiki/True_Assassin#Gameplay",
	"http://fa-d2.wikia.com/wiki/Berserker#Gameplay",
	"http://fa-d2.wikia.com/wiki/Gilgamesh#Gameplay",
	"http://fa-d2.wikia.com/wiki/Avenger#Gameplay",
	"http://fa-d2.wikia.com/wiki/Diarmuid#Gameplay",
	"http://fa-d2.wikia.com/wiki/Lancelot#Gameplay",
	"http://fa-d2.wikia.com/wiki/Gilles_de_Rais#Gameplay",
	"http://fa-d2.wikia.com/wiki/Iskander#Gameplay",
	"http://fa-d2.wikia.com/wiki/Nero#Gameplay",
	"http://fa-d2.wikia.com/wiki/Saber_(Gawain)#Gameplay",
	"http://fa-d2.wikia.com/wiki/Tamamo_no_Mae#Gameplay",
	"http://fa-d2.wikia.com/wiki/Assassin_%28Li_Shu_Wen%29#Gameplay",
	"http://fa-d2.wikia.com/wiki/Jeanne_d%27Arc#Gameplay",
	"http://fa-d2.wikia.com/wiki/Jeanne_d%27Arc#Gameplay",
	"http://fa-d2.wikia.com/wiki/Rider_of_Black#Gameplay",
	"http://fa-d2.wikia.com/wiki/Rider_of_Black#Gameplay",   //placeholder for nursery rhyme's page
	"http://fa-d2.wikia.com/wiki/Rider_of_Black#Gameplay",   //placeholder for atalanta's page
]

function CreateContextAbilityPanel(panel, abilityname)
{
	var abilityPanel = $.CreatePanel("Panel", panel, "");
	abilityPanel.SetAttributeString("ability_name", abilityname);
	abilityPanel.BLoadLayout("file://{resources}/layout/custom_game/fateanother_context_ability.xml", false, false );
}

function OnHeroButtonShowTooltip()
{
    var panel = $.GetContextPanel();
    var name = panel.GetAttributeString("heroname", "");
    $.DispatchEvent('DOTAShowTextTooltip', panel, $.Localize('#' + name));
}

function OnHeroButtonHideTooltip()
{
    var panel = $.GetContextPanel();
    $.DispatchEvent( 'DOTAHideTextTooltip', panel );
}


function GetIndex(array, object)
{
	for (i=0; i<array.length; i++)
	{
		if (array[i] == object) 
		{
			return i
			
		}
	}
	return -1
}
function CreateAbilityPanelFatepedia(panel, position, ability_name, isAttribute)
{
	var abilityPanel = $.CreatePanel("Panel", panel, "");

	var margin_str = (isAttribute ? "margin-right" : "margin-left")
	var align = (isAttribute ? "right top" : "left top")

	abilityPanel.SetAttributeString("ability_name", ability_name);
	abilityPanel.BLoadLayout("file://{resources}/layout/custom_game/fateanother_context_ability.xml", false, false );

	abilityPanel.style["align"] = align + ";"
	//var init_pos = (parent_position + 1)*55 - 55 + parent_position*10
	//var pos = init_pos - (length-1)*10/2 - (length-1)*55/2
	var truepos = (position + 1)*55 - 55 + position*10 + 7
	abilityPanel.style[margin_str] = truepos + "px;";
	abilityPanel.style["margin-top"] = 7 + "px;";
}
function CreateSubSkillPanel(panel, row, position, length, isAttribute)
{
	var abilityPanel = $.CreatePanel("Panel", panel, "")
	abilityPanel.BLoadLayout("file://{resources}/layout/custom_game/fateanother_fatepedia_skillpanel.xml", false, false );
	var margin_str = (isAttribute ? "margin-right" : "margin-left")
	var align = (isAttribute ? "right top" : "left top")

	var init_pos = (position + 1)*55 - 55 + position*10
	var pos = init_pos
	if (row > 0) {
		pos = init_pos - (length-1)*10/2 - (length-1)*55/2
	}
	var margin_horizontal = pos + 140;
	var margin_vertical = (row + 1)*55 - 55 + row*50 + 50

	var width = 55*length + 10*(length-1) + 20
	var height = 75

	if (row > 0) {
		var pointerPanel = $.CreatePanel("Panel", panel, "")
		pointerPanel.style["width"] = 50 + "px;"
		pointerPanel.style["height"] = 30 + 106*(row-1) + "px;"
		pointerPanel.style["align"] = align + ";"
		pointerPanel.style["background-image"] = "url('s2r://panorama/images/misc/simple_rope.png');"
		pointerPanel.style[margin_str] = init_pos + 153 + "px;";
		pointerPanel.style["margin-top"] = 125 + "px;";
	}

	abilityPanel.style[margin_str] = margin_horizontal + "px;";
	abilityPanel.style["margin-top"] = margin_vertical + "px;";
	abilityPanel.style["align"] = align + ";"
	abilityPanel.style["border-radius"] = "7px 7px 7px 7px;"
	abilityPanel.style["border"] = "3px solid #939da0;"

	abilityPanel.style["background-color"] = "#939da0;"
	abilityPanel.style["width"]	= width + "px;"
	abilityPanel.style["height"] = height + "px;"
	return abilityPanel
}
function OnHeroButtonPressed() {

    var name = $.GetContextPanel().GetAttributeString("heroname", "");
    var parentPanel = $.GetContextPanel().GetParent().GetParent();
    var infoPanel = parentPanel.FindChildInLayoutFile("FatepediaHeroInfoPanel");
    var portraitPanel = parentPanel.FindChildInLayoutFile("FatepediaHeroIntroImage");
    var namePanel = parentPanel.FindChildInLayoutFile("FatepediaHeroName");
    var skillPanel = parentPanel.FindChildInLayoutFile("FatepediaHeroSkillPanel");
    var attrPanel = parentPanel.FindChildInLayoutFile("FatepediaHeroAttrPanel");
    //var linkPanel = parentPanel.FindChildInLayoutFile("WikiLink");
    var directory = "url('s2r://panorama/images/custom_game/portrait/";
    //$.Msg(name + " " + curIndex);
    //$.Msg(skillPanel);

    skillPanel.RemoveAndDeleteChildren();
    attrPanel.RemoveAndDeleteChildren();

    infoPanel.visible = true;
	namePanel.text = $.Localize('#' + name);
    portraitPanel.style["background-image"] = directory +  name + ".png');"; // portrait
	//namePanel.text = "#npc_dota_hero_legion_commander";
 
    // herodata
    var heroesdata = PlayerTables.GetTableValue("hero_selection_heroes_data", name);

    //regular abilities
    var heroabil = heroesdata["abilities"];
    var herolinked = heroesdata["linked_abilities"]
    var herolinkedrow = heroesdata["linked_abilities_row"]

    var abillength = Object.keys(heroabil).length
    var subSkillPanel = CreateSubSkillPanel(skillPanel, 0, 0, abillength, false)
    for (i=0; i<abillength; i++) {
    	CreateAbilityPanelFatepedia(subSkillPanel, i, heroabil[i+1], false);
    	if (herolinked[i+1] != null){
    		var curlinklength = Object.keys(herolinked[i+1]).length;
    		var currow = herolinkedrow[i+1]
    		var subLinkedPanel = CreateSubSkillPanel(skillPanel, currow, i, curlinklength, false)
    		for (j=0; j<curlinklength; j++) {
    			CreateAbilityPanelFatepedia(subLinkedPanel, j, herolinked[i+1][j+1], false);
    		}
    	}
    }

    //attributes and combo

    var heroatrandcombo = heroesdata["attributesandcombo"]
    var herolinkedatr = heroesdata["linked_attributes"]
    var herolinkedatrrow = heroesdata["linked_attributes_row"]

    var atrlength = Object.keys(heroatrandcombo).length
    var subAtrPanel = CreateSubSkillPanel(attrPanel, 0, 0, atrlength, true)
    for (i=0; i<atrlength; i++) {
    	CreateAbilityPanelFatepedia(subAtrPanel, atrlength - i - 1, heroatrandcombo[i+1], true);
    	if (herolinkedatr[i+1] != null){
	    	var curlinklength = Object.keys(herolinkedatr[i+1]).length;
	    	var currow = herolinkedatrrow[i+1]
    		var subLinkedPanel = CreateSubSkillPanel(attrPanel, currow, atrlength - i - 1, curlinklength, true)
	    	for (j=0; j<curlinklength; j++) {
	    		//$.Msg(herolinkedatr[i+1][j+1])
	    		CreateAbilityPanelFatepedia(subLinkedPanel, curlinklength - j - 1, herolinkedatr[i+1][j+1], true);
	    	}
	    }
    }

    var herostats = heroesdata["attributes"]
    $.Msg(herostats)
    //CreateContextAbilityPanel(skillPanel, comboes[curIndex]);
    // attributes 
	//linkPanel.text = '<a href="http://www.w3schools.com/html/">Visit our HTML tutorial</a>';
	//linkPanel.text = '<a href="' + guidelinks[curIndex] + '">Double click here for hero build and tips!</a>';
	//"&lt;a href=&quot;" + guidelinks[curIndex] + "&quot;&gt;Click here for quick build guide and tips!&lt;/a&gt;";
	//linkPanel.text = "FatepediaSkillContextText" id="WikiLink" text="&lt;a href=&quot;http://fa-d2.wikia.com/wiki/Gilgamesh#MAX_Enuma_Elish_.28Combo.29&quot;&gt;Click here for quick build guide and tips!&lt;a&gt;";
	//linkPanel.html = guidelinks[curIndex];

}

(function () {

})();