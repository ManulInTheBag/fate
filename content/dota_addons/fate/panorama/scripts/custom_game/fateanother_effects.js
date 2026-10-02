'use strict';

// Вкладка Effects окна настроек (fateanother_options.js): чьи эффекты видны
// над хелсбарами, «мои всегда», и какие эффекты выключены.
//
// Своего состояния у вкладки нет. Профиль, список эффектов и функции правки
// и сохранения держит effect_bars.js в CustomUIConfig().fateEffects: правка
// применяется сразу, на сервер уходит по кнопке Save. Об изменениях он
// сообщает сюда через onChange.

var rows = {};   // id эффекта -> { panel, toggle }
var built = false;


function Store() {
	return GameUI.CustomUIConfig().fateEffects;
}


function Copy(settings) {
	return {
		v: 1,
		scope: settings.scope,
		own: settings.own,
		off: settings.off.slice(),
		icons: settings.icons,
		survival: settings.survival,
	};
}


// Правка = копия текущего профиля, изменённая mutate, уходит в effect_bars.js.
function Change(mutate) {
	var store = Store();
	if (!store || typeof store.change !== 'function') {
		return;
	}
	var next = Copy(store.settings);
	mutate(next);
	store.change(next);
}


function SetOff(settings, id, on) {
	var at = settings.off.indexOf(id);
	if (on && at >= 0) {
		settings.off.splice(at, 1);
	} else if (!on && at < 0) {
		settings.off.push(id);
	}
}


function OnEffIconsToggle() {
	var on = $('#EffIcons').checked;
	Change(function (s) { s.icons = on ? 1 : 0; });
}


function OnEffSurvivalToggle() {
	var on = $('#EffSurvival').checked;
	Change(function (s) { s.survival = on ? 1 : 0; });
}


function OnEffOwnToggle() {
	var on = $('#EffOwn').checked;
	Change(function (s) { s.own = on ? 1 : 0; });
}


function OnEffScope(scope) {
	Change(function (s) { s.scope = scope; });
}


function OnEffSave() {
	var store = Store();
	if (store && typeof store.saveNow === 'function') {
		store.saveNow();
	}
}


function OnEffLoad() {
	var store = Store();
	if (store && typeof store.loadNow === 'function') {
		store.loadNow();
	}
}


function OnEffAll(on) {
	var store = Store();
	if (!store || !store.catalog) {
		return;
	}
	Change(function (s) {
		for (var i = 0; i < store.catalog.length; i++) {
			SetOff(s, store.catalog[i].id, on);
		}
	});
}


// Строка эффекта: портрет Слуги, медальон эффекта, подпись, галочка.
// Клик по всей строке переключает галочку.
function BuildRow(list, item) {
	var row = $.CreatePanel('Panel', list, '');
	row.AddClass('EffectsRow');

	var portrait = $.CreatePanel('Image', row, '');
	portrait.AddClass('EffectsPortrait');
	portrait.SetImage('file://{images}/heroes/' + item.hero + '.png');
	portrait.hittest = false;

	var medal = $.CreatePanel('Image', row, '');
	medal.AddClass('EffectsMedal');
	if (item.medal) {
		medal.SetImage('file://{images}/custom_game/effect_bars/' + item.medal + '.png');
	} else {
		medal.AddClass('NoMedal');
	}
	medal.hittest = false;

	var text = $.CreatePanel('Panel', row, '');
	text.AddClass('EffectsRowText');
	text.hittest = false;

	var hero = $.CreatePanel('Label', text, '');
	hero.AddClass('EffectsRowHero');
	hero.text = $.Localize('#' + item.hero);
	hero.hittest = false;

	var name = $.CreatePanel('Label', text, '');
	name.AddClass('EffectsRowName');
	name.text = $.Localize(item.name);
	name.hittest = false;

	// галочка только показывает состояние: клик ловит строка, иначе он
	// дошёл бы и до галочки, и до строки и переключил бы дважды
	var toggle = $.CreatePanel('ToggleButton', row, '');
	toggle.AddClass('EffectsRowToggle');
	toggle.hittest = false;

	var id = item.id;
	row.SetPanelEvent('onactivate', function () {
		toggle.checked = !toggle.checked;
		var on = toggle.checked;
		Change(function (s) { SetOff(s, id, on); });
	});

	rows[id] = { panel: row, toggle: toggle };
}


function StatusText(store) {
	if (store.load === 'local') {
		return $.Localize('#FA_Effects_Status_Local');
	}
	if (store.saveQueued) {
		return $.Localize('#FA_Effects_Status_Saving');
	}
	// несохранённые правки важнее идущей загрузки: их надо не забыть сохранить
	if (store.load === 'loading' && store.save !== 'pending') {
		return $.Localize('#FA_Effects_Status_Loading');
	}
	switch (store.save) {
		case 'pending':
			return $.Localize('#FA_Effects_Status_Pending');
		case 'saving':
			return $.Localize('#FA_Effects_Status_Saving');
		case 'failed':
			return $.Localize('#FA_Effects_Status_Failed');
		case 'saved':
			return $.Localize('#FA_Effects_Status_Saved');
	}
	switch (store.load) {
		case 'loading':
		case 'idle':
			return $.Localize('#FA_Effects_Status_Loading');
		case 'failed':
			return $.Localize('#FA_Effects_Status_LoadFailed');
		case 'none':
			return $.Localize('#FA_Effects_Status_Default');
	}
	return $.Localize('#FA_Effects_Status_Saved');
}


// Панель повторяет профиль. Программная установка checked не зовёт
// onactivate - петли правок нет.
function Sync() {
	var store = Store();
	if (!store) {
		return;
	}
	var s = store.settings;

	$('#EffIcons').checked = s.icons !== 0;
	$('#EffSurvival').checked = s.survival !== 0;
	$('#EffOwn').checked = s.own !== 0;

	var radio = $('#EffScope_' + s.scope);
	if (radio) {
		radio.checked = true;
	}

	for (var id in rows) {
		var on = s.off.indexOf(id) < 0;
		rows[id].toggle.checked = on;
		rows[id].panel.SetHasClass('Off', !on);
	}

	// кнопка подсвечена, пока есть что сохранять
	$('#EffSave').SetHasClass('Dirty', store.dirty === true);
	$('#EffSave').enabled = store.load !== 'local';
	$('#EffLoad').enabled = store.load !== 'local' && store.load !== 'loading' && store.save !== 'saving';

	var status = $('#EffStatus');
	status.text = StatusText(store);
	status.SetHasClass('Bad', store.save === 'failed' || (store.load === 'failed' && store.save !== 'saved'));
	status.SetHasClass('Good', store.save === 'saved');
}


// effect_bars.js (HUD) может загрузиться позже окна настроек - ждём его.
function Build() {
	var store = Store();
	if (!store || !store.catalog) {
		$.Schedule(0.5, Build);
		return;
	}

	if (!built) {
		built = true;
		var list = $('#EffList');
		list.RemoveAndDeleteChildren();
		rows = {};
		for (var i = 0; i < store.catalog.length; i++) {
			BuildRow(list, store.catalog[i]);
		}
	}

	store.onChange = Sync;
	Sync();
}


(function () {
	Build();
})();
