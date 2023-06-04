function OnHeroKilled(data)
{
	//$.Msg("[FATE] fate_hero_killed");
	//$.Msg(data, "\n------");
	var killer = data.killer
	var victim = data.victim

	var popupCount = $("#CombatEventPanel").GetChildCount();
	//$.Msg(popupCount);
	if (popupCount > 5)
	{
		$("#CombatEventPanel").GetChild(0).DeleteAsync(0);
	}

	var popup = $.CreatePanel('Panel', $("#CombatEventPanel"), '');
	popup.hittest = false;
	if (Entities.IsEnemy(victim))
	{
		popup.AddClass('CombatEventPopupAlly'); //css properties
	}
	else
	{
		popup.AddClass('CombatEventPopupEnemy'); 
	}
	//popup.AddClass('CombatEventPopupAlly'); //css properties
	// do valid checks
	var victimPortrait = $.CreatePanel('Panel', popup, '');
	//victimPortrait.heroimagestyle = "landscape";
	//victimPortrait.heroname = Entities.GetUnitName(victim);
	victimPortrait.style["width"] = 60 + "px;"
	victimPortrait.style["height"] = 36 + "px;"
	victimPortrait.style["background-image"] = "url('s2r://panorama/images/custom_game/portrait/" + Entities.GetUnitName(victim) + ".png');"
	victimPortrait.style["background-repeat"] = "no-repeat;"
	victimPortrait.style["background-size"] = "60px 36px;"
	victimPortrait.style["margin-top"] = "1px;"
	victimPortrait.style["margin-left"] = "1px;"
	victimPortrait.style["border-radius"] = "5px 5px 5px 5px;"
	victimPortrait.style["border"] = "3px solid #131313;"
	victimPortrait.hittest = false;
	//victimPortrait.AddClass('CombatEventPortrait');
	//victimPortrait.AddClass('VictimOverlay');


	var KDIcon = $.CreatePanel('Image', popup, '');
	if (Entities.IsEnemy(victim))
	{
		KDIcon.SetImage("file://{images}/misc/kill_icon.png");
	}
	else
	{
		KDIcon.SetImage("file://{images}/misc/death_icon.png");
	}
	KDIcon.AddClass('CombatEventIcon');
	KDIcon.hittest = false;

	var killerPortrait = $.CreatePanel('Panel', popup, '');
	//killerPortrait.heroimagestyle = "landscape";
	//killerPortrait.heroname = Entities.GetUnitName(killer);
	killerPortrait.style["width"] = 60 + "px;"
	killerPortrait.style["height"] = 36 + "px;"
	killerPortrait.style["background-image"] = "url('s2r://panorama/images/custom_game/portrait/" + Entities.GetUnitName(killer) + ".png');"
	killerPortrait.style["background-repeat"] = "no-repeat;"
	killerPortrait.style["background-size"] = "60px 36px;"
	killerPortrait.style["margin-top"] = "1px;"
	killerPortrait.style["margin-left"] = "1px;"
	killerPortrait.style["border-radius"] = "5px 5px 5px 5px;"
	killerPortrait.style["border"] = "3px solid #131313;"
	killerPortrait.hittest = false;
	//killerPortrait.AddClass('CombatEventPortrait');
	//killerPortrait.AddClass('KillerOverlay');

	$.Schedule(8, function(){
		if (popup) {popup.DeleteAsync(0);}
	});
}

function OnGoldSent(data)
{
	//$.Msg("[FATE] fate_gold_sent");
	//$.Msg(data, "\n------");
	var goldAmt = data.goldAmt
	var sender = data.sender
	var recipent = data.recipent
    var playerID = Players.GetLocalPlayer();
    var hero = Players.GetPlayerHeroEntityIndex( playerID )

	var popupCount = $("#GoldEventPanel").GetChildCount();
	//$.Msg(popupCount);
	if (popupCount > 5)
	{
		$("#GoldEventPanel").GetChild(0).DeleteAsync(0);
	}


	if (recipent == hero)
	{
		Game.EmitSound("Quickbuy.Available"); 
	}

	var popup = $.CreatePanel('Panel', $("#GoldEventPanel"), '');
	popup.hittest = false;
	popup.AddClass('GoldEventPopup');

	//var recipentPortrait = $.CreatePanel('DOTAHeroImage', popup, '');
	//recipentPortrait.heroimagestyle = "landscape";
	//recipentPortrait.heroname = Entities.GetUnitName(recipent);
	//recipentPortrait.hittest = false;
	//recipentPortrait.AddClass('CombatEventPortrait');

	var recipentPortrait = $.CreatePanel('Panel', popup, '');
	//killerPortrait.heroimagestyle = "landscape";
	//killerPortrait.heroname = Entities.GetUnitName(killer);
	recipentPortrait.style["width"] = 64 + "px;"
	recipentPortrait.style["height"] = 36 + "px;"
	recipentPortrait.style["background-image"] = "url('s2r://panorama/images/custom_game/portrait/" + Entities.GetUnitName(recipent) + ".png');"
	recipentPortrait.style["background-repeat"] = "no-repeat;"
	recipentPortrait.style["background-size"] = "64px 36px;"
	recipentPortrait.style["margin-top"] = "1px;"
	recipentPortrait.style["margin-left"] = "1px;"
	recipentPortrait.style["border-radius"] = "5px 5px 5px 5px;"
	recipentPortrait.style["border"] = "3px solid #131313;"
	recipentPortrait.hittest = false;

	var arrowPanel = $.CreatePanel('Panel', popup, '');
	arrowPanel.style.flowChildren = "down";
	arrowPanel.style.horizontalAlign = "middle";

	var arrowIcon = $.CreatePanel('Image', arrowPanel, '');
	arrowIcon.SetImage("file://{images}/misc/gold_arrow.png");
	arrowIcon.AddClass('GoldEventIcon');
	arrowIcon.hittest = false;

	var goldAmount = $.CreatePanel('Label', arrowPanel, '');
	goldAmount.text = goldAmt
	goldAmount.AddClass('GoldAmountText');

	//var senderPortrait = $.CreatePanel('DOTAHeroImage', popup, '');
	//senderPortrait.heroimagestyle = "landscape";
	//senderPortrait.heroname = Entities.GetUnitName(sender);
	//senderPortrait.hittest = false;
	//senderPortrait.AddClass('CombatEventPortrait');

	var senderPortrait = $.CreatePanel('Panel', popup, '');
	//killerPortrait.heroimagestyle = "landscape";
	//killerPortrait.heroname = Entities.GetUnitName(killer);
	senderPortrait.style["width"] = 64 + "px;"
	senderPortrait.style["height"] = 36 + "px;"
	senderPortrait.style["background-image"] = "url('s2r://panorama/images/custom_game/portrait/" + Entities.GetUnitName(sender) + ".png');"
	senderPortrait.style["background-repeat"] = "no-repeat;"
	senderPortrait.style["background-size"] = "64px 36px;"
	senderPortrait.style["margin-top"] = "1px;"
	senderPortrait.style["margin-left"] = "1px;"
	senderPortrait.style["border-radius"] = "5px 5px 5px 5px;"
	senderPortrait.style["border"] = "3px solid #131313;"
	senderPortrait.hittest = false;

	$.Schedule(8, function(){
		if (popup) {popup.DeleteAsync(0);}
	});
}

function ClearKDPopup()
{
	$.Schedule(4.5, function() {
		for (var i=0; i<$("#CombatEventPanel").GetChildCount(); i++)
		{
			$("#CombatEventPanel").GetChild(i).DeleteAsync(0);
		}
	});
}

(function () {
    GameEvents.Subscribe("fate_hero_killed", OnHeroKilled );
    GameEvents.Subscribe("fate_gold_sent", OnGoldSent );
    //GameEvents.Subscribe("winner_decided", ClearKDPopup);
})();
