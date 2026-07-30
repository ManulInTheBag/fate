"use strict";

// HUD зон контроля. Данные приходят из CustomNetTables "zones"
// (ключи victory / buff_1 / buff_2), сервер пишет их только при изменении.

var TEAM_RED = 2;
var TEAM_BLACK = 3;

var BUFF_ICONS = {
    damage: "file://{images}/spellicons/bloodseeker_bloodrage.png",
    armor: "file://{images}/spellicons/abaddon_aphotic_shield.png",
    ms: "file://{images}/spellicons/dark_seer_surge.png"
};

var g_victory = null;
var g_overtimeSeenAt = 0; // когда клиент впервые увидел овертайм (для баннера)
var g_soonUntil = 0;      // до какого времени держим «овертайм возможен»
var g_soonTeam = 0;       // кто тянет овертайм (для текста подсказки)

// Флаг ot_possible гаснет, как только проигрывающие на пару секунд вышли из
// зоны (TOUCH_GRACE), поэтому сообщение держим ещё столько секунд — иначе
// оно мигает у самого таймаута
var SOON_HOLD = 2.0;

function UpdateVictory(data)
{
    g_victory = data;
    RenderVictory();
}

// Сообщения об овертайме: возможен -> начался -> заканчивается.
// Рисуются на клиенте (а не серверным center message), потому что их можно
// выключить тумблером в Fate settings — сервер шлёт только состояние.
function RenderAnnounce(v, allyTeam)
{
    var panel = $("#ZoneAnnouncePanel");
    if (!panel) return;

    var title = "";
    var sub = "";
    var soon = false;
    var urgent = false;

    if (v && v.enabled === 1 && v.phase === "active")
    {
        var now = Game.GetGameTime();
        if (v.overtime === 1)
        {
            if (g_overtimeSeenAt === 0) g_overtimeSeenAt = now;
            g_soonUntil = 0;

            var endWarn = v.ot_end_warn > 0 ? v.ot_end_warn : 10;
            var leftOT = Math.max(0, v.overtime_end - now);
            if (v.leave_end > 0)
            {
                title = "RETURN TO THE ZONE";
                sub = Math.max(0, v.leave_end - now).toFixed(1) + "s before the round is decided";
                urgent = true;
            }
            else if (leftOT <= endWarn)
            {
                title = "OVERTIME ENDS IN " + Math.max(0, Math.ceil(leftOT)) + "s";
                sub = "Capture the zone or force the enemy out!";
                urgent = true;
            }
            else if (now - g_overtimeSeenAt <= 4)
            {
                title = "OVERTIME!";
                sub = "Flip the zone or force the enemy out!";
                urgent = true;
            }
        }
        else
        {
            g_overtimeSeenAt = 0;
            if (v.ot_possible === 1)
            {
                g_soonUntil = now + SOON_HOLD;
                g_soonTeam = v.ot_team;
            }
            if (now < g_soonUntil)
            {
                title = "OVERTIME POSSIBLE";
                sub = (g_soonTeam === allyTeam)
                    ? "Stay in the zone at the timeout to keep playing"
                    : "Push the enemies out of the zone before the timeout";
                soon = true;
            }
        }
    }
    else
    {
        g_overtimeSeenAt = 0;
        g_soonUntil = 0;
    }

    panel.SetHasClass("AnnounceVisible", title !== "");
    panel.SetHasClass("Soon", soon);
    panel.SetHasClass("Urgent", urgent);
    if (title === "") return;
    $("#ZoneAnnounceTitle").text = title;
    $("#ZoneAnnounceSub").text = sub;
}

function RenderVictory()
{
    var panel = $("#VictoryZonePanel");
    if (!panel) return;

    var v = g_victory;

    // всё в панели рисуется ОТНОСИТЕЛЬНО смотрящего, как стены зоны:
    // союзники синие (слева), враги красные (справа); спектатору
    // «союзники» = Red Faction
    var localTeam = Players.GetTeam(Game.GetLocalPlayerID());
    var allyTeam = (localTeam === TEAM_RED || localTeam === TEAM_BLACK) ? localTeam : TEAM_RED;
    var enemyTeam = (allyTeam === TEAM_RED) ? TEAM_BLACK : TEAM_RED;

    RenderAnnounce(v, allyTeam);

    if (!v || v.enabled !== 1 || !v.phase || v.phase === "none")
    {
        panel.visible = false;
        return;
    }
    panel.visible = true;

    var status = $("#VZStatus");
    var bars = $("#VZBars");
    status.SetHasClass("Contested", false);
    status.SetHasClass("Overtime", false);
    status.SetHasClass("Captured", false);
    status.SetHasClass("EnemyHold", false);
    panel.SetHasClass("OwnedAlly", v.owner === allyTeam);
    panel.SetHasClass("OwnedEnemy", v.owner === enemyTeam);
    panel.SetHasClass("OvertimeActive", v.overtime === 1);

    // зона могла стартовать уже захваченной (отставание 3+ раундов) —
    // тогда полоску показываем и до активации
    var preOwned = (v.owner === allyTeam) ? " (ALLIES HOLD)"
        : (v.owner === enemyTeam ? " (ENEMIES HOLD)" : "");

    if (v.phase === "preround")
    {
        status.text = "STARTS WITH ROUND" + preOwned;
        bars.visible = false;
        return;
    }

    if (v.phase === "grace")
    {
        var left = Math.max(0, Math.ceil(v.grace_end - Game.GetGameTime()));
        status.text = "ACTIVE IN " + left + "s" + preOwned;
        bars.visible = false;
        return;
    }

    // active: одна общая полоска — союзное влияние слева, вражеское справа
    bars.visible = true;
    var allyCount = (allyTeam === TEAM_RED) ? v.count_red : v.count_black;
    var enemyCount = (allyTeam === TEAM_RED) ? v.count_black : v.count_red;
    $("#VZCountAlly").text = allyCount;
    $("#VZCountEnemy").text = enemyCount;

    var capTime = v.capture_time > 0 ? v.capture_time : 1;
    var inf = v.influence || 0; // >0 = Red Faction
    var allyInf = (allyTeam === TEAM_RED) ? inf : -inf;
    $("#VZBarAlly").style.width = (allyInf > 0 ? Math.min(100, allyInf / capTime * 100) : 0) + "%";
    $("#VZBarEnemy").style.width = (allyInf < 0 ? Math.min(100, -allyInf / capTime * 100) : 0) + "%";

    var bonus = "+" + (v.bonus_points || 3);

    if (v.overtime === 1)
    {
        // отсчёты рисуем локальным тикером по таймстемпам с сервера
        var now = Game.GetGameTime();
        if (v.leave_end > 0)
        {
            status.text = "RETURN TO ZONE " + Math.max(0, v.leave_end - now).toFixed(1);
        }
        else
        {
            status.text = "OVERTIME " + Math.max(0, Math.ceil(v.overtime_end - now)) + "s";
        }
        status.SetHasClass("Overtime", true);
    }
    else if (allyCount > 0 && enemyCount > 0)
    {
        status.text = "CONTESTED";
        status.SetHasClass("Contested", true);
    }
    else if (allyCount > 0)
    {
        if (v.owner === allyTeam)
        {
            status.text = "ALLIES CONTROLLING";
            status.SetHasClass("Captured", true);
        }
        else
        {
            status.text = "ALLIES CAPTURING";
        }
    }
    else if (enemyCount > 0)
    {
        if (v.owner === enemyTeam)
        {
            status.text = "ENEMIES CONTROLLING";
            status.SetHasClass("EnemyHold", true);
        }
        else
        {
            status.text = "ENEMIES CAPTURING";
        }
    }
    else if (v.owner === allyTeam)
    {
        status.text = "ALLIES HOLD " + bonus;
        status.SetHasClass("Captured", true);
    }
    else if (v.owner === enemyTeam)
    {
        status.text = "ENEMIES HOLD " + bonus;
        status.SetHasClass("EnemyHold", true);
    }
    else
    {
        status.text = "";
    }
}

function UpdateBuff(index, data)
{
    var row = $("#BuffZone" + index);
    if (!row) return;

    if (!data || data.active !== 1)
    {
        row.SetHasClass("BuffVisible", false);
        return;
    }
    row.SetHasClass("BuffVisible", true);
    row.SetHasClass("OwnerRed", data.owner === TEAM_RED);
    row.SetHasClass("OwnerBlack", data.owner === TEAM_BLACK);

    var icon = $("#BuffIcon" + index);
    icon.SetImage(BUFF_ICONS[data.buff] || "");

    // подсказка при наведении = человекочитаемое описание баффа
    // (само число вынесено сюда, на HUD постоянно не висит)
    if (data.label)
    {
        row.SetPanelEvent("onmouseover", function ()
        {
            $.DispatchEvent("DOTAShowTextTooltip", row, data.label);
        });
        row.SetPanelEvent("onmouseout", function ()
        {
            $.DispatchEvent("DOTAHideTextTooltip", row);
        });
        row.hittest = true;
    }

    var bar = $("#BuffBar" + index);
    var holdTime = data.hold_time > 0 ? data.hold_time : 1;
    bar.style.width = Math.min(100, data.cap_progress / holdTime * 100) + "%";
    bar.SetHasClass("CapRed", data.cap_team === TEAM_RED);
    bar.SetHasClass("CapBlack", data.cap_team === TEAM_BLACK);
}

function OnZonesChanged(tableName, key, data)
{
    if (key === "victory") UpdateVictory(data);
    else if (key === "buff_1") UpdateBuff(1, data);
    else if (key === "buff_2") UpdateBuff(2, data);
}

// локальный тикер: обратный отсчёт грейса и таймеров овертайма
// (сервер шлёт только таймстемпы, сами секунды тикают на клиенте)
function GraceTick()
{
    // g_soonUntil тоже держим в условии: флаг ot_possible мог уже погаснуть,
    // а сообщение ещё висит — без тика его некому снять
    if (g_victory && (g_victory.phase === "grace" || g_victory.overtime === 1
        || g_victory.ot_possible === 1 || Game.GetGameTime() < g_soonUntil))
    {
        RenderVictory();
    }
    $.Schedule(0.25, GraceTick);
}

(function ()
{
    CustomNetTables.SubscribeNetTableListener("zones", OnZonesChanged);
    UpdateVictory(CustomNetTables.GetTableValue("zones", "victory"));
    UpdateBuff(1, CustomNetTables.GetTableValue("zones", "buff_1"));
    UpdateBuff(2, CustomNetTables.GetTableValue("zones", "buff_2"));
    GraceTick();
})();
