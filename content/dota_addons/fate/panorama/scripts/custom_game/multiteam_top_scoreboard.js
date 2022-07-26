"use strict";

var PlayerTables = GameUI.CustomUIConfig().PlayerTables;

var g_ScoreboardHandle = null;
this.g_RadiantScore = 0;
this.g_DireScore = 0;

function UpdateScoreboard()
{
	ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, true );

	$.Schedule( 0.2, UpdateScoreboard );
}

function UpdateRoundScore( data )
{
	g_RadiantScore = data.radiantScore;
	g_DireScore = data.direScore;
}

function SelectionPanelEndListenerPepega(){
	var playerData = Players.GetHeroSelectionPlayerInfo(Game.GetLocalPlayerID())
	if ((playerData.status == 'picked') && !(PlayerTables.GetTableValue('hero_selection_available_heroes', 'HeroSelectionState') < 4)){
		var ScenePanel = $('#TopBarScoreboard');
		ScenePanel.visible = true;
	}
	$.Schedule(2, function() {
			SelectionPanelEndListenerPepega();
		});
}

function UpdateCamera(tableName, changesObject, deletionsObject) {
	var camera_table = PlayerTables.GetAllTableValues('hero_camera');
	var localPlayerId = Game.GetLocalPlayerID();
	var ScenePanel = $('#TopBarScoreboard');
	if (camera_table != null) {
		for (var playerIdInSelection in camera_table) {
			if (playerIdInSelection == localPlayerId) {
    			if (camera_table[localPlayerId].cinematic == true) {
    				ScenePanel.visible = false;
    			} else {
    				ScenePanel.visible = true;
    			}
			}
		}
	}
}


(function()
{
	var shouldSort = true;

	if ( GameUI.CustomUIConfig().multiteam_top_scoreboard )
	{
		var cfg = GameUI.CustomUIConfig().multiteam_top_scoreboard;
		if ( cfg.LeftInjectXMLFile )
		{
			$( "#LeftInjectXMLFile" ).BLoadLayout( cfg.LeftInjectXMLFile, false, false );
		}
		if ( cfg.RightInjectXMLFile )
		{
			$( "#RightInjectXMLFile" ).BLoadLayout( cfg.RightInjectXMLFile, false, false );
		}

		if ( typeof(cfg.shouldSort) !== 'undefined')
		{
			shouldSort = cfg.shouldSort;
		}

		DynamicSubscribePTListener('hero_camera', UpdateCamera);

		var localPlayerId = Game.GetLocalPlayerID();
		if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
			var ScenePanel = $('#TopBarScoreboard');
			ScenePanel.visible = false;
			//$.Schedule(5, function() {
			//	SelectionPanelEndListenerPepega();
			//});
		}
	}
	
	if ( ScoreboardUpdater_InitializeScoreboard === null ) { $.Msg( "WARNING: This file requires shared_scoreboard_updater.js to be included." ); }

	var scoreboardConfig =
	{
		"teamXmlName" : "file://{resources}/layout/custom_game/multiteam_top_scoreboard_team.xml",
		"playerXmlName" : "file://{resources}/layout/custom_game/multiteam_top_scoreboard_player.xml",
		"shouldSort" : shouldSort
	};
	g_ScoreboardHandle = ScoreboardUpdater_InitializeScoreboard( scoreboardConfig, $( "#MultiteamScoreboard" ) );

	UpdateScoreboard();

	if (Game.GetMapInfo().map_display_name == "fate_elim_6v6" || Game.GetMapInfo().map_display_name == "fate_elim_7v7") { 
		GameEvents.Subscribe( "winner_decided", UpdateRoundScore );
	}
})();

