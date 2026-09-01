'use strict';


var STACK_MODIFIER = 'modifier_rasputin_finisher_counter';
var CHARGE_MODIFIER = 'modifier_rasputin_dash_charges';


var CURSE_MODIFIER = 'modifier_rasputin_curse_counter';


var REBORN_MODIFIER = 'modifier_rasputin_reborn';


var GRAB_CD_MODIFIER = 'modifier_rasputin_grab_cd';


var MAX_CURSES = 20;


var MAX_STACKS = 10;


var WARN_STACKS = 5;


function AbilityValue(entity, abilityName, key, fallback) {
	var ability = Entities.GetAbilityByName(entity, abilityName);

	if (ability === undefined || ability === -1) {
		return fallback;
	}

	var value = Abilities.GetSpecialValueFor(ability, key);

	if (typeof value !== 'number' || !(value > 0)) {
		return fallback;
	}

	return value;
}


function ReadMaxima(entity) {
	MAX_STACKS = AbilityValue(entity, 'rasputin_finisher', 'territory_max_stacks', MAX_STACKS);
	MAX_CURSES = AbilityValue(entity, 'rasputin_finisher', 'curse_stacks_to_revive', MAX_CURSES);
	WARN_STACKS = AbilityValue(entity, 'rasputin_knife_dash', 'grab_stack_threshold', WARN_STACKS);
	DIVIDERS = MAX_STACKS - 1;
}


function HasModifier(entity, name) {
	var count = Entities.GetNumBuffs(entity);

	for (var i = 0; i < count; i++) {
		var buff = Entities.GetBuff(entity, i);

		if (Buffs.GetName(entity, buff) === name) {
			return true;
		}
	}

	return false;
}


var REFRESH_INTERVAL = 0.1;


var BAR_CENTER_X = 4;
var BAR_CENTER_Y = -29;
var BAR_WIDTH = 105;
var BAR_HEIGHT = 10;


var MANA_HEIGHT = 6;
var MANA_OVERLAP = 1;


var STACKS_WIDTH = 131;
var STACKS_HEIGHT = 15;
var STACKS_GAP = 3;


var CURSE_WIDTH = STACKS_WIDTH;
var CURSE_HEIGHT = 11;
var CURSE_GAP = 5;


var CHARGES_SIZE = 22;
var CHARGES_GAP = 9;


var STACKS_NUDGE_X = 5;
var STACKS_NUDGE_Y = -3;
var CHARGES_NUDGE_X = 6;
var CHARGES_NUDGE_Y = 2;


var DIVIDERS = MAX_STACKS - 1;


var CHARGES_LEVEL2_EXTRA = 8;
var LEVEL_TWO_DIGITS = 10;


var PANEL_OFFSET_X = BAR_CENTER_X - STACKS_WIDTH / 2 + STACKS_NUDGE_X;
var PANEL_OFFSET_Y = BAR_CENTER_Y - BAR_HEIGHT / 2 - STACKS_GAP - STACKS_HEIGHT
	+ STACKS_NUDGE_Y;


var STACKS_Y = 0;
var HEALTH_Y = STACKS_Y + STACKS_HEIGHT + STACKS_GAP;
var MANA_Y = HEALTH_Y + BAR_HEIGHT - MANA_OVERLAP;

var CURSE_X = (STACKS_WIDTH - CURSE_WIDTH) / 2;
var CURSE_Y = MANA_Y + MANA_HEIGHT + CURSE_GAP;


var CHARGES_X = STACKS_WIDTH / 2 + BAR_WIDTH / 2 + CHARGES_GAP
	- STACKS_NUDGE_X + CHARGES_NUDGE_X;
var CHARGES_Y = HEALTH_Y + BAR_HEIGHT / 2
	- CHARGES_SIZE / 2 - STACKS_NUDGE_Y + CHARGES_NUDGE_Y;


function ScreenScale() {
	var panel = $.GetContextPanel();
	if (panel && panel.actualuiscale_x > 0) {
		return panel.actualuiscale_x;
	}
	var height = Game.GetScreenHeight();
	return height > 0 ? height / 1080 : 1;
}


function HealthBarOffset(entity) {
	if (Entities.GetHealthBarOffset) {
		var offset = Entities.GetHealthBarOffset(entity);
		if (offset && offset > 0) {
			return offset;
		}
	}
	return 260;
}


function FindModifierTime(entity, modifierName) {
	var count = Entities.GetNumBuffs(entity);
	for (var i = 0; i < count; i++) {
		var buff = Entities.GetBuff(entity, i);
		if (Buffs.GetName(entity, buff) !== modifierName) {
			continue;
		}
		var duration = Buffs.GetDuration(entity, buff);
		var remaining = Buffs.GetRemainingTime(entity, buff);
		if (!(duration > 0)) {
			return null;
		}
		return { remaining: Math.max(remaining, 0), duration: duration };
	}
	return null;
}

function FindModifierStacks(entity, modifierName) {
	var count = Entities.GetNumBuffs(entity);
	for (var i = 0; i < count; i++) {
		var buff = Entities.GetBuff(entity, i);
		if (Buffs.GetName(entity, buff) === modifierName) {
			return Buffs.GetStackCount(entity, buff);
		}
	}
	return null;
}


function RasputinHud() {
	this.root = $('#RasputinHudRoot');


	this.panels = {};

	this.lastRefresh = 0;


	this.tracked = [];
}


RasputinHud.prototype.Build = function (entity) {
	var panel = $.CreatePanel('Panel', this.root, 'RasputinUnit' + entity);
	panel.AddClass('RasputinUnitPanel');


	var curse = $.CreatePanel('Panel', panel, '');
	curse.AddClass('RasputinCurse');
	curse.style.width = CURSE_WIDTH + 'px;';
	curse.style.height = CURSE_HEIGHT + 'px;';
	curse.style.position = CURSE_X + 'px ' + CURSE_Y + 'px 0px;';

	var curseFill = $.CreatePanel('Panel', curse, '');
	curseFill.AddClass('RasputinCurseFill');

	var stacks = $.CreatePanel('Panel', panel, '');
	stacks.AddClass('RasputinStacks');
	stacks.style.width = STACKS_WIDTH + 'px;';
	stacks.style.height = STACKS_HEIGHT + 'px;';
	stacks.style.position = '0px ' + STACKS_Y + 'px 0px;';

	var fill = $.CreatePanel('Panel', stacks, '');
	fill.AddClass('RasputinStacksFill');


	var ticks = $.CreatePanel('Panel', stacks, '');
	ticks.AddClass('RasputinStacksTicks');
	for (var i = 1; i <= DIVIDERS; i++) {
		var tick = $.CreatePanel('Panel', ticks, '');
		tick.AddClass('RasputinStackTick');
		tick.style.position = (i * 100 / MAX_STACKS) + '% 0px 0px;';
	}

	var charges = $.CreatePanel('Panel', panel, '');
	charges.AddClass('RasputinCharges');
	charges.style.width = CHARGES_SIZE + 'px;';
	charges.style.height = CHARGES_SIZE + 'px;';
	charges.style.position = CHARGES_X + 'px ' + CHARGES_Y + 'px 0px;';

	var chargesLabel = $.CreatePanel('Label', charges, '');
	chargesLabel.AddClass('RasputinChargesLabel');
	chargesLabel.text = '0';

	var built = {
		panel: panel,
		curse: curse,
		curseFill: curseFill,
		stacks: stacks,
		fill: fill,
		lastCurse: null,
		charges: charges,
		chargesLabel: chargesLabel,
		lastStacks: -1,
		lastCharges: -1,
		lastChargesShown: null,
		lastWideLevel: null,
	};

	this.panels[entity] = built;

	return built;
};


RasputinHud.prototype.Destroy = function (entity) {
	var built = this.panels[entity];
	if (!built) {
		return;
	}
	built.panel.DeleteAsync(0);
	delete this.panels[entity];
};


RasputinHud.prototype.UpdateStacks = function (built, stacks, entity) {

	var grabReady = stacks >= WARN_STACKS && !HasModifier(entity, GRAB_CD_MODIFIER);

	var max = stacks >= MAX_STACKS;

	if (built.lastStacks === stacks && built.lastGrabReady === grabReady) {
		return;
	}

	built.lastStacks = stacks;
	built.lastGrabReady = grabReady;

	var pct = Math.max(0, Math.min(stacks, MAX_STACKS)) / MAX_STACKS * 100;

	built.fill.style.width = pct + '%';

	built.stacks.SetHasClass('Max', max && !grabReady);
	built.stacks.SetHasClass('MaxReady', max && grabReady);
	built.stacks.SetHasClass('Warn', !max && grabReady);
};


RasputinHud.prototype.UpdateChargesOffset = function (built, level) {

	var wide = level >= LEVEL_TWO_DIGITS;

	if (built.lastWideLevel === wide) {
		return;
	}
	built.lastWideLevel = wide;

	var x = CHARGES_X + (wide ? CHARGES_LEVEL2_EXTRA : 0);

	built.charges.style.position = x + 'px ' + CHARGES_Y + 'px 0px;';
};


RasputinHud.prototype.UpdateCurse = function (built, entity) {

	var reborn = FindModifierTime(entity, REBORN_MODIFIER);
	var curses = FindModifierStacks(entity, CURSE_MODIFIER);


	var shown = curses !== null || reborn !== null;

	if (built.lastCurseShown !== shown) {
		built.lastCurseShown = shown;
		built.curse.visible = shown;
	}

	if (!shown) {
		return;
	}

	var pct, state;

	if (reborn) {
		pct = reborn.remaining / reborn.duration * 100;
		state = 'Reborn';
	} else {
		pct = Math.min(curses, MAX_CURSES) / MAX_CURSES * 100;
		state = curses >= MAX_CURSES ? 'Full' : '';
	}


	if (built.lastCurse !== pct || built.lastCurseState !== state) {
		built.lastCurse = pct;
		built.lastCurseState = state;
		built.curseFill.style.width = pct + '%';
		built.curse.SetHasClass('Full', state === 'Full');
		built.curse.SetHasClass('Reborn', state === 'Reborn');
	}
};


RasputinHud.prototype.UpdateCharges = function (built, charges, shown) {
	if (built.lastChargesShown !== shown) {
		built.lastChargesShown = shown;
		built.charges.visible = shown;
	}

	if (!shown || built.lastCharges === charges) {
		return;
	}
	built.lastCharges = charges;

	built.chargesLabel.text = String(charges);
	built.charges.SetHasClass('Empty', charges <= 0);
};


RasputinHud.prototype.IsRasputin = function (entity) {
	return FindModifierStacks(entity, CHARGE_MODIFIER) !== null;
};


RasputinHud.prototype.Refresh = function () {

	var localHero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());

	var players = Game.GetAllPlayerIDs();

	var seen = {};

	this.tracked = [];

	for (var i = 0; i < players.length; i++) {

		var entity = Players.GetPlayerHeroEntityIndex(players[i]);

		if (entity === -1 || !Entities.IsValidEntity(entity)) {
			continue;
		}


		if (entity !== localHero) {
			continue;
		}

		if (!this.IsRasputin(entity)) {
			continue;
		}

		seen[entity] = true;

		this.tracked.push(entity);

		var built = this.panels[entity] || this.Build(entity);

		ReadMaxima(entity);

		var stacks = FindModifierStacks(entity, STACK_MODIFIER);
		this.UpdateStacks(built, stacks === null ? 0 : stacks, entity);

		this.UpdateCurse(built, entity);

		var charges = FindModifierStacks(entity, CHARGE_MODIFIER);
		this.UpdateCharges(built, charges === null ? 0 : charges, true);

		this.UpdateChargesOffset(built, Entities.GetLevel(entity));
	}


	for (var index in this.panels) {
		if (!seen[index]) {
			this.Destroy(index);
		}
	}
};


RasputinHud.prototype.Update = function () {

	var that = this;
	$.Schedule(0, function () {
		that.Update();
	});

	var now = Game.GetGameTime();

	if (now - this.lastRefresh >= REFRESH_INTERVAL) {
		this.lastRefresh = now;
		this.Refresh();
	}

	var scale = ScreenScale();

	for (var i = 0; i < this.tracked.length; i++) {

		var entity = this.tracked[i];

		var built = this.panels[entity];

		if (!built || !Entities.IsValidEntity(entity)) {
			continue;
		}


		if (!Entities.IsAlive(entity)) {
			built.panel.SetHasClass('Hidden', true);
			continue;
		}

		var origin = Entities.GetAbsOrigin(entity);
		var z = origin[2] + HealthBarOffset(entity);

		var screenX = Game.WorldToScreenX(origin[0], origin[1], z);
		var screenY = Game.WorldToScreenY(origin[0], origin[1], z);


		if (screenX < 0 || screenY < 0) {
			built.panel.SetHasClass('Hidden', true);
			continue;
		}

		built.panel.SetHasClass('Hidden', false);


		built.panel.style.position =
			(screenX / scale + PANEL_OFFSET_X) + 'px ' +
			(screenY / scale + PANEL_OFFSET_Y) + 'px 0px;';
	}
};


var rasputinHud = new RasputinHud();
rasputinHud.Update();
