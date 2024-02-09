"use strict";

function ToggleMute()
        {
            var playerId = $.GetContextPanel().GetAttributeInt( "player_id", -1 );
            if ( playerId !== -1 )
            {
                var newIsMuted = !Game.IsPlayerMuted( playerId );
                Game.SetPlayerMuted( playerId, newIsMuted );
                $.GetContextPanel().SetHasClass( "player_muted", newIsMuted );
            }
        }

        (function()
        {
            var playerId = $.GetContextPanel().GetAttributeInt( "player_id", -1 );
            $.GetContextPanel().SetHasClass( "player_muted", Game.IsPlayerMuted( playerId ) );
        })();

        function DeathsClicked() {
            if (!GameUI.IsAltDown()) {
                return;
            }
            var playerId = $.GetContextPanel().GetAttributeInt("player_id", -1);
            var localPlayerId = Game.GetLocalPlayerID();
            if (playerId != localPlayerId) {
                return
            }
            var playerInfo = Game.GetPlayerInfo(playerId);
            var numDeaths = playerInfo.player_deaths;
            var deathText = numDeaths == 1 ? "death" : "deaths";
            var deathColor = numDeaths >= 30 ? "_red_" : "_gold_";
            var message = "_gray__arrow_ _default_I have " + deathColor + numDeaths
                + " " + deathText + "_default_!"
            GameEvents.SendCustomGameEventToServer("player_alt_click", {message: message});
        }
