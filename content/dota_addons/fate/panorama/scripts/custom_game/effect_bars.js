'use strict';

// Ряд эффектов со стаками над хелсбаром юнита: медальон с числом, полоска до
// потолка и линия оставшегося времени. Заменил партикли-счётчики над головой
// (Li Shuwen, Saito, Muramasa).
//
// Кого рисовать, говорит сервер: libraries/effect_bars.lua ведёт nettable
// effect_bars, по записи на entindex - { on, vis, <доп. поля> }. Стаки и время
// читаются прямо из баффов, без задержки сети.
//
// Новый эффект = строка в EFFECTS + EffectBars:Track/Untrack в его модификаторе
// + цвета темы в effect_bars.css.

var EFFECTS = [
	{
		theme: 'Shuwen',
		modifier: 'modifier_nss_shock_stackable',
		ability: 'lishuwen_no_second_strike',
		maxKey: 'max_stacks',
		maxFallback: 50,
		// пороги атрибута рисуются, только если он взят - флаг кладёт сервер
		tiers: { flag: 'nss_sa', keys: ['sa_tier1_stacks', 'sa_tier2_stacks'], fallbacks: [10, 25] },
		tickEvery: 10,
	},
	{
		theme: 'Saito',
		modifier: 'saito_formlessness_new_stacks',
		ability: 'saito_formlessness_new',
		maxKey: 'max_slashes',
		maxFallback: 10,
		cells: true,
	},
	{
		theme: 'Muramasa',
		modifier: 'modifier_muramasa_sword_drop_enemy_buff',
		// заряды меча: в KV это sword_stacks атрибута, а атрибут живёт на Мастере
		maxFallback: 5,
		cells: true,
	},
];


var REFRESH_INTERVAL = 0.1;

// Геометрия ванильного хелсбара героя относительно точки
// WorldToScreen(origin + GetHealthBarOffset) - замерена в rasputin_hud.js.
var BAR_CENTER_X = 4;
var BAR_TOP_Y = -34;

var ROW_GAP = 3;
var UNIT_WIDTH = 300;   // .EffectUnit в css
var UNIT_HEIGHT = 30;

// Над своим Распутиным висит его полоска стаков (rasputin_hud) - ряд выше неё.
var RASPUTIN_MODIFIER = 'modifier_rasputin_dash_charges';
var RASPUTIN_LIFT = 21;

var EXPIRING_TIME = 1.5;


var tracked = {};      // entindex -> запись из nettable
var units = {};        // entindex -> построенные панели
var visible = [];      // кого двигать каждый кадр
var lastRefresh = -1;
var root = $('#EffectBarsRoot');


function ScreenScale() {
	var panel = $.GetContextPanel();
	if (panel && panel.actualuiscale_x > 0) {
		return panel.actualuiscale_x;
	}
	var height = Game.GetScreenHeight();
	return height > 0 ? height / 1080 : 1;
}


function HealthBarOffset(entity) {
	var offset = Entities.GetHealthBarOffset(entity);
	return offset > 0 ? offset : 200;
}


function BuffsByName(entity) {
	var result = {};
	var count = Entities.GetNumBuffs(entity);
	for (var i = 0; i < count; i++) {
		var buff = Entities.GetBuff(entity, i);
		result[Buffs.GetName(entity, buff)] = buff;
	}
	return result;
}


// Значение из KV способности владельца эффекта; на клиенте способность
// чужого героя может быть недоступна - тогда запасное число.
function CasterValue(entity, buff, abilityName, key, fallback) {
	if (!abilityName || !key) {
		return fallback;
	}
	var caster = Buffs.GetCaster(entity, buff);
	if (caster === undefined || caster === -1) {
		return fallback;
	}
	var ability = Entities.GetAbilityByName(caster, abilityName);
	if (ability === undefined || ability === -1) {
		return fallback;
	}
	var value = Abilities.GetSpecialValueFor(ability, key);
	return value > 0 ? value : fallback;
}


function OnNetTable(table, key, data) {
	var entity = parseInt(key, 10);
	if (data && data.on === 1) {
		tracked[entity] = data;
	} else {
		delete tracked[entity];
	}
}


function BuildUnit(entity) {
	var panel = $.CreatePanel('Panel', root, '');
	panel.AddClass('EffectUnit');

	var row = $.CreatePanel('Panel', panel, '');
	row.AddClass('EffectRow');

	var built = { panel: panel, row: row, chips: {} };
	units[entity] = built;
	return built;
}


function DestroyUnit(entity) {
	var built = units[entity];
	if (!built) {
		return;
	}
	built.panel.DeleteAsync(0);
	delete units[entity];
}


function BuildChip(built, effect, entity, buff) {
	var chip = $.CreatePanel('Panel', built.row, '');
	chip.AddClass('EffectChip');
	chip.AddClass(effect.theme);

	var medal = $.CreatePanel('Panel', chip, '');
	medal.AddClass('EffectMedal');

	var count = $.CreatePanel('Label', medal, '');
	count.AddClass('EffectCount');
	count.text = '';

	var side = $.CreatePanel('Panel', chip, '');
	side.AddClass('EffectSide');

	var bar = $.CreatePanel('Panel', side, '');
	bar.AddClass('EffectBar');

	var timer = $.CreatePanel('Panel', side, '');
	timer.AddClass('EffectTimer');

	var timerFill = $.CreatePanel('Panel', timer, '');
	timerFill.AddClass('EffectTimerFill');

	var max = CasterValue(entity, buff, effect.ability, effect.maxKey, effect.maxFallback);

	var state = {
		panel: chip,
		count: count,
		bar: bar,
		timerFill: timerFill,
		max: max,
		cells: [],
		fill: null,
		tiers: [],
		lastCount: -1,
		lastTimer: -1,
		lastTierFlag: null,
	};

	if (effect.cells) {
		bar.AddClass('Cells');
		for (var i = 0; i < max; i++) {
			var cell = $.CreatePanel('Panel', bar, '');
			cell.AddClass('EffectCell');
			cell.SetHasClass('Last', i === max - 1);
			state.cells.push(cell);
		}
	} else {
		state.fill = $.CreatePanel('Panel', bar, '');
		state.fill.AddClass('EffectFill');

		if (effect.tickEvery) {
			for (var t = effect.tickEvery; t < max; t += effect.tickEvery) {
				AddTick(bar, t, max, false);
			}
		}

		if (effect.tiers) {
			for (var k = 0; k < effect.tiers.keys.length; k++) {
				state.tiers.push(CasterValue(entity, buff, effect.ability,
					effect.tiers.keys[k], effect.tiers.fallbacks[k]));
			}
			state.tierTicks = [];
			for (var n = 0; n < state.tiers.length; n++) {
				state.tierTicks.push(AddTick(bar, state.tiers[n], max, true));
			}
		}
	}

	built.chips[effect.modifier] = state;
	return state;
}


function AddTick(bar, value, max, tier) {
	var tick = $.CreatePanel('Panel', bar, '');
	tick.AddClass('EffectTick');
	tick.SetHasClass('TierTick', tier);
	tick.style.position = (value * 100 / max) + '% 0px 0px';
	return tick;
}


function UpdateChip(effect, state, entity, buff, data) {
	var stacks = Buffs.GetStackCount(entity, buff);

	// потолок мог не прочитаться из KV - полоска не должна переливаться
	var max = Math.max(state.max, stacks, 1);

	if (stacks !== state.lastCount) {
		if (stacks > state.lastCount && state.lastCount >= 0) {
			state.count.TriggerClass('Pop');
		}
		state.lastCount = stacks;
		state.count.text = String(stacks);

		if (state.fill) {
			state.fill.style.width = (Math.min(stacks, max) * 100 / max) + '%';
		}
		for (var i = 0; i < state.cells.length; i++) {
			state.cells[i].SetHasClass('On', i < stacks);
		}
		state.panel.SetHasClass('Max', stacks >= max);
	}

	if (effect.tiers) {
		var tierOn = data[effect.tiers.flag] === 1;
		if (tierOn !== state.lastTierFlag) {
			state.lastTierFlag = tierOn;
			for (var t = 0; t < state.tierTicks.length; t++) {
				state.tierTicks[t].visible = tierOn;
			}
		}
		state.panel.SetHasClass('Tier1', tierOn && stacks >= state.tiers[0] && stacks < max);
		state.panel.SetHasClass('Tier2', tierOn && stacks >= state.tiers[1] && stacks < max);
	}

	var duration = Buffs.GetDuration(entity, buff);
	var permanent = !(duration > 0);
	state.panel.SetHasClass('Permanent', permanent);

	if (!permanent) {
		var remaining = Math.max(Buffs.GetRemainingTime(entity, buff), 0);
		var pct = Math.round(Math.min(remaining / duration, 1) * 1000) / 10;
		if (pct !== state.lastTimer) {
			state.lastTimer = pct;
			state.timerFill.style.width = pct + '%';
		}
		state.panel.SetHasClass('Expiring', remaining <= EXPIRING_TIME);
	}
}


// Чужие видят ряд, только пока их команда видит юнита (маска vis с сервера,
// бит 2^team - так верно и в FFA с кастомными командами), своя команда и
// зрители - всегда.
function UnitShown(entity, data, localTeam, spectator) {
	if (!Entities.IsValidEntity(entity) || !Entities.IsAlive(entity)) {
		return false;
	}
	if (Entities.NoHealthBar(entity)) {
		return false;
	}
	if (spectator || Entities.GetTeamNumber(entity) === localTeam) {
		return true;
	}
	return Math.floor((data.vis || 0) / Math.pow(2, localTeam)) % 2 === 1;
}


function Refresh() {
	var localPlayer = Players.GetLocalPlayer();
	var localTeam = Players.GetTeam(localPlayer);
	var spectator = Players.IsSpectator(localPlayer);
	var seen = {};

	visible = [];

	for (var key in tracked) {
		var entity = parseInt(key, 10);
		var data = tracked[key];

		if (!UnitShown(entity, data, localTeam, spectator)) {
			continue;
		}

		var buffs = BuffsByName(entity);
		var built = units[entity];
		var any = false;

		for (var e = 0; e < EFFECTS.length; e++) {
			var effect = EFFECTS[e];
			var buff = buffs[effect.modifier];
			var state = built && built.chips[effect.modifier];

			if (buff === undefined) {
				if (state) {
					state.panel.DeleteAsync(0);
					delete built.chips[effect.modifier];
				}
				continue;
			}

			if (!built) {
				built = BuildUnit(entity);
			}
			if (!state) {
				state = BuildChip(built, effect, entity, buff);
			}

			UpdateChip(effect, state, entity, buff, data);
			any = true;
		}

		if (!any) {
			continue;
		}

		built.lift =(entity === Players.GetPlayerHeroEntityIndex(localPlayer)
			&& buffs[RASPUTIN_MODIFIER] !== undefined) ? RASPUTIN_LIFT : 0;

		seen[entity] = true;
		visible.push(entity);
	}

	for (var index in units) {
		if (!seen[index]) {
			DestroyUnit(index);
		}
	}
}


function Update() {
	$.Schedule(0, Update);

	var now = Game.GetGameTime();
	if (now - lastRefresh >= REFRESH_INTERVAL || now < lastRefresh) {
		lastRefresh = now;
		Refresh();
	}

	var scale = ScreenScale();

	for (var i = 0; i < visible.length; i++) {
		var entity = visible[i];
		var built = units[entity];

		if (!built || !Entities.IsValidEntity(entity)) {
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

		var x = Math.round(screenX / scale + BAR_CENTER_X - UNIT_WIDTH / 2);
		var y = Math.round(screenY / scale + BAR_TOP_Y - ROW_GAP - UNIT_HEIGHT - built.lift);

		if (x !== built.x || y !== built.y) {
			built.x = x;
			built.y = y;
			built.panel.style.position = x + 'px ' + y + 'px 0px';
		}
	}
}


(function () {
	var all = CustomNetTables.GetAllTableValues('effect_bars') || [];
	for (var i = 0; i < all.length; i++) {
		OnNetTable('effect_bars', all[i].key, all[i].value);
	}
	CustomNetTables.SubscribeNetTableListener('effect_bars', OnNetTable);
	Update();
})();
