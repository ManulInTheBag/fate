"use strict";

function PortraitClicked()
    {
        // TODO: ctrl and alt click support
        Players.PlayerPortraitClicked( $.GetContextPanel().GetAttributeInt( "player_id", -1 ), false, false );
    }