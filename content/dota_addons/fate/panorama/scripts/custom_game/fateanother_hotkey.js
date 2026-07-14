var globalContext = $.GetContextPanel();

function UpdateHotkey(data)
{
	if (data[0] == null) {
		for (var a = 0; a < 14; a++) {
			data[a] = data[a+1];
		}
	}

	for (var i = 0; i < 6; i++) {
		var seal_button = CMD.sealContainer.GetChild(i);
		if (seal_button) {
			if (!data[i]) { data[i] = ""; }
			seal_button.GetChild(0).text = data[i];
		}
	}
	for (var k = 0; k < CMD.quickbuyContainer.GetChildCount(); k++) {
		var item_button = CMD.quickbuyContainer.GetChild(k);
		if (item_button) {
			if (!data[k+6]) { data[k+6] = ""; }
			item_button.GetChild(1).GetChild(0).text = data[k+6];
		}
	}
}

function OnHotkeySubmitted()
{
	var hotkey = $("#HotkeyEntry").text;
	var playerId = Game.GetLocalPlayerID();

	if (Players.IsSpectator(playerId)) {
		return;
	}

	var ibutton = CMD.currentButton;
	if (ibutton == null || ibutton < 0) {
		return;
	}

	var button = CMD.sealContainer.FindChild(ibutton);
	if (ibutton >= 6) {
		button = CMD.quickbuyContainer.FindChild(ibutton - 6).GetChild(1);
	}
	if (!button) {
		return;
	}

	var label = button.GetChild(0);
	var altButton = CMD.container.FindChildTraverse("EntryAltButton");
	var fButton = CMD.container.FindChildTraverse("EntryFButton");

	var prefix = "";
	if (hotkey == "" || hotkey == " ") {
		hotkey = "";
	} else if (altButton && altButton.checked == true) {
		prefix = "ALT+";
	} else if (fButton && fButton.checked == true) {
		prefix = "F";
	}

	label.text = prefix + hotkey;
	MarkApplyDirty();
	CMD.entryContainer.visible = false;
	if (CMD.currentpanel) {
		CMD.currentpanel.SetHasClass("GrowBorder", false);
	}
	$("#HotkeyEntry").text = "";
	BlurHotkeyEntry();
}

function OnEntryAltToggle()
{
	var altButton = CMD.container.FindChildTraverse("EntryAltButton");
	var fButton = CMD.container.FindChildTraverse("EntryFButton");
	if (altButton && altButton.checked == true && fButton) {
		fButton.checked = false;
	}
	FocusHotkeyEntry();
}

function OnEntryFToggle()
{
	var altButton = CMD.container.FindChildTraverse("EntryAltButton");
	var fButton = CMD.container.FindChildTraverse("EntryFButton");
	if (fButton && fButton.checked == true && altButton) {
		altButton.checked = false;
	}
	FocusHotkeyEntry();
}

function OnHotkeyClear()
{
	var ibutton = CMD.currentButton;
	if (ibutton != null && ibutton >= 0) {
		var button = CMD.sealContainer.FindChild(ibutton);
		if (ibutton >= 6) {
			button = CMD.quickbuyContainer.FindChild(ibutton - 6).GetChild(1);
		}
		if (button) {
			button.GetChild(0).text = "";
		}
	}
	MarkApplyDirty();
	CMD.entryContainer.visible = false;
	if (CMD.currentpanel) {
		CMD.currentpanel.SetHasClass("GrowBorder", false);
	}
	$("#HotkeyEntry").text = "";
	BlurHotkeyEntry();
	var altButton = CMD.container.FindChildTraverse("EntryAltButton");
	var fButton = CMD.container.FindChildTraverse("EntryFButton");
	if (altButton) { altButton.checked = false; }
	if (fButton) { fButton.checked = false; }
}

// Скрытая панель сохраняет input focus, а осиротевший фокус движок отдаёт
// полю чата — поэтому фокус ОБЯЗАН сниматься на каждом пути закрытия попапа.
function BlurHotkeyEntry()
{
	var entry = $("#HotkeyEntry");
	if (entry != null && entry.IsValid()) {
		$.DispatchEvent("DropInputFocus", entry);
	}
}

function FocusHotkeyEntry()
{
	var entry = $("#HotkeyEntry");
	$.Schedule(0.0, function () {
		if (entry == null || !entry.IsValid()) { return; }
		// Попап могли успеть закрыть до отложенного вызова.
		if (CMD.entryContainer == null || CMD.entryContainer.visible !== true) { return; }
		entry.SetFocus();
	});
}

function OnQuickcastToggle()
{
	var t = CMD.container.FindChildTraverse("QuickcastToggle");
	if (t) {
		CMD.quickcast = t.checked;
	}
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

	var iRandomNumberCringe = Math.floor(Math.random() * 999999) * 6;
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
		        CMD.cmdCallbacks[num] = SealHotkeys(seal, num); Game.AddCommand("+ACT_CMD_" + num, CMD.cmdCallbacks[num], "" + num, 512);
		        Game.AddCommand("-ACT_CMD_" + num, Null, "" + num, 512);
		        if (num > 99999) {
		        	CMD.sealreg[i] = "true";
		        }
		        CMD.commandreg[i] = num;
		    }
			RebindKey( num, label.text );
        	AddHotkey("cmd_seal_" + hk, label.text);
        	CMD.hotkeylist[i] = label.text
        } else {
        	DisableBind(num);
        	CMD.hotkeylist[i] = "";
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
			        CMD.cmdCallbacks[item_num] = QuickBuyHotkeys(i, item_num); Game.AddCommand("+ACT_CMD_" + item_num, CMD.cmdCallbacks[item_num], "" + item_num, 512);
			        Game.AddCommand("-ACT_CMD_" + item_num, Null, "" + item_num, 512);
			        if (item_num > 99999) {
			        	CMD.itemreg[i] = "true";
			        }
			        CMD.quickbuyreg[i] = item_num;
			    }
				RebindKey( item_num, label.text );
				CMD.hotkeylist[i+6] = label.text
	        } else {
	        	DisableBind(item_num);
	        	CMD.hotkeylist[i+6] = "";
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
		    CMD.cmdCallbacks[PRnum] = SealHotkeys(4, PRnum); Game.AddCommand("+ACT_CMD_" + PRnum, CMD.cmdCallbacks[PRnum], "" + PRnum, 512);
		    Game.AddCommand("-ACT_CMD_" + PRnum, Null, "" + PRnum, 512);
		    if (PRnum > 99999) {
		    	CMD.sealreg[5] = "true";
		    }
		    CMD.commandreg[i] = PRnum;
		}
		RebindKey( PRnum, slabel.text );
    	AddHotkey("master_presence_resonator", slabel.text);
    	CMD.hotkeylist[5] = slabel.text
    } else {
    	DisableBind(PRnum);
    	CMD.hotkeylist[5] = "";
    }

    // Extra quick-buy slots beyond the original 5 (item_num = base + index + 7,
    // matching the formula used in the seal loop above).
    for (var j = 5; j < CMD.item_list.length; j++) {
        var xitem_num = iRandomNumberCringe + j + 7;
        if (CMD.quickbuyreg[j] !== 9999) {
            xitem_num = CMD.quickbuyreg[j];
        }
        var xitem_button = CMD.quickbuyContainer.GetChild(j);
        var xlabel = xitem_button.GetChild(1).GetChild(0);
        if (xlabel.text !== "") {
            if (CMD.itemreg[j] == "false") {
                CMD.cmdCallbacks[xitem_num] = QuickBuyHotkeys(j, xitem_num); Game.AddCommand("+ACT_CMD_" + xitem_num, CMD.cmdCallbacks[xitem_num], "" + xitem_num, 512);
                Game.AddCommand("-ACT_CMD_" + xitem_num, Null, "" + xitem_num, 512);
                if (xitem_num > 99999) {
                    CMD.itemreg[j] = "true";
                }
                CMD.quickbuyreg[j] = xitem_num;
            }
            RebindKey( xitem_num, xlabel.text );
            CMD.hotkeylist[j+6] = xlabel.text;
        } else {
            DisableBind(xitem_num);
            CMD.hotkeylist[j+6] = "";
        }
    }

    GameEvents.SendCustomGameEventToServer("player_regist_fate_hotkey", {sHotkey: CMD.hotkeylist});

    // Visual feedback: flash the button, then mark the system as active.
    var applyBtn = CMD.container.FindChildTraverse("SealApplyButton");
    var applyLabel = CMD.container.FindChildTraverse("SealApplyLabel");
    if (applyBtn) {
        applyBtn.RemoveClass("ApplyFlash");
        applyBtn.AddClass("ApplyActive");
        $.Schedule(0.0, function () { applyBtn.AddClass("ApplyFlash"); });
    }
    if (applyLabel) {
        applyLabel.text = "ACTIVE ✓";
    }
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

// Resets the Apply button back to its "not yet applied" look after the user
// edits a hotkey, so it's clear a fresh Apply is needed.
function MarkApplyDirty()
{
	var applyBtn = CMD.container.FindChildTraverse("SealApplyButton");
	var applyLabel = CMD.container.FindChildTraverse("SealApplyLabel");
	if (applyBtn) {
		applyBtn.RemoveClass("ApplyActive");
		applyBtn.RemoveClass("ApplyFlash");
	}
	if (applyLabel) {
		applyLabel.text = "Apply";
	}
}

// ---- Key dispatch layer.
// Game.CreateCustomKeyBind cannot bind modifier chords ("ALT+Q" is not a valid
// key name), so each physical key gets ONE dispatcher command and the ALT state
// is checked at press time via GameUI.IsAltDown(). A key whose plain action is
// unassigned falls back to casting the hero ability that key normally holds, so
// binding or clearing never leaves a dead key behind.
var KEY_ABILITY_SLOT = { "Q": 0, "W": 1, "E": 2, "D": 3, "F": 4, "R": 5 };

function MakeKeyDispatcher(baseKey)
{
	return function ()
	{
		var d = CMD.keydispatch[baseKey];
		if (!d) { return; }
		var altDown = GameUI.IsAltDown();
		var num = altDown ? d.alt : d.plain;
		$.Msg("[FateKey] " + baseKey + " alt=" + altDown + " plain=" + d.plain + " altcmd=" + d.alt + " chosen=" + num);
		if (num != null && CMD.cmdEnabled[num] !== false && CMD.cmdCallbacks[num]) {
			CMD.cmdCallbacks[num]();
			return;
		}
		if (!altDown && KEY_ABILITY_SLOT[baseKey] != null) {
			CastAbilitySlot(KEY_ABILITY_SLOT[baseKey])();
		}
	};
}

// Command names carry a per-instance random id: the panel gets recreated when
// the options screen reopens, and AddCommand refuses duplicate names — a stale
// instance would otherwise keep owning the key with dead state. With unique
// names each instance registers fresh and CreateCustomKeyBind re-points the key
// to the newest dispatcher (last one wins).
function EnsureKeyDispatch(baseKey)
{
	if (CMD.keydispatch[baseKey]) { return; }
	CMD.keydispatch[baseKey] = { plain: null, alt: null };
	var cmdName = "ACT_KEY_" + CMD.instanceId + "_" + baseKey;
	Game.AddCommand("+" + cmdName, MakeKeyDispatcher(baseKey), "", 512);
	Game.AddCommand("-" + cmdName, Null, "", 512);
	Game.CreateCustomKeyBind(baseKey, "+" + cmdName);
}

// Registered once per instance; a released ALT-chord bind is pointed here,
// since binds cannot be removed outright.
function EnsureNoopCommand()
{
	if (!CMD.noopCmdName) {
		CMD.noopCmdName = "+ACT_NOOP_" + CMD.instanceId;
		Game.AddCommand(CMD.noopCmdName, Null, "", 512);
		Game.AddCommand("-ACT_NOOP_" + CMD.instanceId, Null, "", 512);
	}
	return CMD.noopCmdName;
}

function ReleaseBindMapping(commandNum)
{
	var prev = CMD.boundkeys[commandNum];
	if (prev) {
		if (prev.direct) {
			Game.CreateCustomKeyBind(prev.direct, EnsureNoopCommand());
		} else if (CMD.keydispatch[prev.base]) {
			if (CMD.keydispatch[prev.base].plain === commandNum) {
				CMD.keydispatch[prev.base].plain = null;
			}
		}
	}
	CMD.boundkeys[commandNum] = null;
}

function RebindKey(commandNum, keyText)
{
	ReleaseBindMapping(commandNum);
	if (keyText.indexOf("ALT+") === 0) {
		// The engine accepts ALT chords as bind names directly (CTRL it does
		// not), and the ALT+X bind slot is independent from plain X, so the
		// hero keeps its ability on the bare key with no dispatcher involved.
		var chord = "ALT+" + keyText.substring(4).toUpperCase();
		Game.CreateCustomKeyBind(chord, "+ACT_CMD_" + commandNum);
		CMD.boundkeys[commandNum] = { direct: chord };
		CMD.cmdEnabled[commandNum] = true;
		return;
	}
	var base = keyText.toUpperCase();
	EnsureKeyDispatch(base);
	CMD.keydispatch[base].plain = commandNum;
	CMD.boundkeys[commandNum] = { base: base, alt: false };
	CMD.cmdEnabled[commandNum] = true;
}

// Casts the local hero's ability in the given slot; used by the key dispatcher
// as the fallback for plain ability keys (Q W E D F R) with no bind assigned.
function CastAbilitySlot(slot)
{
	return function ()
	{
		var pid = Game.GetLocalPlayerID();
		if (Players.IsSpectator(pid)) { return; }
		var hero = Players.GetPlayerHeroEntityIndex(pid);
		if (!hero || hero === -1) { return; }
		var ability = Entities.GetAbility(hero, slot);
		if (!ability || ability === -1) { return; }

		// Abilities.ExecuteAbility's bQuickCast argument is broken in this runtime
		// (passing true casts nothing), so quickcast is emulated with direct unit
		// orders aimed at the cursor; normal targeting is the fallback.
		if (!CMD.quickcast) {
			Abilities.ExecuteAbility(ability, hero, false);
			return;
		}

		// DOTA_ABILITY_BEHAVIOR bits: 4 = NO_TARGET, 8 = UNIT_TARGET, 16 = POINT.
		var behavior = Abilities.GetBehavior(ability);
		var cursor = GameUI.GetCursorPosition();
		var order = { AbilityIndex: ability, UnitIndex: hero, ShowEffects: true };
		if (typeof dotaorderissuer_t !== "undefined") {
			order.OrderIssuer = dotaorderissuer_t.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY;
		}

		if (behavior & 8) {
			var under = GameUI.FindScreenEntities(cursor);
			if (under && under.length > 0) {
				order.OrderType = dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TARGET;
				order.TargetIndex = under[0].entityIndex;
				Game.PrepareUnitOrders(order);
				return;
			}
			if (!(behavior & 16)) {
				Abilities.ExecuteAbility(ability, hero, false);
				return;
			}
		}
		if (behavior & 16) {
			var world = GameUI.GetScreenWorldPosition(cursor);
			if (world) {
				order.OrderType = dotaunitorder_t.DOTA_UNIT_ORDER_CAST_POSITION;
				order.Position = world;
				Game.PrepareUnitOrders(order);
				return;
			}
			Abilities.ExecuteAbility(ability, hero, false);
			return;
		}
		if (behavior & 4) {
			order.OrderType = dotaunitorder_t.DOTA_UNIT_ORDER_CAST_NO_TARGET;
			Game.PrepareUnitOrders(order);
			return;
		}
		Abilities.ExecuteAbility(ability, hero, false);
	};
}

// Clearing a slot: gate its callback and drop its key mapping — the dispatcher
// then falls back to the key's normal hero ability on its own.
function DisableBind(commandNum)
{
	CMD.cmdEnabled[commandNum] = false;
	ReleaseBindMapping(commandNum);
}

// Returns a validated master unit entindex, or -1. Entity indexes do not
// survive between matches, so a mirrored value is only trusted if the unit
// still exists and belongs to this player.
function GetValidMasterUnit(iPID)
{
	var candidates = [CMD.MasterUnit, GameUI.CustomUIConfig().fate_master_unit];
	for (var i = 0; i < candidates.length; i++) {
		var m = candidates[i];
		if (m != null && m !== -1 && Entities.GetPlayerOwnerID(m) == iPID) {
			return m;
		}
	}
	return -1;
}

function SealHotkeys(Seal, commandNum)
{
    return function ()
    {
        if (commandNum != null && CMD.cmdEnabled[commandNum] === false) { return; }
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

        if (panel.visible !== true) {
            $.Msg('[FateHotkey] seal ' + Seal + ': master bar hidden, ignoring');
            return;
        }
        if (Players.GetSelectedEntities( iPID ) != Players.GetPlayerHeroEntityIndex( iPID )) {
            $.Msg('[FateHotkey] seal ' + Seal + ': hero not selected, ignoring');
            return;
        }

        var master = GetValidMasterUnit(iPID);
        if (master === -1) {
            // Master unknown or stale: ask the server to resend it and swallow
            // this press instead of crashing on GetAbility(undefined).
            $.Msg('[FateHotkey] seal ' + Seal + ': master unknown/stale, requesting resend');
            GameEvents.SendCustomGameEventToServer("player_request_master_unit", {});
            return;
        }
        CMD.MasterUnit = master;

        $.Msg('[FateHotkey] seal ' + Seal + ' cast, master ' + master);
        var ability = Entities.GetAbility(master, Seal);
        GameEvents.SendCustomGameEventToServer("player_cast_seal", {iUnit: master, iAbility: ability});
    }
}

function QuickBuyHotkeys(item_order, commandNum)
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

        if (commandNum != null && CMD.cmdEnabled[commandNum] === false) { return; }
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
		"item_ward_familiar",
		"item_sentry_familiar",
		"item_relic_of_the_king",
	]
	this.item_option = [
		"item_condensed_mana_essence",
		"item_b_scroll",
		"item_a_scroll",
		"item_a_plus_scroll",
		"item_s_scroll",
		"item_ex_scroll",
		"item_healing_scroll",
		"item_spirit_link",
		"item_ward_familiar",
		"item_sentry_familiar",
		"item_scout_familiar",
		"item_attack_familiar",
		"item_relic_of_the_king",
		"item_gem_of_speed",
		"item_teleport_scroll",
	]
	this.quickbuyreg = [
		9999,
		9999,
		9999,
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
		"",
		"",
		"",
	]
	// Tracks which physical key each generated command is currently bound to,
	// so a re-Apply with a changed key can release the stale bind.
	this.boundkeys = {}
	this.cmdEnabled = {}
	this.cmdCallbacks = {}
	this.keydispatch = {}
	// Unique per panel instance; see EnsureKeyDispatch.
	this.instanceId = Math.floor(Math.random() * 1000000)
	// Restored ability keys quick-cast by default; the Quickcast checkbox flips this.
	this.quickcast = true

	this.Construct();
	this.entryContainer.visible = false;
	this.itemListContainer.visible = false;
	var qcToggle = this.container.FindChildTraverse("QuickcastToggle");
	if (qcToggle) {
		qcToggle.checked = this.quickcast;
	}
	GameEvents.Subscribe( "player_regist_hotkey", UpdateHotkey);
	GameEvents.Subscribe("player_selected_hero", function (data) {
        CMD.MasterUnit = data.shardUnit;
        // Mirror into the client-global table: the pick event fires only once,
        // so a recreated panel instance would otherwise never learn the master.
        GameUI.CustomUIConfig().fate_master_unit = data.shardUnit;
        $.Msg("[FateHotkey] master unit received: " + data.shardUnit);
    });
	if (this.MasterUnit == null && GameUI.CustomUIConfig().fate_master_unit != null) {
		this.MasterUnit = GameUI.CustomUIConfig().fate_master_unit;
	}
	if (this.MasterUnit == null) {
		// Panel was created after the pick event; ask the server to resend it.
		GameEvents.SendCustomGameEventToServer("player_request_master_unit", {});
	}
	// Play the buy sound when a quick-buy hotkey (bind) purchase succeeds.
	GameEvents.Subscribe("fate_quick_buy_sound", function (data) {
        Game.EmitSound(data.SoundEvent ? data.SoundEvent : "General.Buy");
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

	for (i=0; i < this.item_list.length ; i++) {
		var item_button = this.quickbuyContainer.FindChild(i);
        if (item_button == null) {
        	item_button = $.CreatePanel("Panel", this.quickbuyContainer, i);

			var item = this.item_list[i];

			item_button.BLoadLayoutSnippet('QuickBuyContainerSnippet');
			item_button.GetChild(1).FindChildTraverse("QuickBuyItemIcon").itemname = item;
			this.HotKeyBoxOpen(item_button.GetChild(1), item.slice(5), i + 6);
			if (i < 2) {
				item_button.GetChild(0).visible = false;
			} else {
				this.ArrowOpen(item_button.GetChild(0), item, i);
			}
		}
	}

	for (i=0; i < this.item_option.length ; i++) {
		var item_option = this.itemListContainer.FindChild(i);
        if (item_option == null) {
        	item_option = $.CreatePanel("Panel", this.itemListContainer, i);

			var item = this.item_option[i];

			item_option.BLoadLayoutSnippet('ItemListContainerSnippet');
			item_option.FindChildTraverse("ItemOptionIcon").itemname = item;
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
		    	BlurHotkeyEntry();
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
		    CMD.currentpanel = panel;
			    var __lbl = panel.GetChild(0);
			    var __alt = CMD.container.FindChildTraverse("EntryAltButton");
			    var __f = CMD.container.FindChildTraverse("EntryFButton");
			    if (__alt) { __alt.checked = (__lbl.text.length == 5); }
			    if (__f) { __f.checked = (__lbl.text.length == 2); }
			    $("#HotkeyEntry").text = "";
			    FocusHotkeyEntry();
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
			item_button.GetChild(1).FindChildTraverse("QuickBuyItemIcon").itemname = item_name;
			CMD.itemListContainer.visible = false;
			CMD.quickbuyContainer.FindChild(qButton).GetChild(0).style["background-img-opacity"] = 0.1;
			MarkApplyDirty();
		}
	);
}

var CMD = new SealHotkeyConfig();