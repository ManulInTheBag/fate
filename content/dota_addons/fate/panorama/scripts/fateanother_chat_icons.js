'use strict';

// Фейт-иконки героев в ДЕФОЛТНОМ дотовском чате (in-place, v3).
//
// Герои fate — оверрайды базовых, и чат показывает иконки чужих дотовских
// героев; перекрыть VPK-картинки в реальной игре нельзя. Поэтому в каждой
// строке чата иконка подменяется SetImage'ом на фейт-портрет
// (custom_game/portrait). InlineImage-панели строк — реальные дочерние
// панели html-Label, SetImage по ним работает.
//
// Подход «зеркало с кражей строк» (v2) выброшен: dialog variables
// (результат /roll, фразы колеса) не материализуются в .text и не
// переживают репарент, выдержка перед кражей давала задержку всем
// сообщениям, дота удаляла украденные панели. Нативный чат работает сам:
// колесо мыши, история, попапы, roll/flip, цветные SendCustomMessage —
// всё родное. Цена in-place: иконка может мигнуть 1-2 кадра при появлении
// строки (поллинг всегда срабатывает после первой отрисовки).
//
// Плюс глушится ChatMessageTempLabel — непозиционированный временный
// буфер в HudChat, который дота мигает каждой строкой (в т.ч. метками
// времени) в левом верхнем углу экрана.

var PORTRAIT_PATH = 's2r://panorama/images/custom_game/portrait/';

function GetHudRoot() {
	var p = $.GetContextPanel();
	while (p.GetParent() != null) p = p.GetParent();
	return p;
}

function FindLineOwner(lineText) {
	var playerIds = Game.GetAllPlayerIDs();
	// Самое раннее вхождение «ник:» — иначе сообщение, содержащее чужой
	// ник с двоеточием, атрибутировалось бы не тому.
	var best = -1;
	var bestIdx = -1;
	for (var i = 0; i < playerIds.length; i++) {
		var name = Players.GetPlayerName(playerIds[i]);
		if (!name) continue;
		var idx = lineText.indexOf(name + ':');
		if (idx !== -1 && (bestIdx === -1 || idx < bestIdx)) {
			best = playerIds[i];
			bestIdx = idx;
		}
	}
	return best;
}

function FindFirstImage(p) {
	if (p.paneltype === 'Image') return p;
	// В строку колеса чата дота встраивает виджет DOTAChatWheelMessage, а в
	// нём — SprayImage (спрей/картинка фразы). Иконка героя лежит ВНЕ этого
	// виджета (отдельным InlineImage), поэтому в него не заходим — иначе
	// подменили бы спрей, а иконка героя осталась бы дотовской.
	if (p.paneltype === 'DOTAChatWheelMessage') return null;
	for (var i = 0; i < p.GetChildCount(); i++) {
		var c = p.GetChild(i);
		if (c != null) {
			var img = FindFirstImage(c);
			if (img != null) return img;
		}
	}
	return null;
}

// Подмена иконки в строке. Владелец кэшируется атрибутом на строке; метка
// подмены живёт на самой картинке — если дота пересоздаст содержимое при
// перепарсинге, новая картинка без метки будет подменена снова.
function SwapLineIcon(line, now) {
	var pidAttr = line.GetAttributeString('fateOwner', '');
	var pid;
	if (pidAttr === '') {
		var seen = line.GetAttributeString('fateSeen', '');
		if (seen === '') {
			line.SetAttributeString('fateSeen', String(now));
			seen = String(now);
		}
		var t = line.text || '';
		pid = t !== '' ? FindLineOwner(t) : -1;
		if (pid === -1) {
			// Текст мог не доехать в первый кадр; через 2с бросаем строку
			// (системные сообщения и метки времени владельца не имеют).
			if (now - Number(seen) > 2) line.SetAttributeString('fateOwner', 'none');
			return;
		}
		line.SetAttributeString('fateOwner', String(pid));
	} else {
		if (pidAttr === 'none') return;
		pid = Number(pidAttr);
	}
	var heroName = GetPlayerHeroName(pid);
	if (!heroName || heroName === 'npc_dota_hero_target_dummy') return;
	var img = FindFirstImage(line);
	if (img == null) return; // иконка ещё не создана — следующий кадр
	if (img.GetAttributeString('fateSwapped', '') === heroName) return;
	img.SetImage(PORTRAIT_PATH + heroName + '_png.vtex');
	// Унаследованный режим "cover" обрезает портрет по бокам.
	try { img.SetScaling('stretch'); } catch (e) {}
	img.SetAttributeString('fateSwapped', heroName);
}

// Прогрев текстур портретов: SetImage подхватывает картинку асинхронно,
// без прогрева первая подмена мигала бы дольше.
var preloadedPortraits = {};
(function PreloadPortraits() {
	var playerIds = Game.GetAllPlayerIDs();
	for (var i = 0; i < playerIds.length; i++) {
		var heroName = GetPlayerHeroName(playerIds[i]);
		if (heroName && heroName !== 'npc_dota_hero_target_dummy' && !preloadedPortraits[heroName]) {
			preloadedPortraits[heroName] = true;
			var img = $.CreatePanel('Image', $.GetContextPanel(), '');
			img.hittest = false;
			img.style.width = '1px';
			img.style.height = '1px';
			img.style.opacity = '0';
			img.SetImage(PORTRAIT_PATH + heroName + '_png.vtex');
		}
	}
	$.Schedule(5, PreloadPortraits);
})();

var chatLinesPanel = null;
var tempLabel = null;
var lastTempLabelSearch = 0;

// ChatMessageTempLabel дота включает обратно и может пересоздавать, поэтому
// глушим тройно (стили дота не перетирает) и переискиваем при потере.
function SuppressTempLabel(now) {
	if (tempLabel != null && tempLabel.IsValid()) return;
	if (now - lastTempLabelSearch < 0.25) return;
	lastTempLabelSearch = now;
	tempLabel = GetHudRoot().FindChildTraverse('ChatMessageTempLabel');
	if (tempLabel != null) {
		tempLabel.visible = false;
		tempLabel.style.visibility = 'collapse';
		tempLabel.style.opacity = '0';
		tempLabel.style.marginLeft = '-3000px';
	}
}

(function Poll() {
	// Перепланирование первым: даже если ниже что-то упадёт, цикл жив.
	// Каждый кадр — чтобы мигание чужой иконки длилось минимально.
	$.Schedule(0.01, Poll);
	try {
		var now = Date.now() / 1000;
		if (chatLinesPanel == null || !chatLinesPanel.IsValid()) {
			var hudRoot = GetHudRoot();
			chatLinesPanel = hudRoot.FindChildTraverse('ChatLinesPanel') || hudRoot.FindChildTraverse('ChatLinesPanels');
			if (chatLinesPanel) {
				// Страховка от состояния прошлых версий при живой перезагрузке:
				// v2 держала панель невидимой и прятала кнопки скролла.
				chatLinesPanel.style.opacity = '1';
				var up = hudRoot.FindChildTraverse('ChatScrollUpButton');
				var down = hudRoot.FindChildTraverse('ChatScrollDownButton');
				if (up) up.visible = true;
				if (down) down.visible = true;
			}
		}
		if (chatLinesPanel) {
			for (var i = 0; i < chatLinesPanel.GetChildCount(); i++) {
				var line = chatLinesPanel.GetChild(i);
				if (line != null) SwapLineIcon(line, now);
			}
		}
		SuppressTempLabel(now);
	} catch (e) {
		$.Msg('[fatechat] error: ' + e + (e && e.stack ? '\n' + e.stack : ''));
	}
})();
