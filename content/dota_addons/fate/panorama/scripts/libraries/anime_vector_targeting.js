//--EIEOFLIE VECTOR TARGETING VERSION 0.03, BASED ON Nibuja05 AND Elfansoer Repo with full rewrite logic and style to my style and reduce size of code
//Если берешь то бери с умом Мистер Cеренити :nep_trap:

//спасибо за еду (ManulInTheBag)

"use strict";

var PlayerTables      = GameUI.CustomUIConfig().PlayerTables;

const bFINISH_EVENT   = true;
const bCONTINUE_EVENT = false;

var iOLD_PARTICLE = undefined;

// Start the vector targeting
function StartDrawAnimeVectorTargeting(iAbilityIndex, hAbilityData, bStopOldTargeting)
{
    var GetAnimeVectorTargetingTarget   = hAbilityData.GetAnimeVectorTargetingTarget;
    var GetAnimeVectorTargetingPosition = hAbilityData.GetAnimeVectorTargetingPosition 
                                          && [ 
                                               hAbilityData.GetAnimeVectorTargetingPosition[0], 
                                               hAbilityData.GetAnimeVectorTargetingPosition[1], 
                                               hAbilityData.GetAnimeVectorTargetingPosition[2]
                                             ]
                                          || hAbilityData.GetAnimeVectorTargetingPosition;

    if (!GetAnimeVectorTargetingTarget && !GetAnimeVectorTargetingPosition)
    {
        return;
    }

    var GetAnimeVectorTargetingRange       = hAbilityData.GetAnimeVectorTargetingRange       || 800;
    var GetAnimeVectorTargetingStartRadius = hAbilityData.GetAnimeVectorTargetingStartRadius || 125;
    var GetAnimeVectorTargetingEndRadius   = hAbilityData.GetAnimeVectorTargetingEndRadius   || GetAnimeVectorTargetingStartRadius;
    var GetAnimeVectorTargetingColor       = hAbilityData.GetAnimeVectorTargetingColor       || [0, 255, 0];

    var IsAnimeVectorTargetingIgnoreWidth  = (hAbilityData.IsAnimeVectorTargetingIgnoreWidth || 0) >= 1;
    var IsAnimeVectorTargetingDual         = (hAbilityData.IsAnimeVectorTargetingDual        || 0) >= 1;

    var iCasterIndex    = Abilities.GetCaster(iAbilityIndex);
    var vCasterPosition = Entities.GetAbsOrigin(iCasterIndex);
    var vWorldPosition  = (GetAnimeVectorTargetingTarget)
                           && Entities.GetAbsOrigin(GetAnimeVectorTargetingTarget)
                           || GetAnimeVectorTargetingPosition;
    var vDirection      = (Game.Length2D(vWorldPosition, vCasterPosition) <= 0.05)
                           && Entities.GetForward(iCasterIndex) 
                           || Vector_Normilize(Vector_Sub(vWorldPosition, vCasterPosition));

    //Initialize the particle
    let sParticleName = "particles/ui_mouseactions/custom_range_finder_cone.vpcf";
    if (IsAnimeVectorTargetingDual)
    {   
        GetAnimeVectorTargetingRange = GetAnimeVectorTargetingRange * 0.5;
        sParticleName                = "particles/ui_mouseactions/custom_range_finder_cone_dual.vpcf";
    }

    var iAnimeVectorTargetingParticle = Particles.CreateParticle(sParticleName, ParticleAttachment_t.PATTACH_CUSTOMORIGIN, iCasterIndex);
                                        Particles.SetParticleControl(iAnimeVectorTargetingParticle, 1, Vector_RaizeZ(vWorldPosition, 100));
                                        Particles.SetParticleControl(iAnimeVectorTargetingParticle, 3, [GetAnimeVectorTargetingEndRadius, GetAnimeVectorTargetingStartRadius, IsAnimeVectorTargetingIgnoreWidth]);
                                        Particles.SetParticleControl(iAnimeVectorTargetingParticle, 4, GetAnimeVectorTargetingColor);

    var vNewPosition = Vector_Add(vWorldPosition, Vector_Mult(vDirection, GetAnimeVectorTargetingRange));
    
    if (IsAnimeVectorTargetingDual)
    {
        var vSecondPosition = Vector_Add(vWorldPosition, Vector_Mult(Vector_Negate(vDirection), GetAnimeVectorTargetingRange));

        Particles.SetParticleControl(iAnimeVectorTargetingParticle, 7, vNewPosition);
        Particles.SetParticleControl(iAnimeVectorTargetingParticle, 8, vSecondPosition);
    }
    else
    {
        Particles.SetParticleControl(iAnimeVectorTargetingParticle, 2, vNewPosition);
    }
    
    iOLD_PARTICLE = iAnimeVectorTargetingParticle;

    if (GetAnimeVectorTargetingTarget)
    {
        GetAnimeVectorTargetingPosition = GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition());
    }

    //Start position updates
    return LoopDrawAnimeVectorTargeting(iAbilityIndex, iAnimeVectorTargetingParticle, GetAnimeVectorTargetingTarget, GetAnimeVectorTargetingPosition, IsAnimeVectorTargetingDual, GetAnimeVectorTargetingRange);
}

//Updates the particle effect and detects when the ability is actually casted
function LoopDrawAnimeVectorTargeting(iAbilityIndex, iAnimeVectorTargetingParticle, GetAnimeVectorTargetingTarget, GetAnimeVectorTargetingPosition, IsAnimeVectorTargetingDual, GetAnimeVectorTargetingRange)
{   
    if (iOLD_PARTICLE !== iAnimeVectorTargetingParticle || iAbilityIndex !== Abilities.GetLocalPlayerActiveAbility())
    {
        return StopDrawAnimeVectorTargeting(iAnimeVectorTargetingParticle);
    }

    var vStartPosition = GetAnimeVectorTargetingPosition;

    if (GetAnimeVectorTargetingTarget)
    {   
        if (!Entities.IsValidEntity(GetAnimeVectorTargetingTarget) || !Entities.IsAlive(GetAnimeVectorTargetingTarget))
        {
            Abilities.ExecuteAbility(iAbilityIndex, Abilities.GetCaster(iAbilityIndex), true);

            return StopDrawAnimeVectorTargeting(iAnimeVectorTargetingParticle);
        }

        vStartPosition = Entities.GetAbsOrigin(GetAnimeVectorTargetingTarget);
    }

    var vCursorPosition = GameUI.GetCursorPosition();
    var vWorldPosition  = GameUI.GetScreenWorldPosition(vCursorPosition);

    if (!vWorldPosition || ( GetAnimeVectorTargetingTarget && Game.Length2D(vWorldPosition, GetAnimeVectorTargetingPosition) <= 0.05 ) )
    {
        return $.Schedule( 0.01, function() {LoopDrawAnimeVectorTargeting(iAbilityIndex, iAnimeVectorTargetingParticle, GetAnimeVectorTargetingTarget, GetAnimeVectorTargetingPosition, IsAnimeVectorTargetingDual, GetAnimeVectorTargetingRange);});
    }

    var vChangeVector = Vector_Sub(vWorldPosition, vStartPosition);
    
    if (!(vChangeVector[0] == 0 && vChangeVector[1] == 0 && vChangeVector[2] == 0))
    {   
        var vDirection = Vector_Normilize(Vector_Sub(vStartPosition, vWorldPosition));
            vDirection = Vector_Flatten(Vector_Negate(vDirection));
            
        var vNewPosition = Vector_Add(vStartPosition, Vector_Mult(vDirection, GetAnimeVectorTargetingRange));

        Particles.SetParticleControl(iAnimeVectorTargetingParticle, 1, Vector_RaizeZ(vStartPosition, 100));

        if (IsAnimeVectorTargetingDual)
        {
            var vSecondPosition = Vector_Add(vStartPosition, Vector_Mult(Vector_Negate(vDirection), GetAnimeVectorTargetingRange));

            Particles.SetParticleControl(iAnimeVectorTargetingParticle, 7, vNewPosition);
            Particles.SetParticleControl(iAnimeVectorTargetingParticle, 8, vSecondPosition);
        }
        else
        {
            Particles.SetParticleControl(iAnimeVectorTargetingParticle, 2, vNewPosition);
        }
    }

    return $.Schedule( 0.01, function() {LoopDrawAnimeVectorTargeting(iAbilityIndex, iAnimeVectorTargetingParticle, GetAnimeVectorTargetingTarget, GetAnimeVectorTargetingPosition, IsAnimeVectorTargetingDual, GetAnimeVectorTargetingRange);});
}

function StopDrawAnimeVectorTargeting(iAnimeVectorTargetingParticle)
{
    if (iAnimeVectorTargetingParticle)
    {
        Particles.DestroyParticleEffect( iAnimeVectorTargetingParticle, true );
        Particles.ReleaseParticleIndex( iAnimeVectorTargetingParticle );

        return iAnimeVectorTargetingParticle = undefined;
    }
}

function Init()
{ 
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Find the ability/item entindex from the panorama panel
    function FindAbilityOnPanel(hPanel)
    {   
        if (hPanel && hPanel.paneltype == "DOTAAbilityPanel")
        {
            //Be sure that it is a default ability Button
            const hParent = hPanel.GetParent();
            if (hParent && (hParent.id == "abilities" || hParent.id == "inventory_list"))
            {
                const hAbilityImage = hPanel.FindChildTraverse("AbilityImage");
                let iAbilityIndex   = hAbilityImage.contextEntityIndex;
                let sAbilityName    = hAbilityImage.abilityname;

                //Will be undefined for items
                if (sAbilityName)
                {
                    return iAbilityIndex;
                }

                //Return item entindex instead
                const hItemImage = hPanel.FindChildTraverse("ItemImage");

                iAbilityIndex    = hItemImage.contextEntityIndex;

                return iAbilityIndex;
            }
        }
        return -1;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function TryCastAnimeVectorTargeting(iAbilityIndex)
    {   
        const iEntIndex = Abilities.GetCaster(iAbilityIndex);
        const iBehavior = Abilities.GetBehavior(iAbilityIndex);
        const bVector   = (iBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING) !== 0 && ( Abilities.IsItem(iAbilityIndex)
                                                                                                                && !Entities.IsMuted(iEntIndex)
                                                                                                                || !Entities.IsSilenced(iEntIndex) );
        const bUnit     = (iBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)      !== 0;
        const bPoint    = (iBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_POINT)            !== 0;
        const bRooted   = (iBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES)    !== 0 && Entities.IsRooted(iEntIndex);

        if (bVector && !bRooted && (bUnit || bPoint))
        {
            var vCursor   = GameUI.GetCursorPosition();
            var hCallback = {iAbilityIndex : iAbilityIndex};

            if (bUnit)
            {
                hCallback.hEntities = SetAnimeTableOneValueByKey(AnimeShallowCopyWithIndex(GameUI.FindScreenEntities(vCursor), "entityIndex"));
            }

            if (bPoint)
            {
                hCallback.hPosition = GameUI.GetScreenWorldPosition(vCursor);
            }

            GameEvents.SendCustomGameEventToServer("update_anime_vector_targeting_ability", hCallback);
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    PlayerTables.SubscribeNetTableListener("anime_vector_targeting", function(sTableName, hChange, hDelete)
    {
        //$.Msg(sTableName, hChange, hDelete);
        const iAbilityIndex = Abilities.GetLocalPlayerActiveAbility();
        const hAbilityData  = hChange[String(iAbilityIndex)];
        if (hAbilityData)
        {
            StartDrawAnimeVectorTargeting(iAbilityIndex, hAbilityData, true);
        }
    });
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Classchange Listener for Quick Cast
    $.RegisterForUnhandledEvent("StyleClassesChanged", CheckQuickCastOnAbilityPanel);
    function CheckQuickCastOnAbilityPanel(hPanel)
    {
        if (hPanel)
        {
            //Check if the panel is an ability or item panel
            const iAbilityIndex = FindAbilityOnPanel(hPanel);
            if (iAbilityIndex === Abilities.GetLocalPlayerActiveAbility()
                && GameUI.GetClickBehaviors() === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_VECTOR_CAST
                && hPanel.BHasClass("is_active")) //BONUS CHECK MB WILL HELP SOME TIMES
            {
                //$.DispatchEvent("IfHasClassEvent", hPanel, "is_active", $.Msg("kkik"));
                TryCastAnimeVectorTargeting(iAbilityIndex);
            }
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    GameUI.SetMouseCallback(function( sEventName, iButton )
    {
        if (sEventName === "pressed"
            && iButton === 0
            && GameUI.GetClickBehaviors() === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST 
            && GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_VECTOR_CAST)
        {
            TryCastAnimeVectorTargeting(Abilities.GetLocalPlayerActiveAbility());
        }
        return bCONTINUE_EVENT;
    });
}

//Bonus Table Func for Entities
function SetAnimeTableOneValueByKey(hTable)
{
    const hTable2 = [];
    for (let cKey in hTable)
    {   
        cKey = Number(cKey);
        if (Entities.IsValidEntity(cKey) && Entities.IsAlive(cKey))
        {
            hTable2.push(cKey);
        }
    }
    return hTable2;
}

//Default Vector Operations:
function Vector_Normilize(vVector)
{
    const fValue = 1 / Math.sqrt(Math.pow(vVector[0], 2) + Math.pow(vVector[1], 2) + Math.pow(vVector[2], 2));
    return [vVector[0] * fValue, vVector[1] * fValue, vVector[2] * fValue];
}

function Vector_Mult(vVector, fMult)
{
    return [vVector[0] * fMult, vVector[1] * fMult, vVector[2] * fMult];
}

function Vector_Add(vVector1, vVector2)
{
    return [vVector1[0] + vVector2[0], vVector1[1] + vVector2[1], vVector1[2] + vVector2[2]];
}

function Vector_Sub(vVector1, vVector2)
{
    return [vVector1[0] - vVector2[0], vVector1[1] - vVector2[1], vVector1[2] - vVector2[2]];
}

function Vector_Negate(vVector)
{
    return [-vVector[0], -vVector[1], -vVector[2]];
}

function Vector_Flatten(vVector)
{
    return [vVector[0], vVector[1], 0];
}

function Vector_RaizeZ(vVector, fRaize)
{
    return [vVector[0], vVector[1], vVector[2] + fRaize];
}

(function(){
    Init();
})();
