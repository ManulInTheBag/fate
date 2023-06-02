'use strict';
var MainPanel = $('#HeroSelectionBox');
var SelectedHeroPanel,
	SelectedTabIndex,
	SelectionTimerEndTime = 0,
	HideEvent,
	DOTA_ACTIVE_GAMEMODE,
	CustomChatLinesPanel,
	//MinimapPTIDs = [],
	HeroesPanels = [],
	tabsData = {},
	PlayerSpawnBoxes = {},
	HeroSelectionState = -1,
	PlayerPanels = [],
	InitializationStates = {},
	HasBanPoint = true,
	HeroSelectionTeam = 2,
	IsDraftMode = false;

function HeroSelectionEnd(bImmidate) {
	$.GetContextPanel().style.opacity = 0;
	hud.GetChild(0).RemoveClass('IsBeforeGameplay');
	$.Schedule(bImmidate ? 0 : 1.6, function() { //1.5 + 0.1
		MainPanel.visible = false;
		if (HideEvent != null)
			GameEvents.Unsubscribe(HideEvent);
		if ($.GetContextPanel().PTID_hero_selection) PlayerTables.UnsubscribeNetTableListener($.GetContextPanel().PTID_hero_selection);
		//if (MinimapPTIDs.length > 0)
		//	for (var i = 0; i < MinimapPTIDs.length; i++) {
		//		PlayerTables.UnsubscribeNetTableListener(MinimapPTIDs[i]);
		//	}
		//$.GetContextPanel().DeleteAsync(0);
	});
}

function ChooseHeroPanelHero() {
	ChooseHeroUpdatePanels();
	if (!IsLocalHeroLockedOrPicked()) {
		var localPlayerId = Game.GetLocalPlayerID();
		if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
			GameEvents.SendCustomGameEventToServer('hero_selection_player_hover', {
				hero: SelectedHeroName
			});
			//Game.EmitSound('melty_lock');
		}
	}
}

function SelectHero() {
	if (!IsLocalHeroPicked()) {
		var localPlayerId = Game.GetLocalPlayerID();
		if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
			GameEvents.SendCustomGameEventToServer('hero_selection_player_select', {
				hero: SelectedHeroName
			});
		}
		//Game.EmitSound('melty_pick');
	}
}

function RandomHero() {
	if (!IsLocalHeroLockedOrPicked()) {
		var localPlayerId = Game.GetLocalPlayerID();
		if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId) && !IsDraftMode) {
			GameEvents.SendCustomGameEventToServer('hero_selection_player_random', {});
		}
	}
}

function UpdateSelectionButton() {
	if (IsDraftMode == true){
		UpdateSelectionButtonDraft();
	} else	{
		var selectedHeroData = HeroesData[SelectedHeroName];
		$.GetContextPanel().SetHasClass('RandomingEnabled', !IsLocalHeroPicked() && !IsLocalHeroLocked() && HeroSelectionState > HERO_SELECTION_PHASE_BANNING);

		var canPick = !IsLocalHeroPicked() &&
			!IsHeroPicked(SelectedHeroName) &&
			!IsHeroBanned(SelectedHeroName) &&
			!IsHeroUnreleased(SelectedHeroName) &&
			!IsHeroDisabledInRanked(SelectedHeroName) &&
			(!IsLocalHeroLocked() || SelectedHeroName === LocalPlayerStatus.hero);

		var context = $.GetContextPanel();
		var mode = 'pick';
		if (HeroSelectionState === HERO_SELECTION_PHASE_BANNING) {
			mode = 'ban';
		} else if (selectedHeroData && selectedHeroData.linked_heroes) {
			mode = IsLocalHeroLocked() && selectedHeroData.heroKey === LocalPlayerStatus.hero ? 'unlock' : 'lock';
		}
		context.SetHasClass('LocalHeroLockButton', mode === 'lock');
		context.SetHasClass('LocalHeroUnlockButton', mode === 'unlock');
		context.SetHasClass('LocalHeroBanButton', mode === 'ban');

		$('#SelectedHeroSelectButton').enabled = canPick;
	}
}

function UpdateTimer() {
	$.Schedule(0.2, UpdateTimer);
	var SelectionTimerRemainingTime = (SelectionTimerEndTime || Number.MIN_SAFE_INTEGER) - Game.GetGameTime();
	//if (HeroSelectionState == HERO_SELECTION_PHASE_END) {
	//	$.Schedule(5, function() {
	//			SelectionPanelEndListener();
	//		});
	//}
	if (SelectionTimerRemainingTime > 0) {
		if (HeroSelectionState < HERO_SELECTION_PHASE_END) {
			hud.GetChild(0).AddClass('IsBeforeGameplay');
		}
		$('#HeroSelectionTimer').text = Math.ceil(SelectionTimerRemainingTime);
		SearchHero();
		for (var playerId in PlayerPanels) {
			var panel = PlayerPanels[playerId];
			var playerInfo = Game.GetPlayerInfo(Number(PlayerPanels));
			if (playerInfo != null) {
				panel.SetHasClass('player_connection_abandoned', playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED);
				panel.SetHasClass('player_connection_failed', playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_FAILED);
				panel.SetHasClass('player_connection_disconnected', playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED);
			}
		}
		//_.each($MinimapSpawnBoxes().Children(), function(child) {
		//	var childrencount = child.GetChildCount();
		//	child.SetHasClass('SpawnBoxUnitPanelChildren2', childrencount >= 2);
		//	child.SetHasClass('SpawnBoxUnitPanelChildren3', childrencount >= 3);
		//	child.SetHasClass('SpawnBoxUnitPanelChildren5', childrencount >= 5);
		//});
	} else {
		$('#HeroSelectionTimer').text = 0;
	}
}

function Snippet_PlayerPanel(playerId, rootPanel) {
	if (PlayerPanels[playerId] == null) {
		var panel = $.CreatePanel('Panel', rootPanel, '');
		panel.BLoadLayoutSnippet('PlayerPanel');
		panel.SetDialogVariable('player_name', Players.GetPlayerName(playerId));
		var statsData = Players.GetStatsData(playerId);
		panel.FindChildTraverse('SlotColor').style.backgroundColor = GetHEXPlayerColor(playerId);
		PlayerPanels[playerId] = panel;
	}
	return PlayerPanels[playerId];
}

function SelectionPanelEndListener(){
	//$.Msg("pepega gaming")
	$.Schedule(1, function() {
				SelectionPanelEndListener();
			});
	if (PlayerTables.IsConnected()) {
		var playerData = Players.GetHeroSelectionPlayerInfo(Game.GetLocalPlayerID())
		if ((playerData.status == 'picked') && !(HeroSelectionState < HERO_SELECTION_PHASE_END)){
			HeroSelectionEnd(true)
		}
	}
}

function UpdateHeroesSelected(tableName, changesObject, deletionsObject) {
	var index;
	//$.Msg(changesObject);
	for (index = 1; index <= 10; ++index) {
		UHSSub(tableName, changesObject, deletionsObject, index)
	};
	UpdateSelectionButton();
}

function UHSSub(tableName, changesObject, deletionsObject, index){
	var teamPlayers = changesObject[index];
	if (teamPlayers != null) {
	var index2;
	//$.Msg("teamPlayers")
	//$.Msg(teamPlayers);
	var teamNumber = index;
	if ($('#team_selection_panels_team' + teamNumber) == null) {
		var isRight = teamNumber % 2 !== 0;
		var TeamSelectionPanel = $.CreatePanel('Panel', $(isRight ? '#RightTeams' : '#LeftTeams'), 'team_selection_panels_team' + teamNumber);
		TeamSelectionPanel.BLoadLayoutSnippet('TeamBar');
		var color = GameUI.CustomUIConfig().team_colors[teamNumber];
		//TeamSelectionPanel.style.backgroundColor = 'gradient(linear, 100% 100%, 0% 100%, from(transparent), color-stop(0.15, ' + color + '4D), to(transparent))';
	}
	var TeamSelectionPanel = $('#team_selection_panels_team' + teamNumber).FindChildTraverse('TeamBarPlayers');
	
		for (index2 = 0; index2 <= 13; ++index2) {
			UHSSub2(tableName, changesObject, deletionsObject, teamPlayers, teamNumber, TeamSelectionPanel, index2);
		};
	};
}

function UHSSub2(tableName, changesObject, deletionsObject, teamPlayers, teamNumber, TeamSelectionPanel, index2){
	var playerData = teamPlayers[index2];
	//$.Msg("playerData" + index2);
	//$.Msg(playerData);
	if (playerData != null) {
		var playerIdInTeam = index2;
		var PlayerPanel = Snippet_PlayerPanel(Number(playerIdInTeam), TeamSelectionPanel);

		var isLocalPlayer = Number(playerIdInTeam) === Game.GetLocalPlayerID();
		var isLocalTeam = Number(teamNumber) === Players.GetTeam(Game.GetLocalPlayerID());

		if (isLocalPlayer) {
			LocalPlayerStatus = playerData;
			$.GetContextPanel().SetHasClass('LocalPlayerLocked', playerData.status === 'locked');
			//$.Msg("OLPP should trigger")
			if (!$.GetContextPanel().BHasClass('LocalPlayerPicked') && playerData.status === 'picked') {
				OnLocalPlayerPicked();
			} else if ($.GetContextPanel().BHasClass('LocalPlayerPicked') && playerData.status !== 'picked') {
				ToggleHeroPreviewHeroList(false);
			}
			$.GetContextPanel().SetHasClass('LocalPlayerPicked', playerData.status === 'picked');
		}

		PlayerPanel.SetHasClass('HeroPickHovered', playerData.status === 'hover');
		PlayerPanel.SetHasClass('HeroPickLocked', playerData.status === 'locked');
		if (playerData.status === 'hover' || playerData.status === 'locked') {
			if (isLocalTeam) {
				PlayerPanel.FindChildTraverse('HeroImage').SetImage("s2r://panorama/images/custom_game/portrait/" + playerData.hero + "_png.vtex");
				PlayerPanel.SetDialogVariable('dota_hero_name', $.Localize('#' + playerData.hero));
			}
		} else if (playerData.status === 'picked') {
			PlayerPanel.FindChildTraverse('HeroImage').SetImage("s2r://panorama/images/custom_game/portrait/" + playerData.hero + "_png.vtex");
			PlayerPanel.SetDialogVariable('dota_hero_name', $.Localize('#' + playerData.hero));
		}
		var heroPanel = $('#HeroListPanel_element_' + playerData.hero);
		if (heroPanel) {
			heroPanel.SetHasClass('AlreadyPicked', IsHeroPicked(playerData.hero));
			heroPanel.SetHasClass('Locked', IsHeroLocked(playerData.hero));
		}
	}
}

//function $MinimapSpawnBoxes() {
//	var vs = $('#MinimapPanel').FindChildrenWithClassTraverse('MinimapSpawnBoxes');
//	for (var i = 0; i < vs.length; i++) {
//		if (vs[i].BHasClass('only_map_landscape_' + Options.GetMapInfo().landscape))
//			return vs[i];
//	}
//}

function OnLocalPlayerPicked() {
	var heroName = LocalPlayerStatus.hero;
	var localHeroData = HeroesData[heroName];
	Game.EmitSound('melty_pick');
	//$.Msg("OLPP1")
	$('#HeroPreviewName').text = $.Localize('#' + heroName).toUpperCase();
	//$.Msg("OLPP2")
	var bio = $.Localize('#' + heroName + '_bio');
	$('#HeroPreviewLore').text = bio !== heroName + '_bio' ? bio : '';
	//$.Msg("OLPP3")
	var hype = $.Localize('#' + heroName + '_hype');
	$('#HeroPreviewOverview').text = hype !== heroName + '_hype' ? hype : '';
	//$.Msg("OLPP4")

	//var model = localHeroData.model
	//$.Msg("pepeg")
	//$.Msg(heroName)
	//$.Msg(model)
	//var heroImageXML = '<DOTAScenePanel particleonly="false" ' +
	//	(localHeroData.useCustomScene
	//		? 'map="scenes/heroes" camera="' + heroName + '" />'
	//		: 'allowrotation="true" unit="' + model + '" />');
	//var ScenePanel = $('#HeroPreviewScene');
	//ScenePanel.RemoveAndDeleteChildren();
	////ScenePanel.BCreateChildren(heroImageXML);
	//$.CreatePanelWithProperties("DOTAScenePanel", ScenePanel, "scene", {particleonly:"false", allowrotation:"true", unit: model});

	//$('#HeroPreviewAbilities').RemoveAndDeleteChildren();
	//$('#SelectedHeroAttributesAndComboPanelInner').RemoveAndDeleteChildren();
	//$('#HeroPreviewAttributesAndCombo').RemoveAndDeleteChildren();
	//FillAbilitiesUI($('#HeroPreviewAbilities'), localHeroData.abilities, 'HeroPreviewAbility');
	//FillAbilitiesUI($('#HeroPreviewAttributesAndCombo'), localHeroData.attributesandcombo, 'HeroPreviewAbility');
	//FillAttributeUI($('#HeroPreviewAttributes'), localHeroData.attributes);
	//ToggleHeroPreviewHeroList(true);
	$.GetContextPanel().RemoveClass('CanRepick');
}

function ToggleHeroPreviewHeroList(isPreview) {
	$.GetContextPanel().SetHasClass('HeroPreview', isPreview != null ? isPreview : !$.GetContextPanel().BHasClass('HeroPreview'));
}

//function OnMinimapClickSpawnBox(team, level, index) {
//	GameEvents.SendCustomGameEventToServer('hero_selection_minimap_set_spawnbox', {
//		team: team,
//		level: level,
//		index: index,
//	});
//}

function OnAdsClicked() {
	var context = $.GetContextPanel();
	$.Schedule(context.BHasClass('AdsClicked') ? 0 : .35, function() {
		$.DispatchEvent('ExternalBrowserGoToURL', 'https://goo.gl/FJynE1');
	});
	if (!context.BHasClass('AdsClicked')){
		context.AddClass('AdsClicked');
		Game.EmitSound('General.CoinsBig');
		var localPlayerId = Game.GetLocalPlayerID();
		if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
			GameEvents.SendCustomGameEventToServer('on_ads_clicked', {});
		}
	}
}

function StartStrategyTime() {

}

function UpdateMainTable(tableName, changesObject, deletionsObject) {
	var newState = changesObject.HeroSelectionState;
	if (changesObject.HeroTabs != null) {
		if (HeroesPanels.length === 0 && HeroesData) {
			var index;
			//$.Msg("UMT problems");
			//$.Msg(Object.keys(changesObject.HeroTabs[1]).length);
			var TabHeroesPanel = $.CreatePanel('Panel', $('#HeroListPanel'), 'HeroListPanel_tabPanels_' + 1);
			TabHeroesPanel.BLoadLayoutSnippet('HeroesPanel');
			FillHeroesTable(changesObject.HeroTabs[1], TabHeroesPanel);
			TabHeroesPanel.visible = false;
			ListenToBanningPhase();
			SelectHeroTab(1);
		}
	}
	if (newState != null) {
		SetCurrentPhase(newState);
	}
	if (changesObject.TimerEndTime != null) {
		SelectionTimerEndTime = changesObject.TimerEndTime;
	}
	if (changesObject.HeroSelectionTeam != null) {
		if (changesObject.HeroSelectionTeam != 0){
			HeroSelectionTeam = changesObject.HeroSelectionTeam;
			$('#HeroSelectionDraftImage').SetImage("s2r://panorama/images/custom_game/hero_selection/pick_" + HeroSelectionTeam + "_png.vtex")
			var isLocalTeam = HeroSelectionTeam === Players.GetTeam(Game.GetLocalPlayerID());
			if (isLocalTeam == true) {
				HasBanPoint = true;
			}
			UpdateSelectionButton();
		}
	}
}

function UpdateDraft(tableName, changesObject, deletionsObject) {
	var newState = changesObject.HeroSelectionState;
	if (changesObject.TeamPicked != null) {
		if (changesObject.TeamPicked != 0){
			var isLocalTeam = changesObject.TeamPicked === Players.GetTeam(Game.GetLocalPlayerID());
			if (isLocalTeam == true) {
				HasBanPoint = false;
			}
			UpdateSelectionButton();
		}
	}
}

function UpdateSelectionButtonDraft() {
	var selectedHeroData = HeroesData[SelectedHeroName];
	$.GetContextPanel().SetHasClass('RandomingEnabled', false);

	var isLocalTeam = HeroSelectionTeam === Players.GetTeam(Game.GetLocalPlayerID());

	var canPick = !IsLocalHeroPicked() &&
		!IsHeroPicked(SelectedHeroName) &&
		!IsHeroBanned(SelectedHeroName) &&
		!IsHeroUnreleased(SelectedHeroName) &&
		!IsHeroDisabledInRanked(SelectedHeroName) &&
		(!IsLocalHeroLocked() || SelectedHeroName === LocalPlayerStatus.hero);

	var context = $.GetContextPanel();
	var mode = 'pick';
	if (HeroSelectionState === HERO_SELECTION_PHASE_BANNING) {
		mode = 'ban';
		//$.Msg("USBDDebug")
		//$.Msg(isLocalTeam);
	} else if (selectedHeroData && selectedHeroData.linked_heroes) {
		mode = IsLocalHeroLocked() && selectedHeroData.heroKey === LocalPlayerStatus.hero ? 'unlock' : 'lock';
	}

	canPick = canPick && isLocalTeam;
	canPick = canPick && HasBanPoint;

	context.SetHasClass('LocalHeroLockButton', mode === 'lock');
	context.SetHasClass('LocalHeroUnlockButton', mode === 'unlock');
	context.SetHasClass('LocalHeroBanButton', mode === 'ban');

	$('#SelectedHeroSelectButton').enabled = canPick;
}

function SetCurrentPhase(newState) {
	switch (newState) {
		case HERO_SELECTION_PHASE_END:
			//HeroSelectionEnd(HeroSelectionState === -1);
			break;
		case HERO_SELECTION_PHASE_STRATEGY:
			$.GetContextPanel().RemoveClass('CanRepick');
			StartStrategyTime();
		case HERO_SELECTION_PHASE_HERO_PICK:
		case HERO_SELECTION_PHASE_BANNING:
			if (!InitializationStates[HERO_SELECTION_PHASE_BANNING]) {
				InitializationStates[HERO_SELECTION_PHASE_BANNING] = true;
				SelectFirstHeroPanel();
			}
	}
	var context = $.GetContextPanel();
	context.SetHasClass('IsInBanPhase', newState === HERO_SELECTION_PHASE_BANNING);
	HeroSelectionState = newState;
	InitializationStates[newState] = true;
	$('#GameModeInfoCurrentPhase').text = $.Localize('#' + 'hero_selection_phase_' + newState);
	UpdateSelectionButton();
}

function ShowHeroPreviewTab(tabID) {
	var index;
	for (index = 1; index <= Object.keys($('#TabContents').Children()).length; ++index) {
		var child = $('#TabContents').Children()[index];
		child.SetHasClass('TabVisible', child.id === tabID);
	};
}

(function() {
	$.GetContextPanel().RemoveClass('LocalPlayerPicked');
	$('#HeroListPanel').RemoveAndDeleteChildren();
	var localPlayerId = Game.GetLocalPlayerID();
	if (Players.IsValidPlayerID(localPlayerId) && !Players.IsSpectator(localPlayerId)) {
		//_DynamicMinimapSubscribe($('#MinimapDynamicIcons'), function(ptid) {
		//	MinimapPTIDs.push(ptid);
		//});
		$.Schedule(0.01, function() {
			SelectionPanelEndListener();
		});
		DynamicSubscribePTListener('hero_selection_available_heroes', UpdateMainTable);
		DynamicSubscribePTListener('hero_selection_draft', UpdateDraft);
		//$.GetContextPanel().SetHasClass('ShowMMR', Options.IsEquals('EnableRatingAffection'));
		var gamemode = Options.GetMapInfo().gamemode;
		//$.Msg(gamemode)
		if (gamemode === 'draft') {
			IsDraftMode = true;
		}
		
		$('#GameModeInfoGamemodeLabel').text = $.Localize('#' + 'arena_game_mode_type_' + gamemode);

		if ($.GetContextPanel().PTID_hero_selection) PlayerTables.UnsubscribeNetTableListener($.GetContextPanel().PTID_hero_selection);
		DynamicSubscribePTListener('hero_selection', UpdateHeroesSelected, function(ptid) {
			$.GetContextPanel().PTID_hero_selection = ptid;
		});

		//DynamicSubscribePTListener('stats_team_rating', function(tableName, changesObject, deletionsObject) {
		//	for (var teamNumber in changesObject) {
		//		$('#team_selection_panels_team' + teamNumber).SetDialogVariable('team_rating', changesObject[teamNumber]);
		//	}
		//});

		//DynamicSubscribePTListener('stats_client', function(tableName, changesObject, deletionsObject) {
		//	for (var playerId in changesObject) {
		//		Snippet_PlayerPanel(+playerId).SetDialogVariable('player_mmr', changesObject[playerId].Rating || 'TBD');
		//	}
		//});
		UpdateTimer();
		//$.Schedule(1, function() {
		//});

		$('#HeroSelectionCustomBackground').SetImage("s2r://panorama/images/custom_game/loading_screen/pickscreen_png.vtex")

		var bglist = Players.GetStatsData(localPlayerId).Backgrounds;
		if (bglist) $('#HeroSelectionCustomBackground').SetImage(bglist[Math.floor(Math.random() * bglist.length)]);
	} else {
		HeroSelectionEnd(true);
	}
})();
