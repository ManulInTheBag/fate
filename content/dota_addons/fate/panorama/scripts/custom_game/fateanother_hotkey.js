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

	// Emote-wheel slot: not part of the seal/quickbuy index scheme, handle it here.
	if (ibutton === "emote") {
		var hotkeyE = $("#HotkeyEntry").text;
		var altE = CMD.container.FindChildTraverse("EntryAltButton");
		var fE = CMD.container.FindChildTraverse("EntryFButton");
		var prefixE = "";
		if (hotkeyE == "" || hotkeyE == " ") {
			hotkeyE = "";
		} else if (altE && altE.checked == true) {
			prefixE = "ALT+";
		} else if (fE && fE.checked == true) {
			prefixE = "F";
		}
		var elabel = CMD.container.FindChildTraverse("EmoteWheelBindLabel");
		if (elabel) { elabel.text = prefixE + hotkeyE; }
		MarkApplyDirty();
		CMD.entryContainer.visible = false;
		if (CMD.currentpanel) { CMD.currentpanel.SetHasClass("GrowBorder", false); }
		$("#HotkeyEntry").text = "";
		BlurHotkeyEntry();
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
	if (ibutton === "emote") {
		var elabel = CMD.container.FindChildTraverse("EmoteWheelBindLabel");
		if (elabel) { elabel.text = ""; }
		MarkApplyDirty();
		CMD.entryContainer.visible = false;
		if (CMD.currentpanel) { CMD.currentpanel.SetHasClass("GrowBorder", false); }
		$("#HotkeyEntry").text = "";
		BlurHotkeyEntry();
		var altC = CMD.container.FindChildTraverse("EntryAltButton");
		var fC = CMD.container.FindChildTraverse("EntryFButton");
		if (altC) { altC.checked = false; }
		if (fC) { fC.checked = false; }
		return;
	}
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

    ApplyEmoteBind();

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

// Opens/releases the emote wheel, which lives in its own panorama context
// (fateanother_emote_wheel). CustomUIConfig is the shared object between panels.
function EmoteWheelOpen()
{
	var api = GameUI.CustomUIConfig().fate_emote_wheel;
	if (api && api.open) { api.open(); }
}

function EmoteWheelRelease()
{
	var api = GameUI.CustomUIConfig().fate_emote_wheel;
	if (api && api.release) { api.release(); }
}

// Binds the emote-wheel key on Apply. Uses a dedicated +/- command pair (unlike
// the seal dispatcher, which only fires on press) so hold-to-open / release-to-send
// works. There is no RemoveCustomKeyBind, so a changed key is released to the noop.
function ApplyEmoteBind()
{
	var elabel = CMD.container.FindChildTraverse("EmoteWheelBindLabel");
	if (!elabel) { return; }

	var keyText = elabel.text;
	var chord = "";
	if (keyText && keyText !== "") {
		if (keyText.indexOf("ALT+") === 0) {
			chord = "ALT+" + keyText.substring(4).toUpperCase();
		} else {
			chord = keyText.toUpperCase();
		}
	}

	// Register the command pair once per panel instance (names carry instanceId).
	if (!CMD.emoteCmd) {
		var base = "ACT_EMOTE_" + CMD.instanceId;
		Game.AddCommand("+" + base, EmoteWheelOpen, "", 512);
		Game.AddCommand("-" + base, EmoteWheelRelease, "", 512);
		CMD.emoteCmd = "+" + base;
	}

	// Release the previously bound key if it changed or was cleared.
	if (CMD.emoteBoundKey && CMD.emoteBoundKey !== chord) {
		Game.CreateCustomKeyBind(CMD.emoteBoundKey, EnsureNoopCommand());
		CMD.emoteBoundKey = null;
	}

	if (chord !== "") {
		Game.CreateCustomKeyBind(chord, CMD.emoteCmd);
		CMD.emoteBoundKey = chord;
	}
}

// ============================================================================
// Emote-wheel layout editor.
//
// The wheel has 8 slots; each can hold any of the 14 emotes. The loadout lives
// in CustomUIConfig().fate_emote_wheel_loadout (shared with the emote-wheel
// panel, which reads it on open) and travels inside the bind profile so it saves
// to / loads from the server with everything else.
// ============================================================================
var EMOTE_SLOTS = 8;
var EMOTE_TOTAL = 14;

function EmoteDefaultLoadout() { return [1, 2, 3, 4, 5, 6, 7, 8]; }

function EmoteLoadout()
{
	var c = GameUI.CustomUIConfig();
	var lo = c.fate_emote_wheel_loadout;
	if (!lo || lo.length !== EMOTE_SLOTS) {
		lo = EmoteDefaultLoadout();
		c.fate_emote_wheel_loadout = lo;
	}
	return lo;
}

function EmoteIconUrl(num)
{
	return "url('s2r://panorama/images/custom_game/emotes/emote_" + num + ".vtex')";
}

// Builds the 8 slot panels and the 14-emote palette once (lazily on first open).
function BuildEmoteConfig()
{
	if (CMD.emoteConfigBuilt) { return; }
	var slots = CMD.container.FindChildTraverse("EmoteConfigSlots");
	var palette = CMD.container.FindChildTraverse("EmoteConfigPalette");
	if (!slots || !palette) { return; }

	for (var i = 0; i < EMOTE_SLOTS; i++) {
		(function (idx) {
			var slot = $.CreatePanel("Panel", slots, "EmoteCfgSlot" + idx);
			slot.AddClass("EmoteCfgSlot");
			slot.style.backgroundSize = "cover";
			var badge = $.CreatePanel("Label", slot, "");
			badge.AddClass("EmoteCfgSlotNum");
			badge.text = "" + (idx + 1);
			slot.SetPanelEvent("onmouseactivate", function () { OnEmoteSlotClick(idx); });
		})(i);
	}

	for (var n = 1; n <= EMOTE_TOTAL; n++) {
		(function (num) {
			var cell = $.CreatePanel("Panel", palette, "EmoteCfgPal" + num);
			cell.AddClass("EmoteCfgCell");
			cell.style.backgroundImage = EmoteIconUrl(num);
			cell.style.backgroundSize = "cover";
			var lbl = $.CreatePanel("Label", cell, "");
			lbl.AddClass("EmoteCfgCellNum");
			lbl.text = "" + num;
			cell.SetPanelEvent("onmouseactivate", function () { OnEmotePaletteClick(num); });
		})(n);
	}

	CMD.emoteConfigBuilt = true;
}

// Repaints slot icons from the current loadout and marks the selected slot.
function RefreshEmoteConfigSlots()
{
	var slots = CMD.container.FindChildTraverse("EmoteConfigSlots");
	if (!slots) { return; }
	var lo = EmoteLoadout();
	for (var i = 0; i < EMOTE_SLOTS; i++) {
		var slot = slots.GetChild(i);
		if (!slot) { continue; }
		var num = lo[i] || (i + 1);
		slot.style.backgroundImage = EmoteIconUrl(num);
		slot.SetHasClass("EmoteCfgSlotSel", i === CMD.emoteSelSlot);
	}
}

// Selecting a slot (click again to deselect).
function OnEmoteSlotClick(i)
{
	CMD.emoteSelSlot = (CMD.emoteSelSlot === i) ? -1 : i;
	RefreshEmoteConfigSlots();
}

// Clicking an emote assigns it to the selected slot (or slot 0 if none picked).
function OnEmotePaletteClick(num)
{
	if (CMD.emoteSelSlot < 0) { CMD.emoteSelSlot = 0; }
	var lo = EmoteLoadout();
	lo[CMD.emoteSelSlot] = num;
	GameUI.CustomUIConfig().fate_emote_wheel_loadout = lo;
	RefreshEmoteConfigSlots();
	MarkApplyDirty(); // fold into the profile; user still presses SAVE TO SERVER
}

function OpenEmoteConfig()
{
	if (Players.IsSpectator(Game.GetLocalPlayerID())) { return; }
	BuildEmoteConfig();
	CMD.emoteSelSlot = -1;
	RefreshEmoteConfigSlots();
	var p = CMD.container.FindChildTraverse("EmoteConfigPanel");
	if (p) { p.visible = true; }
}

function CloseEmoteConfig()
{
	var p = CMD.container.FindChildTraverse("EmoteConfigPanel");
	if (p) { p.visible = false; }
}

// Validates a loadout array from a loaded profile: exactly 8 ints in 1..14.
function SanitizeEmoteLoadout(arr)
{
	if (!arr || arr.length !== EMOTE_SLOTS) { return null; }
	var out = [];
	for (var i = 0; i < EMOTE_SLOTS; i++) {
		var n = parseInt(arr[i], 10);
		if (!(n >= 1 && n <= EMOTE_TOTAL)) { return null; }
		out.push(n);
	}
	return out;
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
	// Emote-wheel bind: dedicated +/- command pair (hold-to-open / release-to-send)
	// and the key it is currently bound to (for releasing a stale bind on rebind).
	this.emoteCmd = null
	this.emoteBoundKey = null
	// Emote-wheel layout editor: which slot is selected, and whether the slot/
	// palette panels have been built yet (done lazily on first open).
	this.emoteSelSlot = -1
	this.emoteConfigBuilt = false

	this.Construct();
	this.entryContainer.visible = false;
	this.itemListContainer.visible = false;
	var emoteCfgPanel = this.container.FindChildTraverse("EmoteConfigPanel");
	if (emoteCfgPanel) { emoteCfgPanel.visible = false; }
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
	// Server-side bind profile: results of save / load round-trips.
	GameEvents.Subscribe("fate_binds_save_result", OnBindsSaveResult);
	GameEvents.Subscribe("fate_binds_loaded", OnBindsLoaded);
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

	// Emote-wheel bind slot reuses the same key-entry popup as the seals; it is
	// marked with the "emote" button id and handled specially on submit/clear/apply.
	var emoteSlot = this.container.FindChildTraverse("EmoteWheelBindSlot");
	if (emoteSlot) {
		this.HotKeyBoxOpen(emoteSlot, "emote", "emote");
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

// ============================================================================
// Save / load bind profile to the external server.
//
// The whole editable state of the panel is serialized to a JSON string and sent
// to the game server (which forwards it to the REST API keyed by SteamID). The
// server side never parses it — it's an opaque blob to everything but this file.
// ============================================================================

// Reads the current panel state into a plain object (the source of truth is the
// UI labels/icons, same as SealButtonApply uses).
function CollectBindProfile()
{
	var seals = [];
	for (var i = 0; i < 6; i++) {
		var sb = CMD.sealContainer.GetChild(i);
		seals.push(sb ? sb.GetChild(0).text : "");
	}

	var items = [];
	var itemKeys = [];
	for (var k = 0; k < CMD.item_list.length; k++) {
		items.push(CMD.item_list[k]);
		var ib = CMD.quickbuyContainer.GetChild(k);
		itemKeys.push(ib ? ib.GetChild(1).GetChild(0).text : "");
	}

	var elabel = CMD.container.FindChildTraverse("EmoteWheelBindLabel");

	return {
		v: 1,
		seals: seals,
		items: items,
		itemKeys: itemKeys,
		emote: elabel ? elabel.text : "",
		emoteLoadout: EmoteLoadout().slice(),
		quickcast: CMD.quickcast ? 1 : 0
	};
}

// Writes a loaded profile back into the panel. Does NOT apply the binds — it
// mirrors the manual-edit flow, so the user still presses Apply afterwards.
function ApplyBindProfile(profile)
{
	if (!profile) { return; }

	if (profile.seals) {
		for (var i = 0; i < 6; i++) {
			var sb = CMD.sealContainer.GetChild(i);
			if (sb) { sb.GetChild(0).text = profile.seals[i] || ""; }
		}
	}

	if (profile.items) {
		for (var k = 0; k < CMD.item_list.length && k < profile.items.length; k++) {
			var itemName = profile.items[k];
			if (itemName) {
				CMD.item_list[k] = itemName;
				var ib = CMD.quickbuyContainer.GetChild(k);
				if (ib) {
					var icon = ib.GetChild(1).FindChildTraverse("QuickBuyItemIcon");
					if (icon) { icon.itemname = itemName; }
				}
			}
		}
	}

	if (profile.itemKeys) {
		for (var m = 0; m < CMD.item_list.length && m < profile.itemKeys.length; m++) {
			var ib2 = CMD.quickbuyContainer.GetChild(m);
			if (ib2) { ib2.GetChild(1).GetChild(0).text = profile.itemKeys[m] || ""; }
		}
	}

	var elabel = CMD.container.FindChildTraverse("EmoteWheelBindLabel");
	if (elabel) { elabel.text = profile.emote || ""; }

	var lo = SanitizeEmoteLoadout(profile.emoteLoadout);
	if (lo) {
		GameUI.CustomUIConfig().fate_emote_wheel_loadout = lo;
		if (CMD.emoteConfigBuilt) { RefreshEmoteConfigSlots(); }
	}

	CMD.quickcast = (profile.quickcast == 1 || profile.quickcast === true);
	var qc = CMD.container.FindChildTraverse("QuickcastToggle");
	if (qc) { qc.checked = CMD.quickcast; }

	MarkApplyDirty();
}

// ---- Client-side guards for save/load: idempotency + a shared 3-per-5-min lock.
// State lives in CustomUIConfig so it survives the panel being recreated when the
// options screen reopens (see the top-of-file CustomUIConfig note). This is UX /
// politeness only — a hacked client can bypass it, so the real per-player limit is
// enforced server-side in addon_game_mode.lua (OnPlayerSaveBinds/OnPlayerLoadBinds).
var BINDS_RATE_MAX = 3;
var BINDS_RATE_WINDOW_MS = 5 * 60 * 1000;
var BINDS_REQUEST_TIMEOUT = 6.0; // s: clear the in-flight flag if no server reply

function BindsNet()
{
	var c = GameUI.CustomUIConfig();
	if (!c.fate_binds_net) {
		c.fate_binds_net = { reqTimes: [], lastSavedProfile: null, saveInFlight: false, loadInFlight: false, pendingSave: null };
	}
	return c.fate_binds_net;
}

// Drops timestamps outside the window (and any stale "future" ones left from a
// previous match, since Date.now() is wall-clock but state persists across matches).
function BindsPrune(net)
{
	var now = Date.now();
	var kept = [];
	for (var i = 0; i < net.reqTimes.length; i++) {
		var t = net.reqTimes[i];
		if (t <= now && (now - t) < BINDS_RATE_WINDOW_MS) { kept.push(t); }
	}
	net.reqTimes = kept;
	return kept;
}

function BindsRateAllowed(net) { return BindsPrune(net).length < BINDS_RATE_MAX; }

// Seconds until a slot frees up, for the "WAIT Ns" hint.
function BindsRateWait(net)
{
	var kept = BindsPrune(net);
	if (kept.length < BINDS_RATE_MAX) { return 0; }
	var oldest = kept[0];
	for (var i = 1; i < kept.length; i++) { if (kept[i] < oldest) { oldest = kept[i]; } }
	return Math.ceil((BINDS_RATE_WINDOW_MS - (Date.now() - oldest)) / 1000);
}

function OnSaveToServer()
{
	var pid = Game.GetLocalPlayerID();
	if (Players.IsSpectator(pid)) { return; }

	var net = BindsNet();
	var json = JSON.stringify(CollectBindProfile());

	// Idempotency: unchanged since the last successful save -> don't send.
	if (net.lastSavedProfile !== null && net.lastSavedProfile === json) {
		SetServerLabel("ServerSaveLabel", "NO CHANGES", "SAVE TO SERVER");
		return;
	}
	if (net.saveInFlight) { return; } // one in flight already
	if (!BindsRateAllowed(net)) {
		SetServerLabel("ServerSaveLabel", "WAIT " + BindsRateWait(net) + "s", "SAVE TO SERVER");
		return;
	}

	net.reqTimes.push(Date.now());
	net.saveInFlight = true;
	net.pendingSave = json;
	GameEvents.SendCustomGameEventToServer("player_save_binds", { data: json });

	var lbl = CMD.container.FindChildTraverse("ServerSaveLabel");
	if (lbl) { lbl.text = "SAVING…"; }

	// Watchdog: if the server never replies (e.g. dropped by the server gate),
	// don't leave the button stuck on "SAVING…".
	$.Schedule(BINDS_REQUEST_TIMEOUT, function () {
		if (net.saveInFlight) {
			net.saveInFlight = false;
			SetServerLabel("ServerSaveLabel", "TIMED OUT", "SAVE TO SERVER");
		}
	});
}

function OnLoadFromServer()
{
	var pid = Game.GetLocalPlayerID();
	if (Players.IsSpectator(pid)) { return; }

	var net = BindsNet();
	if (net.loadInFlight) { return; }
	if (!BindsRateAllowed(net)) {
		SetServerLabel("ServerLoadLabel", "WAIT " + BindsRateWait(net) + "s", "LOAD FROM SERVER");
		return;
	}

	net.reqTimes.push(Date.now());
	net.loadInFlight = true;
	GameEvents.SendCustomGameEventToServer("player_load_binds", {});

	var lbl = CMD.container.FindChildTraverse("ServerLoadLabel");
	if (lbl) { lbl.text = "LOADING…"; }

	$.Schedule(BINDS_REQUEST_TIMEOUT, function () {
		if (net.loadInFlight) {
			net.loadInFlight = false;
			SetServerLabel("ServerLoadLabel", "TIMED OUT", "LOAD FROM SERVER");
		}
	});
}

function OnBindsSaveResult(data)
{
	var net = BindsNet();
	net.saveInFlight = false;
	var ok = data && data.ok == 1;
	if (ok) {
		// Remember exactly what we saved so an immediate re-press is a no-op.
		net.lastSavedProfile = net.pendingSave;
	}
	var btn = CMD.container.FindChildTraverse("ServerSaveButton");
	FlashServerButton(btn, ok);
	SetServerLabel("ServerSaveLabel", ok ? "SAVED ✓" : "SAVE FAILED", "SAVE TO SERVER");
}

function OnBindsLoaded(data)
{
	var net = BindsNet();
	net.loadInFlight = false;
	var btn = CMD.container.FindChildTraverse("ServerLoadButton");

	if (data && data.ok == 1 && data.data) {
		var profile = null;
		try { profile = JSON.parse(data.data); } catch (e) { profile = null; }
		if (profile) {
			ApplyBindProfile(profile);
			// Panel now matches the server, so a following save is a no-op until
			// the user edits something. Store the re-serialized form (not data.data)
			// so it compares equal to what OnSaveToServer computes.
			net.lastSavedProfile = JSON.stringify(CollectBindProfile());
			FlashServerButton(btn, true);
			SetServerLabel("ServerLoadLabel", "LOADED ✓ — press Apply", "LOAD FROM SERVER");
			return;
		}
	}

	FlashServerButton(btn, false);
	var msg = (data && data.status == 404) ? "NO SAVE YET" : "LOAD FAILED";
	SetServerLabel("ServerLoadLabel", msg, "LOAD FROM SERVER");
}

// One-shot green/red flash on the button to signal success/failure.
function FlashServerButton(btn, ok)
{
	if (!btn) { return; }
	btn.RemoveClass("ServerOkFlash");
	btn.RemoveClass("ServerFailFlash");
	var cls = ok ? "ServerOkFlash" : "ServerFailFlash";
	$.Schedule(0.0, function () { btn.AddClass(cls); });
}

// Sets a result label, then restores the default caption after a few seconds.
function SetServerLabel(labelId, text, defaultText)
{
	var lbl = CMD.container.FindChildTraverse(labelId);
	if (!lbl) { return; }
	lbl.text = text;
	$.Schedule(3.0, function () {
		if (lbl && lbl.IsValid()) { lbl.text = defaultText; }
	});
}

var CMD = new SealHotkeyConfig();