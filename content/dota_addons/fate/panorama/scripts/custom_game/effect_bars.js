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
		id: 'shuwen',
		hero: 'npc_dota_hero_bloodseeker',
		theme: 'Shuwen',
		modifier: 'modifier_nss_shock_stackable',
		ability: 'lishuwen_no_second_strike',
		maxKey: 'max_stacks',
		maxFallback: 50,
		// ступени атрибута красят значок, только если он взят - флаг кладёт сервер
		tiers: { flag: 'nss_sa', keys: ['sa_tier1_stacks', 'sa_tier2_stacks'], fallbacks: [10, 25] },
	},
	{
		id: 'saito',
		hero: 'npc_dota_hero_terrorblade',
		theme: 'Saito',
		modifier: 'saito_formlessness_new_stacks',
		ability: 'saito_formlessness_new',
		maxKey: 'max_slashes',
		maxFallback: 10,
	},
	{
		id: 'muramasa',
		hero: 'npc_dota_hero_magnataur',
		theme: 'Muramasa',
		modifier: 'modifier_muramasa_sword_drop_enemy_buff',
		// заряды меча: в KV это sword_stacks атрибута, а атрибут живёт на Мастере
		maxFallback: 5,
	},
	{
		id: 'robin',
		hero: 'npc_dota_hero_sniper',
		theme: 'Robin',
		modifier: 'modifier_robin_poison_stack',
		// потолок яда зашит в способностях Робина: 30, с атрибутом Yew Bow - 50;
		// флаг атрибута кладёт сервер (modifier_robin_poison_stack.lua)
		maxFallback: 30,
		maxFlag: { flag: 'robin_sa', value: 50 },
	},
	{
		id: 'scathach',
		hero: 'npc_dota_hero_monkey_king',
		theme: 'Scathach',
		modifier: 'modifier_stachach_gae_bolg_curse',
		// потолок проклятия Gae Bolg зашит в OnRefresh модификатора
		maxFallback: 10,
	},
	{
		id: 'atalanta_alter',
		hero: 'npc_dota_hero_ursa',
		theme: 'AtalantaAlter',
		modifier: 'modifier_atalanta_curse',
		// потолка нет; со 100 стаков при атрибуте Vision Альтер видит цель -
		// значок на этом пороге пульсирует, флаг кладёт сервер (atalanta_curse.lua)
		maxFallback: 0,
		maxFlag: { flag: 'atalanta_vision', value: 100 },
	},
	{
		id: 'atalanta',
		hero: 'npc_dota_hero_drow_ranger',
		theme: 'Atalanta',
		modifier: 'modifier_celestial_arrow_stacking_debuff',
		// стаки стрел с атрибута Calydonian Snipe, потолка нет
		maxFallback: 0,
	},
	{
		id: 'vlad',
		hero: 'npc_dota_hero_tidehunter',
		theme: 'Vlad',
		modifier: 'modifier_bleed',
		// кровотечение Влада (passive rending), потолка нет
		maxFallback: 0,
	},
	{
		id: 'medusa',
		hero: 'npc_dota_hero_templar_assassin',
		theme: 'Medusa',
		modifier: 'modifier_medusa_bleed',
		// кровотечение с атрибута цепей Медузы, потолка нет
		maxFallback: 0,
	},
	{
		// Death Door King Hassan: число - накопленный бонус к урону Азраэля,
		// цвет - как у черепа над целью (dd_state кладёт сервер, khsn_azrael.lua):
		// зелёный - Азраэль добьёт, красный - уже ниже порога казни.
		// По умолчанию выключен (DefaultSettings): череп над целью и так есть.
		id: 'king_hassan',
		hero: 'npc_dota_hero_skeleton_king',
		theme: 'KingHassan',
		modifier: 'modifier_death_door',
		maxFallback: 0,
		states: { flag: 'dd_state', classes: ['', 'Lethal', 'Execute'] },
	},
	{
		id: 'hassan',
		hero: 'npc_dota_hero_bounty_hunter',
		theme: 'Hassan',
		// Яд Хассана собран из трёх модификаторов: урон наносит скрытый
		// modifier_dirk_poison, умножая на стаки slow + venom, а стаки живут
		// в других модификаторах (slow снимается иммунитетом/снятием
		// замедлений, яд при этом остаётся). Число = настоящий множитель урона;
		// значок тусклый (Idle), пока урон не идёт: яда нет или стаков 0.
		modifier: 'modifier_dirk_poison',
		parts: ['modifier_dirk_poison_slow', 'modifier_weakening_venom'],
		maxFallback: 0,
	},
	{
		// Highnoon Билли: зарядка залпа по этой цели, 0-100 % (стаки ставит
		// billy_highnoon.lua). Кольцо показывает зарядку, а не время.
		id: 'billy',
		hero: 'npc_dota_hero_muerta',
		theme: 'Billy',
		modifier: 'modifier_billy_highnoon_charge',
		maxFallback: 100,
		ringByStacks: true,
		// растёт каждые 0.1 с - «выпрыгивание» цифры дёргало бы значок
		noPop: true,
		suffix: '%',
	},
	{
		// Хедшот Билли (атрибут Here Is an Old Trick): стаки от попаданий
		// способностями, на полных следующий выстрел критует - значок
		// пульсирует (Max). Потолок head_stacks кладёт сервер в billy_head_max
		// (billy_shared.lua): KV чужого героя на клиенте не прочитать.
		id: 'billy_headshot',
		hero: 'npc_dota_hero_muerta',
		theme: 'BillyHeadshot',
		modifier: 'modifier_billy_headshot',
		maxFallback: 3,
		maxExtra: 'billy_head_max',
		showMax: true,
	},
];


// Полоски над СВОИМ героем, как у Распутина (rasputin_hud): стаки, которые
// видит только владелец. Потолок - из KV своей способности или с сервера
// (capExtra в записи nettable, когда он зависит от атрибута).
var OWN_BARS = [
	{
		id: 'hijikata',
		hero: 'npc_dota_hero_spirit_breaker',
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
		id: 'nobunaga',
		hero: 'npc_dota_hero_nevermore',
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
	shuwen: { id: 'shuwen', modifier: 'modifier_nss_shock_stackable', theme: 'Shuwen', life: 2.3 },
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

// Значок «переживёт смертельный удар» (Battle Continuation и похожие
// пассивки) справа от хелсбара героя. Есть ли он и его перезарядку считает
// сервер (libraries/survival_icons.lua, nettable survival_icons): флаги
// атрибутов клиент не видит. Время в записи абсолютное, отсчёт идёт здесь.
var SURVIVAL_SIZE = 34;  // .SurvivalIcon в css
var SURVIVAL_X = 73;     // левый край от Anchor().x: правый край хелсбара (OWN_BAR_X + OWN_BAR_WIDTH) + 2.5px
var SURVIVAL_Y = -5;     // верх от Anchor().y: по центру полоски HP

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
var iconsOff = false;    // значки выключены в настройках (icons в профиле, вкладка Effects)
var survivalOff = false; // значок выживания выключен там же отдельным тумблером (survival)
var survivalTracked = {};  // entindex -> запись из nettable survival_icons
var survivalUnits = {};    // entindex -> панель значка
var root = $('#EffectBarsRoot');


// --- Что показывать: настройки игрока ---------------------------------------
//
// Правятся во вкладке Effects окна настроек (fateanother_effects.js) и на
// сайте (/me/effects), хранятся на сервере статистики по steamid
// (fate_settings.lua -> /settings). Профиль:
//   scope    - чьи эффекты видны: all | from_me | on_me | enemies | allies;
//   own      - наложенные моим героем видны всегда, поверх off и scope;
//   off      - id выключенных эффектов: новый эффект по умолчанию включён;
//   icons    - значки над хелсбарами вообще; survival - значок выживания;
//   billy_hint - баннер выбора цели атрибута Билли Young Outlaw Leader (billy_hud.js);
//   billy_drum - счётчик пуль Билли у хелсбара: drum (барабан с числом) | number
//                (только число) | none; billy_reload - анимация перезарядки барабана.
//   Настройки Билли - блок «Настройки героев» во вкладке; сам счётчик виден только
//   игроку, который играет Билли.
//
// Состояние живёт в CustomUIConfig().fateEffects: его читают этот файл и
// вкладка, и оно переживает перезагрузку панелей. Загрузку ведёт этот файл -
// HUD жив весь матч, вкладка может быть ни разу не открыта. Правка
// применяется сразу, а на сервер уходит по кнопке Save во вкладке.

var SCOPES = ['all', 'from_me', 'on_me', 'enemies', 'allies'];
var BILLY_DRUM_MODES = ['drum', 'number', 'none'];
var SETTINGS_SAVE_TIMEOUT = 15;
var SETTINGS_LOAD_TIMEOUT = 20;   // с: реле в начале матча может быть не готово
var SETTINGS_LOAD_TRIES = 3;
var SETTINGS_MAX_OFF = 64;


// по умолчанию - только эффекты на своём герое (и свои, own): чужие стаки на
// чужих героях у новичка забивали бы экран. В off - эффекты, выключенные по
// умолчанию (Death Door: череп над целью и так виден). Сохранённый профиль
// хранит свой off целиком, так что умолчания на него не влияют.
var DEFAULT_OFF = ['king_hassan'];

function DefaultSettings() {
	return { v: 1, scope: 'on_me', own: 1, off: DEFAULT_OFF.slice(), icons: 1, survival: 1, billy_hint: 1,
		billy_drum: 'drum', billy_reload: 1 };
}


function Flag(value) {
	return value === 0 || value === false ? 0 : 1;
}


// Незнакомые id в off не выбрасываются: их мог выключить сайт или версия
// аддона новее этой.
function SanitizeSettings(raw) {
	var s = DefaultSettings();
	if (!raw || typeof raw !== 'object') {
		return s;
	}
	if (SCOPES.indexOf(raw.scope) >= 0) {
		s.scope = raw.scope;
	}
	s.own = Flag(raw.own);
	s.icons = Flag(raw.icons);
	s.survival = Flag(raw.survival);
	s.billy_hint = Flag(raw.billy_hint);
	if (BILLY_DRUM_MODES.indexOf(raw.billy_drum) >= 0) {
		s.billy_drum = raw.billy_drum;
	}
	s.billy_reload = Flag(raw.billy_reload);
	// свой список выключенных заменяет умолчания целиком, даже пустой
	if (raw.off && typeof raw.off.length === 'number') {
		s.off = [];
		for (var i = 0; i < raw.off.length && s.off.length < SETTINGS_MAX_OFF; i++) {
			var id = raw.off[i];
			if (typeof id === 'string' && /^[a-z0-9_]{1,32}$/.test(id) && s.off.indexOf(id) < 0) {
				s.off.push(id);
			}
		}
	}
	return s;
}


// Список для вкладки: id, герой (имя - из его токена локализации), подпись
// эффекта и медальон (у полосок над своим героем медальона нет).
function Catalog() {
	var list = [];
	for (var e = 0; e < EFFECTS.length; e++) {
		list.push({ id: EFFECTS[e].id, hero: EFFECTS[e].hero, name: '#FA_Effect_' + EFFECTS[e].id, medal: EFFECTS[e].id, own: false });
	}
	for (var b = 0; b < OWN_BARS.length; b++) {
		list.push({ id: OWN_BARS[b].id, hero: OWN_BARS[b].hero, name: '#FA_Effect_' + OWN_BARS[b].id, medal: '', own: true });
	}
	return list;
}


function Store() {
	var config = GameUI.CustomUIConfig();
	if (!config.fateEffects) {
		config.fateEffects = {
			settings: DefaultSettings(),
			offMap: {},
			load: 'idle',      // idle | loading | loaded | none (на сервере пусто) | failed | local
			loadTry: 0,        // номер запроса: ответ таймера сверяет, что он про свой
			loadTries: 0,      // попыток в текущей серии
			save: 'idle',      // idle | pending | saving | saved | failed
			saveSeq: 0,
			dirty: false,      // есть правки, которых нет на сервере
			saveQueued: false, // Save нажат, пока шла загрузка: сохранить после неё
			manualLoad: false, // загрузка по кнопке Load: сервер важнее несохранённых правок
			lastSaved: null,   // строка, которая точно лежит на сервере
			pendingJson: null,
			onChange: null,    // вкладка вешает сюда обновление своей панели
		};
	}
	return config.fateEffects;
}


function Notify(store) {
	if (typeof store.onChange === 'function') {
		try {
			store.onChange();
		} catch (err) {
			store.onChange = null;   // панель вкладки удалена
		}
	}
}


function ApplySettings(store, settings) {
	store.settings = settings;
	store.offMap = {};
	for (var i = 0; i < settings.off.length; i++) {
		store.offMap[settings.off[i]] = true;
	}
	lastRefresh = -1;   // перечитать значки в ближайший кадр
	Notify(store);
}


function LocalCanSave() {
	var player = Players.GetLocalPlayer();
	return player >= 0 && !Players.IsSpectator(player);
}


function SaveSettingsNow(store) {
	if (store.load === 'loading') {
		// иначе ответ загрузки пришёл бы после и сравнивал со старым
		store.saveQueued = true;
		Notify(store);
		return;
	}
	store.saveQueued = false;
	if (!LocalCanSave()) {
		store.save = 'idle';
		Notify(store);
		return;
	}

	var json = JSON.stringify(store.settings);
	if (json === store.lastSaved) {
		store.dirty = false;
		store.save = 'saved';
		Notify(store);
		return;
	}

	store.save = 'saving';
	store.pendingJson = json;
	var seq = ++store.saveSeq;
	GameEvents.SendCustomGameEventToServer('player_save_settings', { data: json });
	Notify(store);

	$.Schedule(SETTINGS_SAVE_TIMEOUT, function () {
		var s = Store();
		if (s.save === 'saving' && s.saveSeq === seq) {
			s.save = 'failed';
			Notify(s);
		}
	});
}


// Вкладка зовёт это на каждую правку: применяется сразу, на сервер - по
// кнопке Save (SaveSettingsNow). Вернул как было - правок снова нет.
function ChangeSettings(next) {
	var store = Store();
	ApplySettings(store, SanitizeSettings(next));
	if (store.save !== 'saving') {
		store.dirty = JSON.stringify(store.settings) !== store.lastSaved;
		store.save = store.dirty ? 'pending' : (store.lastSaved !== null ? 'saved' : 'idle');
	} else {
		store.dirty = true;
	}
	Notify(store);
}


// retry - повтор по таймауту; без него начинается новая серия попыток.
function RequestSettingsLoad(retry) {
	var store = Store();
	var player = Players.GetLocalPlayer();
	if (player < 0) {
		$.Schedule(1, RequestSettingsLoad);   // игрок ещё не назначен
		return;
	}
	if (Players.IsSpectator(player)) {
		store.load = 'local';
		Notify(store);
		return;
	}

	store.load = 'loading';
	store.loadTries = retry ? store.loadTries + 1 : 1;
	var attempt = ++store.loadTry;
	GameEvents.SendCustomGameEventToServer('player_load_settings', {});
	Notify(store);

	$.Schedule(SETTINGS_LOAD_TIMEOUT, function () {
		var s = Store();
		if (s.load !== 'loading' || s.loadTry !== attempt) {
			return;
		}
		if (s.loadTries < SETTINGS_LOAD_TRIES) {
			RequestSettingsLoad(true);
			return;
		}
		s.load = 'failed';
		Notify(s);
		if (s.saveQueued) {
			SaveSettingsNow(s);
		}
	});
}


function OnSettingsLoaded(data) {
	var store = Store();
	var ok = data && data.ok == 1 && typeof data.data === 'string';

	if (ok) {
		var parsed = null;
		try {
			parsed = JSON.parse(data.data);
		} catch (err) {
			parsed = null;
		}
		var settings = SanitizeSettings(parsed);
		store.lastSaved = JSON.stringify(settings);
		store.load = 'loaded';
		// правки, сделанные, пока шла загрузка, важнее сохранённого
		if (!store.dirty) {
			ApplySettings(store, settings);
			store.save = 'saved';
		}
	} else if (data && data.status == 404) {
		store.load = 'none';
		// по кнопке Load «на сервере пусто» = вернуть умолчания
		if (store.manualLoad && !store.dirty) {
			store.lastSaved = null;
			ApplySettings(store, DefaultSettings());
		}
	} else {
		store.load = 'failed';
	}
	store.manualLoad = false;

	Notify(store);
	if (store.saveQueued) {
		SaveSettingsNow(store);
	}
}


function OnSettingsSaveResult(data) {
	var store = Store();
	if (store.save !== 'saving') {
		return;
	}
	if (data && data.ok == 1) {
		store.lastSaved = store.pendingJson;
		// правки, сделанные пока шло сохранение, ждут следующего нажатия
		store.dirty = JSON.stringify(store.settings) !== store.lastSaved;
		store.save = store.dirty ? 'pending' : 'saved';
	} else {
		store.save = 'failed';
	}
	Notify(store);
}


// Кто смотрит - один раз на Refresh, а не на каждый значок.
function ViewContext() {
	var store = Store();
	var localPlayer = Players.GetLocalPlayer();
	return {
		settings: store.settings,
		offMap: store.offMap,
		localPlayer: localPlayer,
		localHero: Players.GetPlayerHeroEntityIndex(localPlayer),
		localTeam: Players.GetTeam(localPlayer),
		spectator: Players.IsSpectator(localPlayer),
	};
}


// PlayerID владельца кастера эффекта - кладёт сервер (c_<модификатор> в
// записи nettable, libraries/effect_bars.lua). Buffs.GetCaster тут не
// помощник: для этих баффов панорама отдаёт -1. У эффекта из частей (яд
// Хассана) - первый известный кастер. -1 - неизвестно / ничей.
function CasterPlayer(effect, data) {
	var names = [effect.modifier].concat(effect.parts || []);
	for (var i = 0; i < names.length; i++) {
		var pid = data['c_' + names[i]];
		if (typeof pid === 'number' && pid >= 0) {
			return pid;
		}
	}
	return -1;
}


// Виден ли эффект id на юните unit от игрока casterPid. «Мой» - наложенный
// юнитом моего игрока (герой, Мастер, призванные). У зрителя нет ни своего
// героя, ни своей команды: «враги» и «союзники» для него - все.
function EffectAllowed(id, unit, casterPid, view) {
	var settings = view.settings;
	var mine = view.localPlayer >= 0 && casterPid === view.localPlayer;

	if (settings.own && mine) {
		return true;
	}
	if (view.offMap[id]) {
		return false;
	}

	switch (settings.scope) {
		case 'from_me':
			return mine;
		case 'on_me':
			return unit === view.localHero;
		case 'enemies':
			return view.spectator || Entities.GetTeamNumber(unit) !== view.localTeam;
		case 'allies':
			return view.spectator || Entities.GetTeamNumber(unit) === view.localTeam;
	}
	return true;
}


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

	var built = { panel: panel, rows: [], chips: {}, layout: '', height: UNIT_HEIGHT };
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

	// Панель растёт вверх на каждый ряд: ряд за её границей Panorama не рисует,
	// даже с overflow: noclip (проверено в игре - пятый и дальше значки
	// пропадали). Низ панели остаётся на месте - его держит Update по height.
	var rows = Math.max(1, Math.ceil(order.length / ROW_MAX));
	built.height = UNIT_HEIGHT + (rows - 1) * ROW_STEP;
	built.panel.style.height = built.height + 'px';
	built.y = null;

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
		y: (row.actualyoffset + chip.actualyoffset) / scale + CHIP_SIZE / 2 - built.height,
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


// Бафф, стаки и «идёт ли урон» эффекта. Обычно это один модификатор; с parts
// стаки складываются из частей, а modifier - тот, без которого они не бьют.
// null - на юните ничего из этого нет.
function ReadEffect(effect, entity, buffs) {
	var main = buffs[effect.modifier];

	if (!effect.parts) {
		return main === undefined ? null
			: { buff: main, stacks: Buffs.GetStackCount(entity, main), idle: false };
	}

	var timer = main;
	var stacks = 0;
	for (var i = 0; i < effect.parts.length; i++) {
		var part = buffs[effect.parts[i]];
		if (part !== undefined) {
			stacks += Buffs.GetStackCount(entity, part);
			if (timer === undefined) {
				timer = part;
			}
		}
	}

	if (timer === undefined) {
		return null;
	}

	return { buff: timer, stacks: stacks, idle: main === undefined || stacks <= 0 };
}


function UpdateChip(effect, state, entity, read, data) {
	var buff = read.buff;
	var stacks = read.stacks;

	state.panel.SetHasClass('Idle', read.idle);

	// 0 = без потолка (проклятие Альтер, стрелы Аталанты); maxFlag - другой
	// потолок или порог, пока на сервере стоит флаг атрибута
	var cap = (effect.maxFlag && data[effect.maxFlag.flag] === 1) ? effect.maxFlag.value : state.max;
	// maxExtra - потолок, который кладёт сервер (зависит от KV владельца)
	if (effect.maxExtra && data[effect.maxExtra] > 0) {
		cap = data[effect.maxExtra];
	}

	// потолок мог не прочитаться из KV - не даём ему быть меньше стаков
	var max = cap > 0 ? Math.max(cap, stacks, 1) : Infinity;

	if (stacks !== state.lastCount || max !== state.lastMax) {
		if (stacks > state.lastCount && state.lastCount >= 0 && !effect.noPop) {
			state.count.TriggerClass('Pop');
		}
		state.lastCount = stacks;
		state.lastMax = max;
		// showMax - «2/3»: сколько осталось до порога
		var text = (effect.showMax && max !== Infinity ? stacks + '/' + max : String(stacks))
			+ (effect.suffix || '');
		state.count.text = text;
		// три знака в 40px влезают только мельче
		state.count.SetHasClass('Wide', text.length >= 3);
	}

	state.panel.SetHasClass('Max', stacks >= max);

	if (effect.states) {
		var current = data[effect.states.flag] || 0;
		for (var c = 1; c < effect.states.classes.length; c++) {
			state.panel.SetHasClass(effect.states.classes[c], current === c);
		}
	}

	if (effect.tiers) {
		var tierOn = data[effect.tiers.flag] === 1;
		state.panel.SetHasClass('Tier1', tierOn && stacks >= state.tiers[0] && stacks < state.tiers[1]);
		state.panel.SetHasClass('Tier2', tierOn && stacks >= state.tiers[1] && stacks < max);
	}

	if (effect.ringByStacks) {
		state.panel.SetHasClass('Permanent', false);
		var filled = Math.round(Math.min(stacks / (max === Infinity ? 1 : max), 1) * 3600) / 10;
		if (filled !== state.lastSweep) {
			state.lastSweep = filled;
			state.ring.style.clip = 'radial( 50% 50%, 0deg, ' + filled + 'deg )';
		}
		return;
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


function RefreshOwnBars(hero, view) {
	var buffs = hero !== -1 && Entities.IsValidEntity(hero) && Entities.IsAlive(hero)
		? BuffsByName(hero) : {};
	var data = tracked[hero] || {};

	ownShown = 0;

	for (var i = 0; i < OWN_BARS.length; i++) {
		var bar = OWN_BARS[i];
		var buff = buffs[bar.modifier];
		var state = ownBars[bar.modifier];

		// полоска - стаки своего героя от него же
		if (buff !== undefined && !EffectAllowed(bar.id, hero, view.localPlayer, view)) {
			buff = undefined;
		}

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

	var view = ViewContext();
	RefreshOwnBars(view.localHero, view);

	var localTeam = Players.GetTeam(localPlayer);
	var spectator = Players.IsSpectator(localPlayer);
	var now = Game.GetGameTime();
	var seen = {};

	RefreshSurvival(localTeam, spectator, now);

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
			var read = ReadEffect(effect, entity, buffs);
			if (read && !EffectAllowed(effect.id, entity, CasterPlayer(effect, data), view)) {
				read = null;
			}
			var state = built && built.chips[effect.modifier];

			if (!read) {
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
				state = BuildChip(built, effect, entity, read.buff);
			}

			// новые стаки во время взрыва покажутся, когда он доиграет
			state.leaveAt = 0;
			state.panel.SetHasClass('Gone', now < (state.burstUntil || 0));
			UpdateChip(effect, state, entity, read, data);
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


function OnSurvivalNetTable(table, key, data) {
	var entity = parseInt(key, 10);
	if (data && data.on === 1) {
		survivalTracked[entity] = data;
	} else {
		delete survivalTracked[entity];
	}
}


function BuildSurvival(entity) {
	var panel = $.CreatePanel('Panel', root, '');
	panel.AddClass('SurvivalIcon');

	var medal = $.CreatePanel('Panel', panel, '');
	medal.AddClass('SurvivalMedal');

	// перезарядка: тёмный сектор на оставшуюся долю, как у иконок способностей
	var shade = $.CreatePanel('Panel', panel, '');
	shade.AddClass('SurvivalShade');

	// после срабатывания: кольцо оставшегося времени баффа на тёмной дорожке
	var track = $.CreatePanel('Panel', panel, '');
	track.AddClass('SurvivalRingTrack');

	var ring = $.CreatePanel('Panel', panel, '');
	ring.AddClass('SurvivalRing');

	var count = $.CreatePanel('Label', panel, '');
	count.AddClass('SurvivalCount');
	count.text = '';

	var state = { panel: panel, shade: shade, ring: ring, count: count, kind: '', mode: '', lastCount: -1, lastSweep: -1 };
	survivalUnits[entity] = state;
	return state;
}


function DestroySurvival(entity) {
	var state = survivalUnits[entity];
	if (!state) {
		return;
	}
	state.panel.DeleteAsync(0);
	delete survivalUnits[entity];
}


// Доля оставшегося времени в градусах дуги от 12 часов по часовой стрелке.
function Sweep(remaining, length) {
	if (!(length > 0)) {
		return 360;
	}
	return Math.round(Math.min(remaining / length, 1) * 3600) / 10;
}


// Состояние значка: Active (сработал, идёт бафф), Spent (заряд израсходован
// без отсчёта - God Hand до следующего раунда), Cooldown, Ready.
function SurvivalMode(data, now) {
	if (data.act_end > now) {
		return { mode: 'Active', remaining: data.act_end - now, length: data.act_len };
	}
	if (data.spent === 1) {
		return { mode: 'Spent', remaining: 0, length: 0 };
	}
	if (data.cd_end > now) {
		return { mode: 'Cooldown', remaining: data.cd_end - now, length: data.cd_len };
	}
	return { mode: 'Ready', remaining: 0, length: 0 };
}


function UpdateSurvival(state, data, now) {
	if (data.kind !== state.kind) {
		if (state.kind) {
			state.panel.RemoveClass('Kind_' + state.kind);
		}
		state.kind = data.kind;
		state.panel.AddClass('Kind_' + data.kind);
	}

	var current = SurvivalMode(data, now);
	var mode = current.mode;
	var remaining = current.remaining;
	var length = current.length;

	if (mode !== state.mode) {
		state.panel.SetHasClass('Ready', mode === 'Ready');
		state.panel.SetHasClass('Active', mode === 'Active');
		state.panel.SetHasClass('Cooldown', mode === 'Cooldown');
		state.panel.SetHasClass('Spent', mode === 'Spent');
		if (mode === 'Ready' && (state.mode === 'Cooldown' || state.mode === 'Spent')) {
			state.panel.TriggerClass('Refreshed');
		}
		state.mode = mode;
		state.lastSweep = -1;
	}

	var sweep = mode === 'Ready' ? 0 : mode === 'Spent' ? 360 : Sweep(remaining, length);
	if (sweep !== state.lastSweep) {
		state.lastSweep = sweep;
		var clip = 'radial( 50% 50%, 0deg, ' + sweep + 'deg )';
		state.shade.style.clip = clip;
		state.ring.style.clip = clip;
	}

	// секунды - на перезарядке и пока бафф идёт (одно кольцо в бою читается плохо)
	var shown = mode === 'Cooldown' || mode === 'Active' ? Math.ceil(remaining) : -1;
	if (shown !== state.lastCount) {
		state.lastCount = shown;
		state.count.text = shown > 0 ? String(shown) : '';
		state.count.SetHasClass('Wide', shown >= 100);
	}
}


function RefreshSurvival(localTeam, spectator, now) {
	var seen = {};

	for (var key in survivalTracked) {
		var entity = parseInt(key, 10);
		var data = survivalTracked[key];

		// Battle Continuation Кухулина сам прячет хелсбар
		// (modifier_battle_cont_active) - значок нужен именно тогда, поэтому
		// пока эффект сработал, он остаётся и встаёт на место бара
		var noBar = Entities.IsValidEntity(entity) && Entities.NoHealthBar(entity);
		var shown = noBar && data.act_end > now
			? Entities.IsAlive(entity) && TeamSees(entity, data.vis, localTeam, spectator)
			: UnitShown(entity, data, localTeam, spectator);
		if (!shown) {
			continue;
		}

		// Перезарядку видят только сам игрок и его союзники (и зрители). Врагу -
		// только «есть сейчас или нет»: значок виден, пока BC готов или
		// сработал, и пропадает на перезарядке / после израсходованного заряда.
		if (!spectator && Entities.GetTeamNumber(entity) !== localTeam) {
			var enemyMode = SurvivalMode(data, now).mode;
			if (enemyMode === 'Cooldown' || enemyMode === 'Spent') {
				continue;
			}
		}

		var state = survivalUnits[entity] || BuildSurvival(entity);
		UpdateSurvival(state, data, now);
		state.noBar = noBar;
		seen[entity] = true;
	}

	for (var index in survivalUnits) {
		if (!seen[index]) {
			DestroySurvival(index);
		}
	}
}


function PlaceSurvival(scale) {
	for (var key in survivalUnits) {
		var state = survivalUnits[key];
		var entity = parseInt(key, 10);
		var at = Entities.IsValidEntity(entity) ? Anchor(entity, scale) : null;

		state.panel.SetHasClass('Hidden', !at);
		if (!at) {
			continue;
		}

		// без хелсбара - по центру, где был бар, а не сбоку от пустоты
		var x = Math.round(at.x + (state.noBar ? -SURVIVAL_SIZE / 2 : SURVIVAL_X));
		var y = Math.round(at.y + SURVIVAL_Y);
		if (x !== state.x || y !== state.y) {
			state.x = x;
			state.y = y;
			state.panel.style.position = x + 'px ' + y + 'px 0px';
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
	if (!EffectAllowed(kind.id, entity, event.caster_pid, ViewContext())) {
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

	// значки и взрывы прячет класс на корне, полоски над своим героем остаются
	var settings = Store().settings;
	var off = settings.icons === 0;
	if (off !== iconsOff) {
		iconsOff = off;
		root.SetHasClass('IconsOff', off);
	}

	// значок выживания - отдельным тумблером
	var survivalHidden = settings.survival === 0;
	if (survivalHidden !== survivalOff) {
		survivalOff = survivalHidden;
		root.SetHasClass('SurvivalOff', survivalHidden);
	}

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
		var y = Math.round(anchor.y - built.height - built.lift);

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
	PlaceSurvival(scale);
}


(function () {
	var all = CustomNetTables.GetAllTableValues('effect_bars') || [];
	for (var i = 0; i < all.length; i++) {
		OnNetTable('effect_bars', all[i].key, all[i].value);
	}
	CustomNetTables.SubscribeNetTableListener('effect_bars', OnNetTable);
	var survival = CustomNetTables.GetAllTableValues('survival_icons') || [];
	for (var k = 0; k < survival.length; k++) {
		OnSurvivalNetTable('survival_icons', survival[k].key, survival[k].value);
	}
	CustomNetTables.SubscribeNetTableListener('survival_icons', OnSurvivalNetTable);
	GameEvents.Subscribe('effect_bars_burst', OnBurst);

	// настройки: вкладка Effects берёт отсюда список и функцию правки
	var store = Store();
	store.catalog = Catalog();
	store.change = ChangeSettings;
	store.saveNow = function () { SaveSettingsNow(Store()); };
	// кнопка Load: забрать версию с сервера, несохранённые правки - отбросить
	store.loadNow = function () {
		var s = Store();
		if (s.load === 'loading' || s.save === 'saving') {
			return;
		}
		s.dirty = false;
		s.saveQueued = false;
		s.manualLoad = true;
		s.save = 'idle';
		RequestSettingsLoad();
	};
	store.sanitize = SanitizeSettings;
	ApplySettings(store, SanitizeSettings(store.settings));
	GameEvents.Subscribe('fate_settings_loaded', OnSettingsLoaded);
	GameEvents.Subscribe('fate_settings_save_result', OnSettingsSaveResult);
	// загрузка - при каждом старте HUD, то есть в каждом матче: CustomUIConfig
	// живёт, пока запущен клиент, и переживает переход между матчами - по
	// флагу «уже загружено» второй матч не увидел бы правку с сайта.
	// Несохранённые правки при этом не теряются (OnSettingsLoaded их не трогает).
	store.saveQueued = false;
	if (store.save === 'saving') {
		store.save = store.dirty ? 'pending' : 'idle';   // ответ на тот запрос уже не придёт
	}
	RequestSettingsLoad();
	Update();
})();
