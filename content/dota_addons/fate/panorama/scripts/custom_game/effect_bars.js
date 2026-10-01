'use strict';

// Ряд эффектов со стаками над хелсбаром юнита: круглый медальон, число стаков
// по центру и кольцо оставшегося времени по краю. Заменил партикли-счётчики
// над головой (Li Shuwen, Saito, Muramasa) и добавил яд Robin Hood.
//
// Кого рисовать, говорит сервер: libraries/effect_bars.lua ведёт nettable
// effect_bars, по записи на entindex - { on, vis, <доп. поля> }. Стаки и время
// читаются прямо из баффов, без задержки сети.
//
// Разовые эффекты (взрыв стаков Ли на NSS) приходят событием effect_bars_burst.
//
// Новый эффект = строка в EFFECTS + EffectBars:Track/Untrack в его модификаторе
// + тема (медальон и цвета) в effect_bars.css.

var EFFECTS = [
	{
		theme: 'Shuwen',
		modifier: 'modifier_nss_shock_stackable',
		ability: 'lishuwen_no_second_strike',
		maxKey: 'max_stacks',
		maxFallback: 50,
		// ступени атрибута красят значок, только если он взят - флаг кладёт сервер
		tiers: { flag: 'nss_sa', keys: ['sa_tier1_stacks', 'sa_tier2_stacks'], fallbacks: [10, 25] },
	},
	{
		theme: 'Saito',
		modifier: 'saito_formlessness_new_stacks',
		ability: 'saito_formlessness_new',
		maxKey: 'max_slashes',
		maxFallback: 10,
	},
	{
		theme: 'Muramasa',
		modifier: 'modifier_muramasa_sword_drop_enemy_buff',
		// заряды меча: в KV это sword_stacks атрибута, а атрибут живёт на Мастере
		maxFallback: 5,
	},
	{
		theme: 'Robin',
		modifier: 'modifier_robin_poison_stack',
		// потолок яда зашит в способностях Робина: 30, с атрибутом Yew Bow - 50;
		// флаг атрибута кладёт сервер (modifier_robin_poison_stack.lua)
		maxFallback: 30,
		maxFlag: { flag: 'robin_sa', value: 50 },
	},
];

// Взрывы по kind из события: тема значка, на месте которого он играет, и
// сколько живёт панель (до конца вспышки иероглифа в effect_bars.css).
// Пока взрыв идёт, значок держит своё место в ряду пустым - соседи не
// съезжают, взрыв и иероглиф играют ровно на нём.
var BURSTS = {
	shuwen: { modifier: 'modifier_nss_shock_stackable', theme: 'Shuwen', life: 2.3 },
};


var REFRESH_INTERVAL = 0.1;

// Геометрия ванильного хелсбара героя относительно точки
// WorldToScreen(origin + GetHealthBarOffset) - замерена в rasputin_hud.js.
var BAR_CENTER_X = 4;
var BAR_TOP_Y = -34;

var ROW_GAP = 3;
var UNIT_WIDTH = 300;   // .EffectUnit в css
var UNIT_HEIGHT = 44;
var CHIP_SIZE = 40;     // .EffectChip и .EffectBurst в css

// Над своим Распутиным висит его полоска стаков (rasputin_hud) - ряд выше неё.
var RASPUTIN_MODIFIER = 'modifier_rasputin_dash_charges';
var RASPUTIN_LIFT = 21;

var EXPIRING_TIME = 1.5;

// Сколько держать место снятого значка в ожидании взрыва: событие и снятие
// баффа приходят в один тик, но Refresh может увидеть снятие раньше.
var BURST_WAIT = 0.5;


var tracked = {};      // entindex -> запись из nettable
var units = {};        // entindex -> построенные панели
var visible = [];      // кого двигать каждый кадр
var bursts = [];       // идущие взрывы
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


// Центр низа ряда над хелсбаром в координатах панорамы, null - юнит за экраном.
function Anchor(entity, scale) {
	var origin = Entities.GetAbsOrigin(entity);
	var z = origin[2] + HealthBarOffset(entity);
	var screenX = Game.WorldToScreenX(origin[0], origin[1], z);
	var screenY = Game.WorldToScreenY(origin[0], origin[1], z);

	if (screenX < 0 || screenY < 0) {
		return null;
	}

	return {
		x: screenX / scale + BAR_CENTER_X,
		y: screenY / scale + BAR_TOP_Y - ROW_GAP,
	};
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


// Видит ли локальный игрок юнита: чужие - только пока их команда его видит
// (маска vis с сервера, бит 2^team - так верно и в FFA с кастомными
// командами), своя команда и зрители - всегда.
function TeamSees(entity, vis, localTeam, spectator) {
	if (spectator || Entities.GetTeamNumber(entity) === localTeam) {
		return true;
	}
	return Math.floor((vis || 0) / Math.pow(2, localTeam)) % 2 === 1;
}


function UnitShown(entity, data, localTeam, spectator) {
	if (!Entities.IsValidEntity(entity) || !Entities.IsAlive(entity)) {
		return false;
	}
	if (Entities.NoHealthBar(entity)) {
		return false;
	}
	return TeamSees(entity, data.vis, localTeam, spectator);
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


// Смещение центра значка от центра ряда - чтобы взрыв сыграл ровно на его месте.
function ChipOffset(built, chip) {
	var scale = ScreenScale();
	var rowWidth = built.row.actuallayoutwidth / scale;
	var chipX = chip.actualxoffset / scale;
	return chipX + CHIP_SIZE / 2 - rowWidth / 2;
}


function BuildChip(built, effect, entity, buff) {
	var chip = $.CreatePanel('Panel', built.row, '');
	chip.AddClass('EffectChip');
	chip.AddClass(effect.theme);

	var medalWrap = $.CreatePanel('Panel', chip, '');
	medalWrap.AddClass('EffectMedalWrap');

	var medal = $.CreatePanel('Panel', medalWrap, '');
	medal.AddClass('EffectMedal');

	var track = $.CreatePanel('Panel', chip, '');
	track.AddClass('EffectRingTrack');

	var ring = $.CreatePanel('Panel', chip, '');
	ring.AddClass('EffectRing');

	var count = $.CreatePanel('Label', chip, '');
	count.AddClass('EffectCount');
	count.text = '';

	var state = {
		modifier: effect.modifier,
		panel: chip,
		count: count,
		ring: ring,
		max: CasterValue(entity, buff, effect.ability, effect.maxKey, effect.maxFallback),
		tiers: [],
		lastCount: -1,
		lastSweep: -1,
	};

	if (effect.tiers) {
		for (var k = 0; k < effect.tiers.keys.length; k++) {
			state.tiers.push(CasterValue(entity, buff, effect.ability,
				effect.tiers.keys[k], effect.tiers.fallbacks[k]));
		}
	}

	built.chips[effect.modifier] = state;
	return state;
}


function UpdateChip(effect, state, entity, buff, data) {
	var stacks = Buffs.GetStackCount(entity, buff);

	var base = (effect.maxFlag && data[effect.maxFlag.flag] === 1) ? effect.maxFlag.value : state.max;

	// потолок мог не прочитаться из KV - не даём ему быть меньше стаков
	var max = Math.max(base, stacks, 1);

	if (stacks !== state.lastCount) {
		if (stacks > state.lastCount && state.lastCount >= 0) {
			state.count.TriggerClass('Pop');
		}
		state.lastCount = stacks;
		state.count.text = String(stacks);
		state.panel.SetHasClass('Max', stacks >= max);
	}

	if (effect.tiers) {
		var tierOn = data[effect.tiers.flag] === 1;
		state.panel.SetHasClass('Tier1', tierOn && stacks >= state.tiers[0] && stacks < state.tiers[1]);
		state.panel.SetHasClass('Tier2', tierOn && stacks >= state.tiers[1] && stacks < max);
	}

	var duration = Buffs.GetDuration(entity, buff);
	var permanent = !(duration > 0);
	state.panel.SetHasClass('Permanent', permanent);

	if (!permanent) {
		var remaining = Math.max(Buffs.GetRemainingTime(entity, buff), 0);
		// дуга от 12 часов по часовой стрелке, убывает к 12 часам
		var sweep = Math.round(Math.min(remaining / duration, 1) * 3600) / 10;
		if (sweep !== state.lastSweep) {
			state.lastSweep = sweep;
			state.ring.style.clip = 'radial( 50% 50%, 0deg, ' + sweep + 'deg )';
		}
		state.panel.SetHasClass('Expiring', remaining <= EXPIRING_TIME);
	}
}


function Refresh() {
	var localPlayer = Players.GetLocalPlayer();
	var localTeam = Players.GetTeam(localPlayer);
	var spectator = Players.IsSpectator(localPlayer);
	var now = Game.GetGameTime();
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
				if (!state) {
					continue;
				}
				// место пустует до взрыва (или его ожидания), потом значок уходит
				if (!state.leaveAt) {
					state.leaveAt = now + BURST_WAIT;
				}
				if (now < Math.max(state.leaveAt, state.burstUntil || 0)) {
					state.panel.AddClass('Gone');
					any = true;
					continue;
				}
				state.panel.DeleteAsync(0);
				delete built.chips[effect.modifier];
				continue;
			}

			if (!built) {
				built = BuildUnit(entity);
			}
			if (!state) {
				state = BuildChip(built, effect, entity, buff);
			}

			// новые стаки во время взрыва покажутся, когда он доиграет
			state.leaveAt = 0;
			state.panel.SetHasClass('Gone', now < (state.burstUntil || 0));
			UpdateChip(effect, state, entity, buff, data);
			any = true;
		}

		if (!any) {
			continue;
		}

		built.lift = (entity === Players.GetPlayerHeroEntityIndex(localPlayer)
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


function OnBurst(event) {
	var kind = BURSTS[event.kind];
	var entity = event.unit;

	if (!kind || !Entities.IsValidEntity(entity)) {
		return;
	}

	var localPlayer = Players.GetLocalPlayer();
	if (!TeamSees(entity, event.vis, Players.GetTeam(localPlayer), Players.IsSpectator(localPlayer))) {
		return;
	}

	// взрыв играет на значке и держит его место пустым до конца; значка
	// нет (взрыв без стаков) - по центру ряда
	var built = units[entity];
	var chip = built && built.chips[kind.modifier];
	var dx = 0;
	if (chip) {
		chip.burstUntil = Game.GetGameTime() + kind.life;
		chip.panel.AddClass('Gone');
		dx = ChipOffset(built, chip.panel);
	}

	var panel = $.CreatePanel('Panel', root, '');
	panel.AddClass('EffectBurst');
	panel.AddClass(kind.theme);

	var scaleLayer = $.CreatePanel('Panel', panel, '');
	scaleLayer.AddClass('BurstScale');

	var spin = $.CreatePanel('Panel', scaleLayer, '');
	spin.AddClass('BurstSpin');

	var glyph = $.CreatePanel('Panel', panel, '');
	glyph.AddClass('BurstGlyph');

	var burst = { entity: entity, panel: panel, chip: chip, dx: dx, lift: built ? built.lift : 0 };
	bursts.push(burst);
	PlaceBurst(burst, ScreenScale());
	panel.DeleteAsync(kind.life);
	$.Schedule(kind.life, function () {
		for (var i = 0; i < bursts.length; i++) {
			if (bursts[i].panel === panel) {
				bursts.splice(i, 1);
				return;
			}
		}
	});
}


// Взрыв идёт за юнитом, в том числе за умершим от этого удара.
function PlaceBurst(burst, scale) {
	var at = Entities.IsValidEntity(burst.entity) ? Anchor(burst.entity, scale) : null;

	burst.panel.SetHasClass('Hidden', !at);

	if (!at) {
		return;
	}

	// ряд мог сдвинуться из-за чужого значка - взрыв идёт за своим местом
	var built = units[burst.entity];
	if (burst.chip && built && built.chips[burst.chip.modifier] === burst.chip) {
		burst.dx = ChipOffset(built, burst.chip.panel);
		burst.lift = built.lift;
	}

	var x = Math.round(at.x + burst.dx - CHIP_SIZE / 2);
	var y = Math.round(at.y - CHIP_SIZE - burst.lift);
	burst.panel.style.position = x + 'px ' + y + 'px 0px';
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

		var anchor = Anchor(entity, scale);
		built.panel.SetHasClass('Hidden', !anchor);

		if (!anchor) {
			continue;
		}

		var x = Math.round(anchor.x - UNIT_WIDTH / 2);
		var y = Math.round(anchor.y - UNIT_HEIGHT - built.lift);

		if (x !== built.x || y !== built.y) {
			built.x = x;
			built.y = y;
			built.panel.style.position = x + 'px ' + y + 'px 0px';
		}
	}

	for (var b = 0; b < bursts.length; b++) {
		PlaceBurst(bursts[b], scale);
	}
}


(function () {
	var all = CustomNetTables.GetAllTableValues('effect_bars') || [];
	for (var i = 0; i < all.length; i++) {
		OnNetTable('effect_bars', all[i].key, all[i].value);
	}
	CustomNetTables.SubscribeNetTableListener('effect_bars', OnNetTable);
	GameEvents.Subscribe('effect_bars_burst', OnBurst);
	Update();
})();
