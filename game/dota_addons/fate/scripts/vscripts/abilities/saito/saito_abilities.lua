--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--NOTE: Using AKA IsNotNull(false) will return "true", because it's a boolean, be careful.
IsNotNull = function(hScript)
    local sType = type(hScript)
    if sType ~= "nil" then
        if sType == "table"
            and type(hScript.IsNull) == "function" then
            return not hScript:IsNull()
        end
        return true
    end
    return false
end
--This function is used basically everywhere in my code, it checks for valid entity based on hScript class AKA heroes/abilities/modifiers(buffs/debuffs) and support BaseEntity.
--Prevent errors that can be caused by mistakes when the entity is missing from the code but you are trying to reach it.
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetDistance = function(hEnt1, hEnt2, b3D)
    hEnt1 = type(hEnt1.GetAbsOrigin) == "function" and hEnt1:GetAbsOrigin() or hEnt1
    hEnt2 = type(hEnt2.GetAbsOrigin) == "function" and hEnt2:GetAbsOrigin() or hEnt2
    return b3D and (hEnt1 - hEnt2):Length() or (hEnt1 - hEnt2):Length2D()
end
--This just return distance, if you use b3D as true it will return distance in 3 axis.
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetDirection = function(hEnt1, hEnt2, b3D)
    hEnt1 = type(hEnt1.GetAbsOrigin) == "function" and hEnt1:GetAbsOrigin() or hEnt1
    hEnt2 = type(hEnt2.GetAbsOrigin) == "function" and hEnt2:GetAbsOrigin() or hEnt2

    local iEnt1 = hEnt1.z
    local iEnt2 = hEnt2.z

    hEnt1.z = b3D and iEnt1 or 0
    hEnt2.z = b3D and iEnt2 or 0

    local vReturn = (hEnt1 - hEnt2):Normalized()

    hEnt1.z = iEnt1
    hEnt2.z = iEnt2

    return vReturn
end
--Same as distance but for direction.
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
SetDirectionByAngles = function(hUnit, vDirection) --Explained why I am using that in the first ability modifier.
    vDirection = VectorToAngles(vDirection)
    return hUnit:SetAbsAngles(vDirection[1], vDirection[2], vDirection[3])
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetClamped = function(nValue, nMin, nMax)
    return nValue <= nMin and nMin or (nValue >= nMax and nMax or nValue)
end
--Autoclamper if you want to use min max values and prevent errors.
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetLerped = function(nMin, nMax, fTime)
    return nMin + ( nMax - nMin ) * fTime
end
--Autolerper AKA GetLerped(1, 1000, 0.5), return 500.
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
TableLength = function(tTable)
    local i = 0
    if type(tTable) == "table" then
        for _ in pairs(tTable) do
            i = i + 1
        end
    end
    return i
end
--Needed for tables that include StringField keys, but I am using that for every table because with that the chances of making an error are much less than with #table.


--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------


--========================================--
local bIsRevoked = function(hUnit)
    local tRevokes = revokes or {}
    for nID, sRevokeModifier in pairs(tRevokes) do
        if hUnit:HasModifier(sRevokeModifier) then
            return true
        end
    end
end
--Added just for F/A 2 or other FATEs, revokes table exists in global scape inside your files with modifier name written.
--========================================--


--========================================--
--Return ability attribute registered, if not registered return nothing.
local GetAttribute = function(hUnit, sAttributeName)
    if IsNotNull(hUnit) then
        hUnit.____tAttributesTable = hUnit.____tAttributesTable or {}
        for _, hAbility in pairs(hUnit.____tAttributesTable) do
            if IsNotNull(hAbility)
                and hAbility:GetAbilityName() == sAttributeName then
                return hAbility
            end
        end
    end
    return nil
end
--========================================--


--========================================--
--This function helps to check the attribute registered in attribute table or not.
local GetAttributeValue = function(hUnit, sAttributeName, sKeyName, nLevel, nDefaultValue)
    --NOTE: -2 becomes 0 return as with GetSpecialValueFor correctly....seems to be.

    nLevel = nLevel or -1
    if nLevel == 0 then
        nLevel = -2
    elseif nLevel > 0 then
        nLevel = nLevel - 1
    end
    --type(nLevel) == "number" and ( nLevel == 0 and -2 or ( nLevel - 1 ) ) or -1

    local hAttributeAbility = GetAttribute(hUnit, sAttributeName)
    if IsNotNull(hAttributeAbility) then
        return hAttributeAbility:GetLevelSpecialValueFor(sKeyName, nLevel)
    end
    return nDefaultValue or 0 --Return default value you set or if not set return 0, basically useful for multiplicative moments when you want for example damage*getattributevalue, but value is 0 so we have to auto-set 1 for correct calculation.
end
--========================================--


--========================================--
--This can help to get value from Combo for example, by simple call this function, added specially for your hero basically.
local GetAbilityValue = function(hUnit, sAbilityName, sKeyName, nLevel, nDefaultValue)
    nLevel = nLevel or -1
    if nLevel == 0 then
        nLevel = -2
    elseif nLevel > 0 then
        nLevel = nLevel - 1
    end

    if IsNotNull(hUnit) then
        local hAbility = hUnit:FindAbilityByName(sAbilityName)
        if IsNotNull(hAbility) then
            return hAbility:GetLevelSpecialValueFor(sKeyName, nLevel)
        end
    end
    return nDefaultValue or 0
end
--========================================--


--========================================--
--CRINGE fix, added specifically for F/A 2 or other FATEs because trees shouldn't be destroyed there.
local fApplyKnockbackSpecial = function(hTarget, nDistance, nDuration, vKnockDirection)
    --=================================--
    local fStopFunction = function(hUnit, sTimerName)
        if type(sTimerName) == "string" then
            Timers:RemoveTimer(sTimerName)
        end

        hUnit:OnPreBounce(nil)
        hUnit:SetBounceMultiplier(0)
        hUnit:PreventDI(false)
        hUnit:SetPhysicsVelocity(Vector(0,0,0))
        hUnit:OnPhysicsFrame(nil)
        hUnit:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
        FindClearSpaceForUnit(hUnit, hUnit:GetAbsOrigin(), true)
    end
    --=================================--
    if not IsKnockbackImmune(hTarget) then
        local sTimerNameUnique = hTarget:GetUnitName()..DoUniqueString(tostring(hTarget:entindex()))
        --=================================--
        hTarget:InterruptMotionControllers(false)

        local hPhysicsThingReturn = Physics:Unit(hTarget)

        hTarget:PreventDI(true)
        hTarget:SetPhysicsFriction(0)
        hTarget:SetPhysicsVelocity(vKnockDirection * ( nDistance / nDuration ))
        hTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
        hTarget:SetGroundBehavior(PHYSICS_GROUND_LOCK)
        hTarget:FollowNavMesh(true)
        --=================================--
        Timers:CreateTimer(sTimerNameUnique,
        {
            endTime  = nDuration,
            callback = function()
                fStopFunction(hTarget, nil)
            end
        })
        --=================================--
        hTarget:OnPhysicsFrame(function(hUnit)
            if GridNav:IsNearbyTree(hUnit:GetAbsOrigin(), hUnit:BoundingRadius2D() * 2, true) then
                fStopFunction(hUnit, sTimerNameUnique)
            end
        end)
        --=================================--
        hTarget:OnPreBounce(function(hUnit, vNormal)
            fStopFunction(hUnit, sTimerNameUnique)
        end)
    end
end
--========================================--


--========================================--
--NOTE: Function created to emit zlodemon_true voices.
local EmitZlodemonTrueSound = function(sSoundName)
    LoopOverPlayers(function(player, playerID, playerHero)
        if playerHero.zlodemon == true and playerHero == self:GetCaster() then
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound=sSoundName})
        end
    end)
end
--========================================--


--========================================--
--NOTE: Function to handle swapping between models in-game.
if IsServer() then
    if type(saito_abilities_chat_event) == "number" then
        StopListeningToGameEvent(saito_abilities_chat_event)
    end
    --===--
    _G.saito_abilities_chat_event = ListenToGameEvent("player_chat", function(tEventTable)
        local nPlayerID = tEventTable.playerid
        local sText     = tEventTable.text
        local hHero     = PlayerResource:GetSelectedHeroEntity(nPlayerID)
        if not (hHero:GetName() == "npc_dota_hero_terrorblade") then
            return
        end
        if IsNotNull(hHero) then
            if sText == "-saito1" then
                hHero:RemoveModifierByName("modifier_saito_model_swap")
                Say(hHero, "Hajime-chan changed to the COAT version.", false)
            end
            if sText == "-saito2" then
                hHero:AddNewModifier(hHero, nil, "modifier_saito_model_swap", {})
                Say(hHero, "Hajime-chan changed to the HAORI version.", false)
            end
        end
    end, nil)
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_model_swap", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_model_swap = modifier_saito_model_swap or class({})

function modifier_saito_model_swap:IsHidden()                                                                       return true end
function modifier_saito_model_swap:IsDebuff()                                                                       return false end
function modifier_saito_model_swap:IsPurgable()                                                                     return false end
function modifier_saito_model_swap:IsPurgeException()                                                               return false end
function modifier_saito_model_swap:RemoveOnDeath()                                                                  return false end
function modifier_saito_model_swap:IsDimensionException()                                                           return true end
function modifier_saito_model_swap:AllowIllusionDuplicate()                                                         return true end
function modifier_saito_model_swap:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_saito_model_swap:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_saito_model_swap:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_saito_model_swap:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.sModelName = "models/heroes/saito_1/saito_1_mdoc.vmdl"
    end
end
function modifier_saito_model_swap:OnRefresh(hTable)
    self:OnCreated(hTable)
end
--========================================--


---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_attributes", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_attributes = modifier_saito_attributes or class({})

function modifier_saito_attributes:IsHidden()                                                                       return true end
function modifier_saito_attributes:IsDebuff()                                                                       return false end
function modifier_saito_attributes:IsPurgable()                                                                     return false end
function modifier_saito_attributes:IsPurgeException()                                                               return false end
function modifier_saito_attributes:RemoveOnDeath()                                                                  return false end
function modifier_saito_attributes:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
--function modifier_saito_attributes:GetAttributes()                                                                  return MODIFIER_ATTRIBUTE_MULTIPLE end
--MODIFIER_ATTRIBUTE_MULTIPLE helps to make copies of modifiers on your hero, they are hidden but helpful, disabled for now as we handle all attributes with one modifier.
--You can uncomment that and use these modifiers if you want to add simple properties with the declared functions, example of how to use is below.
function modifier_saito_attributes:DeclareFunctions()
    local tFunc =   {
                        --MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --Uncomment and write the correct keys\values in the GetAttributeValue function.
                    }
    return tFunc
end
function modifier_saito_attributes:GetModifierBonusStats_Intellect(keys)
    if IsNotNull(self.hParent)
        and IsNotNull(self.hAbility)
        and self.hAbility:GetAbilityName() == "any_attribute" then
        return GetAttributeValue(self.hParent, "any_attribute", "any_value_from_attribute", -1, 0)
    end
end
function modifier_saito_attributes:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.hParent.____tAttributesTable = self.hParent.____tAttributesTable or {}

    if IsNotNull(self.hAbility) then
        table.insert(self.hParent.____tAttributesTable, self.hAbility)
    end
end
function modifier_saito_attributes:OnRefresh(tTable)
    self:OnCreated(tTable)
end










--NOTE1: Basically if what you're looking for is universal and usable for all Servants to be handled on client values, AKA quick build client-server setup.
--NOTE2: This means the checkers above, modifiers and example of usage for the Attributes abilities above.
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_attribute_freedom = saito_attribute_freedom or class({})

function saito_attribute_freedom:IsStealable()                                                                      return true end
function saito_attribute_freedom:IsHiddenWhenStolen()                                                               return false end
function saito_attribute_freedom:OnSpellStart()
    local hCaster     = self:GetCaster()
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(hCaster:GetPlayerOwnerID())

    --print(hPlayerHero:GetUnitName())
    local hMaster_1 = hPlayerHero.MasterUnit --Handling master units which in global scope, added to your selected hero.
    local hMaster_2 = hPlayerHero.MasterUnit2 --Handling master units which in global scope, added to your selected hero.

    if IsNotNull(hPlayerHero) then
        --There we check if the hero died we can't add a modifier so just waiting when the hero is alive and add the modifier.
        Timers:CreateTimer(0, function()
            if hPlayerHero:IsAlive()
                and not IsNotNull(GetAttribute(hPlayerHero, self:GetAbilityName())) then
                hPlayerHero:AddNewModifier(hCaster, self, "modifier_saito_attributes", {})
                return
            end
            return 0.1
        end)

        if IsNotNull(hMaster_1) then
            hMaster_1:SetMana(hMaster_2:GetMana()) --Set mana for the second master to be equal as the current master mana for the first master.

            --hMaster_1:SpendMana(self:GetManaCost(-1), self)
        end

        if type(self.OnAfterSpellStart) == "function" then
            self:OnAfterSpellStart(hPlayerHero)
        end
    end
end 
function saito_attribute_freedom:OnAfterSpellStart(hPlayerHero)
    --This function can be used if you want to do some bonus things for the hero when the attribute is learned.
end

--class(saito_attribute_freedom)
--Explanation:
--As you can see below when ability copy class, it has all functions inside so we can call OnSpellStart in any attribute with the code above.
--But if we write OnSpellStart below, we will override function and it won't work, so for that created function that calls on OnSpellStart named OnAfterSpellStart, basically just use that.
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_attribute_sword = saito_attribute_sword or class(saito_attribute_freedom)

function saito_attribute_sword:OnAfterSpellStart(hPlayerHero)
end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_attribute_memoir = saito_attribute_memoir or class(saito_attribute_freedom)

function saito_attribute_memoir:OnAfterSpellStart(hPlayerHero)
end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_attribute_freestyle = saito_attribute_freestyle or class(saito_attribute_freedom)

function saito_attribute_freestyle:OnAfterSpellStart(hPlayerHero)
end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_attribute_kunishige = saito_attribute_kunishige or class(saito_attribute_freedom)

function saito_attribute_kunishige:OnAfterSpellStart(hPlayerHero)
end




















local nSTATS_REQUIRED = 29.1



--NOTE: This is a custom checker with lots of options, now it is too hardcoded because I fixed a lot of params that weren't in the D2 FATE yet, not the final version but ideal 80%, now should able to use combo abilities as an indicator.
local CheckComboIsReadyIncrement = function(hUnit, iPreviousStackShouldBe)
    local iPreviousStackShouldBe = iPreviousStackShouldBe or 0
    if IsNotNull(hUnit)
        and hUnit:GetStrength() >= nSTATS_REQUIRED
        and hUnit:GetAgility() >= nSTATS_REQUIRED
        and hUnit:GetIntellect() >= nSTATS_REQUIRED then
        local iStacksNow = hUnit:GetModifierStackCount("modifier_saito_style_combo_indicator", hUnit)
        if iStacksNow == iPreviousStackShouldBe then
            return hUnit:SetModifierStackCount("modifier_saito_style_combo_indicator", hUnit, iStacksNow + 1)
        end
    end
end


---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_style_combo_indicator", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_style_combo_indicator = modifier_saito_style_combo_indicator or class({})

function modifier_saito_style_combo_indicator:IsHidden()                                                            return self:GetDuration() <= -1 end
function modifier_saito_style_combo_indicator:IsDebuff()                                                            return true end
function modifier_saito_style_combo_indicator:IsPurgable()                                                          return false end
function modifier_saito_style_combo_indicator:IsPurgeException()                                                    return false end
function modifier_saito_style_combo_indicator:RemoveOnDeath()                                                       return false end
function modifier_saito_style_combo_indicator:DestroyOnExpire()                                                     return false end
function modifier_saito_style_combo_indicator:OnStackCountChanged(iOldStacks)
    if IsServer() then
        --NOTE: The previous crashes were due to overloop when setstackcount checks setstackcount...
        --========================================-- --NOTE: Prevention because if swapped ability is on cooldown, it shouldn't be swapped.
        local hAbilityForSwap_0 = self.hParent:FindAbilityByName(self.sAbilityForSwap_0)
        local hAbilityForSwap_1 = self.hParent:FindAbilityByName(self.sAbilityForSwap_1)

        if not self.bPreventStacksOverloop
            and ( not IsNotNull(hAbilityForSwap_0)
                or not hAbilityForSwap_0:IsCooldownReady() and iOldStacks ~= 0 ) --Improved to check prevention if the first ability is the ability to swap.
            and ( not IsNotNull(hAbilityForSwap_1)
                or not hAbilityForSwap_1:IsCooldownReady()
                or not hAbilityForSwap_1:IsHidden() ) then
            self.bPreventStacksOverloop = true --NOTE: Prevent crashes, can't remember when it happened but somehow I fixed that XDD.
            self:SetStackCount(0)
            self.bPreventStacksOverloop = false
            return nil
        end
        --========================================--
        local iStacksNow = self:GetStackCount()

        if iOldStacks <= 0 and iStacksNow > 0 then
            self.bLocalComboStepsTime = true

            self:SetDuration(self.fStepsDuration, true)
        end

        if iStacksNow >= self.iComboStepsReadyCount then
            self.bLocalComboStepsTime     = false
            self.fLocalComboStepsTime     = 0
            self.bLocalComboAvailableTime = true

            self:SetStackCount(0) --NOTE: Could crash if set count anything but 0, not sure but could be possible.

            self:ComboToSlot(true)
        end
    end
end
function modifier_saito_style_combo_indicator:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        --========================================--
        if not self.hParent:IsRealHero() then --NOTE: Prevention of applying on Masters.
            return self:Destroy()
        end
        --========================================--
        self.fStepsDuration        = self.hAbility:GetSpecialValueFor("activation_steps_duration")
        self.fComboDuration        = self.hAbility:GetSpecialValueFor("activation_duration")
        self.iComboStepsReadyCount = self.hAbility:GetSpecialValueFor("activation_steps")

        self.fThinkInterval = FrameTime()

        self.bLocalComboStepsTime     = self.bLocalComboStepsTime or false
        self.fLocalComboStepsTime     = self.fLocalComboStepsTime or 0
        self.bLocalComboAvailableTime = self.bLocalComboAvailableTime or false
        self.fLocalComboAvailableTime = self.fLocalComboAvailableTime or 0

        self.bLocalComboReleased = self.bLocalComboReleased or false

        self.sAbilityForSwap_0 = "saito_fds"
        self.sAbilityForSwap_1 = self.hAbility:GetAbilityName()

        self:StartIntervalThink(self.fThinkInterval)

        --print(self:GetDuration(), "PEPE")
    end
end
function modifier_saito_style_combo_indicator:OnRefresh(tTable)
    self:OnCreated(tTable) --NOTE: May cause some bugs but looks like is fixed.
end
function modifier_saito_style_combo_indicator:OnIntervalThink()
    if IsServer() then
        local fDuration          = self:GetDuration()
        local fSelfRemaining     = self:GetRemainingTime()
        local fCooldownRemaining = self.hAbility:GetCooldownTimeRemaining()
        --========================================--
        if self.bLocalComboStepsTime then
            self.fLocalComboStepsTime = self.fLocalComboStepsTime + self.fThinkInterval
            if self.fLocalComboStepsTime >= self.fStepsDuration then
                self.bLocalComboStepsTime = false
                self.fLocalComboStepsTime = 0

                self:SetStackCount(0)
            end
        elseif self.bLocalComboAvailableTime then
            self.fLocalComboAvailableTime = self.fLocalComboAvailableTime + self.fThinkInterval
            if self.fLocalComboAvailableTime >= self.fComboDuration
                or ( fCooldownRemaining > 0 ) then --NOTE: Released Combo fix swapping.
                self.bLocalComboAvailableTime = false
                self.fLocalComboAvailableTime = 0

                self.bLocalComboReleased = ( fCooldownRemaining > 0 )--IDK HOW IT FIXED DUPLICATE IN -1 CALL DURATION..

                self:ComboToSlot(false)

                --print("KEKW", fCooldownRemaining)
            end
        end
        --========================================-- --NOTE: Fix visibility in Master.
        local bSetMasterComboTime = false
        --========================================-- fSelfRemaining > 0 or
        if ( fCooldownRemaining <= 0 and ( fDuration > -1 ) and not ( self.bLocalComboStepsTime or self.bLocalComboAvailableTime ) ) then
            self:SetDuration(-1, true)
            --print("SETTING DURATION -1", fSelfRemaining, fDuration, self.bLocalComboReleased, fCooldownRemaining)
            bSetMasterComboTime = true

            if fCooldownRemaining <= 0 and fDuration >= self.hAbility:GetCooldown(-1) then
                EmitSoundOn("Saito.Style.Cast", self.hParent) --Sound when combo is ready. --Just for cool effect ready.
            end
        elseif ( ( fSelfRemaining <= 0 and fCooldownRemaining > 0 ) or ( self.bLocalComboReleased ) ) then
            --========================================-- --NOTE: Ultimate cooldown setup (swapped) because it's in FATE...
            local hSwappedAbility = self.hParent:FindAbilityByName(self.sAbilityForSwap_0)
            if IsNotNull(hSwappedAbility)
                and hSwappedAbility:IsTrained()
                and hSwappedAbility:IsCooldownReady()
                and self.bLocalComboReleased then
                hSwappedAbility:UseResources(false, false, false, true)
            end

            self.bLocalComboReleased = false

            self:SetDuration(fCooldownRemaining, true)

            --print("SETTING DURATION TO DURATION 11", fCooldownRemaining, self.bLocalComboReleased)
            bSetMasterComboTime = true
        end
        --========================================--
        if bSetMasterComboTime then --LOCAL STORAGE SO WON'T BE IN THE NEXT FRAME BUT CLEAR DEFINITELY FOR SURE.
            bSetMasterComboTime = false
            local hComboOnMaster = self.hParent.MasterUnit2
            if IsNotNull(hComboOnMaster) then
                hComboOnMaster = hComboOnMaster:FindAbilityByName(self.sAbilityForSwap_1)
                --========================================--
                if IsNotNull(hComboOnMaster) then
                    hComboOnMaster:EndCooldown()
                    hComboOnMaster:StartCooldown(fCooldownRemaining)
                end
            end
        end
    end
end
function modifier_saito_style_combo_indicator:ComboToSlot(bEnable)
    if IsServer() then
        if bEnable then
            self:SetDuration(self.fComboDuration, true)
        end
        return self.hParent:SwapAbilities(self.sAbilityForSwap_0, self.sAbilityForSwap_1, not bEnable, bEnable)
    end
end










---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_style = saito_style or class({})

function saito_style:GetIntrinsicModifierName()
    return "modifier_saito_style_combo_indicator" --Handle modifier in the combo itself and let it control with modifier properties instead.
end
function saito_style:OnSpellStart()
    local hCaster   = self:GetCaster()
    local nDuration = self:GetSpecialValueFor("duration")

    hCaster:AddNewModifier(hCaster, self, "modifier_saito_style_active", {duration = nDuration})
    hCaster:AddNewModifier(hCaster, self, "modifier_saito_blast_swap", {duration = self:GetSpecialValueFor("blast_duration")}) --To swap to the second combo ability.

    EmitGlobalSound("Saito.Style.Cast.Voice")
    EmitGlobalSound("Saito.Style.Cast")
    EmitZlodemonTrueSound("moskes_saito_combo")
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_style_active", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_style_active = modifier_saito_style_active or class({})

function modifier_saito_style_active:IsHidden()                                                                     return false end
function modifier_saito_style_active:IsDebuff()                                                                     return false end
function modifier_saito_style_active:IsPurgable()                                                                   return false end
function modifier_saito_style_active:IsPurgeException()                                                             return false end
function modifier_saito_style_active:RemoveOnDeath()                                                                return true end
function modifier_saito_style_active:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_EVENT_ON_TAKEDAMAGE
                    }
    return tFunc
end
function modifier_saito_style_active:OnTakeDamage(keys)
    if IsServer() then
        if keys.attacker == self.hParent
            and (not IsNotNull(keys.inflictor) or (not keys.inflictor:IsItem() and keys.inflictor ~= self.hAbility)) --Last check there > preventing crashes and triggering chance from damage of this ability instead.
            and UnitFilter( --This checks filter units for example you can put here settings AKA check non-invis and etc.
                            keys.unit,
                            self.nABILITY_TARGET_TEAM,
                            self.nABILITY_TARGET_TYPE,
                            self.nABILITY_TARGET_FLAGS,
                            self.nCASTER_TEAM
                            ) == UF_SUCCESS
            and RollPseudoRandomPercentage(self.nDamageChance, 1, self.hParent) then
            --and RollPercentage(self.nDamageChance) then --Rolls a number from 1 to 100 and returns true if the roll is less than or equal to the number specified.
            --giveUnitDataDrivenModifier(self.hParent, keys.unit, "silenced", self.nSilenceDuration)

            local nDamageDo = keys.unit:GetHealth() * self.nHPDamage

            DoDamage(self.hParent, keys.unit, nDamageDo, self.nDamageType, DOTA_DAMAGE_FLAG_NONE, self.hAbility, false)

            self:CreateEffect(keys.unit)
        end
    end
end
-- function modifier_saito_style_active:GetAbsorbSpell(keys) --It's just the default linken for D2. --Uncomment if want to use, commented because who knows maybe somewhere F/A 2 checks it out...
--     if IsServer() then
--         --Here write anything when linken procs.
--         return 1
--     end
-- end
function modifier_saito_style_active:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nDamageChance = self.hAbility:GetSpecialValueFor("damage_chance")
    --self.nSilenceDuration = self.hAbility:GetSpecialValueFor("silence_duration")

    self.nHPDamage = self.hAbility:GetSpecialValueFor("hp_damage") * 0.01

    self.nMaxLinkenProcs = self.hAbility:GetSpecialValueFor("max_linken_procs")

    if IsServer() then
        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self.nDamageType = self.hAbility:GetAbilityDamageType()

        self:SetStackCount(self.nMaxLinkenProcs)
    end
end
function modifier_saito_style_active:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_style_active:GetEffectName()
    return "particles/heroes/saito/saito_style_buff_new.vpcf"
end
function modifier_saito_style_active:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_saito_style_active:CreateEffect(hTarget)
    local sSlashPFX = "particles/heroes/saito/saito_style_proc.vpcf"
    local nSlashPFX =   ParticleManager:CreateParticle(sSlashPFX, PATTACH_ABSORIGIN_FOLLOW, hTarget)
                        ParticleManager:SetParticleControlEnt(
                                                                nSlashPFX,
                                                                1,
                                                                hTarget,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_hitloc",
                                                                Vector(0,0,0), -- unknown
                                                                false -- unknown, true
                                                            )
                        --ParticleManager:SetParticleControl(nSlashPFX, 0, hTarget:GetAbsOrigin())
                        ParticleManager:ReleaseParticleIndex(nSlashPFX)

    EmitSoundOn("Saito.Style.Proc", hTarget)
end
function modifier_saito_style_active:BlockSpellCheck()
    local nStacks = self:GetStackCount()
    self:DecrementStackCount()
    return nStacks > 0
end




















--========================================--
local tSaito_QWE =
{
    "saito_flashblade",
    "saito_steelwing",
    "saito_shadowslash",
}
--========================================--
local tSaito_QWE_2 =
{
    "saito_step",
    "saito_storm",
    "saito_vortex",
}
--========================================--
local tSaito_RR =
{
    "saito_formless_invis",
    "saito_formless_slash",
}
--========================================--
local UpgradeShared = function(hAbility, tSharedAbilities)
    local hUnit = hAbility:GetCaster()
    if IsNotNull(hUnit)
        and IsNotNull(hAbility) then
        local nLevel = hAbility:GetLevel()
        for _, sAbilityName in pairs(tSharedAbilities or {}) do
            local hAbilityShared = hUnit:FindAbilityByName(sAbilityName)
            if IsNotNull(hAbilityShared)
                and hAbilityShared:GetLevel() ~= nLevel then
                hAbilityShared:SetLevel(nLevel)
            end
        end
    end
end
--========================================--


---------------------------------------------------------------------------------------------------------------------
--Modifiers that only are needed for showing the radius normally and calculate how much you are using QWE's abilities and divide the values.
--Their stack modification controls from Saito F's ability which gives casting 3-7 times in a row.

LinkLuaModifier("modifier_saito_q_counter", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_w_counter", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_e_counter", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_q_counter = modifier_saito_q_counter or class({})

function modifier_saito_q_counter:IsHidden()                                                                        return false end --Change this to true if you want to hide it from the HUD basically.
function modifier_saito_q_counter:IsDebuff()                                                                        return false end
function modifier_saito_q_counter:IsPurgable()                                                                      return false end
function modifier_saito_q_counter:IsPurgeException()                                                                return false end
function modifier_saito_q_counter:RemoveOnDeath()                                                                   return false end
function modifier_saito_q_counter:GetPriority()                                                                     return MODIFIER_PRIORITY_HIGH end

modifier_saito_w_counter = modifier_saito_w_counter or class(modifier_saito_q_counter)

modifier_saito_e_counter = modifier_saito_e_counter or class(modifier_saito_q_counter)
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_flashblade = saito_flashblade or class({})

function saito_flashblade:IsStealable()                                                                             return true end --Basically not necessary in F/A 2, but adding everywhere just to be safe... This is Rubick's properties XDD
function saito_flashblade:IsHiddenWhenStolen()                                                                      return false end --Basically not necessary in F/A 2, but adding everywhere just to be safe... This is Rubick's properties XDD
function saito_flashblade:GetIntrinsicModifierName()
    return "modifier_saito_q_counter"
end
function saito_flashblade:OnUpgrade() --Call when ability is upgraded in any way AKA -setlevel or by player or LearnAbility or etc.
    if IsServer() then
        UpgradeShared(self, tSaito_QWE)
    end
end
-- function saito_flashblade:OnAbilityPhaseStart()
--     local hCaster = self:GetCaster()
--     return true
-- end
-- function saito_flashblade:OnAbilityPhaseInterrupted()
-- end
function saito_flashblade:GetAOERadius() --AOE radius is required to indicate which radius the ability basically has, and because we are using global point casting.
    local hCaster = self:GetCaster()

    local nDistance = self:GetSpecialValueFor("distance")
    local nCasts    = hCaster:GetModifierStackCount(self:GetIntrinsicModifierName(), hCaster) + 1
    if nCasts >= self:GetSpecialValueFor("repeat_halver_count_need") then
        nDistance = nDistance / nCasts
    end

    return nDistance
end
function saito_flashblade:GetBehavior() --Immediate behavior automatically zerofill cast time, bit.bor is an autosum possible flags and doesn't duplicate like e.g. simple summ AKA FLAG+FLAG == error.
    local nBehavior = tonumber(tostring(self.BaseClass.GetBehavior(self)))
    return bit.bor(nBehavior, self:GetCaster():HasModifier("modifier_saito_style_active") and DOTA_ABILITY_BEHAVIOR_IMMEDIATE or DOTA_ABILITY_BEHAVIOR_NONE)
end
function saito_flashblade:GetCooldown(nLevel)
    return self:GetCaster():HasModifier("modifier_saito_style_active")
           and self:GetSpecialValueFor("combo_cooldown")
           or self.BaseClass.GetCooldown(self, nLevel)
end
-- function saito_flashblade:GetCastPoint()
--     local hCaster = self:GetCaster()

--     local nCastPointIncreaser = 0.05
--     --Base class takes the value of KV == 0.1, then starting cast time.
--     return self.BaseClass.GetCastPoint(self) + ( hCaster:GetModifierStackCount("modifier_saito_fds_cast_controller", hCaster) * nCastPointIncreaser )
-- end
function saito_flashblade:OnSpellStart()
    local hCaster   = self:GetCaster()

    local nDuration = (self:GetAOERadius()/self:GetSpecialValueFor("speed")) + 0.1

    hCaster:AddNewModifier(hCaster, self, "modifier_saito_flashblade_motion", {duration = nDuration}) --Fixed interactions with abilities that lock the hero's location, such as Aestus Domus Aurea and Unreturning Formation: Stone Sentinel Maze.
    --hCaster:AddNewModifier(hCaster, self, "modifier_saito_flashblade_motion", {duration = 10}) --Duration is basically unnecessary but adding 10 seconds if something breaks it ends after 10 seconds.

    local nTurnRateDuration = GetAttributeValue(hCaster, "saito_attribute_freedom", "q_turn_rate_duration", -1, 0)
    if nTurnRateDuration > 0 then
        ProjectileManager:ProjectileDodge(hCaster)

        hCaster:AddNewModifier(hCaster, self, "modifier_saito_flashblade_turn_rate", {duration = nTurnRateDuration})
    end

    if bit.band(self:GetBehavior(), DOTA_ABILITY_BEHAVIOR_IMMEDIATE) ~= 0 then
        hCaster:StartGestureWithPlaybackRate(self:GetCastAnimation(), 2.0)
    end
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_flashblade_motion", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_HORIZONTAL) --Using the motion type activates the ApplyMotionController property for us.
--If you change the type under your Workshop Tools booted, it can not work, so better reload or full reload if still error, check always, GabeN BTW.
modifier_saito_flashblade_motion = modifier_saito_flashblade_motion or class({})

function modifier_saito_flashblade_motion:IsHidden()                                                                return true end
function modifier_saito_flashblade_motion:IsDebuff()                                                                return false end
function modifier_saito_flashblade_motion:IsPurgable()                                                              return false end
function modifier_saito_flashblade_motion:IsPurgeException()                                                        return false end
function modifier_saito_flashblade_motion:RemoveOnDeath()                                                           return true end --Necessary because we want to remove it on death, but if you want you can make it false and the corpse will fly if it dies when flying.
function modifier_saito_flashblade_motion:CheckState()
    local tState =  {
                        [MODIFIER_STATE_STUNNED] = true, --Basically for disable any actions all of them use the stun modifier.
                        -- [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        -- [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true, --Added for testing, can uncomment if there are some errors in the future.
                    }
    return tState
end
function modifier_saito_flashblade_motion:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_OVERRIDE_ANIMATION
                    }
    return tFunc
end
function modifier_saito_flashblade_motion:GetOverrideAnimation(keys) --Animation that will loop when you are flying.
    return ACT_DOTA_OVERRIDE_ABILITY_1
end
function modifier_saito_flashblade_motion:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nRadius = self.hAbility:GetAOERadius()

    self.nSpeed = self.hAbility:GetSpecialValueFor("speed")

    self.nImageRootDuration = self.hAbility:GetSpecialValueFor("image_root_duration")
    self.nImageDuration     = self.hAbility:GetSpecialValueFor("image_duration")
    self.nImageRadius       = self.hAbility:GetSpecialValueFor("image_radius")
    self.nImageDamage       = self.hAbility:GetSpecialValueFor("image_damage") + ( GetAttributeValue(self.hCaster, "saito_attribute_sword", "qwe_hero_level_damage", -1, 0) * self.hCaster:GetLevel() )
    self.nImageCreationDist = self.hAbility:GetSpecialValueFor("image_creation_dist")

    self.nAttr_KnockUPDuration = GetAttributeValue(self.hCaster, "saito_attribute_freedom", "q_knock_up_duration", -1, 0)
    self.nAttr_KnockUPHeight   = GetAttributeValue(self.hCaster, "saito_attribute_freedom", "q_knock_up_height", -1, 0)

    --========================--
    local nCastsDone = self.hCaster:GetModifierStackCount(self.hAbility:GetIntrinsicModifierName(), self.hCaster) + 1  --To reduce the damage by number of cast done.
    if nCastsDone >= self.hAbility:GetSpecialValueFor("repeat_halver_count_need") then
        self.nImageDamage = self.nImageDamage / nCastsDone
    end
    --========================--

    if IsServer() then --Function basically that can only be called on the server side.
        self.nDamageType           = self.hAbility:GetAbilityDamageType()

        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self.vStartLoc = self.hParent:GetAbsOrigin()

        self.vPoint = self.hAbility:GetCursorPosition() + (self.hParent:GetForwardVector() * 10) --Added forward vector solving problem when your hero looks at the ground xDD (turns around and sort of swims).

        self.vMainDirection = GetDirection(self.vPoint, self.vStartLoc)
        self.vMainDistance  = GetDistance(self.vPoint, self.vStartLoc)

        SetDirectionByAngles(self.hParent, self.vMainDirection)
        self.hParent:FaceTowards(self.vPoint) --Post redirection prevention.

        if not self:ApplyHorizontalMotionController() then --If false then the modifier will be immediately destroyed, basically this function ApplyController. You can still use OnIntervalThink, because motion uses a different thinker at a fixed rate.
            self:Destroy()
        end

        if not self.nDashPFX then
            self.nDashPFX =     ParticleManager:CreateParticle("particles/heroes/saito/saito_flashblade_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                                ParticleManager:SetParticleControlEnt(
                                                                        self.nDashPFX,
                                                                        0,
                                                                        self.hParent,
                                                                        PATTACH_POINT_FOLLOW,
                                                                        "attach_hitloc",
                                                                        Vector(0,0,0), -- unknown
                                                                        true -- unknown, true
                                                                    )

            self:AddParticle(self.nDashPFX, false, false, -1, false, false)
        end

        self.sEmitSound = "Saito.Flashblade.Cast"
        self.hParent:EmitSound(self.sEmitSound)

        EmitZlodemonTrueSound("moskes_saito_q")
    end
end
function modifier_saito_flashblade_motion:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_flashblade_motion:OnHorizontalMotionInterrupted()
    if IsServer() then
        self.hParent:RemoveHorizontalMotionController(self) --This is basically necessary when another motion interruptions happens to you, in F/A 2 basically nothing that can't interrupt your hero, as many use Physics, but you can write special custom manipulations in update motion and interrupt it if anything happens.
    end
end
function modifier_saito_flashblade_motion:UpdateHorizontalMotion(hUnit, nTime)
    if IsServer() then
        local vCurrentLoc = hUnit:GetAbsOrigin()

        local vDirection = self.vMainDirection

        local nDistancePerTick = self.nSpeed * nTime
        local nMaxDistance     = self.vMainDistance > self.nRadius and self.nRadius or self.vMainDistance

        local nMinUnitsStep = 10
        local nStepsCount   = math.ceil(nDistancePerTick / nMinUnitsStep)

        local bShouldDestroy = false

        self.nImagesCreated = self.nImagesCreated or 0
        --A bit hardcoded but it is really code that prevents a lot of situations with obstruction positioning... and helps calculate the correct distance for image creation.
        --Spent a lot of time on this PEPE thing because it is about how to avoid ANY CRINGE situation.
        for nStep = 1, nStepsCount do
            nDistancePerTick = ( nMinUnitsStep * nStep )

            local vNextStepPos  = vCurrentLoc + vDirection * nDistancePerTick
            local vNextStepDist = GetDistance(vNextStepPos, self.vStartLoc)

            if not GridNav:IsTraversable(vNextStepPos) or GridNav:IsBlocked(vNextStepPos) or vNextStepDist > nMaxDistance then
                bShouldDestroy = true
                break
            else
                --GridNav:DestroyTreesAroundPoint(vNextStepPos, self.nImageRadius, false) --Just to look cool like a cut tree with a slash.

                if vNextStepDist >= ( self.nImageCreationDist + ( self.nImageCreationDist * self.nImagesCreated ) ) then
                    self.nImagesCreated = self.nImagesCreated + 1
                    self:DoEffect(hUnit, vNextStepPos)
                end
            end
        end

        local vNextMovePoint = vCurrentLoc + vDirection * nDistancePerTick --Get next position based on interval tick time and speed.

        --self:DoEffect(hUnit, vNextMovePoint)
        --print(GridNav:FindPathLength(self.vStartLoc, self.vPoint), GetDistance(self.vStartLoc, self.vPoint, true), hUnit:BoundingRadius2D(), "PEPE")
        hUnit:SetAbsOrigin(vNextMovePoint) --Settings for next position.
        --If you want to change direction for hero while sliding, never use in motions based SetForwardvector, it will interrupt your motion controller, if you use it in OnCreated and OnRefresh will happen, you will have crashes.
        --I added my special overrided angle function for that in self:oncreated, it helps to turn the hero for example when your cast time is 0.
        if bShouldDestroy then
            self:Destroy()
        end
    end
end
function modifier_saito_flashblade_motion:OnDestroy()
    if IsServer() then
       --FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true) --Only for resolving possible errors by finding clear space.
       --Uncomment if there will be any problem with that in the future.
       self.hParent:RemoveGesture(self:GetOverrideAnimation()) --This line is necessary to prevent animation loop issues when modifiers are not exist but you are still animated.
    end
end
function modifier_saito_flashblade_motion:DoEffect(hUnit, vPosition)
    local sImagePFX = "particles/heroes/saito/saito_flashblade_image.vpcf"

    EmitSoundOnLocationWithCaster(vPosition, "Saito.Flashblade.Impact", hUnit)

    local hEntities = FindUnitsInRadius(
                                            self.nCASTER_TEAM,
                                            vPosition,
                                            nil,
                                            self.nImageRadius,
                                            self.nABILITY_TARGET_TEAM,
                                            self.nABILITY_TARGET_TYPE,
                                            self.nABILITY_TARGET_FLAGS,
                                            FIND_CLOSEST,
                                            false
                                        )
    --=================================--
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity) then
            if self.nAttr_KnockUPDuration > 0 then
                ApplyAirborneOnly(hEntity, self.nAttr_KnockUPHeight / self.nAttr_KnockUPDuration, self.nAttr_KnockUPDuration, nil)
                --fApplyKnockbackSpecial(hEntity, self.nAttr_KnockUPHeight, self.nAttr_KnockUPDuration, hEntity:GetUpVector())
                --=================================--
                giveUnitDataDrivenModifier(self.hCaster, hEntity, "stunned", self.nAttr_KnockUPDuration)
            end
            --=================================--
            giveUnitDataDrivenModifier(self.hCaster, hEntity, "rooted", self.nImageRootDuration)
            --=================================--
            --giveUnitDataDrivenModifier(self.hCaster, hEntity, "locked", self.nImageRootDuration)
            --=================================--
            DoDamage(self.hCaster, hEntity, self.nImageDamage, self.nDamageType, DOTA_DAMAGE_FLAG_NONE, self.hAbility, false)

            EmitSoundOn("Hero_Saito.Attack", hEntity)
        end
    end
    --=================================--
    -- Create Particle
    local nImagePFX =   ParticleManager:CreateParticle( sImagePFX, PATTACH_CUSTOMORIGIN, hUnit )
                        ParticleManager:SetParticleControl( nImagePFX, 0, vPosition )
                        ParticleManager:SetParticleControlForward( nImagePFX, 0, hUnit:GetForwardVector() )
                        ParticleManager:SetParticleControlEnt(
                            nImagePFX,
                            1,
                            hUnit,
                            PATTACH_POINT_FOLLOW,
                            "attach_hitloc",
                            Vector(0,0,0), -- unknown
                            true -- unknown, true
                        )
                        ParticleManager:SetParticleControl( nImagePFX, 2, Vector( 6, hUnit:GetModelScale(), 0 ) )
                        ParticleManager:SetParticleControlEnt(
                            nImagePFX,
                            11,
                            hUnit,
                            PATTACH_POINT_FOLLOW,
                            "attach_hitloc",
                            Vector(0,0,0), -- unknown
                            true -- unknown, true
                        )

    --Releasing and clear cache and destroy particles.
    Timers:CreateTimer(self.nImageDuration, function()
        if type(nImagePFX) == "number" then
            ParticleManager:DestroyParticle(nImagePFX, false)
            ParticleManager:ReleaseParticleIndex(nImagePFX)
        end
    end)
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_flashblade_turn_rate", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_flashblade_turn_rate = modifier_saito_flashblade_turn_rate or class({})

function modifier_saito_flashblade_turn_rate:IsHidden()                                                             return false end
function modifier_saito_flashblade_turn_rate:IsDebuff()                                                             return false end
function modifier_saito_flashblade_turn_rate:IsPurgable()                                                           return true end
function modifier_saito_flashblade_turn_rate:IsPurgeException()                                                     return true end
function modifier_saito_flashblade_turn_rate:RemoveOnDeath()                                                        return true end
function modifier_saito_flashblade_turn_rate:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_TURN_RATE_OVERRIDE
                    }
    return tFunc
end
function modifier_saito_flashblade_turn_rate:GetModifierTurnRate_Override(keys)
    return self.nTurnRate
end
function modifier_saito_flashblade_turn_rate:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nTurnRate = GetAttributeValue(self.hCaster, "saito_attribute_freedom", "q_turn_rate", -1, 0)
end
function modifier_saito_flashblade_turn_rate:OnRefresh(tTable)
    self:OnCreated(tTable)
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_steelwing = saito_steelwing or class({})

function saito_steelwing:GetIntrinsicModifierName()
    return "modifier_saito_w_counter"
end
function saito_steelwing:OnUpgrade() --Call when ability is upgraded in any way AKA -setlevel or by player or LearnAbility or etc.
    if IsServer() then
        UpgradeShared(self, tSaito_QWE)
    end
end
function saito_steelwing:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function saito_steelwing:GetBehavior() --Immediate behavior automatically zerofill cast time.
    local nBehavior = tonumber(tostring(self.BaseClass.GetBehavior(self)))
    return bit.bor(nBehavior, self:GetCaster():HasModifier("modifier_saito_style_active") and DOTA_ABILITY_BEHAVIOR_IMMEDIATE or DOTA_ABILITY_BEHAVIOR_NONE)
end
function saito_steelwing:GetCooldown(nLevel)
    return self:GetCaster():HasModifier("modifier_saito_style_active")
           and self:GetSpecialValueFor("combo_cooldown")
           or self.BaseClass.GetCooldown(self, nLevel)
end
-- function saito_steelwing:GetCastPoint()
--     local hCaster = self:GetCaster()

--     local nCastPointIncreaser = 0.05
--     --Base class takes the value of KV == 0.1, then starting cast time.
--     return self.BaseClass.GetCastPoint(self) + ( hCaster:GetModifierStackCount("modifier_saito_fds_cast_controller", hCaster) * nCastPointIncreaser )
-- end
function saito_steelwing:OnSpellStart()
    local hCaster = self:GetCaster()
    local vCasterLoc = hCaster:GetAbsOrigin()

    local nDamageType = self:GetAbilityDamageType()

    local nRadius = self:GetAOERadius()

    --local nKnockDistance = self:GetSpecialValueFor("knock_distance")

    local nStunDuration  = self:GetSpecialValueFor("stun_duration")
    local nDamage        = self:GetSpecialValueFor("damage") + ( GetAttributeValue(hCaster, "saito_attribute_sword", "qwe_hero_level_damage", -1, 0) * hCaster:GetLevel() )

    local nCastsDone = hCaster:GetModifierStackCount(self:GetIntrinsicModifierName(), hCaster) + 1  --To reduce the damage by number of cast done.
    if nCastsDone >= self:GetSpecialValueFor("repeat_halver_count_need") then
        nStunDuration = nStunDuration / nCastsDone
        nDamage = nDamage / nCastsDone
    end

    local nAttr_MSS_Duraiton = GetAttributeValue(hCaster, "saito_attribute_freedom", "w_ms_slow_duration", -1, 0)

    local hEntities = FindUnitsInRadius(
                                            hCaster:GetTeamNumber(),
                                            vCasterLoc,
                                            nil,
                                            nRadius,
                                            self:GetAbilityTargetTeam(),
                                            self:GetAbilityTargetType(),
                                            self:GetAbilityTargetFlags(),
                                            FIND_CLOSEST,
                                            false
                                        )
    --=================================--
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity) then
            --=================================--
            fApplyKnockbackSpecial(hEntity, nRadius - GetDistance(hEntity, vCasterLoc), 0.2, GetDirection(hEntity, vCasterLoc))
            --=================================--
            giveUnitDataDrivenModifier(hCaster, hEntity, "stunned", nStunDuration)
            --=================================--
            if nAttr_MSS_Duraiton > 0 then
                hEntity:AddNewModifier(hCaster, self, "modifier_saito_steelwing_mss", {duration = nAttr_MSS_Duraiton})
            end
            --=================================--
            DoDamage(hCaster, hEntity, nDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
        end
    end

    self:DoClapEffect(hCaster)

    if bit.band(self:GetBehavior(), DOTA_ABILITY_BEHAVIOR_IMMEDIATE) ~= 0 then
        hCaster:StartGestureWithPlaybackRate(self:GetCastAnimation(), 2.0)
    end
end
function saito_steelwing:DoClapEffect(hCaster)
    local nClapPFX =    ParticleManager:CreateParticle("particles/heroes/saito/saito_steelwing_clap.vpcf", PATTACH_WORLDORIGIN, nil)
                        ParticleManager:SetParticleControlForward(nClapPFX, 0, hCaster:GetForwardVector())
                        ParticleManager:SetParticleControl(nClapPFX, 0, hCaster:GetAbsOrigin())
                        ParticleManager:SetParticleControl(nClapPFX, 1, Vector(self:GetAOERadius(), 0, 0))
                        ParticleManager:ReleaseParticleIndex(nClapPFX)

    hCaster:EmitSound("Saito.Steelwing.Cast")
    EmitZlodemonTrueSound("moskes_saito_w")
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_steelwing_mss", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE) --mss == move speed slow

modifier_saito_steelwing_mss = modifier_saito_steelwing_mss or class({})

function modifier_saito_steelwing_mss:IsHidden()                                                                    return false end
function modifier_saito_steelwing_mss:IsDebuff()                                                                    return true end
function modifier_saito_steelwing_mss:IsPurgable()                                                                  return true end
function modifier_saito_steelwing_mss:IsPurgeException()                                                            return true end
function modifier_saito_steelwing_mss:RemoveOnDeath()                                                               return true end
function modifier_saito_steelwing_mss:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
                    }
    return tFunc
end
function modifier_saito_steelwing_mss:GetModifierMoveSpeedBonus_Percentage(keys)
    return self.nMSSlow
end
function modifier_saito_steelwing_mss:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nMSSlow = GetAttributeValue(self.hCaster, "saito_attribute_freedom", "w_ms_slow", -1, 0)
end
function modifier_saito_steelwing_mss:OnRefresh(tTable)
    self:OnCreated(tTable)
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_shadowslash = saito_shadowslash or class({})

function saito_shadowslash:GetIntrinsicModifierName()
    return "modifier_saito_e_counter"
end
function saito_shadowslash:OnUpgrade() --Call when ability is upgraded in any way AKA -setlevel or by player or LearnAbility or etc.
    if IsServer() then
        UpgradeShared(self, tSaito_QWE)
    end
end
function saito_shadowslash:GetAOERadius()
    local hCaster     = self:GetCaster()
    local nPullRadius = self:GetSpecialValueFor("pull_radius")

    local nCasts = hCaster:GetModifierStackCount(self:GetIntrinsicModifierName(), hCaster) + 1
    if nCasts >= self:GetSpecialValueFor("repeat_halver_count_need") then
        nPullRadius = nPullRadius / nCasts
    end

    return nPullRadius
end
function saito_shadowslash:GetBehavior() --Immediate behavior automatically zerofill cast time.
    local nBehavior = tonumber(tostring(self.BaseClass.GetBehavior(self)))
    return bit.bor(nBehavior, self:GetCaster():HasModifier("modifier_saito_style_active") and DOTA_ABILITY_BEHAVIOR_IMMEDIATE or DOTA_ABILITY_BEHAVIOR_NONE)
end
function saito_shadowslash:GetCooldown(nLevel) --Changing the cooldown if we are in the combo state then shows the cooldown for the ability will be 3 seconds like in KV as the default value.
    return self:GetCaster():HasModifier("modifier_saito_style_active")
           and self:GetSpecialValueFor("combo_cooldown")
           or self.BaseClass.GetCooldown(self, nLevel)
end
-- function saito_shadowslash:GetCastPoint()
--     local hCaster = self:GetCaster()

--     local nCastPointIncreaser = 0.05
--     --Base class takes the value of KV == 0.1, then starting cast time.
--     return self.BaseClass.GetCastPoint(self) + ( hCaster:GetModifierStackCount("modifier_saito_fds_cast_controller", hCaster) * nCastPointIncreaser )
-- end
function saito_shadowslash:OnSpellStart()
    local hCaster = self:GetCaster()
    local vCasterLoc = hCaster:GetAbsOrigin()

    local nCasterTeam = hCaster:GetTeamNumber()

    local nDamageType = self:GetAbilityDamageType()

    local nRadius = self:GetAOERadius()

    local nDamage = self:GetSpecialValueFor("pull_damage") + ( GetAttributeValue(hCaster, "saito_attribute_sword", "qwe_hero_level_damage", -1, 0) * hCaster:GetLevel() )

    local nCastsDone = hCaster:GetModifierStackCount(self:GetIntrinsicModifierName(), hCaster) + 1  --To reduce the damage by number of cast done.
    if nCastsDone >= self:GetSpecialValueFor("repeat_halver_count_need") then
        nDamage = nDamage / nCastsDone
    end

    local nBurstRadius       = self:GetSpecialValueFor("burst_radius")
    local nBurstStunDuration = self:GetSpecialValueFor("burst_stun_duration")
    local nBurstDelay        = self:GetSpecialValueFor("burst_delay")
    local nBurstDamage       = nDamage * self:GetSpecialValueFor("burst_damage_pct") * 0.01

    local vPullPoint = vCasterLoc --+ hCaster:GetForwardVector() * hCaster:BoundingRadius2D() * 3

    local hAbility = self --It's only necessary for timers that can't assign itself if it will be removed from code, basically unnecessary, but I just wrote it here.

    local nTargetTeam  = self:GetAbilityTargetTeam()
    local nTargetType  = self:GetAbilityTargetType()
    local nTargetFlags = self:GetAbilityTargetFlags()

    local nAttr_MRR_Duraiton = GetAttributeValue(hCaster, "saito_attribute_freedom", "e_mr_reduction_duration", -1, 0)

    local hEntities = FindUnitsInRadius(
                                            nCasterTeam,
                                            vCasterLoc,
                                            nil,
                                            nRadius,
                                            nTargetTeam,
                                            nTargetType,
                                            nTargetFlags,
                                            FIND_CLOSEST,
                                            false
                                        )
    --=================================--
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity) then
            local vEntLoc = hEntity:GetAbsOrigin()
            --=================================--
            FindClearSpaceForUnit(hEntity, vPullPoint, true) --Set and clear space with interrupting motion and etc.
            --=================================--
            if nAttr_MRR_Duraiton > 0 then
                hEntity:AddNewModifier(hCaster, self, "modifier_saito_shadowslash_mrr", {duration = nAttr_MRR_Duraiton})
            end
            --=================================--
            DoDamage(hCaster, hEntity, nDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, hAbility, false)
            --=================================--
            self:PullTargetEffect(hEntity, vEntLoc)
        end
    end
    --=================================--
    --Creates one timer and after delay, just iterate the same entity and apply its modifiers and damage.
    Timers:CreateTimer(nBurstDelay, function() --Using timers as every custom games use it, very useful lib, but no need to use it everywhere, only as first solution or if you don't want to create lots of modifiers for simple things AKA current.
        for _, hEntity in pairs(hEntities) do
            if IsNotNull(hEntity)
                and hEntity:IsAlive() then --Just checker for not to blow around dead enemies.
                local hEntities2 = FindUnitsInRadius(
                                                        nCasterTeam,
                                                        hEntity:GetAbsOrigin(),
                                                        nil,
                                                        nBurstRadius,
                                                        nTargetTeam,
                                                        nTargetType,
                                                        nTargetFlags,
                                                        FIND_CLOSEST,
                                                        false
                                                    )
                --=================================--
                for _, hEntity2 in pairs(hEntities2) do
                    if IsNotNull(hEntity2) then
                        local vEntLoc = hEntity2:GetAbsOrigin()

                        giveUnitDataDrivenModifier(hCaster, hEntity, "stunned", nBurstStunDuration)

                        DoDamage(hCaster, hEntity, nBurstDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, hAbility, false)
                        --=================================--
                        self:PullTargetEffect(hEntity2, vEntLoc)
                    end
                end
            end
        end
    end)
    --=================================--
    self:DoPullEffect(hCaster, nRadius)
    --=================================--
    if bit.band(self:GetBehavior(), DOTA_ABILITY_BEHAVIOR_IMMEDIATE) ~= 0 then
        hCaster:StartGestureWithPlaybackRate(self:GetCastAnimation(), 2.0)
    end
end
function saito_shadowslash:DoPullEffect(hCaster, nRadius)
    local sPullPFX = "particles/heroes/saito/saito_shadowslash_aoe.vpcf"

    local nPullPFX =    ParticleManager:CreateParticle( sPullPFX, PATTACH_ABSORIGIN_FOLLOW, hCaster )
                        ParticleManager:SetParticleControl(nPullPFX, 1, Vector( nRadius, nRadius, nRadius ))
                        ParticleManager:SetParticleControl(nPullPFX, 2, Vector( 0.1, 0, 0 ))
                        ParticleManager:SetParticleControlEnt(
                                                                nPullPFX,
                                                                3,
                                                                hCaster,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_swordpack",
                                                                hCaster:GetForwardVector(), -- unknown
                                                                false -- unknown, true
                                                            )
                        ParticleManager:SetParticleControlForward(nPullPFX, 3, hCaster:GetForwardVector())
                        --ParticleManager:DestroyParticle(nPullPFX, false)
                        ParticleManager:ReleaseParticleIndex(nPullPFX)


    hCaster:EmitSound("Saito.Formless.Slash.Cast")
    hCaster:EmitSound("Saito.Shadowslash.Cast")
    EmitZlodemonTrueSound("moskes_saito_e")
end
function saito_shadowslash:PullTargetEffect(hTarget, vOldLoc)
    local sPullPFX = "particles/heroes/saito/saito_shadowslash_pull.vpcf"

    local nPullPFX =    ParticleManager:CreateParticle( sPullPFX, PATTACH_ABSORIGIN_FOLLOW, hTarget )
                        ParticleManager:SetParticleControlEnt(
                                                                nPullPFX,
                                                                0,
                                                                hTarget,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_hitloc",
                                                                Vector(0,0,0), -- unknown
                                                                false -- unknown, true
                                                            )
                        ParticleManager:SetParticleControl(nPullPFX, 1, vOldLoc)
                        --ParticleManager:DestroyParticle(nPullPFX, false)
                        ParticleManager:ReleaseParticleIndex(nPullPFX)

    EmitSoundOn("Saito.Shadowslash.Impact", hTarget)
    EmitSoundOn("Hero_Saito.Attack", hTarget)
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_shadowslash_mrr", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE) --mrr == magic resistance reduction

modifier_saito_shadowslash_mrr = modifier_saito_shadowslash_mrr or class({})

function modifier_saito_shadowslash_mrr:IsHidden()                                                                  return false end
function modifier_saito_shadowslash_mrr:IsDebuff()                                                                  return true end
function modifier_saito_shadowslash_mrr:IsPurgable()                                                                return true end
function modifier_saito_shadowslash_mrr:IsPurgeException()                                                          return true end
function modifier_saito_shadowslash_mrr:RemoveOnDeath()                                                             return true end
function modifier_saito_shadowslash_mrr:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
                    }
    return tFunc
end
function modifier_saito_shadowslash_mrr:GetModifierMagicalResistanceBonus(keys)
    return self.nMagicResistReduction
end
function modifier_saito_shadowslash_mrr:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nMagicResistReduction = GetAttributeValue(self.hCaster, "saito_attribute_freedom", "e_mr_reduction", -1, 0)
end
function modifier_saito_shadowslash_mrr:OnRefresh(tTable)
    self:OnCreated(tTable)
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_mind_eye = saito_mind_eye or class({})

function saito_mind_eye:GetAOERadius()
    return self:GetSpecialValueFor("proc_radius")
end
function saito_mind_eye:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()

    local vCasterLoc = hCaster:GetAbsOrigin()

    local nTargetTeam  = self:GetAbilityTargetTeam()
    local nTargetType  = self:GetAbilityTargetType()
    local nTargetFlags = self:GetAbilityTargetFlags()

    local nDuration = self:GetSpecialValueFor("duration")

    local nCastRange = self:GetEffectiveCastRange(vCasterLoc, hTarget)

    if hTarget == hCaster then
        local hEntities = FindUnitsInRadius(
                                                hCaster:GetTeamNumber(),
                                                vCasterLoc,
                                                nil,
                                                nCastRange,
                                                nTargetTeam,
                                                nTargetType,
                                                nTargetFlags,
                                                FIND_CLOSEST, --This helps find your closest ally if you break the cycle after the first entity.
                                                false
                                            )
        --=================================--
        for _, hEntity in pairs(hEntities) do
            if hEntity ~= hCaster then
                hEntity:AddNewModifier(hCaster, self, "modifier_saito_mind_eye_active", {duration = nDuration})
                break
            end
        end
    elseif IsNotNull(hTarget) then
        hTarget:AddNewModifier(hCaster, self, "modifier_saito_mind_eye_active", {duration = nDuration})
    end

    hCaster:AddNewModifier(hCaster, self, "modifier_saito_mind_eye_active", {duration = nDuration})

    --=================================--
    CheckComboIsReadyIncrement(hCaster, 1)
    --=================================--
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_mind_eye_active", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_mind_eye_active = modifier_saito_mind_eye_active or class({})

function modifier_saito_mind_eye_active:IsHidden()                                                                  return false end
function modifier_saito_mind_eye_active:IsDebuff()                                                                  return false end
function modifier_saito_mind_eye_active:IsPurgable()                                                                return false end
function modifier_saito_mind_eye_active:IsPurgeException()                                                          return false end
function modifier_saito_mind_eye_active:RemoveOnDeath()                                                             return true end
function modifier_saito_mind_eye_active:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_HEALTH_BONUS,
                        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,

                        MODIFIER_EVENT_ON_ABILITY_START
                    }
    return tFunc
end
function modifier_saito_mind_eye_active:GetModifierHealthBonus(keys)
    return self.nBonusHP
end
function modifier_saito_mind_eye_active:GetModifierConstantHealthRegen(keys)
    return self.nBonusHPRegen
end
function modifier_saito_mind_eye_active:OnAbilityStart(keys)
    if IsServer()
        and IsNotNull(keys.unit)
        and IsNotNull(keys.ability)
        and not keys.ability:IsItem()
        and GetDistance(keys.unit, self.hParent) <= self.nRadius
        --and not self.hParent:HasModifier("modifier_saito_mind_eye_out_of_range")
        and not self.hCaster:HasModifier("modifier_saito_mind_eye_ss_interval")
        --and ( keys.unit:GetUnitName() == "npc_dota_hero_vengefulspirit" or keys.unit:GetUnitName() == "npc_dota_hero_treant" )
        and UnitFilter( --This checks filter units for example you can put here settings AKA check non-invis and etc.
                        keys.unit,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_HERO,
                        DOTA_UNIT_TARGET_FLAG_NONE, --DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                        self.hCaster:GetTeamNumber()
                        ) == UF_SUCCESS then

        self.hCaster:AddNewModifier(self.hCaster, self.hAbility, "modifier_saito_mind_eye_ss_interval", {duration = self.nSSInterval})

        giveUnitDataDrivenModifier(self.hCaster, keys.unit, "locked", self.nSSDuration)
        --giveUnitDataDrivenModifier(self.hCaster, keys.unit, "silenced", self.nSSDuration)

        local hSilenceNew = keys.unit:AddNewModifier(self.hCaster, self.hAbility, "modifier_rooted", {duration = self.nSSDuration})
        if IsNotNull(hSilenceNew) then
            if type(hSilenceNew._nSpecialBuff) == "number" then
                ParticleManager:DestroyParticle(hSilenceNew._nSpecialBuff, false)
                ParticleManager:ReleaseParticleIndex(hSilenceNew._nSpecialBuff)
                hSilenceNew._nSpecialBuff = nil
            end
            hSilenceNew._nSpecialBuff = ParticleManager:CreateParticle("particles/heroes/saito/saito_mind_eye_silence.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.unit)
            hSilenceNew:AddParticle(hSilenceNew._nSpecialBuff, false, false, -1, false, false)
        end

        EmitSoundOn("Saito.MindEye.Impact", keys.unit)
        --Using these functions just because they exist in the global scope of F/A 2, you can basically write your own modifiers, and add them to the table for FATE settings...
    end
end
function modifier_saito_mind_eye_active:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nRadius = self.hAbility:GetAOERadius()

    self.nSSInterval = self.hAbility:GetSpecialValueFor("root_lock_cooldown")
    self.nSSDuration = self.hAbility:GetSpecialValueFor("root_lock_duration")

    self.nBonusHP      = self.hAbility:GetSpecialValueFor("hp_bonus") + GetAttributeValue(self.hCaster, "saito_attribute_memoir", "me_hp_bonus", -1, 0)
    self.nBonusHPRegen = self.hAbility:GetSpecialValueFor("hp_regen")
    self.nAllyScale    = self.hAbility:GetSpecialValueFor("ally_scale") * 0.01

    if self.hCaster ~= self.hParent and self.hParent:GetUnitName() ~= "npc_dota_hero_dark_willow" then --Only Okita receives a 100% bonus.
        self.nBonusHP       = self.nBonusHP * self.nAllyScale
        self.nBonusHPRegen  = self.nBonusHPRegen * self.nAllyScale
    end

    if IsServer() then
        HardCleanse(self.hParent) --NOTE: FATE mechanic.
        --self.hParent:Purge(false, true, false, true, true) --NOTE: Removed because this is FATE, dota mechanic.
        self:CastPFX(self.hParent)

        local bHasAttribute = IsNotNull(GetAttribute(self.hCaster, "saito_attribute_memoir"))

        if bHasAttribute then
            local nShellDuration = GetAttributeValue(self.hCaster, "saito_attribute_memoir", "me_shell_duration", -1, 0)
            local nChance        = GetAttributeValue(self.hCaster, "saito_attribute_memoir", "me_okita_chance", -1, 0)

            self.hParent:AddNewModifier(self.hCaster, self.hAbility, "modifier_saito_mind_eye_shell", {duration = nShellDuration})
            self.hParent:AddNewModifier(self.hCaster, self.hAbility, "modifier_saito_mind_eye_linken", {duration = nShellDuration})

            if self.hParent:GetUnitName() == "npc_dota_hero_dark_willow" and RollPseudoRandomPercentage(nChance, 2, self.hParent) then --If the target is Okita then add her agility bonus and reset abilities.
                --if self.hParent:GetUnitName() == "npc_dota_hero_dark_willow" and RollPercentage(nChance) then --Rolls a number from 1 to 100 and returns true if the roll is less than or equal to the number specified.
                ResetAbilities(self.hParent) --FATE mechanic, described in F/A 2 code... needs as other functions because it is FATE...

                self.hParent:AddNewModifier(self.hCaster, self.hAbility, "modifier_saito_mind_eye_agility", {})
            end
        end

        if self.hCaster ~= self.hParent then
            --self:StartIntervalThink(0.1)
        end
    end
end
function modifier_saito_mind_eye_active:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_mind_eye_active:OnIntervalThink()
    if IsServer() then
        if GetDistance(self.hCaster, self.hParent) > self.nRadius * 2 then --Added a checker to see if units with this buff in range near Saito == 2 * diameter.
            self.hParent:AddNewModifier(self.hCaster, self.hAbility, "modifier_saito_mind_eye_out_of_range", {})
        else
            self.hParent:RemoveModifierByNameAndCaster("modifier_saito_mind_eye_out_of_range", self.hCaster)
        end
    end
end
function modifier_saito_mind_eye_active:OnDestroy()
    if IsServer() then
        --self.hParent:RemoveModifierByNameAndCaster("modifier_saito_mind_eye_out_of_range", self.hCaster)
    end
end 
function modifier_saito_mind_eye_active:CastPFX(hTarget)

    -- local sCastPFX =    "particles/heroes/saito/saito_mind_eye_cast.vpcf"
    -- local nCastPFX =    ParticleManager:CreateParticle(sCastPFX, PATTACH_ABSORIGIN_FOLLOW, hTarget)
    --                     ParticleManager:SetParticleControlForward(nCastPFX, 0, hTarget:GetForwardVector())
    --                     ParticleManager:SetParticleControlEnt(
    --                                                             nCastPFX,
    --                                                             1,
    --                                                             hTarget,
    --                                                             PATTACH_POINT_FOLLOW,
    --                                                             "attach_hitloc",
    --                                                             Vector(0,0,0), -- unknown
    --                                                             false -- unknown, true
    --                                                             )
    --                     ParticleManager:ReleaseParticleIndex(nCastPFX)

    EmitSoundOn("Saito.MindEye.Cast", hTarget)
end
function modifier_saito_mind_eye_active:GetEffectName()
    return "particles/heroes/saito/saito_mind_eye_buff.vpcf"
end
function modifier_saito_mind_eye_active:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
--This modifier is necessary for checking intervals, basically to prevent situations where you and an allied hero will double silence the same enemy or for meme infinity silence.
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_mind_eye_ss_interval", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE) --ss == stun silence

modifier_saito_mind_eye_ss_interval = modifier_saito_mind_eye_ss_interval or class({})

function modifier_saito_mind_eye_ss_interval:IsHidden()                                                             return false end
function modifier_saito_mind_eye_ss_interval:IsDebuff()                                                             return true end
function modifier_saito_mind_eye_ss_interval:IsPurgable()                                                           return false end
function modifier_saito_mind_eye_ss_interval:IsPurgeException()                                                     return false end
function modifier_saito_mind_eye_ss_interval:RemoveOnDeath()                                                        return false end
--This modifier is necessary to check the distance of an ally with this buff from Saito, to show the player a radius within which Mind's Eye (True) stun/silence can proc or not.
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_mind_eye_out_of_range", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE) --Not deleted, just kept it here for the future.

modifier_saito_mind_eye_out_of_range = modifier_saito_mind_eye_out_of_range or class({})

function modifier_saito_mind_eye_out_of_range:IsHidden()                                                            return false end
function modifier_saito_mind_eye_out_of_range:IsDebuff()                                                            return true end
function modifier_saito_mind_eye_out_of_range:IsPurgable()                                                          return false end
function modifier_saito_mind_eye_out_of_range:IsPurgeException()                                                    return false end
function modifier_saito_mind_eye_out_of_range:RemoveOnDeath()                                                       return true end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_mind_eye_shell", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_mind_eye_shell = modifier_saito_mind_eye_shell or class({})

function modifier_saito_mind_eye_shell:IsHidden()                                                                   return false end
function modifier_saito_mind_eye_shell:IsDebuff()                                                                   return false end
function modifier_saito_mind_eye_shell:IsPurgable()                                                                 return false end
function modifier_saito_mind_eye_shell:IsPurgeException()                                                           return false end
function modifier_saito_mind_eye_shell:RemoveOnDeath()                                                              return true end
function modifier_saito_mind_eye_shell:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
                    }
    return tFunc
end
function modifier_saito_mind_eye_shell:GetModifierTotal_ConstantBlock(keys) --Using this property to prevent resistance + resistance from Intervention [D] seal, this event works after the [D] seal event.
    if IsServer()
        and type(keys.damage) == "number" then
        return keys.damage * self.nDamageBlock
    end
end
function modifier_saito_mind_eye_shell:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nDamageBlock = GetAttributeValue(self.hCaster, "saito_attribute_memoir", "me_shell_block", -1, 0) * 0.01
end
function modifier_saito_mind_eye_shell:OnRefresh(tTable)
    self:OnCreated(tTable)
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_mind_eye_linken", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_mind_eye_linken = modifier_saito_mind_eye_linken or class({})

function modifier_saito_mind_eye_linken:IsHidden()                                                                  return false end
function modifier_saito_mind_eye_linken:IsDebuff()                                                                  return false end
function modifier_saito_mind_eye_linken:IsPurgable()                                                                return false end
function modifier_saito_mind_eye_linken:IsPurgeException()                                                          return false end
function modifier_saito_mind_eye_linken:RemoveOnDeath()                                                             return true end
-- function modifier_saito_mind_eye_linken:GetAbsorbSpell(keys) --It's just the default linken for D2. --Uncomment if want to use, commented because who knows maybe somewhere F/A 2 checks it out...
--     if IsServer() then
--         --Here write anything when linken procs.
--         self:Destroy()
--         return 1
--     end
-- end
function modifier_saito_mind_eye_linken:GetEffectName()
    return "particles/heroes/saito/saito_mind_eye_linken.vpcf"
end
function modifier_saito_mind_eye_linken:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_mind_eye_agility", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_mind_eye_agility = modifier_saito_mind_eye_agility or class({})

function modifier_saito_mind_eye_agility:IsHidden()                                                                 return false end
function modifier_saito_mind_eye_agility:IsDebuff()                                                                 return false end
function modifier_saito_mind_eye_agility:IsPurgable()                                                               return false end
function modifier_saito_mind_eye_agility:IsPurgeException()                                                         return false end
function modifier_saito_mind_eye_agility:RemoveOnDeath()                                                            return false end
function modifier_saito_mind_eye_agility:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_STATS_AGILITY_BONUS
                    }
    return tFunc
end
function modifier_saito_mind_eye_agility:GetModifierBonusStats_Agility(keys)
    return self:GetStackCount()
end
function modifier_saito_mind_eye_agility:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nBonusAgility = GetAttributeValue(self.hCaster, "saito_attribute_memoir", "me_okita_agility", -1, 0)

    if IsServer() then
        self:SetStackCount(self:GetStackCount() + self.nBonusAgility)
    end
end
function modifier_saito_mind_eye_agility:OnRefresh(tTable)
    self:OnCreated(tTable)
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_fds = saito_fds or class({})

function saito_fds:OnUpgrade() --Call when ability is upgraded in any way AKA -setlevel or by player or LearnAbility or etc.
    if IsServer() then
        UpgradeShared(self, tSaito_QWE_2)
    end
end
function saito_fds:GetIntrinsicModifierName()
    return "modifier_saito_fds_cast_controller"
end
function saito_fds:OnSpellStart()
    local hCaster = self:GetCaster()
    local nDuration = self:GetSpecialValueFor("active_duration") + GetAttributeValue(hCaster, "saito_attribute_freestyle", "fds_active_duration", -1, 0)

    hCaster:AddNewModifier(hCaster, self, "modifier_saito_fds_active", {duration = nDuration})

    --=================================--
    CheckComboIsReadyIncrement(hCaster, 0)
    --=================================--

    local sCastPFX =    "particles/heroes/saito/saito_fds_cast.vpcf"
    local nCastPFX =    ParticleManager:CreateParticle(sCastPFX, PATTACH_ABSORIGIN_FOLLOW, hCaster)
                        ParticleManager:SetParticleControlForward(nCastPFX, 0, hCaster:GetForwardVector())
                        ParticleManager:SetParticleControlEnt(
                                                                nCastPFX,
                                                                1,
                                                                hCaster,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_hitloc",
                                                                Vector(0,0,0), -- unknown
                                                                false -- unknown, true
                                                                )
                        ParticleManager:ReleaseParticleIndex(nCastPFX)


    hCaster:EmitSound("Saito.FDS.Cast")
    hCaster:EmitSound("Saito.FDS.Cast.Voice")
    EmitZlodemonTrueSound("moskes_saito_f")
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_fds_cast_controller", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_fds_cast_controller = modifier_saito_fds_cast_controller or class({})

function modifier_saito_fds_cast_controller:IsHidden()                                                              return false end
function modifier_saito_fds_cast_controller:IsDebuff()                                                              return false end
function modifier_saito_fds_cast_controller:IsPurgable()                                                            return false end
function modifier_saito_fds_cast_controller:IsPurgeException()                                                      return false end
function modifier_saito_fds_cast_controller:RemoveOnDeath()                                                         return false end
function modifier_saito_fds_cast_controller:DestroyOnExpire()                                                       return false end --Need to prevent removing if something error with duration modification.
function modifier_saito_fds_cast_controller:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,

                        MODIFIER_EVENT_ON_TAKEDAMAGE
                    }
    return tFunc
end
--Use FullyCast because it handles the ability after full cast, when it has already gone on cooldown... don't use the execute ability if you want to end the ability's cooldown manually.
function modifier_saito_fds_cast_controller:OnAbilityFullyCast(keys) --Different from OnAbilityStart like it is proc when ANY ability has already been cast, when OnAbilityStart occurs at cast time, OnAbilityFullyCast occurs at full cast but does not work for toggle like abilities.
    if IsServer()
        and keys.unit == self.hParent
        and IsNotNull(keys.ability) then
        --There's controller for swapping to another QWE set--
        --Manually coded basically... because it can be any endpoint you want... who knows...
        --It is functional attribute so it is written differently (meaning detached from the main code).
        if self:CheckSwapQWESet(keys.ability) then
            return --Stop prevention. --If you don't do this then will PEPE...
        end
        --Should be defined before EndCombo function for the correct swapping on the max stack before it is zerofill.

        if self.tLocalAbilitiesCheck[keys.ability:GetAbilityName()] then
            self:IncrementStackCount() --Just increment the number of self stacks count by 1.

            local nCurrentStacks = self:GetStackCount()

            local nCheckInterval = self.nCheckInterval - (nCurrentStacks * self.nCheckDecreaser)

            self:StartIntervalThink(nCheckInterval)
            self:SetDuration(nCheckInterval, true) --I added this to show the duration in the modifier circle itself, so you will know if you can cast the ability or not (how much time).

            --=======--
            local nLockerCooldown = self.hParent:HasModifier("modifier_saito_style_active")
                                    and self.nLockerTimeCombo
                                    or (self.nLockerTime + self.nLockerIncreaser * nCurrentStacks)

            --There just controller for the number of casted QWE abilities, for normal showing radius in HUD, can also be hidden, everything will be fine.
            for sAbilityName, _ in pairs(self.tLocalAbilitiesCheck) do
                local hAbility = self.hParent:FindAbilityByName(sAbilityName)
                if IsNotNull(hAbility) then
                    local sModifierName = hAbility:GetIntrinsicModifierName()

                    local nNewStacks = hAbility == keys.ability
                                       and ( self.hParent:GetModifierStackCount(sModifierName, self.hCaster) + 1 )
                                       or 0

                    self.hParent:SetModifierStackCount(sModifierName, self.hCaster, nNewStacks)

                    --At the same time we just end their cooldowns, because if don't do this then they will go on cooldown.... PEPE
                    hAbility:EndCooldown() --Should be done before BreakCombo function, which puts the abilities on cooldown.
                    hAbility:StartCooldown(nLockerCooldown * self.hParent:GetCooldownReduction()) --There is my genius mechanic, which puts the abilities to micro-cooldown after use.
                end
            end
            --Check over all for resetting if using basically different abilities.
            --=======--
            if nCurrentStacks >= self.nMaxCasts then --This should be after the previous functions for correct interaction of cooldown.
                self:BreakCombo()
            end
        end
    end
end
function modifier_saito_fds_cast_controller:OnTakeDamage(keys)
    if IsServer() then
        if keys.attacker == self.hParent
            and IsNotNull(keys.inflictor) and not keys.inflictor:IsItem()
            and UnitFilter( --This checks filter units for example you can put here settings AKA check non-invis and etc.
                            keys.unit,
                            self.nABILITY_TARGET_TEAM,
                            self.nABILITY_TARGET_TYPE,
                            self.nABILITY_TARGET_FLAGS,
                            self.nCASTER_TEAM
                            ) == UF_SUCCESS then

            local bIsBuffActive  = self.hParent:HasModifier("modifier_saito_fds_active")
            local bIsComboActive = self.hParent:HasModifier("modifier_saito_style_active")
            local bHasAttribute  = IsNotNull(GetAttribute(self.hParent, "saito_attribute_freestyle"))

            if bIsBuffActive then
                local nScaler = bIsComboActive and GetAbilityValue(self.hCaster, "saito_style", "fds_hp_mp_scale", -1, 1) or 1
                local nMPGain = self.nMPGainPerDamage * nScaler
                local nHPGain = ( self.nHPGainPerDamage + GetAttributeValue(self.hCaster, "saito_attribute_freestyle", "fds_active_hp_gain", self.hAbility:GetLevel(), 0) ) * nScaler

                self.hParent:GiveMana(self.nMPGainPerDamage)

                if bHasAttribute then
                    self.hParent:Heal(nHPGain, self.hAbility)
                end

                keys.unit:AddNewModifier(self.hCaster, self.hAbility, "modifier_saito_fds_active_sdr", {duration = self.nReductionDuration})
            end
        end
    end
end
function modifier_saito_fds_cast_controller:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nLockerTimeCombo = self.hAbility:GetSpecialValueFor("locker_time_combo")
    self.nLockerTime      = self.hAbility:GetSpecialValueFor("locker_time")
    self.nLockerIncreaser = self.hAbility:GetSpecialValueFor("locker_increaser")

    self.nCheckInterval  = self.hAbility:GetSpecialValueFor("check_interval") + GetAttributeValue(self.hCaster, "saito_attribute_freestyle", "fds_check_interval", -1, 0)
    self.nCheckDecreaser = self.hAbility:GetSpecialValueFor("check_decreaser")

    self.nMaxCasts = self.hAbility:GetSpecialValueFor("max_casts")

    self.nMPGainPerDamage = self.hAbility:GetSpecialValueFor("active_mp_gain")
    self.nHPGainPerDamage = self.hAbility:GetSpecialValueFor("active_hp_gain")

    self.nReductionDuration = self.hAbility:GetSpecialValueFor("active_debuff_duration")

    self.tLocalAbilitiesCheck = self.tLocalAbilitiesCheck or {}
    for _, sAbilityName in pairs(tSaito_QWE) do --Picks values from local storage of this file, cannot be accessed from other scope AKA file without requiring this file.
        self.tLocalAbilitiesCheck[sAbilityName] = true
        --Also in the same table we register their intrinsic modifiers for controlling.
    end

    if IsServer() then
        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()
    end
end
function modifier_saito_fds_cast_controller:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_fds_cast_controller:OnIntervalThink()
    if IsServer() then
        --Each time when spell executed, thinker restarts and will proc only if you will be too late.
        self:BreakCombo()
    end
end
function modifier_saito_fds_cast_controller:BreakCombo() --Just created this function to simplify the code.
    if IsServer() then
        self:StartIntervalThink(-1) --Canceling OnIntervalThink before next start.
        self:SetDuration(-1, true) --Reset infinity duration.
        self:SetStackCount(0) --Nullifying counter, AKA end of casting.

        if self._bSwapedSet then
            self:SwapQWEAbilities(true, false)
            self._bSwapedSet = false
            self._tStepsAreDone = {}
        end

        for sAbilityName, _ in pairs(self.tLocalAbilitiesCheck) do
            local hAbility = self.hParent:FindAbilityByName(sAbilityName)
            if IsNotNull(hAbility) then --There we put on cooldown each ability differently because they can have different cooldown, if you use sharing from KV then there will be the last shared cooldown or ability that you put on the cd for the first.
                --Here can be added a function that checks ability on cooldown or not, then if combo is breaking other abilities if they have different cooldown will not be affected and can be cast when cooldown ends for them...
                hAbility:UseResources(false, false, false, true) --Put in cooldown, the difference between <> StartCooldown is that UseResources counts -WTF mode and requires less operation.
                --======--
                -- How to include cooldown with all modifications: if you want more manual, you need:
                -- hAbility:EndCooldown() --This is necessary because sometimes the cooldown cannot start if the ability is still on cooldown.
                -- hAbility:StartCooldown(value or hAbility:GetCooldown(-1 or level) * hUnit:GetCooldownReduction())
                -- Or simpler hAbility:StartCooldown(hAbility:GetEffectiveCooldown(-1))

                --======-- Nullifying used counts of abilities QWE.
                local sModifierName = hAbility:GetIntrinsicModifierName()

                self.hParent:SetModifierStackCount(sModifierName, self.hCaster, 0)
            end
        end
    end
end
function modifier_saito_fds_cast_controller:SwapQWEAbilities(bEnable1, bEnable2)
    if IsServer() then
        local tStepsTable = tSaito_QWE --This connects us to local global storage table, if you want to copy you have to re-index each index... with new table.
        local tAssocTable = tSaito_QWE_2
        for _, sAbilityName1 in pairs(tStepsTable) do
            self.hParent:SwapAbilities(sAbilityName1, tAssocTable[_], bEnable1, bEnable2)
        end
    end
end
function modifier_saito_fds_cast_controller:CheckSwapQWESet(hAbility) --Basically hardcoded, PEPE.
    if IsServer()
        and IsNotNull(GetAttribute(self.hParent, "saito_attribute_sword"))
        and not self.hParent:HasModifier("modifier_saito_style_active") then --Locks the swapping if you are in combo state, except for the situation when you cast combo that is already in the 2nd state sent from QWE2.

        local nSwapDuration = GetAttributeValue(self.hCaster, "saito_attribute_sword", "fds_swap_set_duration", -1, 0)
        --Get number here because it always calls when we need, attributes as talents basically have to always be called on code which updates more than once for it to actually work.

        self._tStepsAreDone = self._tStepsAreDone or {}

        local sAbilityNameNow = hAbility:GetAbilityName()

        local tStepsTable = tSaito_QWE --This connects us to a local global storage table, if you want to copy you have to re-index each index... with a new table.
        local tAssocTable = tSaito_QWE_2

        if self._bSwapedSet then
            for _, sAbilityName2 in pairs(tAssocTable) do
                if sAbilityName2 == sAbilityNameNow then
                    self:BreakCombo()
                    return true --Return is a break function, code below will not be proceed, except self._sQWE_Swapped_Timer which will be called from the modifier scope.
                end
            end
        else
            local bPassThisCheck = false
            for _, sAbilityName in pairs(tStepsTable) do
                --It's an old comment if you use a tAssocTable like [index] = value.
                --Of course there we can check just tAssocTable[sAbilityNameNow] ~= nil, but since we need a step (by index number) it's better to use that way because the tables used are the same and with table changes it will all be handled automatically.
                if sAbilityNameNow == sAbilityName then
                    bPassThisCheck = true
                    break
                end
            end
            if bPassThisCheck then
                local nStacksNow = self:GetStackCount()
                --print(self.nMaxCasts, nStacksNow)
                self._tStepsAreDone[1] = self._tStepsAreDone[1] or ( sAbilityNameNow == tStepsTable[1] and nStacksNow == 0 )
                self._tStepsAreDone[2] = self._tStepsAreDone[2] or ( self._tStepsAreDone[1] and sAbilityNameNow == tStepsTable[2] and nStacksNow == 1 )
                --print(self._tStepsAreDone[1], self._tStepsAreDone[2], "PEPE")
                if self._tStepsAreDone[1]
                    and self._tStepsAreDone[2]
                    --and sAbilityNameNow == tStepsTable[3]
                    and nStacksNow + 2 == self.nMaxCasts then --After that check the last step.
                    --print("KEK", nStacksNow + 2)
                    self:SwapQWEAbilities(false, true)
                    self._tStepsAreDone = {} --Quickly clears the saved list of used abilities.
                    self._bSwapedSet = true
                    self:StartIntervalThink(nSwapDuration)
                    self:SetDuration(nSwapDuration, true)
                    self:IncrementStackCount()
                    return true
                end
            end
        end
        return false
    end
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_fds_active", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_fds_active = modifier_saito_fds_active or class({})

function modifier_saito_fds_active:IsHidden()                                                                       return false end
function modifier_saito_fds_active:IsDebuff()                                                                       return false end
function modifier_saito_fds_active:IsPurgable()                                                                     return false end
function modifier_saito_fds_active:IsPurgeException()                                                               return false end
function modifier_saito_fds_active:RemoveOnDeath()                                                                  return true end
function modifier_saito_fds_active:IsAura()                                                                         return true end
function modifier_saito_fds_active:IsAuraActiveOnDeath()                                                            return false end
function modifier_saito_fds_active:IsPermanent()                                                                    return false end
function modifier_saito_fds_active:GetAuraEntityReject(hEntity)
    return not IsNotNull(GetAttribute(self.hParent, "saito_attribute_freestyle"))
end
function modifier_saito_fds_active:GetAuraRadius()
    return self.nRadius
end
function modifier_saito_fds_active:GetAuraSearchTeam()
    return self.nABILITY_TARGET_TEAM
end
function modifier_saito_fds_active:GetAuraSearchType()
    return self.nABILITY_TARGET_TYPE
end
function modifier_saito_fds_active:GetAuraSearchFlags()
    return self.nABILITY_TARGET_FLAGS
end
function modifier_saito_fds_active:GetModifierAura()
    return "modifier_saito_fds_aura_sdr" --SDR == spell_damage_reduction
end
function modifier_saito_fds_active:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nRadius = GetAttributeValue(self.hCaster, "saito_attribute_freestyle", "fds_active_aura_min_reduction_range", -1, 0)

    if IsServer() then
        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        if IsNotNull(GetAttribute(self.hParent, "saito_attribute_freestyle")) then
            self:OnIntervalThink()
            self:StartIntervalThink(1)
        end
    end
end
function modifier_saito_fds_active:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_fds_active:OnIntervalThink()
    if IsServer() then
        local nPulsesPFX =  ParticleManager:CreateParticle("particles/heroes/saito/saito_fds_aura_pulses.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                            ParticleManager:SetParticleControl(nPulsesPFX, 1, Vector(self.nRadius, 0, 0))
                            ParticleManager:ReleaseParticleIndex(nPulsesPFX)
    end
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_fds_aura_sdr", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_fds_aura_sdr = modifier_saito_fds_aura_sdr or class({})

function modifier_saito_fds_aura_sdr:IsHidden()                                                                     return false end
function modifier_saito_fds_aura_sdr:IsDebuff()                                                                     return true end
function modifier_saito_fds_aura_sdr:IsPurgable()                                                                   return false end
function modifier_saito_fds_aura_sdr:IsPurgeException()                                                             return false end
function modifier_saito_fds_aura_sdr:RemoveOnDeath()                                                                return true end
function modifier_saito_fds_aura_sdr:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
                    }
    return tFunc
end
function modifier_saito_fds_aura_sdr:GetModifierTotalDamageOutgoing_Percentage(keys)
    if IsNotNull(self.hCaster)
        and IsNotNull(self.hParent) then
        local nDistance = GetDistance(self.hCaster, self.hParent)
        local nReductionCalc = RemapValClamped(nDistance, self.nMinRange, self.nMaxRange, self.nMinReduction, self.nMaxReduction)
        --Autolerper and autoclamper values bases on how close your hero is to the enemy hero... with this modifier from aura.

        if IsClient() or bit.band(keys.damage_type or DAMAGE_TYPE_NONE, DAMAGE_TYPE_MAGICAL) ~= 0 then
            return nReductionCalc
        end
    end
end
function modifier_saito_fds_aura_sdr:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nMinRange = GetAttributeValue(self.hCaster, "saito_attribute_freestyle", "fds_active_aura_min_reduction_range", -1, 0)
    self.nMaxRange = GetAttributeValue(self.hCaster, "saito_attribute_freestyle", "fds_active_aura_max_reduction_range", -1, 0)

    self.nMinReduction = GetAttributeValue(self.hCaster, "saito_attribute_freestyle", "fds_active_aura_min_reduction", -1, 0)
    self.nMaxReduction = GetAttributeValue(self.hCaster, "saito_attribute_freestyle", "fds_active_aura_max_reduction", -1, 0)

    if IsServer() then
        self:OnIntervalThink()
        self:StartIntervalThink(1)
    end
end
function modifier_saito_fds_aura_sdr:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_fds_aura_sdr:OnIntervalThink()
    if IsServer() then
        local nPulsePFX =   ParticleManager:CreateParticle("particles/heroes/saito/saito_fds_aura_pulses_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                            ParticleManager:ReleaseParticleIndex(nPulsePFX)
    end
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_fds_active_sdr", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_fds_active_sdr = modifier_saito_fds_active_sdr or class({})

function modifier_saito_fds_active_sdr:IsHidden()                                                                   return false end
function modifier_saito_fds_active_sdr:IsDebuff()                                                                   return true end
function modifier_saito_fds_active_sdr:IsPurgable()                                                                 return false end
function modifier_saito_fds_active_sdr:IsPurgeException()                                                           return false end
function modifier_saito_fds_active_sdr:RemoveOnDeath()                                                              return true end
function modifier_saito_fds_active_sdr:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
                    }
    return tFunc
end
function modifier_saito_fds_active_sdr:GetModifierTotalDamageOutgoing_Percentage(keys)
    --if IsClient() or bit.band(keys.damage_type or DAMAGE_TYPE_NONE, DAMAGE_TYPE_MAGICAL) ~= 0 then
        return self:GetStackCount() * self.nReductionStack
    --end
end
function modifier_saito_fds_active_sdr:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nMaxStacks      = self.hAbility:GetSpecialValueFor("active_debuff_max_stacks")
    self.nReductionStack = self.hAbility:GetSpecialValueFor("active_debuff_reduction_stack")

    if IsServer() then
        self:SetStackCount(math.min(self:GetStackCount() + 1, self.nMaxStacks)) --Each time this modifier increments it, the stack count increases if it isn't already maxed out.
        --If it has a max stack it will only update the duration.
    end
end
function modifier_saito_fds_active_sdr:OnRefresh(tTable)
    self:OnCreated(tTable)
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_formless_invis = saito_formless_invis or class({})

function saito_formless_invis:OnUpgrade() --Call when ability is upgraded in any way AKA -setlevel or by player or LearnAbility or etc.
    if IsServer() then
        UpgradeShared(self, tSaito_RR)
    end
end
function saito_formless_invis:OnSpellStart()
    local hCaster   = self:GetCaster()
    local nDuration = self:GetSpecialValueFor("duration")

    hCaster:AddNewModifier(hCaster, self, "modifier_saito_formless_invis", {duration = nDuration})

    EmitSoundOn("Saito.Formless.Invis.Cast.Voice", hCaster)
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_formless_invis", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_formless_invis = modifier_saito_formless_invis or class({})

function modifier_saito_formless_invis:IsHidden()                                                                   return false end
function modifier_saito_formless_invis:IsDebuff()                                                                   return false end
function modifier_saito_formless_invis:IsPurgable()                                                                 return false end
function modifier_saito_formless_invis:IsPurgeException()                                                           return false end
function modifier_saito_formless_invis:RemoveOnDeath()                                                              return true end
function modifier_saito_formless_invis:CheckState()
    local tState = {}

    tState[MODIFIER_STATE_INVISIBLE] = self:GetStackCount() == 0

    return tState
end
function modifier_saito_formless_invis:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,

                        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
                        MODIFIER_PROPERTY_EVASION_CONSTANT,

                        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
                        MODIFIER_EVENT_ON_ATTACK
                    }
    return tFunc
end
function modifier_saito_formless_invis:GetModifierInvisibilityLevel(keys) --This required the correct work of invisibility.
    return self:GetStackCount() + 1
end
function modifier_saito_formless_invis:GetModifierMoveSpeedBonus_Percentage(keys)
    return self.nBonusMS
end
function modifier_saito_formless_invis:GetModifierEvasion_Constant(keys)
    return self.nEvasion
end
function modifier_saito_formless_invis:OnAbilityExecuted(keys)
    if IsServer()
        and keys.unit == self.hParent then
        self:BreakInvis()
    end
end
function modifier_saito_formless_invis:OnAttack(keys)
    if IsServer()
        and keys.attacker == self.hParent then
        self:BreakInvis()
    end
end
function modifier_saito_formless_invis:BreakInvis()
    if IsServer() then
        if self:GetStackCount() > -1 then
            local nShadowPFX =  ParticleManager:CreateParticle("particles/heroes/saito/saito_formless_invis_start.vpcf", PATTACH_WORLDORIGIN, nil)
                                ParticleManager:SetParticleControl(nShadowPFX, 0, self.hParent:GetAbsOrigin())
                                ParticleManager:ReleaseParticleIndex(nShadowPFX)
        end

        self:SetStackCount(-1)
        self:StartIntervalThink(self.nFadeDelay) --Start fade delay.
    end
end
function modifier_saito_formless_invis:StartInvis()
    if IsServer() then
        self:SetStackCount(0) --Stack counter helps us to provide value to client side for CheckState.
        self:StartIntervalThink(-1) --When the fade is delayed, the thinker stops.

        local nShadowPFX =  ParticleManager:CreateParticle("particles/heroes/saito/saito_formless_invis_start.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleControl(nShadowPFX, 0, self.hParent:GetAbsOrigin())
                            ParticleManager:ReleaseParticleIndex(nShadowPFX)

        EmitSoundOn("Saito.Formless.Invis.Cast", self.hParent)
        EmitZlodemonTrueSound("moskes_saito_r")
    end
end   
function modifier_saito_formless_invis:OnIntervalThink()
    if IsServer() then
        self:StartInvis()
    end
end
function modifier_saito_formless_invis:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nBonusMS = self.hAbility:GetSpecialValueFor("bonus_ms")
    self.nEvasion = GetAttributeValue(self.hCaster, "saito_attribute_kunishige", "fli_evasion", -1, 0)

    self.nFadeDelay = self.hAbility:GetSpecialValueFor("fade_delay") - GetAttributeValue(self.hCaster, "saito_attribute_kunishige", "fli_fade_delay", -1, 0)

    if IsServer()
        and not self._bSwaped then --Prevent the situation if you somehow use invis again or refresh it.
        self._bSwaped = true
        self.hParent:SwapAbilities(tSaito_RR[1], tSaito_RR[2], false, true)

        self:StartInvis()

        self.hCaster:SetModifierStackCount("modifier_saito_formless_slash_counter", self.hCaster, 0) --Post fix if you don't use the max number of slashes.
    end
end
function modifier_saito_formless_invis:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_formless_invis:OnDestroy()
    if IsServer()
        and self._bSwaped then
        self._bSwaped = false
        self.hParent:SwapAbilities(tSaito_RR[1], tSaito_RR[2], true, false)
    end
end










---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_formless_slash = saito_formless_slash or class({})

function saito_formless_slash:OnUpgrade() --Call when ability is upgraded in any way AKA -setlevel or by player or LearnAbility or etc.
    if IsServer() then
        UpgradeShared(self, tSaito_RR)
    end
end
function saito_formless_slash:GetIntrinsicModifierName()
    return "modifier_saito_formless_slash_counter" --Basically we can handle stacks on the invis modifier because without it this ability can't work...
end
function saito_formless_slash:GetCastRange(vLocation, hTarget)
    return self.BaseClass.GetCastRange(self, vLocation, hTarget) + GetAttributeValue(self:GetCaster(), "saito_attribute_kunishige", "fls_cast_range", -1, 0)
end
function saito_formless_slash:GetAbilityTextureName() --Just for the visual difference (spellicons) between each slash, add this...
    local hCaster = self:GetCaster()
    return "custom/saito/saito_formless_slash_" .. (hCaster:GetModifierStackCount("modifier_saito_formless_slash_counter", hCaster) + 1)
end
function saito_formless_slash:GetCastPoint()
    local hCaster = self:GetCaster()
    return self.BaseClass.GetCastPoint(self) + ( hCaster:GetModifierStackCount("modifier_saito_formless_slash_counter", hCaster) == 3 and 0.3 or 0 )
end
function saito_formless_slash:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()

    local nMaxSlashes = self:GetSpecialValueFor("max_slashes")

    local nStacks = ( hCaster:GetModifierStackCount("modifier_saito_formless_slash_counter", hCaster) + 1 ) % nMaxSlashes
    if nStacks == 0 then
        EmitSoundOn("Saito.Formless.Slash.Last.Voice", hCaster)
        EmitZlodemonTrueSound("moskes_saito_rlast")
    elseif nStacks == 1 then
        EmitSoundOn("Saito.Formless.Slash.Cast.Voice", hCaster)
        EmitZlodemonTrueSound("moskes_saito_rslash")
    end
end
function saito_formless_slash:OnAbilityPhaseInterrupted()
    local hCaster = self:GetCaster()

    StopSoundOn("Saito.Formless.Slash.Cast.Voice", hCaster)
    StopSoundOn("Saito.Formless.Slash.Last.Voice", hCaster)
end
function saito_formless_slash:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()

    if IsSpellBlocked(hTarget) then
        return nil
    end

    local nDamageType = self:GetAbilityDamageType()

    local nMaxSlashes = self:GetSpecialValueFor("max_slashes")

    local nSlashInstances = self:GetSpecialValueFor("slash_instances")

    local nLockDuration     = self:GetSpecialValueFor("lock_duration")
    local nLastLockDuration = self:GetSpecialValueFor("last_lock_duration")
    --TO DO: Fixing there to attack damage if needed.
    local nSlashDamage = self:GetSpecialValueFor("slash_damage") + hCaster:GetAverageTrueAttackDamage(hTarget) * 0.01 * GetAttributeValue(hCaster, "saito_attribute_kunishige", "fls_dmg_per_atk", self:GetLevel(), 0)
    local nLastDamage  = self:GetSpecialValueFor("last_damage") + hCaster:GetAverageTrueAttackDamage(hTarget) * 0.01 * GetAttributeValue(hCaster, "saito_attribute_kunishige", "fls_last_dmg_per_atk", self:GetLevel(), 0)

    local nRevokedScale = GetAttributeValue(hCaster, "saito_attribute_kunishige", "fls_revoked_scale", -1, 1)
    if not hTarget:IsHero() or bIsRevoked(hTarget) then
        nSlashDamage = nSlashDamage * nRevokedScale
        nLastDamage = nLastDamage * nRevokedScale
    end

    local nStacksNew = ( hCaster:GetModifierStackCount("modifier_saito_formless_slash_counter", hCaster) + 1 ) % nMaxSlashes
    --There only if /nSlashes == without the .value after the dot then it autosets to 0 the slash counter and also helps handle which slashes it is.
    hCaster:SetModifierStackCount("modifier_saito_formless_slash_counter", hCaster, nStacksNew)
    
    local nAttrRootDuration     = GetAttributeValue(hCaster, "saito_attribute_freedom", "fls_root_duration", -1, 0)
    local nAttrLastRootDuration = GetAttributeValue(hCaster, "saito_attribute_freedom", "fls_last_root_duration", -1, 0)

    if nStacksNew == 0 then
        hCaster:RemoveModifierByNameAndCaster("modifier_saito_formless_invis", hCaster) --Invis breaks early.
        giveUnitDataDrivenModifier(hCaster, hTarget, "locked", nLastLockDuration)
        if nAttrLastRootDuration > 0 then
            giveUnitDataDrivenModifier(hCaster, hTarget, "rooted", nAttrLastRootDuration)
        end
        DoDamage(hCaster, hTarget, nLastDamage, nDamageType, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, self, false)
        self:DoLastSlashEffect(hTarget)
    else
        giveUnitDataDrivenModifier(hCaster, hTarget, "locked", nLockDuration)
        if nAttrRootDuration > 0 then
            giveUnitDataDrivenModifier(hCaster, hTarget, "rooted", nAttrRootDuration)
        end
        for i = 1, nSlashInstances do
            DoDamage(hCaster, hTarget, nSlashDamage, nDamageType, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, self, false)
        end
        self:DoDoubleSlashEffect(hTarget)
    end

    self:CreateFlash(hCaster)
end
function saito_formless_slash:CreateFlash(hCaster)
    local sFlashPFX = "particles/heroes/saito/saito_formless_slash_cast.vpcf"
    local nFlashPFX =   ParticleManager:CreateParticle( sFlashPFX, PATTACH_ABSORIGIN_FOLLOW, hCaster )
                        ParticleManager:SetParticleControlEnt(
                                                                nFlashPFX,
                                                                0,
                                                                hCaster,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_swordpack",
                                                                hCaster:GetForwardVector(), -- unknown
                                                                false -- unknown, true
                                                            )
                        ParticleManager:SetParticleControlForward(nFlashPFX, 0, hCaster:GetForwardVector())
                        ParticleManager:ReleaseParticleIndex(nFlashPFX)

    EmitSoundOn("Saito.Formless.Slash.Cast", hCaster)
end
function saito_formless_slash:DoDoubleSlashEffect(hTarget)
    local sSlashPFX = "particles/heroes/saito/saito_formless_slash_double.vpcf"
    local nSlashPFX =   ParticleManager:CreateParticle(sSlashPFX, PATTACH_ABSORIGIN_FOLLOW, hTarget)
                        ParticleManager:SetParticleControlEnt(
                                                                nSlashPFX,
                                                                0,
                                                                hTarget,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_hitloc",
                                                                Vector(0,0,0), -- unknown
                                                                false -- unknown, true
                                                            )
                        ParticleManager:SetParticleControl(nSlashPFX, 1, hTarget:GetAbsOrigin())
                        ParticleManager:SetParticleControl(nSlashPFX, 2, hTarget:GetAbsOrigin())
                        ParticleManager:SetParticleControl(nSlashPFX, 3, hTarget:GetAbsOrigin())
                        ParticleManager:ReleaseParticleIndex(nSlashPFX)

    EmitSoundOn("Saito.Formless.Slash.Impact", hTarget)
end
function saito_formless_slash:DoLastSlashEffect(hTarget)
    local sSlashPFX = "particles/heroes/saito/saito_formless_slash_last.vpcf"
    local nSlashPFX =   ParticleManager:CreateParticle(sSlashPFX, PATTACH_ABSORIGIN_FOLLOW, hTarget)
                       -- ParticleManager:SetParticleControlForward(nSlashPFX, 1, -self:GetCaster():GetForwardVector())
                        ParticleManager:SetParticleControlTransformForward(nSlashPFX, 1, hTarget:GetAbsOrigin(), -self:GetCaster():GetForwardVector())
                        ParticleManager:SetParticleControlEnt(
                                                                nSlashPFX,
                                                                0,
                                                                hTarget,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_hitloc",
                                                                Vector(0,0,0), -- unknown
                                                                false -- unknown, true
                                                            )

                       -- ParticleManager:SetParticleControl(nSlashPFX, 1, hTarget:GetAbsOrigin())
                        --ParticleManager:SetParticleControl(nSlashPFX, 10, GetDirection(hTarget, self:GetCaster()))
                        ParticleManager:ReleaseParticleIndex(nSlashPFX)

    EmitSoundOn("Saito.Formless.Slash.Last", hTarget)
    EmitSoundOn("Saito.Formless.Slash.Layer", hTarget)
    EmitSoundOn("Saito.Formless.Slash.Blood", hTarget)
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_formless_slash_counter", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_formless_slash_counter = modifier_saito_formless_slash_counter or class({})

function modifier_saito_formless_slash_counter:IsHidden()                                                           return not self:GetParent():HasModifier("modifier_saito_formless_invis") end --Hide counter if don't have the invis modifier AKA not swapped.
function modifier_saito_formless_slash_counter:IsDebuff()                                                           return false end
function modifier_saito_formless_slash_counter:IsPurgable()                                                         return false end
function modifier_saito_formless_slash_counter:IsPurgeException()                                                   return false end
function modifier_saito_formless_slash_counter:RemoveOnDeath()                                                      return false end






























--INVINCIBLE SWORD [SA] ABILITIES
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_step = saito_step or class({})

function saito_step:GetAOERadius()
    return self:GetSpecialValueFor("max_distance")
end
function saito_step:CastFilterResultLocation(vLocation)
    if IsLocked(self:GetCaster()) then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end
function saito_step:GetCustomCastErrorLocation(vLocation)
    return "#saito_step_locked_error"
end
function saito_step:OnSpellStart()
    local hCaster = self:GetCaster()
    local vPoint  = self:GetCursorPosition() + hCaster:GetForwardVector()

    local nMaxDistance = self:GetAOERadius()
    local nMinDistance = self:GetSpecialValueFor("min_distance")

    local nRadius = self:GetSpecialValueFor("radius")

    local nDamageType = self:GetAbilityDamageType()
    local nDamage = self:GetSpecialValueFor("damage")

    local nStunDuration = self:GetSpecialValueFor("stun_duration")

    local vCasterLoc = hCaster:GetAbsOrigin()
    local vDirection = GetDirection(vPoint, hCaster)
    local nDistance  = math.min(math.max(GetDistance(vPoint, vCasterLoc), nMinDistance), nMaxDistance)

    vPoint = vCasterLoc + vDirection * nDistance
    while ( not GridNav:IsTraversable(vPoint) or GridNav:IsBlocked(vPoint) ) do
        nDistance = nDistance - 10
        vPoint = vCasterLoc + vDirection * nDistance
    end

    FindClearSpaceForUnit(hCaster, vPoint, true)

    local hEntities = FindUnitsInRadius(
                                            hCaster:GetTeamNumber(),
                                            vPoint,
                                            nil,
                                            nRadius,
                                            self:GetAbilityTargetTeam(),
                                            self:GetAbilityTargetType(),
                                            self:GetAbilityTargetFlags(),
                                            FIND_CLOSEST,
                                            false
                                        )
    --=================================--
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity) then
            giveUnitDataDrivenModifier(hCaster, hEntity, "stunned", nStunDuration)

            DoDamage(hCaster, hEntity, nDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
        end
    end

    local nBlinkEND_PFX =   ParticleManager:CreateParticle("particles/heroes/saito/saito_step_aoe_end.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleControlForward(nBlinkEND_PFX, 0, hCaster:GetForwardVector())
                            ParticleManager:SetParticleControl(nBlinkEND_PFX, 0, vPoint)
                            --ParticleManager:SetParticleControl(nBlinkEND_PFX, 1, vCasterLoc)
                            ParticleManager:SetParticleControl(nBlinkEND_PFX, 2, Vector(nRadius, 0, 0))
                            --ParticleManager:DestroyParticle(nBlinkEND_PFX, false)
                            ParticleManager:ReleaseParticleIndex(nBlinkEND_PFX)

    hCaster:EmitSound("Saito.Step.Cast")
    EmitSoundOnLocationWithCaster(vPoint, "Saito.Step.Impact", hCaster)
    EmitZlodemonTrueSound("moskes_saito_qup")

    hCaster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1_END, 1.0)
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_storm = saito_storm or class({})

function saito_storm:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()

    hCaster:AddNewModifier(hCaster, self, "modifier_saito_storm_motion", {duration = self:GetSpecialValueFor("duration")})
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_storm_motion", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_HORIZONTAL)

modifier_saito_storm_motion = modifier_saito_storm_motion or class({})

function modifier_saito_storm_motion:IsHidden()                                                                     return true end
function modifier_saito_storm_motion:IsDebuff()                                                                     return false end
function modifier_saito_storm_motion:IsPurgable()                                                                   return false end
function modifier_saito_storm_motion:IsPurgeException()                                                             return false end
function modifier_saito_storm_motion:RemoveOnDeath()                                                                return true end
function modifier_saito_storm_motion:GetPriority()                                                                  return MODIFIER_PRIORITY_HIGH end
function modifier_saito_storm_motion:CheckState()
    local hState =  {
                        [MODIFIER_STATE_STUNNED] = true
                    }

    if IsNotNull(self.hTarget)
        and self.hTarget:HasFlyMovementCapability() then
        hState[MODIFIER_STATE_FLYING]  = true
    end

    return hState
end
function modifier_saito_storm_motion:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_PROPERTY_OVERRIDE_ANIMATION
                    }
    return hFunc
end
function modifier_saito_storm_motion:GetOverrideAnimation(keys)
    return ACT_DOTA_OVERRIDE_ABILITY_2
end
function modifier_saito_storm_motion:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.nDamageType           = self.hAbility:GetAbilityDamageType()
        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self.hTarget = self.hAbility:GetCursorTarget()

        self.fDuration = self.hAbility:GetSpecialValueFor("fly_duration")
        self.fFixTime  = self:GetDuration() - self.fDuration
        self.fSpeed    = 1000 --CORRELATES WITH FLYING TIME.

        self.fOffset = ( self.hTarget:BoundingRadius2D() + self.hParent:BoundingRadius2D() ) * 2

        self.nDamage = self.hAbility:GetSpecialValueFor("damage")

        self.nStunDuration = self.hAbility:GetSpecialValueFor("stun_duration")

        self.nPierceRange = self.hAbility:GetSpecialValueFor("pierce_range")
        self.nPierceWidth = self.hAbility:GetSpecialValueFor("pierce_width")

        if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end

        if not self.nDashPFX then
            self.nDashPFX =     ParticleManager:CreateParticle("particles/heroes/saito/saito_flashblade_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                                ParticleManager:SetParticleControlEnt(
                                                                        self.nDashPFX,
                                                                        0,
                                                                        self.hParent,
                                                                        PATTACH_POINT_FOLLOW,
                                                                        "attach_hitloc",
                                                                        Vector(0,0,0), -- unknown
                                                                        true -- unknown, true
                                                                    )

            self:AddParticle(self.nDashPFX, false, false, -1, false, false)
        end

        EmitSoundOn("Saito.Formless.Slash.Cast", self.hParent)
        EmitSoundOn("Saito.Storm.Cast", self.hParent)
        EmitZlodemonTrueSound("moskes_saito_wup")
    end
end
function modifier_saito_storm_motion:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_storm_motion:UpdateHorizontalMotion(me, dt)
    --me == Unit, dt == time, basically me == self.hParent == self:GetParent(), dt == 0.03333 == FrameTime() == basic time 33hz thinks on the Server.
    if IsNotNull(self.hTarget)
        and UnitFilter( self.hTarget,
                        self.nABILITY_TARGET_TEAM,
                        self.nABILITY_TARGET_TYPE,
                        self.nABILITY_TARGET_FLAGS,
                        self.nCASTER_TEAM ) == UF_SUCCESS then
        local fDistance = GetDistance(self.hTarget, me)
        local fRemainingTime = self:GetRemainingTime() - self.fFixTime
        --if fDistance > self.fOffset then
        --This thinking motion with each frame gets closer based on the total time it should take to hit the target.
        if fRemainingTime > dt then
            local vDirection  = GetDirection(self.hTarget, me)
            local fSpeed      = fDistance / fRemainingTime
            local fUnitsPerDt = fSpeed * dt
            local vCurPos     = me:GetAbsOrigin()
            local vNextPos    = vCurPos + vDirection * fUnitsPerDt

            if fDistance <= self.fOffset then
                vNextPos = vCurPos
            end
            
            if fUnitsPerDt >= fDistance then
                vNextPos = self.hTarget:GetAbsOrigin() - vDirection * self.fOffset
            end

            self.hParent:FaceTowards(vNextPos)
            SetDirectionByAngles(me, vDirection)

            return me:SetAbsOrigin(vNextPos)
        elseif not self.bTargetPoked then
            return self:PokeEnemy()
        end
    end
    return self:Destroy()
end
function modifier_saito_storm_motion:OnHorizontalMotionInterrupted()
    self:Destroy()
end
function modifier_saito_storm_motion:OnDestroy()
    if IsServer() then
        self.hParent:RemoveHorizontalMotionController(self)
        --self.hParent:InterruptMotionControllers(true)
        self.hParent:RemoveGesture(self:GetOverrideAnimation()) --This line is necessary to prevent animation loop issues when modifiers are not exist but you are still animated.
    end
end
function modifier_saito_storm_motion:PokeEnemy()
    if IsServer()
        and IsNotNull(self.hTarget) then
        self.bTargetPoked = true

        --Uncomment for normal linken.
        -- if self.hTarget:TriggerSpellAbsorb(self.hAbility) then
        --     return nil
        -- end
        if IsSpellBlocked(self.hTarget) then
            return nil
        end

        giveUnitDataDrivenModifier(self.hCaster, self.hTarget, "stunned", self.nStunDuration)

        local vParentLoc = self.hParent:GetAbsOrigin()
        local vDirection = GetDirection(self.hTarget, vParentLoc)

        self:PlayEffects(self.hTarget, vDirection)

        local tEntities = FindUnitsInLine(
                                            self.nCASTER_TEAM,
                                            vParentLoc,
                                            vParentLoc + vDirection * self.nPierceRange,
                                            nil,
                                            self.nPierceWidth,
                                            self.nABILITY_TARGET_TEAM,
                                            self.nABILITY_TARGET_TYPE,
                                            self.nABILITY_TARGET_FLAGS
                                        )

        for _, hEntity in pairs(tEntities) do
            if IsNotNull(hEntity) then
                DoDamage(self.hCaster, hEntity, self.nDamage, self.nDamageType, DOTA_DAMAGE_FLAG_NONE, self.hAbility, false)
            end
        end
    end
end
function modifier_saito_storm_motion:PlayEffects(hTarget, vDirection)
    local sImpactPFX = "particles/heroes/saito/saito_storm_impact.vpcf"

    local nImpactPFX = ParticleManager:CreateParticle(sImpactPFX, PATTACH_ABSORIGIN_FOLLOW, hTarget)
                        ParticleManager:SetParticleControlEnt(
                                                                nImpactPFX,
                                                                0,
                                                                hTarget,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_hitloc",
                                                                Vector(0,0,0), -- unknown
                                                                true -- unknown, true
                                                                )

    ParticleManager:SetParticleControl(nImpactPFX, 1, hTarget:GetAbsOrigin())
    ParticleManager:SetParticleControlForward(nImpactPFX, 1, vDirection)
    ParticleManager:SetParticleControl(nImpactPFX, 4, Vector(self.nPierceRange, self.nPierceWidth, 0))
    ParticleManager:ReleaseParticleIndex(nImpactPFX)

    EmitSoundOn("Saito.Storm.Impact", hTarget)
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_vortex = saito_vortex or class({})

function saito_vortex:GetAOERadius()
    return self:GetSpecialValueFor("pull_radius")
end
function saito_vortex:OnSpellStart()
    local hCaster = self:GetCaster()

    hCaster:AddNewModifier(hCaster, self, "modifier_saito_vortex_slashing", {duration = 3}) --3 seconds just to prevent any mistakes.

    EmitZlodemonTrueSound("moskes_saito_eup")
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_vortex_slashing", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_vortex_slashing = modifier_saito_vortex_slashing or class({})

function modifier_saito_vortex_slashing:IsHidden()                                                                  return false end
function modifier_saito_vortex_slashing:IsDebuff()                                                                  return false end
function modifier_saito_vortex_slashing:IsPurgable()                                                                return false end
function modifier_saito_vortex_slashing:IsPurgeException()                                                          return false end
function modifier_saito_vortex_slashing:RemoveOnDeath()                                                             return true end
function modifier_saito_vortex_slashing:IsAura()                                                                    return true end
function modifier_saito_vortex_slashing:IsAuraActiveOnDeath()                                                       return false end
function modifier_saito_vortex_slashing:IsPermanent()                                                               return false end
function modifier_saito_vortex_slashing:CheckState()
    local tState =  {
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_STUNNED]           = true
                    }
    return tState
end
function modifier_saito_vortex_slashing:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_OVERRIDE_ANIMATION
                    }
    return tFunc
end
function modifier_saito_vortex_slashing:GetOverrideAnimation()
    return ACT_DOTA_OVERRIDE_ABILITY_3 --NOTE: Change to 1 or 3 or 4 and choose yourself, each time need to use addon_game_launch to reload..
end
function modifier_saito_vortex_slashing:GetAuraRadius()
    return self.nPullRadius
end
function modifier_saito_vortex_slashing:GetAuraDuration()
    return 0.1
end
function modifier_saito_vortex_slashing:GetAuraSearchTeam()
    return self.nABILITY_TARGET_TEAM
end
function modifier_saito_vortex_slashing:GetAuraSearchType()
    return self.nABILITY_TARGET_TYPE
end
function modifier_saito_vortex_slashing:GetAuraSearchFlags()
    return self.nABILITY_TARGET_FLAGS
end
function modifier_saito_vortex_slashing:GetModifierAura()
    return "modifier_saito_vortex_pull"
end
function modifier_saito_vortex_slashing:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nPullRadius = self.hAbility:GetAOERadius()

    self.nSlashRadius     = self.hAbility:GetSpecialValueFor("slash_radius")
    self.nSlashLastRadius = self.hAbility:GetSpecialValueFor("slash_last_radius")

    self.nSlashStunDuration = self.hAbility:GetSpecialValueFor("slash_stun_duration")

    self.nKnockDistance = self.hAbility:GetSpecialValueFor("knockback_distance")
    self.nKnockDuration = self.hAbility:GetSpecialValueFor("knockback_duration")

    self.nSlashCount    = self.hAbility:GetSpecialValueFor("slashes_count")
    self.nSlashInterval = self.hAbility:GetSpecialValueFor("slashes_interval")

    self.nSlashDamage     = self.hAbility:GetSpecialValueFor("slash_damage")
    self.nSlashLastDamage = self.hAbility:GetSpecialValueFor("slash_last_damage")

    if IsServer() then
        self.nDamageType           = self.hAbility:GetAbilityDamageType()
        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self:StartIntervalThink(self.nSlashInterval)
        self:OnIntervalThink()
    end
end
function modifier_saito_vortex_slashing:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_saito_vortex_slashing:OnIntervalThink()
    if IsServer() then
        self:IncrementStackCount()

        local nDamage = self.nSlashDamage
        local nRadius = self.nSlashRadius

        local bLastSlash = (self:GetStackCount() % self.nSlashCount) == 0

        if bLastSlash then
            nDamage = self.nSlashLastDamage
            nRadius = self.nSlashLastRadius
        end

        local vParentLoc = self.hParent:GetAbsOrigin()

        local tEntities = FindUnitsInRadius(
                                            self.nCASTER_TEAM,
                                            vParentLoc,
                                            nil,
                                            nRadius,
                                            self.nABILITY_TARGET_TEAM,
                                            self.nABILITY_TARGET_TYPE,
                                            self.nABILITY_TARGET_FLAGS,
                                            FIND_CLOSEST,
                                            false)

        for _, hEntity in pairs(tEntities) do
            if IsNotNull(hEntity) then
                if bLastSlash then
                    giveUnitDataDrivenModifier(self.hCaster, hEntity, "stunned", self.nKnockDuration)

                    fApplyKnockbackSpecial(hEntity, self.nKnockDistance, self.nKnockDuration, GetDirection(hEntity, vParentLoc))

                    EmitSoundOn("Saito.Vortex.Impact", hEntity)
                else
                    giveUnitDataDrivenModifier(self.hCaster, hEntity, "stunned", self.nSlashStunDuration)

                    EmitSoundOn("Hero_Saito.Attack", hEntity)
                end
                DoDamage(self.hCaster, hEntity, nDamage, self.nDamageType, DOTA_DAMAGE_FLAG_NONE, self.hAbility, false)
            end
        end

        self:PlayEffects(self.hParent, nRadius)

        giveUnitDataDrivenModifier(self.hCaster, self.hParent, "pause_sealdisabled", 0.3) --NOTE: With another solution [?]

        if bLastSlash then
            self:Destroy()
        end
    end
end
function modifier_saito_vortex_slashing:OnDestroy()
    if IsServer() then
        self.hParent:RemoveGesture(self:GetOverrideAnimation()) --This line is necessary to prevent animation loop issues when modifiers are not exist but you are still animated.
    end
end
function modifier_saito_vortex_slashing:PlayEffects(hCaster, nRadius)
    local sImpactPFX = "particles/heroes/saito/saito_vortex_slash.vpcf"
    local nImpactPFX =  ParticleManager:CreateParticle(sImpactPFX, PATTACH_ABSORIGIN_FOLLOW, hCaster)
                        --ParticleManager:SetParticleControl(nImpactPFX, 0, hCaster:GetAbsOrigin())
                        ParticleManager:SetParticleControl(nImpactPFX, 1, Vector( nRadius, nRadius, nRadius ))
                        ParticleManager:SetParticleControl(nImpactPFX, 2, Vector( 0.2, 0, 0 ))
                        ParticleManager:SetParticleControlEnt(
                                                                nImpactPFX,
                                                                3,
                                                                hCaster,
                                                                PATTACH_POINT_FOLLOW,
                                                                "attach_hitloc",
                                                                hCaster:GetForwardVector(), -- unknown
                                                                false -- unknown, true
                                                            )
                        ParticleManager:SetParticleControlForward(nImpactPFX, 3, hCaster:GetForwardVector())
                        --ParticleManager:DestroyParticle(nImpactPFX, false)
                        ParticleManager:ReleaseParticleIndex(nImpactPFX)

    EmitSoundOnLocationWithCaster(hCaster:GetAbsOrigin(), "Saito.Shadowslash.Cast", hCaster)
    EmitSoundOn("Saito.Formless.Slash.Cast", hCaster)

    hCaster:StartGesture(ACT_DOTA_CAST_ABILITY_3) --Just for now... it's PEPE but for testing.
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_vortex_pull", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_HORIZONTAL)

modifier_saito_vortex_pull = modifier_saito_vortex_pull or class({})

function modifier_saito_vortex_pull:IsHidden()                                                                      return false end
function modifier_saito_vortex_pull:IsDebuff()                                                                      return true end
function modifier_saito_vortex_pull:IsPurgable()                                                                    return true end
function modifier_saito_vortex_pull:IsPurgeException()                                                              return true end
function modifier_saito_vortex_pull:RemoveOnDeath()                                                                 return true end
function modifier_saito_vortex_pull:GetPriority()                                                                   return MODIFIER_PRIORITY_NORMAL end
function modifier_saito_vortex_pull:CheckState()
    local tState =  {
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
                    }
    return tState
end
function modifier_saito_vortex_pull:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nPullSpeed = self.hAbility:GetSpecialValueFor("pull_speed")

    if IsServer() then
        self.nThinkTime = FrameTime()
        self:StartIntervalThink(self.nThinkTime)

        self.nOffset = ( self.hCaster:BoundingRadius2D() + self.hParent:BoundingRadius2D() ) * 2

        local nLockDuration = (self.hAbility:GetSpecialValueFor("slashes_count") - 1) * self.hAbility:GetSpecialValueFor("slashes_interval")
        --Based on -= total time, if it is dispelled then it no longer applies.
        giveUnitDataDrivenModifier(self.hCaster, self.hParent, "locked", nLockDuration) --Can be changed instead if you enter the name of the current modifier in the "list" of locks (in util.lua), and remove this function that adds the locks manually.
    end
end
function modifier_saito_vortex_pull:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_saito_vortex_pull:OnIntervalThink()
    if IsServer() then
        self:ChargeMotion(self.hParent, self.nThinkTime)
    end
end
function modifier_saito_vortex_pull:ChargeMotion(me, dt)
    if IsServer() then
        local vCenterLoc = self.hCaster:GetAbsOrigin()

        local vDirection = GetDirection(vCenterLoc, me)

        local nPullSpeed = self.nPullSpeed * dt

        local vNowLoc  = me:GetAbsOrigin()
        local vNextLoc = vNowLoc + vDirection * nPullSpeed
        local vNextLoc = GetGroundPosition(vNextLoc, me)

        if GetDistance(me, vCenterLoc) > self.nOffset then
            self.hParent:SetAbsOrigin(vNextLoc)
        end
    end
end
function modifier_saito_vortex_pull:OnHorizontalMotionInterrupted() --Looks can be called because modifier type is motioned.
    if IsServer() then
        print("TEST")
        self:Destroy()
    end
end
function modifier_saito_vortex_pull:OnDestroy()
    if IsServer() then
        FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true)
    end
end




















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
saito_blast = saito_blast or class({})

function saito_blast:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end
function saito_blast:OnSpellStart()
    local hCaster = self:GetCaster()

    local vCasterLoc  = hCaster:GetAbsOrigin()
    local vCasterFow  = hCaster:GetForwardVector()
    local vStartPoint = vCasterLoc + vCasterFow * 100

    local nSpeed = self:GetSpecialValueFor("speed")

    local nDamage = self:GetSpecialValueFor("damage")

    local nKnockbackDuration = self:GetSpecialValueFor("knockback_duration")
    local nKnockbackDistance = self:GetSpecialValueFor("knockback_distance")

    local nSDRDuration = self:GetSpecialValueFor("turn_and_slow_duration")
    local nRadialCount = self:GetSpecialValueFor("radial_count")

    self.___tHittedTargets = {}

    local tProjectileInfo = {
                                Source       = hCaster,
                                Ability      = self,
                                vSpawnOrigin = vCasterLoc,

                                iUnitTargetTeam   = self:GetAbilityTargetTeam(),
                                iUnitTargetType   = self:GetAbilityTargetType(),
                                iUnitTargetFlags  = self:GetAbilityTargetFlags(),

                                EffectName        = "particles/heroes/saito/saito_blast_projectile.vpcf",
                                fDistance         = self:GetAOERadius(),
                                fStartRadius      = self:GetSpecialValueFor("radius_start"),
                                fEndRadius        = self:GetSpecialValueFor("radius_end"),
                                vVelocity         = vCasterFow * nSpeed,

                                bHasFrontalCone   = false,

                                bProvidesVision   = false,
                                iVisionRadius     = 0,
                                iVisionTeamNumber = hCaster:GetTeamNumber(),

                                bVisibleToEnemies = true,

                                ExtraData = {
                                                vStart_x = vCasterLoc.x,
                                                vStart_y = vCasterLoc.y,
                                                vStart_z = vCasterLoc.z,

                                                nSDRDuration = nSDRDuration,

                                                nKnockDur  = nKnockbackDuration,
                                                nKnockDist = nKnockbackDistance,

                                                damage      = nDamage,
                                                nDamageType = self:GetAbilityDamageType(),
                                            }
                            }

    local fAngles = 360 / nRadialCount
    for iArray = 1, nRadialCount do
        tProjectileInfo.vVelocity = GetDirection(vStartPoint, vCasterLoc) * nSpeed

        local nBlastProjectile = ProjectileManager:CreateLinearProjectile(tProjectileInfo)

        vStartPoint = RotatePosition(vCasterLoc, QAngle(0, fAngles, 0), vStartPoint)
    end

    EmitSoundOn("Saito.Blast.Cast.Voice", hCaster)
    EmitSoundOn("Saito.Blast.Cast", hCaster)

    hCaster:RemoveModifierByNameAndCaster("modifier_saito_blast_swap", hCaster) --Swapping back after emitting sound.
end
function saito_blast:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
    if IsNotNull(hTarget) and not self.___tHittedTargets[hTarget] then --Uncomment to make the unit only affected by one blast, when standing in an area of multiple blasts.
        self.___tHittedTargets[hTarget] = true

        local hCaster = self:GetCaster()
        --=================================--
        fApplyKnockbackSpecial(hTarget, tExtraData.nKnockDist, tExtraData.nKnockDur, GetDirection(hTarget, Vector(tExtraData.vStart_x, tExtraData.vStart_y, tExtraData.vStart_z)))
        --=================================--
        DoDamage(hCaster, hTarget, tExtraData.damage, tExtraData.nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
        --=================================--
        hTarget:AddNewModifier(hCaster, self, "modifier_saito_blast_turn_and_slow", {duration = tExtraData.nSDRDuration})
        --=================================--
        giveUnitDataDrivenModifier(hCaster, hTarget, "locked", tExtraData.nKnockDur)
        --=================================--
        EmitSoundOn("Saito.Blast.Impact", hTarget)
    end
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_blast_turn_and_slow", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_blast_turn_and_slow = modifier_saito_blast_turn_and_slow or class({})

function modifier_saito_blast_turn_and_slow:IsHidden()                                                              return false end
function modifier_saito_blast_turn_and_slow:IsDebuff()                                                              return true end
function modifier_saito_blast_turn_and_slow:IsPurgable()                                                            return false end
function modifier_saito_blast_turn_and_slow:IsPurgeException()                                                      return false end
function modifier_saito_blast_turn_and_slow:RemoveOnDeath()                                                         return true end
function modifier_saito_blast_turn_and_slow:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
                        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
                    }
    return tFunc
end
function modifier_saito_blast_turn_and_slow:GetModifierTurnRate_Percentage(keys)
    return RemapValClamped(self:GetElapsedTime(), 0, self:GetDuration(), self.nTASMaxValue, self.nTASMinValue)
end
function modifier_saito_blast_turn_and_slow:GetModifierMoveSpeedBonus_Percentage(keys)
    return RemapValClamped(self:GetElapsedTime(), 0, self:GetDuration(), self.nTASMaxValue, self.nTASMinValue)
end
--Autolerper and autoclamper values based on elapsed time after applied... with this modifier from duration.
function modifier_saito_blast_turn_and_slow:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    --self.nSDRValue = self.hAbility:GetSpecialValueFor("sdr_value")
    self.nTASMaxValue = self.hAbility:GetSpecialValueFor("turn_and_slow_max_value")
    self.nTASMinValue = self.hAbility:GetSpecialValueFor("turn_and_slow_min_value")
end
function modifier_saito_blast_turn_and_slow:OnRefresh(tTable)
    self:OnCreated(tTable)
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_saito_blast_swap", "abilities/saito/saito_abilities", LUA_MODIFIER_MOTION_NONE)

modifier_saito_blast_swap = modifier_saito_blast_swap or class({})

function modifier_saito_blast_swap:IsHidden()                                                                       return true end
function modifier_saito_blast_swap:IsDebuff()                                                                       return false end
function modifier_saito_blast_swap:IsPurgable()                                                                     return false end
function modifier_saito_blast_swap:IsPurgeException()                                                               return false end
function modifier_saito_blast_swap:RemoveOnDeath()                                                                  return false end
function modifier_saito_blast_swap:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.hParent:SwapAbilities("saito_mind_eye", "saito_blast", false, true)
    end
end
function modifier_saito_blast_swap:OnRefresh(tTable)
    --self:OnCreated(tTable)
end
function modifier_saito_blast_swap:OnDestroy()
    if IsServer() then
        self.hParent:SwapAbilities("saito_mind_eye", "saito_blast", true, false)
    end
end