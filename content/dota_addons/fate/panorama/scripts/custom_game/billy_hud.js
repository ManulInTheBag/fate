'use strict';

// Барабан револьвера Билли справа от хелсбара своего героя - на месте кружка
// зарядов E у Распутина (rasputin_hud.js). Пули - стаки modifier_billy_bullets
// (интринсик D), гнёзд - base_bullets D. Заряженные гнёзда идут подряд от
// верхнего («под бойком»); выстрел поворачивает барабан на гнездо, перезарядка
// идёт под звук: гильзы вылетают, патроны встают по одному, полный оборот на
// трещотке (PlayReload). Число в центре не крутится. Состояние:
//   Armed - D включена и пули есть: барабан оранжевый, способности усилены;
//   Off   - D выключена: пули лежат в запасе, барабан стальной;
//   Empty - D включена, но пуль нет: пустые гнёзда горят красным до перезарядки (F).
// Сервер под HUD ничего не пишет: всё читается из баффа и способности.
//
// Весь код в замыкании: в глобальную область не попадает ни одно имя (у
// effect_bars.js те же Update/Refresh/root - на случай общей области видимости
// HUD-скриптов), цикл кадра - через новое замыкание, как в rasputin_hud.js.

(function () {
	var BULLETS_MODIFIER = 'modifier_billy_bullets';
	var D_ABILITY = 'billy_bullets_to_spare';

	var REFRESH_INTERVAL = 0.1;

	// Все круги - картинки из images/custom_game/billy/build_billy_drum.py (CSS-круги
	// панорама на 32px рисует без сглаживания). Размеры дублируются в billy_hud.css
	// и в генераторе. Панель BOX 48px (с запасом под ореол), барабан 32px по её центру;
	// центр чуть правее кружка зарядов Распутина (82.5, -27) от
	// WorldToScreen(origin + GetHealthBarOffset), чтобы барабан не наезжал на плашку уровня.
	var BOX = 48;
	var DRUM = 32;
	var OFFSET_X = 86.5 - BOX / 2;
	var OFFSET_Y = -27 - BOX / 2;
	var CHAMBER_BOX = 16;         // картинка гнезда: круг 8px + место под ореол
	var CHAMBER_RADIUS = 10.5;    // от центра барабана до центра гнезда
	var DEFAULT_CHAMBERS = 6;     // тело барабана нарисовано под 6 гнёзд
	var TURN_TIME = 0.16;         // поворот на гнездо после выстрела
	// Перезарядка подогнана под звук billy_reload (sounds/billy/sfx/billy_reload.mp3,
	// 1.28 с): 0.08-0.34 выброс гильз, 0.44-0.80 щелчки патронов по гнёздам,
	// 0.88-1.26 трещотка прокрутки с замедлением. Пули сервер выдаёт сразу, HUD
	// видит их в среднем на полпериода опроса позже - на столько и сдвинуто.
	var RELOAD_LAG = REFRESH_INTERVAL / 2;
	var RELOAD_EJECT = 0.08;      // гнёзда пустеют
	var RELOAD_LOAD_FROM = 0.44;  // первый патрон
	var RELOAD_LOAD_TO = 0.80;    // последний патрон
	var RELOAD_SPIN_AT = 0.88;    // полный оборот...
	var RELOAD_SPIN_TIME = 0.4;   // ...с замедлением (ease-out в CSS) до конца трещотки
	// с двузначным уровнем плашка уровня шире - сдвиг как у Распутина
	var LEVEL2_EXTRA = 8;
	var LEVEL_TWO_DIGITS = 10;

	// Настройки игрока (блок «Настройки героев» во вкладке Effects, профиль -
	// effect_bars.js): billy_drum = drum | number | none, billy_reload - анимация
	// перезарядки. До загрузки профиля - умолчания: барабан с анимацией.
	function Options() {
		var store = GameUI.CustomUIConfig().fateEffects;
		var s = store && store.settings;
		return {
			mode: s && (s.billy_drum === 'number' || s.billy_drum === 'none') ? s.billy_drum : 'drum',
			reload: !(s && s.billy_reload === 0),
		};
	}

	var root = $('#BillyHudRoot');
	var built = null;      // { entity, panel, label, last* }
	var lastRefresh = -1;


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


	function FindStacks(entity, name) {
		var count = Entities.GetNumBuffs(entity);
		for (var i = 0; i < count; i++) {
			var buff = Entities.GetBuff(entity, i);
			if (Buffs.GetName(entity, buff) === name) {
				return Buffs.GetStackCount(entity, buff);
			}
		}
		return null;
	}


	// Точка на окружности барабана: угол от верха по часовой, в px от левого верха
	// панели барабана (у неё нет рамки - иначе отсчёт идёт от внутреннего края рамки).
	function OnRim(radius, deg, size) {
		var rad = (deg - 90) * Math.PI / 180;
		return (DRUM / 2 + radius * Math.cos(rad) - size / 2) + 'px ' +
			(DRUM / 2 + radius * Math.sin(rad) - size / 2) + 'px 0px';
	}


	function Build(entity, chambers) {
		var panel = $.CreatePanel('Panel', root, '');
		panel.AddClass('BillyBullets');

		var glow = $.CreatePanel('Panel', panel, '');
		glow.AddClass('BillyBulletsGlow');

		// крутится только барабан; число - соседняя панель поверх
		var drum = $.CreatePanel('Panel', panel, '');
		drum.AddClass('BillyDrum');

		var step = 360 / chambers;
		var slots = [];
		for (var i = 0; i < chambers; i++) {
			var slot = $.CreatePanel('Panel', drum, '');
			slot.AddClass('BillyChamber');
			slot.style.position = OnRim(CHAMBER_RADIUS, i * step, CHAMBER_BOX);
			slots.push(slot);
		}

		// режим «только число»: чёрный кружок под числом, как был счётчик до барабана
		var disc = $.CreatePanel('Panel', panel, '');
		disc.AddClass('BillyNumberDisc');
		var discGlow = $.CreatePanel('Panel', disc, '');
		discGlow.AddClass('BillyNumberGlow');

		var label = $.CreatePanel('Label', panel, '');
		label.AddClass('BillyBulletsLabel');
		label.text = '';

		return {
			entity: entity,
			panel: panel,
			drum: drum,
			slots: slots,
			step: step,
			turn: 0,             // сколько гнёзд барабан уже провернул
			reload: 0,           // поколение анимации перезарядки: новое изменение пуль гасит старую
			label: label,
			lastCount: -1,
			lastState: '',
			lastWide: null,
		};
	}


	function Spin(time) {
		built.drum.style.transitionDuration = time + 's';
		built.drum.style.transform = 'rotateZ(' + (-built.turn * built.step) + 'deg)';
	}


	// Заряжены гнёзда turn, turn+1, ... (по часовой от верхнего): после
	// поворота под бойком всегда следующая пуля.
	function FillChambers(bullets) {
		var n = built.slots.length;
		for (var i = 0; i < n; i++) {
			var k = ((i - built.turn) % n + n) % n;
			built.slots[i].SetHasClass('Loaded', k < bullets);
		}
	}


	// Число и гнёзда, как их видно (во время перезарядки отстают от сервера на ≤1 с).
	function Show(bullets) {
		built.label.text = String(bullets);
		FillChambers(bullets);
	}


	// Перезарядка под звук: гильзы вылетают, патроны встают по одному на щелчки,
	// затем полный оборот на трещотке. Колбэки сверяют поколение и сущность:
	// выстрел посреди анимации или пересборка барабана её обрывают.
	function PlayReload(target) {
		var gen = ++built.reload;
		var owner = built;
		function Step(at, fn) {
			$.Schedule(Math.max(0, at - RELOAD_LAG), function () {
				if (built === owner && built.reload === gen) {
					fn();
				}
			});
		}

		Step(RELOAD_EJECT, function () { Show(0); });
		for (var j = 1; j <= target; j++) {
			(function (count) {
				var t = target > 1 ? (count - 1) / (target - 1) : 1;
				Step(RELOAD_LOAD_FROM + (RELOAD_LOAD_TO - RELOAD_LOAD_FROM) * t, function () {
					Show(count);
					built.panel.TriggerClass('Insert');
				});
			})(j);
		}
		Step(RELOAD_SPIN_AT, function () {
			Show(target);
			built.turn += built.slots.length;
			Spin(RELOAD_SPIN_TIME);
		});
	}


	function ChamberCount(d) {
		var count = d !== -1 && d !== undefined ? Abilities.GetSpecialValueFor(d, 'base_bullets') : 0;
		return count > 0 ? count : DEFAULT_CHAMBERS;
	}


	function Destroy() {
		if (built) {
			built.panel.DeleteAsync(0);
			built = null;
		}
	}


	// Young Outlaw Leader: пока открыт выбор цели награды - баннер-подсказка с
	// отсчётом (сам выбор - клик по портрету в топ-баре, shared_scoreboard_updater.js).
	var wantedHint = null;

	// Баннер выключается во вкладке Effects (профиль billy_hint, effect_bars.js) -
	// кто уже знает атрибут, видит только прицелы на портретах.
	function HintEnabled() {
		var store = GameUI.CustomUIConfig().fateEffects;
		return !(store && store.settings && store.settings.billy_hint === 0);
	}

	function RefreshWantedHint() {
		var data = CustomNetTables.GetTableValue('sync', 'billy_wanted');
		var h = data && data.hunters ? data.hunters[String(Game.GetLocalPlayerID())] : null;
		var left = h && h.target == -1 && HintEnabled() ? h.pick_end - Game.GetGameTime() : -1;
		if (left <= 0) {
			if (wantedHint) {
				wantedHint.DeleteAsync(0);
				wantedHint = null;
			}
			return;
		}
		if (!wantedHint) {
			wantedHint = $.CreatePanel('Panel', root, '');
			wantedHint.AddClass('BillyWantedHint');
			var title = $.CreatePanel('Label', wantedHint, '');
			title.AddClass('BillyWantedHintTitle');
			title.text = $.Localize('#Billy_Wanted_Hint_Title');
			wantedHint.timer = $.CreatePanel('Label', wantedHint, '');
			wantedHint.timer.AddClass('BillyWantedHintText');
		}
		wantedHint.timer.text = $.Localize('#Billy_Wanted_Hint_Text').replace('{s}', String(Math.ceil(left)));
	}


	function Refresh() {
		RefreshWantedHint();
		var hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
		var bullets = hero !== -1 && Entities.IsValidEntity(hero) ? FindStacks(hero, BULLETS_MODIFIER) : null;

		// счётчик только у Билли (его интринсик D) и только своему игроку
		var opts = Options();
		if (bullets === null || opts.mode === 'none') {
			Destroy();
			return;
		}

		var d = Entities.GetAbilityByName(hero, D_ABILITY);
		var chambers = ChamberCount(d);

		if (!built || built.entity !== hero || built.slots.length !== chambers) {
			Destroy();
			built = Build(hero, chambers);
		}
		built.panel.SetHasClass('NumberOnly', opts.mode === 'number');

		var on = d !== -1 && d !== undefined && Abilities.GetToggleState(d);
		var state = !on ? 'Off' : (bullets > 0 ? 'Armed' : 'Empty');

		if (bullets !== built.lastCount) {
			var reloaded = built.lastCount >= 0 && bullets > built.lastCount;
			if (built.lastCount >= 0 && !reloaded) {
				// выстрел: вспышка числа и поворот на столько гнёзд, сколько пуль ушло
				built.panel.TriggerClass('Spent');
				built.turn += built.lastCount - bullets;
				Spin(TURN_TIME);
			}
			built.lastCount = bullets;
			// анимация - только у барабана и если игрок её не выключил
			if (reloaded && opts.mode === 'drum' && opts.reload) {
				PlayReload(bullets);
			} else {
				built.reload++;      // обрывает недоигранную перезарядку
				Show(bullets);
			}
		}

		if (state !== built.lastState) {
			built.panel.SetHasClass('Armed', state === 'Armed');
			built.panel.SetHasClass('Off', state === 'Off');
			built.panel.SetHasClass('Empty', state === 'Empty');
			built.lastState = state;
		}

		var wide = Entities.GetLevel(hero) >= LEVEL_TWO_DIGITS;
		if (wide !== built.lastWide) {
			built.lastWide = wide;
			built.offsetX = OFFSET_X + (wide ? LEVEL2_EXTRA : 0);
		}
	}


	function Place() {
		if (!built) {
			return;
		}
		var entity = built.entity;
		if (!Entities.IsValidEntity(entity) || !Entities.IsAlive(entity) || Entities.NoHealthBar(entity)) {
			built.panel.SetHasClass('Hidden', true);
			return;
		}

		var origin = Entities.GetAbsOrigin(entity);
		var z = origin[2] + HealthBarOffset(entity);
		var screenX = Game.WorldToScreenX(origin[0], origin[1], z);
		var screenY = Game.WorldToScreenY(origin[0], origin[1], z);

		if (screenX < 0 || screenY < 0) {
			built.panel.SetHasClass('Hidden', true);
			return;
		}

		var scale = ScreenScale();
		built.panel.SetHasClass('Hidden', false);
		built.panel.style.position =
			(screenX / scale + built.offsetX) + 'px ' + (screenY / scale + OFFSET_Y) + 'px 0px;';
	}


	// Каждый кадр только двигаем, данные - раз в REFRESH_INTERVAL. Перепланирование
	// первым: исключение в Refresh не должно убить цикл.
	function Update() {
		$.Schedule(0, function () {
			Update();
		});

		var now = Game.GetGameTime();
		if (now - lastRefresh >= REFRESH_INTERVAL || now < lastRefresh) {
			lastRefresh = now;
			Refresh();
		}

		Place();
	}


	Update();
})();
