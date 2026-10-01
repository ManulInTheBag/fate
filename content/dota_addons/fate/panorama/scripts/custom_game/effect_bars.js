'use strict';

// Ряд эффектов со стаками над хелсбаром юнита: круглый медальон, число стаков
// по центру и кольцо оставшегося времени по краю. Заменил партикли-счётчики
// над головой (Li Shuwen, Saito, Muramasa) и добавил яд Robin Hood,
// проклятия Gae Bolg Скатах и Аталанты Альтер, стрелы Аталанты, кровотечения
// Влада и Медузы, яд Хассана. Плюс полоски над своим героем (OWN_BARS).
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
	{
		theme: 'Scathach',
		modifier: 'modifier_stachach_gae_bolg_curse',
		// потолок проклятия Gae Bolg зашит в OnRefresh модификатора
		maxFallback: 10,
	},
	{
		theme: 'AtalantaAlter',
		modifier: 'modifier_atalanta_curse',
		// потолка нет; со 100 стаков при атрибуте Vision Альтер видит цель -
		// значок на этом пороге пульсирует, флаг кладёт сервер (atalanta_curse.lua)
		maxFallback: 0,
		maxFlag: { flag: 'atalanta_vision', value: 100 },
	},
	{
		theme: 'Atalanta',
		modifier: 'modifier_celestial_arrow_stacking_debuff',
		// стаки стрел с атрибута Calydonian Snipe, потолка нет
		maxFallback: 0,
	},
	{
		theme: 'Vlad',
		modifier: 'modifier_bleed',
		// кровотечение Влада (passive rending), потолка нет
		maxFallback: 0,
	},
	{
		theme: 'Medusa',
		modifier: 'modifier_medusa_bleed',
		// кровотечение с атрибута цепей Медузы, потолка нет
		maxFallback: 0,
	},
	{
		theme: 'Hassan',
		modifier: 'modifier_dirk_poison_slow',
		// стаки яда кинжалов Хассана: по ним считается урон modifier_dirk_poison
		maxFallback: 0,
	},
];


// Полоски над СВОИМ героем, как у Распутина (rasputin_hud): стаки, которые
// видит только владелец. Потолок - из KV своей способности или с сервера
// (capExtra в записи nettable, когда он зависит от атрибута).
var OWN_BARS = [
	{
		theme: 'Hijikata',
		modifier: 'modifier_hijikata_ult_stacks',
		// стаки = накопленный урон в % от порога; с атрибутом BC потолок выше
		// 100 - сервер кладёт его в hijikata_cap (hijikata_ult.lua)
		capExtra: 'hijikata_cap',
		maxFallback: 100,
		tickEvery: 25,
		markAt: 100,
		label: function (stacks) { return stacks + '%'; },
	},
	{
		theme: 'Nobunaga',
		// стаки, которые тратит D (demon_king_release)
		modifier: 'modifier_demon_king_materialization',
		ability: 'demon_king_materialization',
		maxKey: 'maximum_stack_count',
		maxFallback: 10,
		tickEvery: 1,
		label: function (stacks, max) { return stacks + ' / ' + max; },
	},
];

// Геометрия полоски Распутина (rasputin_hud.js): 131x15, низ на 3px выше
// хелсбара. Каждая следующая полоска и ряд значков над ней - выше на OWN_BAR_STEP.
var OWN_BAR_WIDTH = 131;
var OWN_BAR_HEIGHT = 15;
var OWN_BAR_X = -60.5;  // левый край от Anchor().x
var OWN_BAR_Y = -18;    // верх от Anchor().y
var OWN_BAR_STEP = 21;

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

// Больше ROW_MAX значков - перенос: нижний ряд держит первые ROW_MAX эффектов
// (в порядке EFFECTS), остальные встают рядом выше, каждый ряд по центру.
// 4 значка ~ 176px - в полтора хелсбара.
var ROW_MAX = 4;
var ROW_STEP = 44;      // от низа ряда до низа следующего: значок + зазор

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
var ownBars = {};      // modifier -> полоска над своим героем
var ownShown = 0;      // сколько полосок сейчас над своим героем
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

	var built = { panel: panel, rows: [], chips: {}, layout: '' };
	units[entity] = built;
	return built;
}


// Ряд k снизу (0 - нижний). Ряды не в потоке: каждый прижат к низу панели
// юнита и поднят отступом.
function Row(built, k) {
	while (built.rows.length <= k) {
		var row = $.CreatePanel('Panel', built.panel, '');
		row.AddClass('EffectRow');
		row.style.marginBottom = (built.rows.length * ROW_STEP) + 'px';
		built.rows.push(row);
	}
	return built.rows[k];
}


// Раскладка значков по рядам. Перекладывает только когда меняется набор
// эффектов - значки не прыгают, пока набор тот же.
function LayoutRows(built) {
	var order = [];
	for (var e = 0; e < EFFECTS.length; e++) {
		if (built.chips[EFFECTS[e].modifier]) {
			order.push(EFFECTS[e].modifier);
		}
	}

	var layout = order.join(',');
	if (layout === built.layout) {
		return;
	}
	built.layout = layout;

	// по порядку: SetParent кладёт в конец ряда
	for (var i = 0; i < order.length; i++) {
		built.chips[order[i]].panel.SetParent(Row(built, Math.floor(i / ROW_MAX)));
	}
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
// Центр значка относительно точки Anchor (низ-центр ряда), в px панорамы:
// взрыв играет ровно на нём, в каком бы ряду он ни стоял.
function ChipOffset(built, chip) {
	var scale = ScreenScale();
	var row = chip.GetParent();
	return {
		x: (row.actualxoffset + chip.actualxoffset) / scale + CHIP_SIZE / 2 - UNIT_WIDTH / 2,
		y: (row.actualyoffset + chip.actualyoffset) / scale + CHIP_SIZE / 2 - UNIT_HEIGHT,
	};
}


function BuildChip(built, effect, entity, buff) {
	var chip = $.CreatePanel('Panel', Row(built, 0), '');
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

	// 0 = без потолка (проклятие Альтер, стрелы Аталанты); maxFlag - другой
	// потолок или порог, пока на сервере стоит флаг атрибута
	var cap = (effect.maxFlag && data[effect.maxFlag.flag] === 1) ? effect.maxFlag.value : state.max;

	// потолок мог не прочитаться из KV - не даём ему быть меньше стаков
	var max = cap > 0 ? Math.max(cap, stacks, 1) : Infinity;

	if (stacks !== state.lastCount) {
		if (stacks > state.lastCount && state.lastCount >= 0) {
			state.count.TriggerClass('Pop');
		}
		state.lastCount = stacks;
		state.count.text = String(stacks);
		// три цифры в 40px влезают только мельче
		state.count.SetHasClass('Wide', stacks >= 100);
	}

	state.panel.SetHasClass('Max', stacks >= max);

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


function OwnValue(entity, abilityName, key, fallback) {
	if (!abilityName || !key) {
		return fallback;
	}
	var ability = Entities.GetAbilityByName(entity, abilityName);
	if (ability === undefined || ability === -1) {
		return fallback;
	}
	var value = Abilities.GetSpecialValueFor(ability, key);
	return value > 0 ? value : fallback;
}


function BuildOwnBar(bar) {
	var panel = $.CreatePanel('Panel', root, '');
	panel.AddClass('EffectOwnBar');
	panel.AddClass(bar.theme);

	var fill = $.CreatePanel('Panel', panel, '');
	fill.AddClass('EffectOwnFill');

	var ticks = $.CreatePanel('Panel', panel, '');
	ticks.AddClass('EffectOwnTicks');

	var label = $.CreatePanel('Label', panel, '');
	label.AddClass('EffectOwnLabel');

	return { panel: panel, fill: fill, ticks: ticks, label: label, max: -1, lastStacks: -1 };
}


// Деления: каждые tickEvery стаков, яркое - на markAt (порог внутри потолка).
function BuildTicks(state, bar, max) {
	state.ticks.RemoveAndDeleteChildren();
	for (var t = bar.tickEvery; t < max; t += bar.tickEvery) {
		var tick = $.CreatePanel('Panel', state.ticks, '');
		tick.AddClass('EffectOwnTick');
		tick.SetHasClass('Mark', t === bar.markAt);
		tick.style.position = (t * 100 / max) + '% 0px 0px';
	}
	if (bar.markAt && bar.markAt < max && bar.markAt % bar.tickEvery !== 0) {
		var mark = $.CreatePanel('Panel', state.ticks, '');
		mark.AddClass('EffectOwnTick');
		mark.AddClass('Mark');
		mark.style.position = (bar.markAt * 100 / max) + '% 0px 0px';
	}
}


function RefreshOwnBars(hero) {
	var buffs = hero !== -1 && Entities.IsValidEntity(hero) && Entities.IsAlive(hero)
		? BuffsByName(hero) : {};
	var data = tracked[hero] || {};

	ownShown = 0;

	for (var i = 0; i < OWN_BARS.length; i++) {
		var bar = OWN_BARS[i];
		var buff = buffs[bar.modifier];
		var state = ownBars[bar.modifier];

		if (buff === undefined) {
			if (state) {
				state.panel.DeleteAsync(0);
				delete ownBars[bar.modifier];
			}
			continue;
		}

		if (!state) {
			state = ownBars[bar.modifier] = BuildOwnBar(bar);
		}

		var max = bar.capExtra && data[bar.capExtra] > 0
			? data[bar.capExtra]
			: OwnValue(hero, bar.ability, bar.maxKey, bar.maxFallback);
		var stacks = Buffs.GetStackCount(hero, buff);

		if (max !== state.max) {
			state.max = max;
			state.lastStacks = -1;
			BuildTicks(state, bar, max);
		}

		if (stacks !== state.lastStacks) {
			state.lastStacks = stacks;
			state.fill.style.width = (Math.min(stacks, max) * 100 / max) + '%';
			state.label.text = bar.label(stacks, max);
			state.panel.SetHasClass('Max', stacks >= max);
			state.panel.SetHasClass('Empty', stacks <= 0);
		}

		state.slot = ownShown;
		ownShown++;
	}
}


function PlaceOwnBars(hero, scale) {
	var at = null;
	if (ownShown > 0 && Entities.IsValidEntity(hero)) {
		at = Anchor(hero, scale);
	}

	for (var modifier in ownBars) {
		var state = ownBars[modifier];
		state.panel.SetHasClass('Hidden', !at);
		if (!at) {
			continue;
		}
		var x = Math.round(at.x + OWN_BAR_X);
		var y = Math.round(at.y + OWN_BAR_Y - state.slot * OWN_BAR_STEP);
		if (x !== state.x || y !== state.y) {
			state.x = x;
			state.y = y;
			state.panel.style.position = x + 'px ' + y + 'px 0px';
		}
	}
}


function Refresh() {
	var localPlayer = Players.GetLocalPlayer();

	RefreshOwnBars(Players.GetPlayerHeroEntityIndex(localPlayer));

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

		LayoutRows(built);

		built.lift = 0;
		if (entity === Players.GetPlayerHeroEntityIndex(localPlayer)) {
			built.lift = (buffs[RASPUTIN_MODIFIER] !== undefined ? RASPUTIN_LIFT : 0)
				+ ownShown * OWN_BAR_STEP;
		}

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
	var off = { x: 0, y: -CHIP_SIZE / 2 };
	if (chip) {
		chip.burstUntil = Game.GetGameTime() + kind.life;
		chip.panel.AddClass('Gone');
		off = ChipOffset(built, chip.panel);
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

	var burst = { entity: entity, panel: panel, chip: chip, off: off, lift: built ? built.lift : 0 };
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
		burst.off = ChipOffset(built, burst.chip.panel);
		burst.lift = built.lift;
	}

	var x = Math.round(at.x + burst.off.x - CHIP_SIZE / 2);
	var y = Math.round(at.y + burst.off.y - CHIP_SIZE / 2 - burst.lift);
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

	PlaceOwnBars(Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer()), scale);
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
