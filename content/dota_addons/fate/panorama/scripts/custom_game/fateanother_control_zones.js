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

function UpdateVictory(data)
{
    g_victory = data;
    RenderVictory();
}

function RenderVictory()
{
    var panel = $("#VictoryZonePanel");
    if (!panel) return;

    var v = g_victory;
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

    if (v.phase === "preround")
    {
        status.text = "STARTS WITH ROUND";
        bars.visible = false;
        return;
    }

    if (v.phase === "grace")
    {
        var left = Math.max(0, Math.ceil(v.grace_end - Game.GetGameTime()));
        status.text = "ACTIVE IN " + left + "s";
        bars.visible = false;
        return;
    }

    // active / captured: показываем бары и счётчики
    bars.visible = true;
    $("#VZCountRed").text = v.count_red;
    $("#VZCountBlack").text = v.count_black;

    var capTime = v.capture_time > 0 ? v.capture_time : 1;
    $("#VZBarRed").style.width = Math.min(100, v.progress_red / capTime * 100) + "%";
    $("#VZBarBlack").style.width = Math.min(100, v.progress_black / capTime * 100) + "%";

    if (v.phase === "captured")
    {
        status.text = "CAPTURED!";
        status.SetHasClass("Captured", true);
    }
    else if (v.overtime === 1)
    {
        status.text = "OVERTIME!";
        status.SetHasClass("Overtime", true);
    }
    else if (v.count_red > 0 && v.count_red === v.count_black)
    {
        status.text = "CONTESTED";
        status.SetHasClass("Contested", true);
    }
    else if (v.count_red > v.count_black)
    {
        status.text = "RED CAPTURING";
    }
    else if (v.count_black > v.count_red)
    {
        status.text = "BLACK CAPTURING";
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

// локальный тикер для обратного отсчёта грейса (сервер в грейсе молчит)
function GraceTick()
{
    if (g_victory && g_victory.phase === "grace")
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
