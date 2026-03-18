var globalContext = $.GetContextPanel();

function UpdateHotkey(data)
{
	if (data[0] == null) {
		for (var a = 0; a < 11; a++) {
			data[a] = data[a+1];
		}
	}

	var altButton = CMD.container.FindChildTraverse("AltButton");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButton");
    var fButton = CMD.container.FindChildTraverse("FButton");
	var altButtonBuy = CMD.container.FindChildTraverse("AltButtonBuy");
    var ctrlButtonBuy = CMD.container.FindChildTraverse("CtrlButtonBuy");
    var fButtonBuy = CMD.container.FindChildTraverse("FButtonBuy");
	for (var i = 0; i < 6; i++) {
		var seal_button = CMD.sealContainer.GetChild(i)
		var slabel = seal_button.GetChild(0);
		if (!data[i]) {
			data[i] = "";
		}
		slabel.text = data[i];
		if (slabel.text !== "" && slabel.text !== " ") {
			//$.Msg(slabel.text.length)
			if (slabel.text.length == 5) {
				altButton.checked = true;
				slabel.style["font-size"] = "30px";
			} else if (slabel.text.length == 6) {
				ctrlButton.checked = true;
				slabel.style["font-size"] = "30px";
			} else if (slabel.text.length == 2) {
				fButton.checked = true;
				slabel.style["font-size"] = "50px";
			}
		}
		if (i < 5) {
			var item_button = CMD.quickbuyContainer.GetChild(i)
			var qlabel = item_button.GetChild(1).GetChild(0);
			if (!data[i+6]) {
				data[i+6] = "";
			}
			qlabel.text = data[i+6];
			if (qlabel.text !== "" && qlabel.text !== " ") {
				if (qlabel.text.length == 5) {
					altButtonBuy.checked = true;
					qlabel.style["font-size"] = "30px";
				} else if (slabel.text.length == 6) {
					ctrlButtonBuy.checked = true;
					qlabel.style["font-size"] = "30px";
				} else if (slabel.text.length == 2) {
					fButtonBuy.checked = true;
					qlabel.style["font-size"] = "50px";
				}
			}
		}
	}
}

function OnHotkeySubmitted()
{
	var hotkey = $("#HotkeyEntry").text;
	//$.Msg(hotkey);
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var prefix = "";
    var ibutton = CMD.currentButton

    var button = CMD.sealContainer.FindChild(ibutton);
    var altButton = CMD.container.FindChildTraverse("AltButton");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButton");
    var fButton = CMD.container.FindChildTraverse("FButton");

    if (ibutton >= 6) {
    	button = CMD.quickbuyContainer.FindChild(ibutton - 6).GetChild(1);
    	altButton = CMD.container.FindChildTraverse("AltButtonBuy");
    	ctrlButton = CMD.container.FindChildTraverse("CtrlButtonBuy");
    	fButton = CMD.container.FindChildTraverse("FButtonBuy");
    };
    //$.Msg(button);
    var label = button.GetChild(0);
    

    if (hotkey == "" || hotkey == " ") {
    	prefix = "";
    	hotkey = "";
    } else if (altButton.checked == true) {
    	prefix = "ALT+";
    	label.style["font-size"] = "30px";
    } else if (ctrlButton.checked == true) {
    	prefix = "CTRL+";
    	label.style["font-size"] = "30px";
    } else if (fButton.checked == true) {
    	prefix = "F";
    	label.style["font-size"] = "50px";
    }  
    //$.Msg(label.text);
    label.text = prefix + hotkey;
    CMD.entryContainer.visible = false;
    CMD.currentpanel.SetHasClass("GrowBorder", false)
    $("#HotkeyEntry").text = " ";
    $("#HotkeyEntry").text = "";
}

function OnAltButtonToggle()
{
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var altButton = CMD.container.FindChildTraverse("AltButton");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButton");
    var fButton = CMD.container.FindChildTraverse("FButton");

    var total_childred = CMD.sealContainer.GetChildCount();

	for (i=0; i < total_childred ; i++) {
		var seal_button = CMD.sealContainer.GetChild(i)
		var label = seal_button.GetChild(0);
		if (ctrlButton.checked == true) {
			label.text = label.text.substring(5);
		} else if (fButton.checked == true) {
			label.text = label.text.substring(1);
		}
		if (label.text == "" || label.text == " ") {
			label.text = "";
		} else {
			if (altButton.checked == true) {
				label.text = "ALT+" + label.text;
				label.style["font-size"] = "30px";
			} else {
				label.text = label.text.substring(4);
				label.style["font-size"] = "55px";
			}
		}
	}
	ctrlButton.checked = false;
	fButton.checked = false;
}

function OnCtrlButtonToggle()
{
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var altButton = CMD.container.FindChildTraverse("AltButton");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButton");
    var fButton = CMD.container.FindChildTraverse("FButton");

    var total_childred = CMD.sealContainer.GetChildCount();

	for (i=0; i < total_childred ; i++) {
		var seal_button = CMD.sealContainer.GetChild(i);
		var label = seal_button.GetChild(0);
		if (altButton.checked == true) {
			label.text = label.text.substring(4);
		} else if (fButton.checked == true) {
			label.text = label.text.substring(1);
		}
		if (label.text == "" || label.text == " ") {
			label.text = "";
		} else {
			if (ctrlButton.checked == true) {
				label.text = "CTRL+" + label.text;
				label.style["font-size"] = "30px";
			} else {
				label.text = label.text.substring(5);
				label.style["font-size"] = "55px";
			}
		}
	}
    altButton.checked = false;
    fButton.checked = false;
}

function OnFButtonToggle()
{
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var altButton = CMD.container.FindChildTraverse("AltButton");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButton");
    var fButton = CMD.container.FindChildTraverse("FButton");

    var total_childred = CMD.sealContainer.GetChildCount();

	for (i=0; i < total_childred ; i++) {
		var seal_button = CMD.sealContainer.GetChild(i);
		var label = seal_button.GetChild(0);
		if (altButton.checked == true) {
			label.text = label.text.substring(4);
		} else if (ctrlButton.checked == true) {
			label.text = label.text.substring(5);
		}
		if (label.text == "" || label.text == " ") {
			label.text = "";
		} else {
			if (fButton.checked == true) {
				label.text = "F" + label.text;
				label.style["font-size"] = "50px";
			} else {
				label.text = label.text.substring(1);
				label.style["font-size"] = "55px";
			}
		}
	}
    altButton.checked = false;
    ctrlButton.checked = false;
}

function OnAltButtonBuyToggle()
{
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var altButton = CMD.container.FindChildTraverse("AltButtonBuy");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButtonBuy");
    var fButton = CMD.container.FindChildTraverse("FButtonBuy");

    var total_childred = CMD.quickbuyContainer.GetChildCount();

	for (i=0; i < total_childred ; i++) {
		var item_button = CMD.quickbuyContainer.GetChild(i)
		var label = item_button.GetChild(1).GetChild(0);
		if (ctrlButton.checked == true) {
			label.text = label.text.substring(5);
		} else if (fButton.checked == true) {
			label.text = label.text.substring(1);
		}
		if (label.text == "" || label.text == " ") {
			label.text = "";
		} else {
			if (altButton.checked == true) {
				label.text = "ALT+" + label.text;
				label.style["font-size"] = "30px";
			} else {
				label.text = label.text.substring(4);
				label.style["font-size"] = "55px";
			}
		}
	}
	ctrlButton.checked = false;
	fButton.checked = false;
}

function OnCtrlButtonBuyToggle()
{
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var altButton = CMD.container.FindChildTraverse("AltButtonBuy");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButtonBuy");
    var fButton = CMD.container.FindChildTraverse("FButtonBuy");

    var total_childred = CMD.quickbuyContainer.GetChildCount();

	for (i=0; i < total_childred ; i++) {
		var item_button = CMD.quickbuyContainer.GetChild(i);
		var label = item_button.GetChild(1).GetChild(0);
		if (altButton.checked == true) {
			label.text = label.text.substring(4);
		} else if (fButton.checked == true) {
			label.text = label.text.substring(1);
		}
		if (label.text == "" || label.text == " ") {
			label.text = "";
		} else {
			if (ctrlButton.checked == true) {
				label.text = "CTRL+" + label.text;
				label.style["font-size"] = "30px";
			} else {
				label.text = label.text.substring(5);
				label.style["font-size"] = "55px";
			}
		}
	}
    altButton.checked = false;
    fButton.checked = false;
}

function OnFButtonBuyToggle()
{
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var altButton = CMD.container.FindChildTraverse("AltButtonBuy");
    var ctrlButton = CMD.container.FindChildTraverse("CtrlButtonBuy");
    var fButton = CMD.container.FindChildTraverse("FButtonBuy");

    var total_childred = CMD.quickbuyContainer.GetChildCount();

	for (i=0; i < total_childred ; i++) {
		var item_button = CMD.quickbuyContainer.GetChild(i);
		var label = item_button.GetChild(1).GetChild(0);
		if (altButton.checked == true) {
			label.text = label.text.substring(4);
		} else if (ctrlButton.checked == true) {
			label.text = label.text.substring(5);
		}
		if (label.text == "" || label.text == " ") {
			label.text = "";
		} else {
			if (fButton.checked == true) {
				label.text = "F" + label.text;
				label.style["font-size"] = "50px";
			} else {
				label.text = label.text.substring(1);
				label.style["font-size"] = "55px";
			}
		}
	}
    altButton.checked = false;
    ctrlButton.checked = false;
}

function SealButtonApply()
{
	$.Msg("apply button");
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
        return;
    };

    var hero = Players.GetPlayerHeroEntityIndex( playerId );
    var name = Entities.GetUnitName( hero);
    if (name == "npc_dota_hero_wisp") {
    	return;
    };

	const iRandomNumberCringe = Math.floor(Math.random() * 999999) * 6;
	if (iRandomNumberCringe < 99999) {
		iRandomNumberCringe = 300000;
	}
    for (var i = 0; i < 5; i++) {
        var hk = i + 1;
        var seal = i;
        if (i == 3) {
            seal = 5;
        } else if (i == 4) {
            seal = 3;
        };
        var num = iRandomNumberCringe + hk;
        if (CMD.commandreg[i] !== 9999) {
        	num = CMD.commandreg[i];
        }
        $.Msg(num)
    	var seal_button = CMD.sealContainer.GetChild(i)
		var label = seal_button.GetChild(0);
		if (label.text !== "") {
			if (CMD.sealreg[i] == "false") {
		        Game.AddCommand("+ACT_CMD_" + num, SealHotkeys(seal), "" + num, 512);
		        Game.AddCommand("-ACT_CMD_" + num, Null, "" + num, 512);
		        if (num > 99999) {
		        	CMD.sealreg[i] = "true";
		        }
		        CMD.commandreg[i] = num;
		    }
			Game.CreateCustomKeyBind( label.text, "+ACT_CMD_" + num );
        	AddHotkey("cmd_seal_" + hk, label.text);
        	CMD.hotkeylist[i] = label.text
        }

        if (i < 5) {
        	// item regist
        	var item_num = iRandomNumberCringe + hk + 6;
        	if (CMD.quickbuyreg[i] !== 9999) {
	        	item_num = CMD.quickbuyreg[i];
	        }
	        var item_button = CMD.quickbuyContainer.GetChild(i)
			var label = item_button.GetChild(1).GetChild(0);
			if (label.text !== "") {
				if (CMD.itemreg[i] == "false") {
			        Game.AddCommand("+ACT_CMD_" + item_num, QuickBuyHotkeys(i), "" + item_num, 512);
			        Game.AddCommand("-ACT_CMD_" + item_num, Null, "" + item_num, 512);
			        if (item_num > 99999) {
			        	CMD.itemreg[i] = "true";
			        }
			        CMD.quickbuyreg[i] = item_num;
			    }
				Game.CreateCustomKeyBind( label.text, "+ACT_CMD_" + item_num );
				CMD.hotkeylist[i+6] = label.text
	        }
        }
    };
    var PRnum = iRandomNumberCringe + 6;
    if (CMD.commandreg[5] !== 9999) {
       	PRnum = CMD.commandreg[5];
    }
    var scan_button = CMD.sealContainer.GetChild(5)
	var slabel = scan_button.GetChild(0);
	if (slabel.text !== "") {
		if (CMD.sealreg[5] == "false") {
		    Game.AddCommand("+ACT_CMD_" + PRnum, SealHotkeys(4), "" + PRnum, 512);
		    Game.AddCommand("-ACT_CMD_" + PRnum, Null, "" + PRnum, 512);
		    if (PRnum > 99999) {
		    	CMD.sealreg[5] = "true";
		    }
		    CMD.commandreg[i] = PRnum;
		}
		Game.CreateCustomKeyBind( slabel.text, "+ACT_CMD_" + PRnum );
    	AddHotkey("master_presence_resonator", slabel.text);
    	CMD.hotkeylist[5] = slabel.text
    }

    GameEvents.SendCustomGameEventToServer("player_regist_fate_hotkey", {sHotkey: CMD.hotkeylist});
}

function AddHotkey(Seal, Hotkey)
{
    // var panel = GetHUDRootUI().FindChildTraverse("MasterBar").FindChildTraverse("MasterBarSeals");
    // var button = panel.FindChildTraverse(Seal);
    // button.FindChildTraverse("HotkeyContainer").visible = true;
    // button.FindChildTraverse("HotkeyContainer").FindChildTraverse("HotkeyText").text = Hotkey;
}

function Null() 
{

}

function SealHotkeys(Seal)
{
    return function () 
    {
        $.Msg('Set is Press or Release');
        $.Msg( Seal + ' is Press');
        var panel = GetHUDRootUI().FindChildTraverse("MasterBar");
        var iPID = Game.GetLocalPlayerID();

        if (Players.IsSpectator(iPID)) {
            return;
        };

        var hero = Players.GetPlayerHeroEntityIndex( iPID );
        var name = Entities.GetUnitName(hero);

        if (name == "npc_dota_hero_wisp") {
        	return;
        };
        

        if (panel.visible == true && Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            if (name !== "npc_dota_hero_wisp") {
                $.Msg('master ' + CMD.MasterUnit);
                $.Msg('hotkey ' + Seal);
                var ability = Entities.GetAbility(CMD.MasterUnit, Seal);
                GameEvents.SendCustomGameEventToServer("player_cast_seal", {iUnit: CMD.MasterUnit, iAbility: ability});
            };
        };
    }
}

function QuickBuyHotkeys(item_order)
{
    return function () 
    {
        var iPID = Game.GetLocalPlayerID();

        if (Players.IsSpectator(iPID)) {
            return;
        };

        var hero = Players.GetPlayerHeroEntityIndex( iPID );
        var name = Entities.GetUnitName(hero);

        if (name == "npc_dota_hero_wisp") {
        	return;
        };

        var item_name = CMD.item_list[item_order];
        //$.Msg(item_name);

        if (Players.GetSelectedEntities( iPID ) == Players.GetPlayerHeroEntityIndex( iPID )) {
            GameEvents.SendCustomGameEventToServer("player_quick_buy_custom", {iHero: hero, sItem: item_name});
        };
    }
}

function SealHotkeyConfig() {
	var that = this;
	this.playerId = Game.GetLocalPlayerID();
	this.container = globalContext;
	this.sealContainer = this.container.FindChildTraverse("SealContainer");
	this.quickbuyContainer = this.container.FindChildTraverse("QuickBuyContainer");
	this.entryContainer = this.container.FindChildTraverse("HotkeyEntryPanel");
	this.itemListContainer = this.container.FindChildTraverse("ItemListContainer");
	this.hotkeyInput = "";
	this.currentButton = -1;
	this.item_choose = "";
	this.currentpanel = null;
	this.MasterUnit
	this.commandreg = [
		9999,
		9999,
		9999,
		9999,
		9999,
		9999,
	]
	this.sealreg = [
		"false",
		"false",
		"false",
		"false",
		"false",
		"false",
	]
	this.item_list = [
		"item_mana_essence",
		"item_c_scroll",
		"item_healing_scroll",
		"item_a_plus_scroll",
		"item_gem_of_speed",
	]
	this.item_option = [
		"item_condensed_mana_essence",
		"item_b_scroll",
		"item_a_scroll",
		"item_a_plus_scroll",
		"item_s_scroll",
		"item_ex_scroll",
		"item_d_scroll",
		"item_e_scroll",
		"item_healing_scroll",
		"item_berserk_scroll",
		"item_spirit_link",
		"item_ward_familiar",
		"item_sentry_familiar",
		"item_gem_of_speed",
		"item_teleport_scroll",
	]
	this.quickbuyreg = [
		9999,
		9999,
		9999,
		9999,
		9999,
	]
	this.itemreg = [
		"false",
		"false",
		"false",
		"false",
		"false",
	]
	this.hotkeylist = [
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
	]
	
	this.Construct();
	this.entryContainer.visible = false;
	this.itemListContainer.visible = false;
	GameEvents.Subscribe( "player_regist_hotkey", UpdateHotkey);
	GameEvents.Subscribe("player_selected_hero", function (data) {
        CMD.MasterUnit = data.shardUnit;
    });
	//GameEvents.Subscribe( "fate_serv_statistic_sort_all", UpdateDataAll);
}

SealHotkeyConfig.prototype.Construct = function() {
	var that = this;
	//var total_childred = this.sealContainer.GetChildCount()
	var directory = "url('s2r://panorama/images/spellicons/";
	var directory_item = "url('s2r://panorama/images/items/";

	for (i=0; i < 6 ; i++) {
		var seal_button = this.sealContainer.FindChild(i);
        if (seal_button == null) {
        	seal_button = $.CreatePanel("Panel", this.sealContainer, i);
        	
			var ability = "cmd_seal_" + (i + 1);
			//$.Msg(seal_button);
			if (i == 4) {
				ability = "master_intervention"
			}
			if (i == 5) {
				ability = "master_resonator"
			}
			seal_button.BLoadLayoutSnippet('SealContainerSnippet');
			seal_button.style["background-image"] = directory + ability + "_png.vtex')";
			this.HotKeyBoxOpen(seal_button, ability, i);
		}
	}

	for (i=0; i < 5 ; i++) {
		var item_button = this.quickbuyContainer.FindChild(i);
        if (item_button == null) {
        	item_button = $.CreatePanel("Panel", this.quickbuyContainer, i);
        	
			var item = this.item_list[i];
			item = item.slice(5)

			item_button.BLoadLayoutSnippet('QuickBuyContainerSnippet');
			item_button.GetChild(1).style["background-image"] = directory_item + item + "_png.vtex')";
			this.HotKeyBoxOpen(item_button.GetChild(1), item, i + 6);
			if (i < 2) {
				item_button.GetChild(0).visible = false;
			} else {
				this.ArrowOpen(item_button.GetChild(0), item, i);
			}
		}
	}

	for (i=0; i < 15 ; i++) {
		var item_option = this.itemListContainer.FindChild(i);
        if (item_option == null) {
        	item_option = $.CreatePanel("Panel", this.itemListContainer, i);
        	
			var item = this.item_option[i];

			item_option.BLoadLayoutSnippet('ItemListContainerSnippet');
			item_option.style["background-image"] = directory_item + item + "_png.vtex')";
			this.ChangeItemList(item_option, item, );
		}
	}
}

SealHotkeyConfig.prototype.HotKeyBoxOpen = function(panel, ability_name, iButton) {
    var that = this;
    if (this.playerId == null) {
    	//$.Msg('this.playerId cannot found');
    	this.playerId = Game.GetLocalPlayerID();
    };
    if (Players.IsSpectator(this.playerId)) {
    	//$.Msg('spectator');
        return;
    };
    
    //$.Msg(panel);
    panel.SetPanelEvent("onmouseactivate",
		function() {
			if (CMD.entryContainer.visible == true) {
		    	//$.Msg('already open ');
		    	CMD.currentpanel.SetHasClass("GrowBorder", false)
		    	CMD.entryContainer.visible = false;
		    	return;
		    }
		    if (CMD.itemListContainer.visible == true) {
		    	return;
		    }
			//$.Msg('open box');
			panel.SetHasClass("GrowBorder", true)
			CMD.currentButton = iButton;
		    CMD.entryContainer.visible = true;
		    CMD.itemListContainer.visible = false;
		    CMD.currentpanel = panel
		}
	);
}

SealHotkeyConfig.prototype.ArrowOpen = function(panel, ability_name, iButton) {
    var that = this;
    if (this.playerId == null) {
    	//$.Msg('this.playerId cannot found');
    	this.playerId = Game.GetLocalPlayerID();
    };
    if (Players.IsSpectator(this.playerId)) {
    	//$.Msg('spectator');
        return;
    };
    
    //$.Msg(panel);
    panel.SetPanelEvent("onmouseactivate",
		function() {
			if (CMD.itemListContainer.visible == true) {
		    	//$.Msg('already open ');
		    	CMD.quickbuyContainer.FindChild(CMD.currentButton).GetChild(0).style["background-img-opacity"] = 0.1;
		    	CMD.itemListContainer.visible = false;
		    	return;
		    }

		    if (CMD.entryContainer.visible == true) {
		    	return;
		    }
			//$.Msg('open box');
			panel.style["background-img-opacity"] = 1.0;
			CMD.entryContainer.visible = false;
			CMD.currentButton = iButton;
		    CMD.itemListContainer.visible = true;
		}
	);
}

SealHotkeyConfig.prototype.ChangeItemList = function(panel, item_name) {
    var that = this;

    panel.SetPanelEvent("onmouseactivate",
		function() {
			var qButton = CMD.currentButton;
			CMD.item_list[qButton] = item_name;
			var item_button = CMD.quickbuyContainer.FindChild(qButton);
			item_button.GetChild(1).style["background-image"] = "url('s2r://panorama/images/items/" + item_name + "_png.vtex')";
			CMD.itemListContainer.visible = false;
			CMD.quickbuyContainer.FindChild(qButton).GetChild(0).style["background-img-opacity"] = 0.1;
		}
	);
}

var CMD = new SealHotkeyConfig();