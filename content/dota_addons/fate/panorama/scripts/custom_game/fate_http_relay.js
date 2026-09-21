"use strict";

// fate_http_relay.js — клиентская половина HTTP-реле (см. scripts/vscripts/fate_http.lua).
//
// В локальном лобби игровой сервер больше не может ходить в интернет
// (CreateHTTPRequestScriptVM = nil с ~18.09.2026). Зато клиент может: скрытый
// DOTAHTMLPanel — это CEF-браузер. Сервер присылает событие fate_http_request
// {rid, url}, мы открываем url в панели 1×1, воркер отдаёт страницу с
// <title>rid|status|body</title>, событие HTMLTitle приносит его сюда, и мы
// возвращаем серверу fate_http_response {rid, status, data}.
//
// Подключается из custom_ui_manifest.xml (секция <scripts>), поэтому стартует
// раньше экрана выбора команд — рейтинги на пике тоже идут через реле.
(function () {
	var REQUEST_TIMEOUT_SECONDS = 10;
	var READY_RETRY_SECONDS = 1;
	var READY_MAX_ATTEMPTS = 120;

	var readyAcked = false;
	var readyAttempts = 0;

	function removePanel(panel) {
		if (panel && panel.IsValid()) { panel.DeleteAsync(0); }
	}

	// Скрипт манифеста стартует раньше, чем нам выдали слот игрока: первые
	// ready доходят до сервера с PlayerID = -1 и тот их молча пропускает.
	// Повторяем раз в секунду, пока сервер не подтвердит ack'ом.
	function sendReady() {
		if (readyAcked) { return; }
		readyAttempts++;
		GameEvents.SendCustomGameEventToServer("fate_http_ready", {});
		if (readyAttempts >= READY_MAX_ATTEMPTS) { return; }
		$.Schedule(READY_RETRY_SECONDS, sendReady);
	}

	function onAck() {
		readyAcked = true;
	}

	function onRequest(event) {
		var rid = String(event.rid);
		var url = String(event.url);
		var finished = false;
		$.Msg("[FateHttp] request " + rid);

		var panel = $.CreatePanel("DOTAHTMLPanel", $.GetContextPanel(), "FateHttpRelay_" + rid);
		panel.style.width = "1px";
		panel.style.height = "1px";
		panel.style.opacity = "0.01";

		function finish() {
			if (finished) { return; }
			finished = true;
			removePanel(panel);
		}

		$.RegisterEventHandler("HTMLTitle", panel, function (_sourcePanel, title) {
			if (finished || typeof title !== "string") { return; }
			// Формат: rid|status|body. Чужие заголовки (пустая страница,
			// «Attention Required! | Cloudflare» и т.п.) — в лог и мимо.
			var first = title.indexOf("|");
			if (first < 0 || title.substr(0, first) !== rid) {
				$.Msg("[FateHttp] " + rid + " чужой title: " + title.substr(0, 80));
				return;
			}
			var second = title.indexOf("|", first + 1);
			if (second < 0) { return; }
			var status = parseInt(title.substr(first + 1, second - first - 1), 10);
			var data = title.substr(second + 1);
			finish();
			$.Msg("[FateHttp] response " + rid + " status=" + status + " length=" + data.length);
			GameEvents.SendCustomGameEventToServer("fate_http_response", {
				rid: rid,
				status: isNaN(status) ? 0 : status,
				data: data
			});
		});

		panel.SetURL(url);

		$.Schedule(REQUEST_TIMEOUT_SECONDS, function () {
			if (finished) { return; }
			finish();
			$.Msg("[FateHttp] timeout " + rid);
			GameEvents.SendCustomGameEventToServer("fate_http_failure", {
				rid: rid,
				reason: "client_timeout"
			});
		});
	}

	GameEvents.Subscribe("fate_http_request", onRequest);
	GameEvents.Subscribe("fate_http_ack", onAck);
	sendReady();
})();
