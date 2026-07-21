// Emote wheel: a radial picker for the fbt_incident_1..14 emotes (the ones you
// normally trigger by typing "#N" in chat). The hotkey panel binds a key whose
// +command opens the wheel and whose -command releases it, so this is a
// hold-to-open / release-to-send control like Dota's message wheel.
//
// Selection is purely cursor-angle driven (no clicks, no TextEntry) which keeps
// us clear of the panorama focus/hittest pitfalls documented for this addon.
// The server (addon_game_mode.lua TriggerEmote) is authoritative for the 5s
// cooldown and the spam punishment; it echoes state back via fate_emote_state /
// fate_emote_punished so the wheel can reflect it.

(function () {
    var SEG_COUNT = 8;          // wheel has 8 slots...
    var TOTAL_EMOTES = 14;      // ...chosen from fbt_incident_1..14
    var RADIUS = 130;           // segment placement radius, container CSS px
    var DEADZONE_RATIO = 0.16;  // fraction of container size = "cancel" (center)
    var COOLDOWN = 2;           // client-optimistic cooldown, seconds (matches server)

    // The wheel loadout maps each of the 8 slots to an emote number (1..14). It
    // is shared with the hotkey config panel via CustomUIConfig, so editing it
    // there takes effect here the next time the wheel is opened. Default = 1..8.
    function DefaultLoadout() { return [1, 2, 3, 4, 5, 6, 7, 8]; }
    function GetLoadout() {
        var c = GameUI.CustomUIConfig();
        var lo = c.fate_emote_wheel_loadout;
        if (!lo || lo.length !== SEG_COUNT) {
            lo = DefaultLoadout();
            c.fate_emote_wheel_loadout = lo;
        }
        return lo;
    }

    var ctx = $.GetContextPanel();
    var backdrop = ctx.FindChildTraverse("EmoteWheelBackdrop");
    var container = ctx.FindChildTraverse("EmoteWheelContainer");
    var hub = ctx.FindChildTraverse("EmoteWheelHub");
    var hubLabel = ctx.FindChildTraverse("EmoteWheelHubLabel");
    var punishPanel = ctx.FindChildTraverse("EmotePunishPanel");
    var punishLabel = ctx.FindChildTraverse("EmotePunishLabel");
    var punishSub = ctx.FindChildTraverse("EmotePunishSub");

    var segments = [];
    var isOpen = false;
    var selected = -1;
    var pollToken = 0;          // bumped on each Open/Close so stale polls stop
    var punishUntil = 0;        // game seconds
    var cooldownUntil = 0;      // game seconds (2s between emotes)
    var rateUntil = 0;          // game seconds (up to 10s rate-limit window)

    // --- Build the 8 segment panels once, arranged clockwise from the top. -----
    // Icons/badges are filled in by RefreshSegments() from the current loadout,
    // so re-opening the wheel reflects any changes made in the config panel.
    function BuildSegments() {
        var half = 360 / 2; // container is 360x360 in CSS px
        var segHalf = 84 / 2;
        for (var i = 0; i < SEG_COUNT; i++) {
            var theta = i * (2 * Math.PI / SEG_COUNT); // 0 = top, clockwise
            var x = half + RADIUS * Math.sin(theta) - segHalf;
            var y = half - RADIUS * Math.cos(theta) - segHalf;

            var seg = $.CreatePanel("Panel", container, "EmoteSeg" + i);
            seg.AddClass("EmoteSegment");
            seg.style.position = x.toFixed(1) + "px " + y.toFixed(1) + "px 0px";
            seg.style.backgroundSize = "cover";
            seg.style.backgroundRepeat = "no-repeat";
            seg.style.backgroundPosition = "center";

            segments.push(seg);
        }
        RefreshSegments();
    }

    // Points each segment at its loadout emote's icon.
    function RefreshSegments() {
        var lo = GetLoadout();
        for (var i = 0; i < SEG_COUNT; i++) {
            var num = lo[i] || (i + 1);
            segments[i].style.backgroundImage =
                "url('s2r://panorama/images/custom_game/emotes/emote_" + num + ".vtex')";
        }
    }

    function Highlight(index) {
        if (index === selected) { return; }
        selected = index;
        for (var i = 0; i < segments.length; i++) {
            segments[i].SetHasClass("EmoteSegmentActive", i === index);
        }
    }

    // Maps the current cursor position to a segment index, or -1 if inside the
    // central dead-zone. Cursor and actuallayout* share the same device-pixel
    // space (see arena_util.IsCursorOnPanel).
    function CursorToSegment() {
        var w = container.actuallayoutwidth;
        var h = container.actuallayoutheight;
        if (!w || !h) { return -1; }
        var pos = container.GetPositionWithinWindow();
        var cx = pos.x + w / 2;
        var cy = pos.y + h / 2;

        var cur = GameUI.GetCursorPosition();
        var dx = cur[0] - cx;
        var dy = cur[1] - cy;

        var dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < w * DEADZONE_RATIO) { return -1; }

        // atan2(dx, -dy) -> clockwise angle from straight up, range (-pi, pi].
        var theta = Math.atan2(dx, -dy);
        if (theta < 0) { theta += 2 * Math.PI; }
        var idx = Math.round(theta / (2 * Math.PI / SEG_COUNT)) % SEG_COUNT;
        return idx;
    }

    // Effective block time = the later of the 2s cooldown and the 10s rate window.
    function BlockUntil() {
        return Math.max(cooldownUntil, rateUntil);
    }

    // Shows the remaining cooldown on the central hub while the wheel is open.
    function UpdateHub() {
        var cd = Math.ceil(BlockUntil() - Game.GetGameTime());
        if (cd > 0 && !IsPunished()) {
            hubLabel.text = cd + "s";
            hub.SetHasClass("EmoteHubCooldown", true);
        } else {
            hubLabel.text = "";
            hub.SetHasClass("EmoteHubCooldown", false);
        }
    }

    function Poll(token) {
        if (!isOpen || token !== pollToken) { return; }
        Highlight(CursorToSegment());
        UpdateHub();
        $.Schedule(0.0, function () { Poll(token); });
    }

    function IsPunished() {
        return Game.GetGameTime() < punishUntil;
    }

    function ShowPunish() {
        var left = Math.max(0, Math.ceil(punishUntil - Game.GetGameTime()));
        punishLabel.text = "ты че долбоеб";
        punishSub.text = "колесо эмоций заблокировано ещё " + left + " сек.";
        punishPanel.visible = true;
        backdrop.visible = true;
        container.visible = false;
    }

    // --- Public: called by the hotkey bind's +command. ------------------------
    function Open() {
        if (isOpen) { return; }
        isOpen = true;
        selected = -1;
        ctx.AddClass("EmoteWheelOpen");

        if (IsPunished()) {
            ShowPunish();
            return;
        }
        punishPanel.visible = false;
        backdrop.visible = true;
        container.visible = true;
        RefreshSegments(); // pick up any loadout change from the config panel
        Highlight(-1);
        UpdateHub();
        pollToken++;
        Poll(pollToken);
    }

    // --- Public: called by the hotkey bind's -command. ------------------------
    function Release() {
        if (!isOpen) { return; }
        isOpen = false;
        pollToken++; // stop any running poll
        ctx.RemoveClass("EmoteWheelOpen");
        backdrop.visible = false;
        container.visible = false;
        punishPanel.visible = false;

        var pick = selected;
        selected = -1;
        for (var i = 0; i < segments.length; i++) {
            segments[i].SetHasClass("EmoteSegmentActive", false);
        }

        if (pick < 0 || IsPunished()) { return; }

        // Always send the attempt: the server is authoritative for the cooldown,
        // the 3/10s rate limit AND the spam punishment. If the client suppressed
        // sends during cooldown/rate-limit, those presses would never reach the
        // server and the "too many presses" block would never trigger.
        var num = GetLoadout()[pick] || (pick + 1);
        GameEvents.SendCustomGameEventToServer("player_send_emote", { emote: num });
        // Optimistic local cooldown for the hub; the server confirms via fate_emote_state.
        if (Game.GetGameTime() >= BlockUntil()) {
            cooldownUntil = Game.GetGameTime() + COOLDOWN;
        }
    }

    // --- Server state sync ----------------------------------------------------
    GameEvents.Subscribe("fate_emote_state", function (data) {
        if (data.cooldownUntil != null) { cooldownUntil = data.cooldownUntil; }
        if (data.rateUntil != null) { rateUntil = data.rateUntil; }
        if (data.punishUntil != null) { punishUntil = data.punishUntil; }
    });

    GameEvents.Subscribe("fate_emote_punished", function (data) {
        var dur = data.duration ? data.duration : 120;
        punishUntil = Game.GetGameTime() + dur;
        cooldownUntil = punishUntil;
        if (isOpen) { ShowPunish(); } // swap the open wheel for the message
    });

    // --- Init -----------------------------------------------------------------
    BuildSegments();
    backdrop.visible = false;
    container.visible = false;
    punishPanel.visible = false;

    // Expose the open/release API to the hotkey panel (separate panorama context;
    // CustomUIConfig is the shared object between them).
    GameUI.CustomUIConfig().fate_emote_wheel = { open: Open, release: Release };
    $.Msg("[FateEmoteWheel] loaded");
})();
