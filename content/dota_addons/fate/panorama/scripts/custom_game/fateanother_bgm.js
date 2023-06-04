var g_GameConfig = FindCustomUIRoot($.GetContextPanel());
//g_GameConfig.curBGMentindex = 0;
g_GameConfig.curBGMIndex = 1;
g_GameConfig.nextBGMIndex = 1;
g_GameConfig.BGMSchedule = 0;
g_GameConfig.duration = [481,187,327,219,142,183,143,233,212,247,241,280,224,288,187,318,270,344,255,375,292,184,202,142,162,215,140,126,249,133,185];
//g_GameConfig.duration = [5,5,5,5,5,5,5,5];
g_GameConfig.bRepeat = false;
g_GameConfig.bIsBGMOn = true;
g_GameConfig.bIsAutoChange = false;
g_GameConfig.InitialIndex = 0;

function OnRepeatToggle()
{
    g_GameConfig.bRepeat = !g_GameConfig.bRepeat;
}

function OnDropDownChanged()
{
    if (g_GameConfig.bIsAutoChange) {
        return
    }

    var selection = $("#FateConfigBGMList").GetSelected();
    g_GameConfig.nextBGMIndex = parseInt(selection.id);
    //$.Msg("Next BGM Index: " + selection.id);
    //$.Msg("Schedule num: " + g_GameConfig.BGMSchedule);
    if (g_GameConfig.BGMSchedule != 0) {
        $.Msg("schedule probably cancelled")
        $.CancelScheduled(g_GameConfig.BGMSchedule, {});
    }
    PlayBGM();
    //$.CancelScheduled(g_GameConfig.BGMSchedule, {});
}

function PlayBGM()
{
    if (g_GameConfig.curBGMentindex != 0) {
        Game.StopSound(g_GameConfig.curBGMentindex);
    }
    g_GameConfig.curBGMIndex = g_GameConfig.nextBGMIndex;

    var BGMname = "BGM." + g_GameConfig.curBGMIndex.toString();
    var BGMduration = g_GameConfig.duration[g_GameConfig.curBGMIndex]+2;
    var dropPanel = $("#FateConfigBGMList");
    //$.Msg("Playing " + BGMname + " for " + BGMduration.toString() + " seconds");

    // Set a flag so that OnDropDownChange() does not run due to SetSelected()
    g_GameConfig.bIsAutoChange = true;
    //$.Msg("Scheduled destroying")
    $.Schedule(0.033, function(){g_GameConfig.bIsAutoChange = false;})

    if (dropPanel) {dropPanel.SetSelected(g_GameConfig.nextBGMIndex)} else ($.Msg("gabenpidor"));
    g_GameConfig.curBGMentindex = Game.EmitSound(BGMname);

    g_GameConfig.BGMSchedule = $.Schedule(BGMduration, function(){
        //$.Msg("Schedule worked, destroying current BGM" + g_GameConfig.curBGMIndex.toString())
        if (g_GameConfig.bIsBGMOn === true){
            if (!g_GameConfig.bRepeat) {
                g_GameConfig.nextBGMIndex = Math.floor((Math.random() * 30) + 1);
            }
            PlayBGM();
        }
    });
    //$.Msg(g_GameConfig.BGMSchedule)
}

function StopBGM()
{
    if (g_GameConfig.curBGMentindex != 0) {
        Game.StopSound(g_GameConfig.curBGMentindex);
    }
    if (g_GameConfig.BGMSchedule != 0) {
        $.CancelScheduled(g_GameConfig.BGMSchedule, {});
    }
}

function OnIntro(index)
{
    var index2 = Math.floor((Math.random() * 30) + 1);
    g_GameConfig.nextBGMIndex = index2;
    //$.Msg("Next BGM Index: " + selection.id);
    if (g_GameConfig.BGMSchedule != 0) {
        $.CancelScheduled(g_GameConfig.BGMSchedule, {});
    };
    Game.EmitSound("melty_game_start");
    if (g_GameConfig.curBGMentindex != 0) {
        Game.StopSound(g_GameConfig.curBGMentindex);
    }
    $.Schedule(9.0, function(){
        PlayBGM();
    })
    //$.Msg('Game start: change BGM ' + g_GameConfig.nextBGMIndex);
}

(function() {
    GameEvents.Subscribe( "bgm_intro", OnIntro );

    var index2 = 0;
    g_GameConfig.nextBGMIndex = index2;
    //$.Msg("Next BGM Index: " + selection.id);
    if (g_GameConfig.BGMSchedule != 0) {
        $.CancelScheduled(g_GameConfig.BGMSchedule, {});
    };
    PlayBGM();
    //$.Msg('Game start: change BGM ' + g_GameConfig.nextBGMIndex);
})();
