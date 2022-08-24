'use strict';

var remembered = 0;

function UpdateCamera(tableName, changesObject, deletionsObject) {
	if (PlayerTables.IsConnected()){
		var camera_table = PlayerTables.GetAllTableValues('hero_camera');
		var localPlayerId = Game.GetLocalPlayerID();
		if (camera_table != null) {
			for (var playerIdInSelection in camera_table) {
				if (playerIdInSelection == localPlayerId) {
					if (camera_table[localPlayerId].remember == true) {
						GameUI.SetCameraPitchMin(90);
	    				GameUI.SetCameraPitchMax(90);
	    				remembered = GameUI.GetCameraLookAtPosition()[2];
	    			}
	    			if (camera_table[localPlayerId].reset == true){
	    				remembered = 0;
	    			}
					GameUI.SetCameraYaw(camera_table[localPlayerId].yaw);
	   				GameUI.SetCameraPitchMin(camera_table[localPlayerId].pitch);
	    			GameUI.SetCameraPitchMax(camera_table[localPlayerId].pitch);
	    			//$.Msg(remembered)
	    			GameUI.SetCameraLookAtPositionHeightOffset(camera_table[localPlayerId].heightOffset);
	    			GameUI.SetCameraLookAtPositionHeightOffset(camera_table[localPlayerId].heightOffset - remembered);
	    			GameUI.SetCameraDistance(camera_table[localPlayerId].distance);
	    			//$.Msg(GameUI.GetCameraLookAtPosition()[2]);
	    			if (camera_table[localPlayerId].cinematic == true) {
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false);
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false);
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false);
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false);
	    				GameUI.SetCameraTerrainAdjustmentEnabled(true)
	    				$('#BlackBarTop').visible = true;
	    				$('#BlackBarBottom').visible = true;
	    			} else {
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, true);
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, true);
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, true);
	    				GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, true);
	    				GameUI.SetCameraTerrainAdjustmentEnabled(true)
	    				$('#BlackBarTop').visible = false;
	    				$('#BlackBarBottom').visible = false;
	    			}
				}
			}
		}
	}
}


(function() {
	 //DynamicSubscribePTListener('hero_camera', UpdateCamera);
})();