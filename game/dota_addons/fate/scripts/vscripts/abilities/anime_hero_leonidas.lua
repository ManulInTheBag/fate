--CreateTalentsModifiers("leonidas")

--JUST FOR NEWEST VERSION FROM MY SOURCES
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--NOTE: Using aka IsNotNull(false) will return "true", because it's boolean, 1st got in vergil trigger gauge, be carefull.
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
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetDistance = function(hEnt1, hEnt2, b3D)
    hEnt1 = type(hEnt1.GetAbsOrigin) == "function" and hEnt1:GetAbsOrigin() or hEnt1
    hEnt2 = type(hEnt2.GetAbsOrigin) == "function" and hEnt2:GetAbsOrigin() or hEnt2
    return b3D and (hEnt1 - hEnt2):Length() or (hEnt1 - hEnt2):Length2D()
end
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
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetClamped = function(nValue, nMin, nMax)
    return nValue <= nMin and nMin or (nValue >= nMax and nMax or nValue)
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetLerped = function(nMin, nMax, fTime)
    return nMin + ( nMax - nMin ) * fTime
end


--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
TableLength = function(hTable)
    local i = 0
    if type(hTable) == "table" then
        for _ in pairs(hTable) do
            i = i + 1
        end
    end
    return i
end


if IsServer() then
    --!!----------------------------------------------------------------------------------------------------------------------------------------------------------
    RollPseudoRandom = function(nChance, hEntity) --NOTE: As each bonus code i've loaded from my sources
        if type(nChance) == "number" 
            and IsNotNull(hEntity) then
            local sEntityName = hEntity:GetName()

            hEntity = type(hEntity.GetCaster) == "function"
                      and hEntity:GetCaster()
                      or hEntity

            hEntity.___tRPR_TABLE              = hEntity.___tRPR_TABLE or {}
            hEntity.___tRPR_TABLE[sEntityName] = hEntity.___tRPR_TABLE[sEntityName] or ( TableLength(hEntity.___tRPR_TABLE) + 1 )
            
            return RollPseudoRandomPercentage( nChance, hEntity.___tRPR_TABLE[sEntityName], hEntity )
        end
        return false
    end
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------





-- ANIME_ATTRIBUTE_NONE = 0
-- ANIME_ATTRIBUTE_1    = 1
-- ANIME_ATTRIBUTE_2    = 2
-- ANIME_ATTRIBUTE_3    = 4
-- ANIME_ATTRIBUTE_4    = 8
-- ANIME_ATTRIBUTE_5    = 16
-- ANIME_ATTRIBUTE_MAX  = ANIME_ATTRIBUTE_5

--========================================--
local GetAttributeValue = function(hUnit, sAttributeName, sKeyName, nLevel, nDefaultValue, bReturnAbility)
    --NOTE: -2 Becomes 0 return as with GetSpecialValueFor properly.... looks like
    nLevel = nLevel or -1
    if nLevel == 0 then
        nLevel = -2
    elseif nLevel > 0 then
        nLevel = nLevel - 1
    end
    --type(nLevel) == "number" and ( nLevel == 0 and -2 or ( nLevel - 1 ) ) or -1
    if IsNotNull(hUnit) then
        hUnit.____tAttributesTable = hUnit.____tAttributesTable or {}
        local hAttributeAbility = hUnit.____tAttributesTable[sAttributeName]
        if IsNotNull(hAttributeAbility) then
            if bReturnAbility then
                return hAttributeAbility
            end
            return hAttributeAbility:GetLevelSpecialValueFor(sKeyName, nLevel)
        end
    end
    return nDefaultValue or 0
end
--========================================--


---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_attributes", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_attributes = modifier_leonidas_attributes or class({})

function modifier_leonidas_attributes:IsHidden()                                                                       return false end
function modifier_leonidas_attributes:IsDebuff()                                                                       return false end
function modifier_leonidas_attributes:IsPurgable()                                                                     return false end
function modifier_leonidas_attributes:IsPurgeException()                                                               return false end
function modifier_leonidas_attributes:RemoveOnDeath()                                                                  return false end
function modifier_leonidas_attributes:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_leonidas_attributes:GetAttributes()                                                                  return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_leonidas_attributes:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
                        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
                        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
                    }
    return tFunc
end
function modifier_leonidas_attributes:GetModifierBonusStats_Strength(keys)
    if IsNotNull(self.hParent)
        and IsNotNull(self.hAbility)
        and self.hAbility:GetAbilityName() == "leonidas_math_attribute" then
        return GetAttributeValue(self.hParent, "leonidas_math_attribute", "int_to_str_pct", -1, 0, false) * self.hParent:GetIntellect() * 0.01
    end
end
function modifier_leonidas_attributes:GetModifierPhysicalArmorBonus(keys)
    if IsNotNull(self.hParent)
        and IsNotNull(self.hAbility)
        and self.hAbility:GetAbilityName() == "leonidas_army_attribute" then
        return GetAttributeValue(self.hParent, "leonidas_army_attribute", "bonus_armor_from_base_pct", -1, 0, false) * self.hParent:GetPhysicalArmorBaseValue() * 0.01
    end
end
-- function modifier_leonidas_attributes:GetModifierBaseDamageOutgoing_Percentage(keys)
--     if IsNotNull(self.hParent)
--         and IsNotNull(self.hAbility)
--         and self.hAbility:GetAbilityName() == "leonidas_army_attribute" then
--         return GetAttributeValue(hUnit, "leonidas_pride_attribute", "scale_per_hero", -1, 0, false)
--     end
-- end
function modifier_leonidas_attributes:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.hParent.____tAttributesTable = self.hParent.____tAttributesTable or {}

    if IsNotNull(self.hAbility) then
        self.hParent.____tAttributesTable[self.hAbility:GetAbilityName()] = self.hAbility
    end
end
function modifier_leonidas_attributes:OnRefresh(tTable)
    self:OnCreated(tTable)
end







--========================================--
local bIsRevoked = function(hUnit)
    local tRevokes = revokes or {}
    for nID, sRevokeModifier in pairs(tRevokes) do
        if hUnit:HasModifier(sRevokeModifier) then
            return true
        end
    end
end
--========================================--

--GetDisadvantageousSituationScale
local GetPrideAndBerserkedScaledDamage = function(hUnit, nDamage)
    local nDamage, bIsCritical = ( nDamage or 0 ), false
    if IsNotNull(hUnit) then
        --========================================--
        local nAlliesDead   = 0
        local nEnemiesAlive = 0
        --========================================--
        if not hUnit:PassivesDisabled() then --Because it's like passive
            local nUnitTeamNumber = hUnit:GetTeamNumber()
            LoopOverPlayers(function(hPlayer, nPlayerID, hPlayerHero)
                local bIsAlive    = hPlayerHero:IsAlive()
                local nTeamNumber = PlayerResource:GetTeam(nPlayerID)
                if nTeamNumber == nUnitTeamNumber then
                    if not bIsAlive then
                        nAlliesDead = nAlliesDead + 1
                    end
                else
                    if bIsAlive then
                        nEnemiesAlive = nEnemiesAlive + 1
                    end
                end
                --print("WTF", hPlayerHero:GetUnitName())
            end)
        end
        --========================================--
        local nPrideScaleValue = 1 + ( ( nAlliesDead + nEnemiesAlive ) * ( GetAttributeValue(hUnit, "leonidas_pride_attribute", "scale_per_hero", -1, 0, false) ) * 0.01 )
        --print("PRIDE SCALE MULTIPLIER: ", nPrideScaleValue)
        --========================================--
        nDamage = nDamage * nPrideScaleValue
        --========================================--
        if hUnit:HasModifier("modifier_leonidas_berserk") then --Because only while berserked
            local hMadAttribute = GetAttributeValue(hUnit, "leonidas_mad_attribute", "", -1, 0, true)

            local nCritChance     = hMadAttribute:GetSpecialValueFor("crit_chance")
            local nCritDamageBase = hMadAttribute:GetSpecialValueFor("crit_damage_base")
            local nCritDamageStr  = hMadAttribute:GetSpecialValueFor("crit_damage_str") * 0.01
            --========================================--
            if RollPseudoRandom(nCritChance, hUnit) then
                local nCritScale = ( nCritDamageBase + ( nCritDamageStr * hUnit:GetStrength() ) ) * 0.01
                --print("CRIT SCALE MULTIPLIER: ", nCritScale)
                nDamage = nDamage * nCritScale
                bIsCritical = true

                --SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hTarget, keys.original_damage * fCriticalDamage * 0.01, nil)
            end
        end
    end
    return ( nDamage or 0 ), bIsCritical
end









--NOTE: Basicaly if u watching is universal and can be used for all servants for handle on client values, aka fast creation server-client setuping
--NOTE2: This means checker above, modifier and example of usage for Attribute abilities above.
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_math_attribute = leonidas_math_attribute or class({}) 

function leonidas_math_attribute:IsStealable()                                         return true end
function leonidas_math_attribute:IsHiddenWhenStolen()                                  return false end
function leonidas_math_attribute:OnSpellStart()
    local hCaster     = self:GetCaster()
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(hCaster:GetPlayerOwnerID())

    local hMaster_1 = hPlayerHero.MasterUnit
    local hMaster_2 = hPlayerHero.MasterUnit2

    if IsNotNull(hPlayerHero) then
        Timers:CreateTimer(0, function()
            if hPlayerHero:IsAlive() then
                local bHasAttribute = false
                local tAllModifiers = hPlayerHero:FindAllModifiers()
                for _, hModifier in pairs(tAllModifiers) do
                    if IsNotNull(hModifier) and hModifier:GetName() == "modifier_leonidas_attributes" and hModifier:GetAbility() == self then
                        bHasAttribute = true
                    end
                end
                if not bHasAttribute then
                    hPlayerHero:AddNewModifier(hCaster, self, "modifier_leonidas_attributes", {})
                    return
                end
            end
            return 0.1
        end)

        if IsNotNull(hMaster_1) then
            hMaster_1:SetMana(hMaster_2:GetMana())
            --hMaster_1:SpendMana(self:GetManaCost(-1), self)
        end

        if type(self.OnAfterSpellStart) == "function" then
            self:OnAfterSpellStart(hPlayerHero)
        end
    end
end 
function leonidas_math_attribute:OnAfterSpellStart(hPlayerHero)
    
end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_army_attribute = leonidas_army_attribute or class(leonidas_math_attribute)

function leonidas_army_attribute:OnAfterSpellStart(hPlayerHero)

end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_pride_attribute = leonidas_pride_attribute or class(leonidas_math_attribute)

function leonidas_pride_attribute:OnAfterSpellStart(hPlayerHero)
    
end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_mad_attribute = leonidas_mad_attribute or class(leonidas_math_attribute)

function leonidas_mad_attribute:OnAfterSpellStart(hPlayerHero)
    local hBerserkAbility = hPlayerHero:FindAbilityByName("leonidas_berserk")
    if IsNotNull(hBerserkAbility)
        and hBerserkAbility:GetMaxLevel() > hBerserkAbility:GetLevel() then
        hBerserkAbility:SetLevel(hBerserkAbility:GetLevel() + 1)
    end
end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_bc_attribute = leonidas_bc_attribute or class(leonidas_math_attribute)

function leonidas_bc_attribute:OnAfterSpellStart(hPlayerHero)
    local hBCAbility = hPlayerHero:FindAbilityByName("leonidas_bc")
    if IsNotNull(hBCAbility)
        and hBCAbility:GetMaxLevel() > hBCAbility:GetLevel() then
        hBCAbility:SetLevel(hBCAbility:GetLevel() + 1)
    end
end








--NOTE: This is custom checker with many options, too hardcoded now because i fixed many params which not exist in anime yet, not final version but ideal 80%, now should using combo ability as additor
local CheckComboIsReadyIncrement = function(hUnit, iPreviousStackShouldBe)
    local iPreviousStackShouldBe = iPreviousStackShouldBe or 0
    if IsNotNull(hUnit)
        and hUnit:GetStrength() >= 30
        and hUnit:GetAgility() >= 30
        and hUnit:GetIntellect() >= 30 then
        local iStacksNow = hUnit:GetModifierStackCount("modifier_leonidas_enomotia_combo_indicator", hUnit)
        if iStacksNow == iPreviousStackShouldBe then
            return hUnit:SetModifierStackCount("modifier_leonidas_enomotia_combo_indicator", hUnit, iStacksNow + 1)
        end
    end
end




---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_enomotia_combo_indicator", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_enomotia_combo_indicator = modifier_leonidas_enomotia_combo_indicator or class({})

function modifier_leonidas_enomotia_combo_indicator:IsHidden()                                                                  return self:GetDuration() <= -1 end
function modifier_leonidas_enomotia_combo_indicator:IsDebuff()                                                                  return false end
function modifier_leonidas_enomotia_combo_indicator:IsPurgable()                                                                return false end
function modifier_leonidas_enomotia_combo_indicator:IsPurgeException()                                                          return false end
function modifier_leonidas_enomotia_combo_indicator:RemoveOnDeath()                                                             return false end
function modifier_leonidas_enomotia_combo_indicator:DestroyOnExpire()                                                           return false end
function modifier_leonidas_enomotia_combo_indicator:OnStackCountChanged(iOldStacks)
    if IsServer() then --NOTE: Crashes were because overloops when setstackcount checks setstackcount...
        --========================================-- --NOTE: Kostil prevention because if swapped ability in cooldown thats shouldbn'e be swapped
        local hAbilityForSwap_0 = self.hParent:FindAbilityByName(self.sAbilityForSwap_0)
        local hAbilityForSwap_1 = self.hParent:FindAbilityByName(self.sAbilityForSwap_1)

        if not self.bPreventStacksOverloop
            and not ( IsNotNull(hAbilityForSwap_0)
            and hAbilityForSwap_0:IsTrained() 
            and hAbilityForSwap_0:IsCooldownReady()
            and IsNotNull(hAbilityForSwap_1)
            and hAbilityForSwap_1:IsTrained() 
            and hAbilityForSwap_1:IsCooldownReady() 
            and hAbilityForSwap_1:IsHidden() ) then
            self.bPreventStacksOverloop = true
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

            self:SetStackCount(0) --NOTE: If trying setup any other ount ++ will be crash... maybe because at same time calls on master

            self:ComboToSlot(true)
        end
    end
end
function modifier_leonidas_enomotia_combo_indicator:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        --========================================--
        if not self.hParent:IsRealHero() then --Note: Prevention from applying on Master....
            return self:Destroy()
        end
        --========================================--
        self.fStepsDuration        = self.hAbility:GetSpecialValueFor("steps_duration")
        self.fComboDuration        = self.hAbility:GetSpecialValueFor("combo_duration")
        self.iComboStepsReadyCount = self.hAbility:GetSpecialValueFor("combo_steps")

        self.fThinkInterval = 0.03

        self.bLocalComboStepsTime     = self.bLocalComboStepsTime or false
        self.fLocalComboStepsTime     = self.fLocalComboStepsTime or 0
        self.bLocalComboAvailableTime = self.bLocalComboAvailableTime or false
        self.fLocalComboAvailableTime = self.fLocalComboAvailableTime or 0

        self.bLocalComboReleased = self.bLocalComboReleased or false

        self.sAbilityForSwap_0 = "leonidas_enomotia"
        self.sAbilityForSwap_1 = self.hAbility:GetAbilityName()

        self:StartIntervalThink(self.fThinkInterval)

        --print(self:GetDuration(), "ONCRWATETETETE")
    end
end
function modifier_leonidas_enomotia_combo_indicator:OnRefresh(hTable)
    self:OnCreated(hTable) --NOTE: Can cause some bugs but looks like reinition fixed
end
function modifier_leonidas_enomotia_combo_indicator:OnIntervalThink()
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
                or ( fCooldownRemaining > 0 ) then --NOTE: Released combo fix swaping
                self.bLocalComboAvailableTime = false
                self.fLocalComboAvailableTime = 0

                self.bLocalComboReleased = ( fCooldownRemaining > 0 )--IDK HOW IT FIXED DUBLICATE IN -1 CALL DURATION...

                self:ComboToSlot(false)

                --print("KEK", fCooldownRemaining)
            end
        end
        --========================================-- --NOTE: Fix visibility in master
        local bSetMasterComboTime = false
        --========================================-- fSelfRemaining > 0 or 
        if ( fCooldownRemaining <= 0 and ( fDuration > -1 ) and not ( self.bLocalComboStepsTime or self.bLocalComboAvailableTime ) ) then
            self:SetDuration(-1, true)
            --print("SETING DURATION -1", fSelfRemaining, fDuration, self.bLocalComboReleased)
            bSetMasterComboTime = true
        elseif ( ( fSelfRemaining <= 0 and fCooldownRemaining > 0 ) or ( self.bLocalComboReleased ) ) then
            self.bLocalComboReleased = false

            self:SetDuration(fCooldownRemaining, true)
            
            --print("SETING DURATION TO DURATION 11", fCooldownRemaining, self.bLocalComboReleased)
            bSetMasterComboTime = true
            --========================================-- --NOTE: Setup ultimate(swapped) cooldown because it's exist in fate...
            local hSwappedAbility = self.hParent:FindAbilityByName(self.sAbilityForSwap_0)
            if IsNotNull(hSwappedAbility)
                and hSwappedAbility:IsTrained()
                and hSwappedAbility:IsCooldownReady() then
                hSwappedAbility:UseResources(false, false, true)
            end
        end
        --========================================--
        if bSetMasterComboTime then --LOCAL STORAGE SO WILL BE NOTHING IN NEXT FRAME BUT FOR CLEAR SURE
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
function modifier_leonidas_enomotia_combo_indicator:ComboToSlot(bEnable)
    if IsServer() then
        if bEnable then
            EmitSoundOn("Artoria.Combo.Ready", self.hParent)
            self:SetDuration(self.fComboDuration, true)
        end
        return self.hParent:SwapAbilities(self.sAbilityForSwap_0, self.sAbilityForSwap_1, not bEnable, bEnable)
    end
end





























---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_kick = leonidas_kick or class({})

function leonidas_kick:IsStealable()                                         return true end
function leonidas_kick:IsHiddenWhenStolen()                                  return false end
function leonidas_kick:OnAbilityPhaseStart()
    local hCaster  = self:GetCaster()
    return true
end
function leonidas_kick:OnAbilityPhaseInterrupted()
end
function leonidas_kick:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()

    if IsSpellBlocked(hTarget) then
        return nil
    end

    local nDamageType = self:GetAbilityDamageType()

    local vDirection = GetDirection(hTarget, hCaster)

    local nDistance = self:GetSpecialValueFor("push_distance") * ( 1 + ( GetAttributeValue(hCaster, "leonidas_math_attribute", "kick_push_distance_pct_scale_per_int", -1, 0, false) * hCaster:GetIntellect() * 0.01 ) )
    local nDuration = math.max(self:GetSpecialValueFor("push_duration"), FrameTime())
    --print(nDistance)
    local nSlowDuration = self:GetSpecialValueFor("slow_duration")
    local nSlowPct      = self:GetSpecialValueFor("slow_pct")

    local nBaseDamage, bBaseCritical     = GetPrideAndBerserkedScaledDamage(hCaster, self:GetSpecialValueFor("base_damage"))
    local nBounceDamage, bBounceCritical = GetPrideAndBerserkedScaledDamage(hCaster, self:GetSpecialValueFor("bounce_damage"))

    local bCasterBerserked = hCaster:HasModifier("modifier_leonidas_berserk")

    local nLocked  = 1
    local nStunned = bCasterBerserked and 1 or 0

    local hKickModifier = hTarget:AddNewModifier(hCaster, self, "modifier_leonidas_enomotia_slow", {duration = nDuration, nSlow = 0, nLocked = 0, nStunned = nStunned})
    if IsNotNull(hKickModifier)
        and not hKickModifier.nImpactPFX then
        hKickModifier.nImpactPFX =  ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_sparta_kick_trail.vpcf", PATTACH_CENTER_FOLLOW, hTarget)
                                    ParticleManager:SetParticleControlForward(hKickModifier.nImpactPFX, 1, vDirection)

        hKickModifier:AddParticle(hKickModifier.nImpactPFX, false, false, -1, false, false)
    end

    EmitSoundOn("Leonidas.Kick.Cast.1", hCaster)
    EmitSoundOn("Leonidas.Kick.Impact.1", hTarget)

    if not IsKnockbackImmune(hTarget) then
        local sTimerNameUnique = self:GetAbilityName()..DoUniqueString(tostring(hTarget:entindex())) --.."_"
        --=================================--
        hTarget:InterruptMotionControllers(false)

        local hPhysicsThingReturn = Physics:Unit(hTarget)

        hTarget:PreventDI(true)
        hTarget:SetPhysicsFriction(0)
        hTarget:SetPhysicsVelocity(vDirection * ( nDistance / nDuration ))
        hTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
        hTarget:SetGroundBehavior(PHYSICS_GROUND_LOCK)
        hTarget:FollowNavMesh(true)
        --=================================--
        Timers:CreateTimer(sTimerNameUnique,
        {
            endTime  = nDuration,
            callback = function()
                hTarget:OnPreBounce(nil)
                hTarget:SetBounceMultiplier(0)
                hTarget:PreventDI(false)
                hTarget:SetPhysicsVelocity(Vector(0,0,0))
                hTarget:OnPhysicsFrame(nil)
                hTarget:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
                FindClearSpaceForUnit(hTarget, hTarget:GetAbsOrigin(), true)
            end
        })
        --=================================--
        hTarget:OnPreBounce(function(hUnit, vNormal)
            Timers:RemoveTimer(sTimerNameUnique)

            if IsNotNull(hKickModifier) then
                hKickModifier:Destroy()
            end

            hUnit:OnPreBounce(nil)
            hUnit:SetBounceMultiplier(0)
            hUnit:PreventDI(false)
            hUnit:SetPhysicsVelocity(Vector(0,0,0))
            hUnit:OnPhysicsFrame(nil)
            hUnit:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
            FindClearSpaceForUnit(hUnit, hUnit:GetAbsOrigin(), true)

            hUnit:AddNewModifier(hCaster, self, "modifier_leonidas_enomotia_slow", {duration = nSlowDuration, nSlow = nSlowPct, nStunned = nStunned, nLocked = nLocked})

            local nImpactPFX =  ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_sparta_kick_impact.vpcf", PATTACH_CENTER_FOLLOW, hUnit)
                                ParticleManager:ReleaseParticleIndex(nImpactPFX)

            EmitSoundOn("Leonidas.Kick.Impact.2", hUnit)
            --=================================--
            DoDamage(hCaster, hUnit, nBounceDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
            --=================================--
            if bBounceCritical then
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hUnit, nBounceDamage, nil)
            end
        end)
        --=================================--
        DoDamage(hCaster, hTarget, nBaseDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
        --=================================--
        if bBaseCritical then
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hTarget, nBaseDamage, nil)
        end
    end
end















--лвл проеб просперити


---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_catch = leonidas_catch or class({})

function leonidas_catch:IsStealable()                                         return true end
function leonidas_catch:IsHiddenWhenStolen()                                  return false end
function leonidas_catch:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function leonidas_catch:GetCooldown(nLevel)
    local hCaster = self:GetCaster()
    local nCooldown = self.BaseClass.GetCooldown(self, nLevel)
          nCooldown = ( nCooldown - ( nCooldown * GetAttributeValue(hCaster, "leonidas_math_attribute", "catch_cdr_pct_scale_per_int", -1, 0, false) * hCaster:GetIntellect() * 0.01 ) )
    return nCooldown
end
function leonidas_catch:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()
    return true
end
function leonidas_catch:OnAbilityPhaseInterrupted()
end
function leonidas_catch:OnSpellStart()
    local hCaster = self:GetCaster()

    local nRadius = self:GetAOERadius() + ( hCaster:BoundingRadius2D() * 2 ) --NOTE: This requires for equality when RBMing target for catching if distance equality visible.

    local nDamageType = self:GetAbilityDamageType()
    local nBaseDamage, bBaseCritical = GetPrideAndBerserkedScaledDamage(hCaster, self:GetSpecialValueFor("base_damage"))

    local nFlyHeight    = self:GetSpecialValueFor("fly_height")
    local nFlyDuration  = self:GetSpecialValueFor("fly_duration")
    local nSlowDuration = self:GetSpecialValueFor("slow_duration")
    local nSlowPct      = self:GetSpecialValueFor("slow_pct")

    local vCasterLoc  = hCaster:GetAbsOrigin()
    local vCasterBack = vCasterLoc + ( hCaster:GetForwardVector() * nRadius * -0.5 )

    local bCasterBerserked = hCaster:HasModifier("modifier_leonidas_berserk")

    local nLocked  = 1
    local nStunned = bCasterBerserked and 1 or 0

    local tKnockBackTable = {
                                should_stun        = 0,
                                knockback_duration = nFlyDuration,
                                duration           = nFlyDuration,
                                knockback_distance = 0,
                                knockback_height   = nFlyHeight,
                                center_x           = vCasterLoc.x,
                                center_y           = vCasterLoc.y,
                                center_z           = vCasterLoc.z
                            }

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
            local vEntLoc = hEntity:GetAbsOrigin()
            local vEntDir = GetDirection(vEntLoc, vCasterBack)
                  vEntLoc = vEntLoc + vEntDir * 1 --( hEntity:BoundingRadius2D() * 2 )

            tKnockBackTable.knockback_distance = GetDistance(vEntLoc, vCasterBack)

            tKnockBackTable.center_x = vEntLoc.x
            tKnockBackTable.center_y = vEntLoc.y
            tKnockBackTable.center_z = vEntLoc.z

            hEntity:InterruptMotionControllers(false)

            --print(nFlyDuration + nSlowDuration)
            hEntity:AddNewModifier(hCaster, self, "modifier_leonidas_enomotia_slow", {duration = nFlyDuration + nSlowDuration, nSlow = nSlowPct, nStunned = nStunned, nLocked = nLocked})

            local hKnockMod = hEntity:AddNewModifier(hCaster, self, "modifier_knockback", tKnockBackTable)
            if IsNotNull(hKnockMod)
                and not hKnockMod.nTrailPFX then
                hKnockMod.nTrailPFX =   ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_catch_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, hEntity)
                                        ParticleManager:SetParticleControlEnt(
                                                                                hKnockMod.nTrailPFX, 
                                                                                0, 
                                                                                hEntity, 
                                                                                PATTACH_POINT_FOLLOW, 
                                                                                "attach_hitloc", 
                                                                                Vector(0, 0, 0), 
                                                                                false
                                                                            )
                hKnockMod:AddParticle(hKnockMod.nTrailPFX, false, false, -1, false, false)
                --=================================--
                Timers:CreateTimer(tKnockBackTable.knockback_duration - FrameTime(), function() --NOTE: Roflan ebalo sound fix
                    if IsNotNull(hKnockMod) then
                        EmitSoundOn("Leonidas.Catch.Impact.2", hEntity)
                    end
                end)
            end
            --=================================--
            EmitSoundOn("Leonidas.Catch.Impact.1", hEntity)
            --=================================--
            DoDamage(hCaster, hEntity, nBaseDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
            --=================================--
            if bBaseCritical then
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hEntity, nBaseDamage, nil)
            end
            --=================================--
            if not bCasterBerserked then
                break
            end
        end
    end
    --=================================--
    local nSwingPFX = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_catch_swing.vpcf", PATTACH_CENTER_FOLLOW, hCaster)
                      ParticleManager:ReleaseParticleIndex(nSwingPFX)
    --=================================--
    CheckComboIsReadyIncrement(hCaster, 1)

    EmitSoundOn("Leonidas.Catch.Cast.1", hCaster)
    EmitSoundOn("Leonidas.Catch.Cast.2", hCaster)
end



















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_pride = leonidas_pride or class({})

function leonidas_pride:IsStealable()                                         return true end
function leonidas_pride:IsHiddenWhenStolen()                                  return false end
function leonidas_pride:GetCastRange(vLocation, hTarget)
    local hCaster = self:GetCaster()
    local nScale  = 1
    if type(hCaster.GetIntellect) == "function" then
        nScale = nScale + ( GetAttributeValue(hCaster, "leonidas_math_attribute", "pride_range_pct_scale_per_int", -1, 0, false) * hCaster:GetIntellect() * 0.01 )
    end
    return self.BaseClass.GetCastRange(self, vLocation, hTarget) * nScale
end
function leonidas_pride:GetBehavior()
    local hCaster = self:GetCaster()
    local nBonus  = DOTA_ABILITY_BEHAVIOR_NONE
    local nBonus2 = DOTA_ABILITY_BEHAVIOR_NONE
    if IsNotNull(hCaster) then
        nBonus = hCaster:HasModifier("modifier_leonidas_berserk")
                 and DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
                 or nBonus
        nBonus2 = GetAttributeValue(hCaster, "leonidas_pride_attribute", "counter_resist", -1, 0, false) > 0
                  and DOTA_ABILITY_BEHAVIOR_IMMEDIATE
                  or nBonus2
    end
    return bit.bor(self.BaseClass.GetBehavior(self), nBonus + nBonus2)
end
function leonidas_pride:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function leonidas_pride:OnAbilityPhaseStart()
    local hCaster  = self:GetCaster()
    return true
end
function leonidas_pride:OnAbilityPhaseInterrupted()
end
function leonidas_pride:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local vPoint  = self:GetCursorPosition() + hCaster:GetForwardVector()
    --=================================--
    local nCounterDuration = GetAttributeValue(hCaster, "leonidas_pride_attribute", "counter_duration", -1, 0, false)
    --if IsNotNull(hPrideAttribute) then
    if nCounterDuration > 0 then
        EmitSoundOn("Leonidas.Pride.Cast.2", hCaster)

        hCaster:AddNewModifier(hCaster, self, "modifier_leonidas_pride_counter", {duration = nCounterDuration, nCounterResist = GetAttributeValue(hCaster, "leonidas_pride_attribute", "counter_resist", -1, 0, false)})
    else
        --=================================--
        self:ReleaseSpear(vPoint, hTarget, 0, true)
        --=================================--
    end
    --=================================--
    --ScreenShake(hCaster:GetAbsOrigin(), 7, 3, 2, 300 * 5, 0, true)
    --=================================--
    CheckComboIsReadyIncrement(hCaster, 0)
end
function leonidas_pride:ReleaseSpear(vPoint, hTarget, nBonusDamage, bCanDodge)
    local bLockOnTarget = IsNotNull(hTarget) and not IsSpellBlocked(hTarget)

    local hCaster = self:GetCaster()

    local nTeamNumber = hCaster:GetTeamNumber()

    local vDirection = GetDirection(vPoint, hCaster)
    local nDistance  = GetDistance(vPoint, hCaster)

    local nRadius       = self:GetAOERadius()
    local nVisionRadius = self:GetSpecialValueFor("vision_radius")
    
    local nSpeed        = self:GetSpecialValueFor("speed")
    local nDamage       = self:GetSpecialValueFor("damage") + GetAttributeValue(hCaster, "leonidas_pride_attribute", "bonus_damage", -1, 0, false)
    local nStunDuration = self:GetSpecialValueFor("stun_duration")

    local vSpawnLoc = hCaster:GetAttachmentOrigin(hCaster:ScriptLookupAttachment("ATTACH_HITLOC"))

    local sSpearParticle = "particles/heroes/anime_hero_leonidas/leonidas_pride_spear_tracking.vpcf" --particles/econ/items/clockwerk/clockwerk_2022_cc/clockwerk_2022_cc_rocket_flare.vpcf

    if not bCanDodge then
        EmitGlobalSound("Leonidas.Pride.Cast.1")
        EmitGlobalSound("Leonidas.Pride.Cast.3")
    else
        EmitSoundOn("Leonidas.Pride.Cast.1", hCaster)
        EmitSoundOn("Leonidas.Pride.Cast.3", hCaster)
    end

    if bLockOnTarget then
        local tSpearProjectile =    {
                                        EffectName = sSpearParticle,
                                        Source     = hCaster,
                                        vSourceLoc = vSpawnLoc,
                                        Target     = hTarget,
                                        Ability    = self,
                                        
                                        --iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,

                                        iMoveSpeed = nSpeed,

                                        --flExpireTime = 0,

                                        --bIsAttack            = false,
                                        --bSuppressTargetCheck = false,
                                        --bReplaceExisting     = false,
                                        --bIgnoreObstructions  = true,
                                        bDodgeable = bCanDodge,
                                        
                                        bDrawsOnMinimap   = true,
                                        bVisibleToEnemies = true,

                                        bProvidesVision   = true,
                                        iVisionRadius     = nVisionRadius,
                                        iVisionTeamNumber = nTeamNumber,

                                        ExtraData = {
                                                        nDamage       = nDamage + nBonusDamage,
                                                        nRadius       = nRadius,
                                                        nStunDuration = nStunDuration
                                                    }
                                    }

        local nSpearProjectile = ProjectileManager:CreateTrackingProjectile(tSpearProjectile)
    else
        local nSpearParticle =  ParticleManager:CreateParticle(sSpearParticle, PATTACH_WORLDORIGIN, nil)
                                ParticleManager:SetParticleShouldCheckFoW(nSpearParticle, false)
                                ParticleManager:SetParticleAlwaysSimulate(nSpearParticle)
                                ParticleManager:SetParticleControl(nSpearParticle, 0, vSpawnLoc)
                                ParticleManager:SetParticleControl(nSpearParticle, 1, GetGroundPosition(vPoint, nil))
                                ParticleManager:SetParticleControl(nSpearParticle, 2, Vector(nSpeed, 0, 0))

        local tSpearProjectile =    {
                                        EffectName   = "",
                                        Source       = hCaster,
                                        vSpawnOrigin = vSpawnLoc,

                                        Ability = self,

                                        vVelocity     = vDirection * ( nDistance / ( GetDistance(vPoint, vSpawnLoc, true) ) * nSpeed ),
                                        --vAcceleration = Vector(0, 0, 0),
                                        --fMaxSpeed = -1,

                                        fDistance = nDistance,

                                        --fStartRadius = 100,
                                        --fEndRadius   = 100,

                                        fExpireTime = 0,

                                        --iUnitTargetTeam  = nABILITY_TARGET_TEAM,
                                        --iUnitTargetFlags = nABILITY_TARGET_TYPE,
                                        --iUnitTargetType  = nABILITY_TARGET_FLAGS,

                                        --bIgnoreSource   = false,
                                        bHasFrontalCone = true,

                                        bDrawsOnMinimap   = true,
                                        bVisibleToEnemies = true,

                                        bProvidesVision   = true,
                                        iVisionRadius     = nVisionRadius,
                                        iVisionTeamNumber = nTeamNumber,

                                        ExtraData         = {
                                                                nSpearParticle = nSpearParticle,
                                                                nDamage        = nDamage + nBonusDamage,
                                                                nRadius        = nRadius,
                                                                nStunDuration  = nStunDuration
                                                                --fDestroyTime     = ( GetDistance(GetGroundPosition(vPoint, nil), vCasterBase, true) / fSpeed ) - ( fDistance / fSpeed )
                                                            }
                                    }

        local nSpearProjectile = ProjectileManager:CreateLinearProjectile(tSpearProjectile)
    end
    -- local nGroundedSpearPFX = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_pride_spear_grounded.vpcf", PATTACH_WORLDORIGIN, nil)
    --                           ParticleManager:SetParticleShouldCheckFoW( nGroundedSpearPFX, false )
    --                           ParticleManager:SetParticleControlOrientationFLU(nGroundedSpearPFX, 0, hCaster:GetForwardVector(), -hCaster:GetRightVector(), hCaster:GetUpVector())
    --                           ParticleManager:SetParticleControl(nGroundedSpearPFX, 0, vPoint)
end
function leonidas_pride:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
    if IsServer() then
        if type(tExtraData.nSpearParticle) == "number" then
            ParticleManager:DestroyParticle(tExtraData.nSpearParticle, false)
            ParticleManager:ReleaseParticleIndex(tExtraData.nSpearParticle)
        end

        local hCaster = self:GetCaster()

        local nDamage, bCritical = GetPrideAndBerserkedScaledDamage(hCaster, tExtraData.nDamage)

        local hEntities = FindUnitsInRadius(
                                                hCaster:GetTeamNumber(),
                                                vLocation,
                                                nil,
                                                tExtraData.nRadius,
                                                self:GetAbilityTargetTeam(),
                                                self:GetAbilityTargetType(),
                                                self:GetAbilityTargetFlags(),
                                                FIND_ANY_ORDER,
                                                false
                                            )
        --=================================--
        for _, hEntity in pairs(hEntities) do
            if IsNotNull(hEntity) then
                hEntity:AddNewModifier(hEntity, self, "modifier_leonidas_enomotia_slow", {duration = tExtraData.nStunDuration, nSlow = 0, nStunned = 1, nLocked = 0, nDisarmed = 0})
                --=================================--
                DoDamage(hCaster, hEntity, nDamage, self:GetAbilityDamageType(), DOTA_DAMAGE_FLAG_NONE, self, false)
                --=================================--
                if bCritical then
                    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hEntity, nDamage, nil)
                end
            end
        end
        --===============================
        ScreenShake(vLocation, 7, 3, 2, tExtraData.nRadius * 5, 0, true)
        --===============================
        local nImpactPFX =  ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_pride_spear_impact.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleShouldCheckFoW(nImpactPFX, false)
                            ParticleManager:SetParticleControl(nImpactPFX, 0, GetGroundPosition(vLocation, nil))
                            ParticleManager:SetParticleControl(nImpactPFX, 1, Vector(tExtraData.nRadius, tExtraData.nRadius, tExtraData.nRadius))
                            ParticleManager:ReleaseParticleIndex(nImpactPFX)

        EmitSoundOnLocationWithCaster(vLocation, "Leonidas.Pride.Impact.1", hCaster)
    end
end

---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_pride_counter", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_pride_counter = modifier_leonidas_pride_counter or class({})

function modifier_leonidas_pride_counter:IsHidden()                                                                       return false end
function modifier_leonidas_pride_counter:IsDebuff()                                                                       return false end
function modifier_leonidas_pride_counter:IsPurgable()                                                                     return false end
function modifier_leonidas_pride_counter:IsPurgeException()                                                               return false end
function modifier_leonidas_pride_counter:RemoveOnDeath()                                                                  return true end
function modifier_leonidas_pride_counter:GetPriority()                                                                    return MODIFIER_PRIORITY_HIGH end
function modifier_leonidas_pride_counter:CheckState()
    local tState =  {
                        [MODIFIER_STATE_ROOTED]   = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_MUTED]    = true
                    }
    return tState
end
function modifier_leonidas_pride_counter:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
                        MODIFIER_PROPERTY_DISABLE_TURNING
                    }
    return tFunc
end
function modifier_leonidas_pride_counter:GetModifierIncomingDamage_Percentage(keys)
    if IsServer() then
        --print(keys.damage, keys.original_damage)
        self.nBonusDamage = math.ceil(self.nBonusDamage + ( keys.original_damage * self.nCounterResist * 0.01 ))
        self:SetStackCount(self.nBonusDamage)
        return -self.nCounterResist
    end
end
function modifier_leonidas_pride_counter:GetModifierDisableTurning(keys)
    return 1
end
function modifier_leonidas_pride_counter:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.nCounterResist = tTable.nCounterResist or 0

        self.vPoint  = self.hAbility:GetCursorPosition()
        self.hTarget = self.hAbility:GetCursorTarget()

        self.nBonusDamage = self.nBonusDamage or 0

        self.hParent:SwapAbilities("leonidas_pride", "leonidas_pride_release", false, true)

        local nReleaseStart = self:GetDuration()

        self.hParent:FaceTowards(self.vPoint)
        self.hParent:SetForwardVector(GetDirection(self.vPoint, self.hParent))

        EndAnimation(self.hParent)
        StartAnimation(self.hParent, {duration = nReleaseStart, activity = ACT_DOTA_CHANNEL_ABILITY_7, rate = 1.0})

        --self:StartIntervalThink(nReleaseStart)
    end
end
function modifier_leonidas_pride_counter:OnIntervalThink()
    if IsServer() then

        self:StartIntervalThink(-1)
    end
end
function modifier_leonidas_pride_counter:OnDestroy()
    if IsServer()
        and IsNotNull(self.hParent)
        and self.hParent:IsAlive() then
        --self:OnIntervalThink()
        self.hParent:SwapAbilities("leonidas_pride", "leonidas_pride_release", true, false)

        local hAbility     = self.hAbility
        local vPoint       = self.vPoint
        local hTarget      = self.hTarget
        local nBonusDamage = self.nBonusDamage

        EndAnimation(self.hParent)
        StartAnimation(self.hParent, {duration = 0.3, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1.0})

        Timers:CreateTimer(0.3, function() --MB WILL ADD ALIVE CHECK LATER THERE
            hAbility:ReleaseSpear(vPoint, hTarget, nBonusDamage, true)
        end)
    end
end
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_pride_release = leonidas_pride_release or class({})

function leonidas_pride_release:IsStealable()                                         return true end
function leonidas_pride_release:IsHiddenWhenStolen()                                  return false end
function leonidas_pride_release:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()
    return true
end
function leonidas_pride_release:OnAbilityPhaseInterrupted()
end
function leonidas_pride_release:OnSpellStart()
    local hCaster = self:GetCaster()

    hCaster:RemoveModifierByNameAndCaster("modifier_leonidas_pride_counter", hCaster)
end





















--FINISHED: YES, EXCEPT SOUNDS AND DESCRIPTIONS
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_berserk = leonidas_berserk or class({})

function leonidas_berserk:IsStealable()                                         return true end
function leonidas_berserk:IsHiddenWhenStolen()                                  return false end
function leonidas_berserk:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function leonidas_berserk:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()
    return true
end
function leonidas_berserk:OnAbilityPhaseInterrupted()
end
function leonidas_berserk:CastFilterResult()
    local hCaster = self:GetCaster()
    if IsServer()
        and bIsRevoked(hCaster) then
        return UF_FAIL_CUSTOM
    end
    return self.BaseClass.CastFilterResult(self)
end
function leonidas_berserk:GetCustomCastError()
    return "#leonidas_berserk_custom_cast_error"
end
function leonidas_berserk:OnSpellStart()
    local hCaster   = self:GetCaster()
    local nDuration = self:GetSpecialValueFor("duration")

    hCaster:AddNewModifier(hCaster, self, "modifier_leonidas_berserk", {duration = nDuration})

    EmitSoundOn("Leonidas.Berserk.Cast.1", hCaster)
    --EmitGlobalSound("Leonidas.MultiAttack.Sound")
end

---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_berserk", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_berserk = modifier_leonidas_berserk or class({})

function modifier_leonidas_berserk:IsHidden()                                                                       return false end
function modifier_leonidas_berserk:IsDebuff()                                                                       return false end
function modifier_leonidas_berserk:IsPurgable()                                                                     return false end
function modifier_leonidas_berserk:IsPurgeException()                                                               return false end
function modifier_leonidas_berserk:RemoveOnDeath()                                                                  return true end
function modifier_leonidas_berserk:GetPriority()                                                                    return MODIFIER_PRIORITY_HIGH end
function modifier_leonidas_berserk:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
                        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
                        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
                        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
                    }
    return tFunc
end
-- function modifier_leonidas_berserk:GetCritDamage(keys) --NOT REMEMBER HOW RETURN CORRECT VALUES THERE
--     return 300
-- end
function modifier_leonidas_berserk:GetModifierPreAttack_CriticalStrike(keys)
    if IsServer()
        and RollPseudoRandom(self.nCritChance, self) then
        self.bCriticalAttack = true
        return ( self.nCritDamageBase + ( self.nCritDamageStr * self.hParent:GetStrength() ) )
    end
end
function modifier_leonidas_berserk:GetModifierProcAttack_Feedback(keys) --NOTE: Как бы я не хотел засунуть сюда 3% от макс хп врага физикой.... я не заснул т.к долго думал над балансом... и т.д
    if IsServer()
        and self.bCriticalAttack then
        self.bCriticalAttack = false
        local nSwingPFX = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_berserk_crit_swing.vpcf", PATTACH_CENTER_FOLLOW, self.hParent)
                          ParticleManager:ReleaseParticleIndex(nSwingPFX)

        EmitSoundOn("Hero_Juggernaut.BladeDance", self.hParent)
    end
end
function modifier_leonidas_berserk:GetModifierAttackSpeedBonus_Constant(keys)
    return ( 100 - self.hParent:GetHealthPercent() ) * self.nMaxASPerMissingHP
end
function modifier_leonidas_berserk:GetModifierBonusStats_Intellect(keys)
    return self.nReduceIntPct
end
function modifier_leonidas_berserk:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    --VALUES WE PICK FROM ATTRIBUTE BASICALY? NO FOR NOW NOT
    --local hMadAttribute = GetAttributeValue(self.hParent, "leonidas_mad_attribute", "", -1, 0, true)

    self.nRadius = self.hAbility:GetAOERadius()

    self.nPurgeTimes  = self.hAbility:GetSpecialValueFor("purge_times")
    self.nPurgedTimes = 0

    self.nPurgeDamage     = self.hAbility:GetSpecialValueFor("purge_damage")
    self.nMissingHPDamage = self.hAbility:GetSpecialValueFor("purge_damage_missing_hp_pct") * 0.01

    self.nMaxASPerMissingHP = self.hAbility:GetSpecialValueFor("max_as_per_missing_hp") * 0.01

    self.nReduceIntPct = 0 --NOTE: Fixing recall if recall sometime will be
    self.nReduceIntPct = self.hAbility:GetSpecialValueFor("reduce_int_pct") * self.hParent:GetIntellect() * 0.01  --NOTE: Doesn't call in int basicaly or will be crash

    self.nCritChance     = self.hAbility:GetSpecialValueFor("crit_chance")
    self.nCritDamageBase = self.hAbility:GetSpecialValueFor("crit_damage_base")
    self.nCritDamageStr  = self.hAbility:GetSpecialValueFor("crit_damage_str") * 0.01

    if IsServer() then
        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self.nDamageType = self.hAbility:GetAbilityDamageType()

        self:StartIntervalThink(self.hAbility:GetSpecialValueFor("purge_tick"))
        self:OnIntervalThink()
    end
end
function modifier_leonidas_berserk:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_leonidas_berserk:OnIntervalThink()
    if IsServer()
        and self.nPurgedTimes < self.nPurgeTimes then
        self.nPurgedTimes = self.nPurgedTimes + 1
        --=================================--
        local hEntities = FindUnitsInRadius(
                                                self.nCASTER_TEAM,
                                                self.hParent:GetAbsOrigin(),
                                                nil,
                                                self.nRadius,
                                                self.nABILITY_TARGET_TEAM,
                                                self.nABILITY_TARGET_TYPE,
                                                self.nABILITY_TARGET_FLAGS,
                                                FIND_ANY_ORDER,
                                                false
                                            )
        --=================================--
        for _, hEntity in pairs(hEntities) do
            if IsNotNull(hEntity) then
                local nCalculatedDamage = self.nPurgeDamage + ( ( self.hParent:GetHealthDeficit() * self.nMissingHPDamage ) / self.nPurgeTimes )
                local nCalculatedDamage, bIsCritical = GetPrideAndBerserkedScaledDamage(self.hParent, nCalculatedDamage)
                --=================================--
                --print(nCalculatedDamage)
                DoDamage(self.hCaster, hEntity, nCalculatedDamage, self.nDamageType, DOTA_DAMAGE_FLAG_NONE, self.hAbility, false)
                --=================================--
                if bIsCritical then
                    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hEntity, nCalculatedDamage, nil)
                end
            end
        end
        --=================================--
        HardCleanse(self.hParent) --NOTE: Fate Mech
        --self.hParent:Purge(false, true, false, true, true) --NOTE: Removed because fate pepegas
        --=================================--
        local nRadius = self.nRadius + 100
        local nCastPFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_berserk_pulse.vpcf", PATTACH_CENTER_FOLLOW, self.hParent)
                            ParticleManager:SetParticleControlEnt(
                                                                    nCastPFX, 
                                                                    1, 
                                                                    self.hParent, 
                                                                    PATTACH_CENTER_FOLLOW, 
                                                                    "attach_hitloc", 
                                                                    Vector(0, 0, 0),
                                                                    false
                                                                )
                            for i = 2, 6 do
                                ParticleManager:SetParticleControl(nCastPFX, i, Vector(nRadius, nRadius, nRadius))
                            end
                            ParticleManager:SetParticleControl(nCastPFX, 60, Vector(0, 0, 0))
                            ParticleManager:SetParticleControl(nCastPFX, 61, Vector(0, 0, 0))
                            ParticleManager:ReleaseParticleIndex(nCastPFX)

        EmitSoundOn("Leonidas.Berserk.Cast.2", self.hParent)
        --local hComboModifier = self.hParent:FindModifierByNameAndCaster("modifier_leonidas_enomotia_shield", self.hCaster)
        --if not ( IsNotNull(hComboModifier) and hComboModifier.bIsComboShield ) then
        if not self.hParent:HasModifier("pause_sealenabled") then
            StartAnimation(self.hParent, {duration = 0.5, activity = self.hAbility:GetCastAnimation(), rate = 2.0})
        end
    end
end
function modifier_leonidas_berserk:GetEffectName()
    return "particles/heroes/anime_hero_leonidas/leonidas_berserk_buff.vpcf"
end
function modifier_leonidas_berserk:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_leonidas_berserk:GetStatusEffectName()
    return "particles/heroes/anime_hero_leonidas/leonidas_berserk_buff_status_fx.vpcf"
end
function modifier_leonidas_berserk:StatusEffectPriority()
    return self:GetPriority()
end
















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_bc = leonidas_bc or class({})

function leonidas_bc:IsStealable()                                         return true end
function leonidas_bc:IsHiddenWhenStolen()                                  return false end
function leonidas_bc:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function leonidas_bc:GetAbilityTextureName()
    return "anime_hero_leonidas/leonidas_bc"..math.max(1, self:GetLevel())
end
function leonidas_bc:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()
    return true
end
function leonidas_bc:OnAbilityPhaseInterrupted()
end
-- function leonidas_bc:GetBehavior()
--     local hCaster        = self:GetCaster()
--     local hActiveAbility = hCaster:GetCurrentActiveAbility()
--     local bCanUseInStun  = false
--     if IsNotNull(hActiveAbility)
--         and type(string.match(hActiveAbility:GetAbilityName(), "leonidas_enomotia")) ~= nil then
--         bCanUseInStun = true
--     end
--     return bit.bor(self.BaseClass.GetBehavior(self), DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE)
-- end
function leonidas_bc:CastFilterResult()
    local hCaster = self:GetCaster()
    if hCaster:GetHealthPercent() > self:GetSpecialValueFor("hp_require_pct") then
        return UF_FAIL_CUSTOM
    end
    return self.BaseClass.CastFilterResult(self)
end
function leonidas_bc:GetCustomCastError()
    return "#leonidas_bc_custom_cast_error"
end
function leonidas_bc:OnOwnerDied()
    local hCaster = self:GetCaster()

    if not hCaster:PassivesDisabled()
        and self:GetLevel() > 1 then
        local vCasterLoc = hCaster:GetAbsOrigin()

        local nRadius = self:GetAOERadius()

        local hEntities = FindUnitsInRadius(
                                                hCaster:GetTeamNumber(),
                                                vCasterLoc,
                                                nil,
                                                nRadius,
                                                self:GetAbilityTargetTeam(),
                                                self:GetAbilityTargetType(),
                                                self:GetAbilityTargetFlags(),
                                                FIND_ANY_ORDER,
                                                false
                                            )
        --=================================--
        for _, hEntity in pairs(hEntities) do
            if IsNotNull(hEntity)
                and hCaster ~= hEntity then
                hEntity:AddNewModifier(hCaster, self, "modifier_leonidas_enomotia_shield", {duration = self:GetSpecialValueFor("enomotia_shield_duration"), nDamageBlock = self:GetSpecialValueFor("enomotia_shield_block")})
            end
        end
        --=================================--
        nRadius = nRadius + 100
        local nCastPFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_berserk_pulse.vpcf", PATTACH_CENTER_FOLLOW, hCaster)
                            ParticleManager:SetParticleControlEnt(
                                                                    nCastPFX, 
                                                                    1,
                                                                    hCaster, 
                                                                    PATTACH_CENTER_FOLLOW, 
                                                                    "attach_hitloc", 
                                                                    Vector(0, 0, 0),
                                                                    false
                                                                )
                            for i = 2, 6 do
                                ParticleManager:SetParticleControl(nCastPFX, i, Vector(nRadius, nRadius, nRadius))
                            end
                            ParticleManager:SetParticleControl(nCastPFX, 60, Vector(255, 125, 0))
                            ParticleManager:SetParticleControl(nCastPFX, 61, Vector(255, 125, 0))
                            ParticleManager:ReleaseParticleIndex(nCastPFX)

        --StartAnimation(hCaster, {duration = 1.0, activity = self:GetCastAnimation(), rate = 1.0})
        hCaster:StartGestureWithPlaybackRate(self:GetCastAnimation(), 0.5)

        EmitSoundOnLocationWithCaster(vCasterLoc, "Leonidas.Berserk.Cast.2", hCaster)
    end
end
function leonidas_bc:OnSpellStart()
    local hCaster   = self:GetCaster()
    local nDuration = self:GetSpecialValueFor("duration")

    hCaster:AddNewModifier(hCaster, self, "modifier_leonidas_bc_immortal", {duration = nDuration})

    StartAnimation(hCaster, {duration = 0.5, activity = self:GetCastAnimation(), rate = 2.0})

    EmitSoundOn("Leonidas.BC.Cast.1", hCaster)
    EmitSoundOn("Leonidas.BC.Cast.2", hCaster)
end

---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_bc_immortal", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_bc_immortal = modifier_leonidas_bc_immortal or class({})

function modifier_leonidas_bc_immortal:IsHidden()                                                                       return false end
function modifier_leonidas_bc_immortal:IsDebuff()                                                                       return false end
function modifier_leonidas_bc_immortal:IsPurgable()                                                                     return false end
function modifier_leonidas_bc_immortal:IsPurgeException()                                                               return false end
function modifier_leonidas_bc_immortal:RemoveOnDeath()                                                                  return true end
function modifier_leonidas_bc_immortal:GetPriority()                                                                    return MODIFIER_PRIORITY_ULTRA end
function modifier_leonidas_bc_immortal:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MIN_HEALTH,
                        MODIFIER_PROPERTY_DISABLE_HEALING
                    }
    return tFunc
end
function modifier_leonidas_bc_immortal:GetMinHealth(keys)
    return self.nHealthLoc
end
function modifier_leonidas_bc_immortal:GetDisableHealing(keys)
    return self.nDisableHeal
end
function modifier_leonidas_bc_immortal:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nHealthLoc   = self.hParent:GetHealth()
    self.nDisableHeal = self.hAbility:GetSpecialValueFor("disable_heal")

    self.nPostRegenHPDuration = self.hAbility:GetSpecialValueFor("post_regen_hp_duration")
    self.nPostRegenHPPct      = self.hAbility:GetSpecialValueFor("post_regen_hp_pct")

    if IsServer() then
        self.sSoundForEmit = "Leonidas.BC.Loop.1"
        EmitSoundOn(self.sSoundForEmit, self.hParent)
    end
end
function modifier_leonidas_bc_immortal:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_leonidas_bc_immortal:GetEffectName()
    return "particles/heroes/anime_hero_leonidas/leonidas_bc_buff.vpcf"
end
function modifier_leonidas_bc_immortal:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_leonidas_bc_immortal:GetStatusEffectName()
    return "particles/heroes/anime_hero_leonidas/leonidas_bc_buff_status_fx.vpcf"
end
function modifier_leonidas_bc_immortal:StatusEffectPriority()
    return self:GetPriority()
end
function modifier_leonidas_bc_immortal:OnDestroy()
    if IsServer() then
        StopSoundOn(self.sSoundForEmit, self.hParent)
    end
    if IsServer()
        and self.hAbility:GetLevel() > 1 then
        self.hParent:AddNewModifier(self.hCaster, self.hAbility, "modifier_leonidas_bc_heal", {duration = self.nPostRegenHPDuration, nRegenPct = self.nPostRegenHPPct})
    end
end


---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_bc_heal", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_bc_heal = modifier_leonidas_bc_heal or class({})

function modifier_leonidas_bc_heal:IsHidden()                                                                       return false end
function modifier_leonidas_bc_heal:IsDebuff()                                                                       return false end
function modifier_leonidas_bc_heal:IsPurgable()                                                                     return false end
function modifier_leonidas_bc_heal:IsPurgeException()                                                               return false end
function modifier_leonidas_bc_heal:RemoveOnDeath()                                                                  return true end
function modifier_leonidas_bc_heal:GetPriority()                                                                    return MODIFIER_PRIORITY_NORMAL end
function modifier_leonidas_bc_heal:DeclareFunctions()
    local tFunc =   {
                        --MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
                        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
                    }
    return tFunc
end
-- function modifier_leonidas_bc_heal:GetModifierConstantHealthRegen(keys)
--     return self.nConstantHealPct + ( self.hParent:GetStrength() * self.nStrengthHeal_Pct )
-- end
function modifier_leonidas_bc_heal:GetModifierHealthRegenPercentage(keys)
    return -self:GetStackCount()
end
function modifier_leonidas_bc_heal:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    -- self.nConstantHealPct  = 30
    -- self.nStrengthHeal_Pct = 300 * 0.01

    if IsServer() then
        self:SetStackCount(-(tTable.nRegenPct or 0))

        self.sSoundForEmit = "Leonidas.BC.Loop.2"
        EmitSoundOn(self.sSoundForEmit, self.hParent)
    end
end
function modifier_leonidas_bc_heal:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_leonidas_bc_heal:OnDestroy()
    if IsServer() then
        StopSoundOn(self.sSoundForEmit, self.hParent)
    end
end
function modifier_leonidas_bc_heal:GetEffectName()
    return "particles/heroes/anime_hero_leonidas/leonidas_bc_heal.vpcf"
end
function modifier_leonidas_bc_heal:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end


















---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_enomotia = leonidas_enomotia or class({})

function leonidas_enomotia:IsStealable()                                         return true end
function leonidas_enomotia:IsHiddenWhenStolen()                                  return false end
function leonidas_enomotia:GetAOERadius()
    local hCaster = self:GetCaster()
    local nScale  = 1
    if type(hCaster.GetIntellect) == "function" then
        nScale = nScale + ( GetAttributeValue(hCaster, "leonidas_math_attribute", "enomotia_radius_pct_scale_per_int", -1, 0, false) * hCaster:GetIntellect() * 0.01 )
    end
    return self:GetSpecialValueFor("radius") * nScale
end
function leonidas_enomotia:OnAbilityPhaseStart()
    return true
end
function leonidas_enomotia:OnAbilityPhaseInterrupted()
end
function leonidas_enomotia:StopShields_PFX(nParticleIndex, bNow)
    if type(nParticleIndex) == "number" then
        ParticleManager:DestroyParticle(nParticleIndex, bNow)
        ParticleManager:ReleaseParticleIndex(nParticleIndex)
    end
end
function leonidas_enomotia:OnSpellStart()
    local hCaster  = self:GetCaster()

    local vForward = hCaster:GetForwardVector()
    local vRight   = hCaster:GetRightVector()
    local vUp      = hCaster:GetUpVector()

    local vCasterLoc = hCaster:GetAbsOrigin()
    local vCasterGnd = GetGroundPosition(vCasterLoc, hCaster)

    local nDamageType = self:GetAbilityDamageType()
    
    local nRadius     = self:GetAOERadius()
    local nPushRadius = nRadius * self:GetSpecialValueFor("push_radius")

    local nPushDuration         = math.max(self:GetSpecialValueFor("push_duration"), 0.1)
    local nPushSlowDuration     = self:GetSpecialValueFor("push_slow_duration")
    local nPushSlowPct          = self:GetSpecialValueFor("push_slow_pct")

    local nShieldDuration       = self:GetSpecialValueFor("shield_duration")
    local nShieldDamage         = self:GetSpecialValueFor("shield_damage")
    local nShieldCount          = self:GetSpecialValueFor("shield_count")
    local nShieldRows           = math.max(self:GetSpecialValueFor("shield_rows"), 1)
    local nBaseBlockPerShield   = self:GetSpecialValueFor("base_block_per_shield")
    local nBonusBlockPerPushed  = self:GetSpecialValueFor("bonus_block_per_pushed")

    local nPFX_AnimStartTime   = math.max(self:GetSpecialValueFor("pfx_anim_start_time"), 0.1)
    local nPFX_AnimLoopTime    = self:GetSpecialValueFor("pfx_anim_loop_time")
    local nPFX_AnimReleaseTime = self:GetSpecialValueFor("pfx_anim_release_time")
    local nPFX_AnimeFullTime   = nPFX_AnimStartTime + nPFX_AnimLoopTime + nPFX_AnimReleaseTime
    --print(nPFX_AnimeFullTime)
    giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealenabled", nPFX_AnimeFullTime)

    StartAnimation(hCaster, {duration = nPFX_AnimStartTime + nPFX_AnimLoopTime, activity = ACT_DOTA_CHANNEL_ABILITY_6, rate = 1.0})
    --=================================--
    local _nShieldsPFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_shields.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleShouldCheckFoW(_nShieldsPFX, false)
                            ParticleManager:SetParticleControlOrientationFLU(_nShieldsPFX, 0, vForward, -vRight, vUp)
                            ParticleManager:SetParticleControlOrientationFLU(_nShieldsPFX, 1, vForward, -vRight, vUp)
                            ParticleManager:SetParticleControl(_nShieldsPFX, 0, hCaster:GetAttachmentOrigin(hCaster:ScriptLookupAttachment("ATTACH_HITLOC")))
                            ParticleManager:SetParticleControl(_nShieldsPFX, 1, (vCasterGnd + vForward * -100) + Vector(0, 0, 270))
                            ParticleManager:SetParticleControl(_nShieldsPFX, 2, (vCasterGnd + vForward * -100) + Vector(0, 0, 270))
                            ParticleManager:SetParticleControl(_nShieldsPFX, 3, Vector(nPFX_AnimLoopTime, ( nShieldCount / nShieldRows ), nShieldRows))
                            ParticleManager:SetParticleControl(_nShieldsPFX, 4, Vector(nRadius, nRadius, ( nShieldCount * 0.1 ) / nPFX_AnimStartTime ))
    --=================================--
    EmitSoundOn("Leonidas.Enomotia.Cast.Shield", hCaster)
    EmitSoundOn("Leonidas.Enomotia.Cast.Shields", hCaster)
    --=================================--
    Timers:CreateTimer(nPFX_AnimStartTime, function()
        if IsNotNull(hCaster)
            and hCaster:IsAlive() then
            self:StopShields_PFX(_nShieldsPFX, false)
            --EndAnimation(hCaster)
            --StartAnimation(hCaster, {duration = nPFX_AnimLoopTime, activity = ACT_DOTA_CHANNEL_ABILITY_6, rate = 1.0})
            --=================================--
            EmitSoundOn("Leonidas.Enomotia.Cast.1", hCaster)
            --=================================--
            Timers:CreateTimer(nPFX_AnimLoopTime, function()
                if IsNotNull(hCaster)
                    and hCaster:IsAlive() then
                    EmitSoundOn("Leonidas.Enomotia.Cast.2", hCaster)
                    self:ReleaseEnomotia(hCaster, nPFX_AnimReleaseTime, nPushRadius, nRadius, nPushDuration, nPushSlowDuration, nPushSlowPct, nShieldDuration, nDamageType, nShieldDamage, nShieldCount, nBaseBlockPerShield, nBonusBlockPerPushed)
                end
            end)
        else
            self:StopShields_PFX(_nShieldsPFX, true)
        end
    end)
end
function leonidas_enomotia:ReleaseEnomotia(hCaster, nPFX_AnimReleaseTime, nPushRadius, nRadius, nPushDuration, nPushSlowDuration, nPushSlowPct, nShieldDuration, nDamageType, nShieldDamage, nShieldCount, nBaseBlockPerShield, nBonusBlockPerPushed)
    local vCasterLoc = hCaster:GetAbsOrigin()
    local vCasterGnd = GetGroundPosition(vCasterLoc, hCaster)

    local nTeamNumber = hCaster:GetTeamNumber()

    local nBaseDamage, bBaseCritical = GetPrideAndBerserkedScaledDamage(hCaster, nShieldCount * nShieldDamage)

    local nPushedUnits = 0

    local bCasterBerserked = hCaster:HasModifier("modifier_leonidas_berserk")

    local nDisarmed = 1
    local nLocked   = 1
    local nStunned  = bCasterBerserked and 1 or 0

    EndAnimation(hCaster)
    StartAnimation(hCaster, {duration = nPFX_AnimReleaseTime, activity = ACT_DOTA_CHANNEL_END_ABILITY_6, rate = 2.0})

    ScreenShake(vCasterGnd, 7, 3, 2, nRadius * 5, 0, true)

    EmitSoundOnLocationWithCaster(vCasterGnd, "Leonidas.Enomotia.Release.1", hCaster)
    EmitSoundOn("Leonidas.Enomotia.Release.2", hCaster)

    local nLightning_PFX =  ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_lightning.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleShouldCheckFoW(nLightning_PFX, false)
                            ParticleManager:SetParticleControl(nLightning_PFX, 0, vCasterGnd + Vector(0, 0, 1500))
                            ParticleManager:SetParticleControl(nLightning_PFX, 1, vCasterGnd + Vector(0, 0, 100))
                            --ParticleManager:DestroyParticle(nLightning_PFX, false)
                            ParticleManager:ReleaseParticleIndex(nLightning_PFX)

    local nExplode_PFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleShouldCheckFoW(nExplode_PFX, false)
                            ParticleManager:SetParticleControl(nExplode_PFX, 0, vCasterGnd)
                            ParticleManager:SetParticleControl(nExplode_PFX, 1, Vector(nRadius, 0, 0))
                            --ParticleManager:DestroyParticle(nExplode_PFX, false)
                            ParticleManager:ReleaseParticleIndex(nExplode_PFX)
        
    local tKnockBackTable = {
                                should_stun         = 0,
                                knockback_duration  = 1,
                                duration            = 1,
                                knockback_distance  = 1,
                                knockback_height    = 0,
                                center_x            = vCasterGnd.x,
                                center_y            = vCasterGnd.y,
                                center_z            = vCasterGnd.z
                            }

    local hEntities = FindUnitsInRadius(
                                            nTeamNumber,
                                            vCasterGnd,
                                            nil,
                                            nRadius,
                                            self:GetAbilityTargetTeam(),
                                            self:GetAbilityTargetType(),
                                            self:GetAbilityTargetFlags(),
                                            FIND_ANY_ORDER,
                                            false
                                        )
    --=================================--
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity)
            and hEntity ~= hCaster then
            local nTeamNumberEntity = hEntity:GetTeamNumber()
            local nDistanceToEntity = GetDistance(vCasterGnd, hEntity)
            if nDistanceToEntity <= nPushRadius then
                tKnockBackTable.knockback_distance = math.floor(nPushRadius - nDistanceToEntity)
                tKnockBackTable.knockback_duration = nPushDuration--(tKnockBackTable.knockback_distance / math.max(nRadius, 1)) * 0.5
                tKnockBackTable.duration = tKnockBackTable.knockback_duration
                --=================================--
                --hEntity:AddNewModifier(hCaster, self, "modifier_knockback", tKnockBackTable) -- MB SWAP TO PHYSICS BECAUSE IDK
                --hEntity:AddNewModifier(hCaster, self, "modifier_rooted", {duration = tKnockBackTable.duration})
                --=================================--
                if nTeamNumberEntity ~= nTeamNumber then
                    local hSlowMod = hEntity:AddNewModifier(hEntity, self, "modifier_leonidas_enomotia_slow", {duration = nPushSlowDuration, nSlow = nPushSlowPct, nStunned = nStunned, nLocked = nLocked, nDisarmed = nDisarmed})
                    if IsNotNull(hSlowMod)
                        and not hSlowMod.nDisarmed_PFX then
                        hSlowMod.nDisarmed_PFX = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_debuff.vpcf", PATTACH_OVERHEAD_FOLLOW, hEntity)

                        hSlowMod:AddParticle(hSlowMod.nDisarmed_PFX, false, false, -1, false, true)

                        EmitSoundOn("Leonidas.Enomotia.Impact.1", hEntity)
                    end
                end
                --=================================--
                if not IsKnockbackImmune(hEntity) then
                    local sTimerNameUnique = self:GetAbilityName()..DoUniqueString(tostring(hEntity:entindex())) --.."_"
                    --=================================--
                    local hPhysicsThingReturn = Physics:Unit(hEntity)

                    hEntity:PreventDI(true)
                    hEntity:SetPhysicsFriction(0)
                    hEntity:SetPhysicsVelocity(GetDirection(hEntity, vCasterGnd) * (tKnockBackTable.knockback_distance / tKnockBackTable.duration))
                    hEntity:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
                    hEntity:SetGroundBehavior(PHYSICS_GROUND_LOCK)
                    hEntity:FollowNavMesh(true)
                    --=================================--
                    Timers:CreateTimer(sTimerNameUnique,
                    {
                        endTime  = tKnockBackTable.knockback_duration,
                        callback = function()
                            hEntity:OnPreBounce(nil)
                            hEntity:SetBounceMultiplier(0)
                            hEntity:PreventDI(false)
                            hEntity:SetPhysicsVelocity(Vector(0,0,0))
                            hEntity:OnPhysicsFrame(nil)
                            hEntity:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
                            FindClearSpaceForUnit(hEntity, hEntity:GetAbsOrigin(), true)
                        end
                    })
                    --=================================--
                    hEntity:OnPreBounce(function(hUnit, vNormal)
                        Timers:RemoveTimer(sTimerNameUnique)

                        hUnit:OnPreBounce(nil)
                        hUnit:SetBounceMultiplier(0)
                        hUnit:PreventDI(false)
                        hUnit:SetPhysicsVelocity(Vector(0,0,0))
                        hUnit:OnPhysicsFrame(nil)
                        hUnit:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
                        FindClearSpaceForUnit(hUnit, hUnit:GetAbsOrigin(), true)
                    end)
                end
                --=================================--
                nPushedUnits = nPushedUnits + 1
            end
            --=================================--
            if nTeamNumberEntity ~= nTeamNumber then
                EmitSoundOn("Leonidas.Enomotia.Impact.2", hEntity)
                --=================================--
                DoDamage(hCaster, hEntity, nBaseDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
                --=================================--
                if bBaseCritical then
                    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hEntity, nBaseDamage, nil)
                end
            end
        end
    end
    --=================================--
    local nPreviousStacks = hCaster:GetModifierStackCount("modifier_leonidas_enomotia_shield", hCaster)
    --=================================--
    hCaster:RemoveModifierByNameAndCaster("modifier_leonidas_enomotia_shield", hCaster)
    --=================================--
    nBaseBlockPerShield = nBaseBlockPerShield + ( GetAttributeValue(hCaster, "leonidas_army_attribute", "enomotia_damage_block_from_armor_pct", -1, 0, false) * hCaster:GetPhysicalArmorValue(false) * 0.01 )
    --=================================--
    local nDamageBlock = nShieldCount * ( nBaseBlockPerShield + ( nPushedUnits * nBonusBlockPerPushed ) )
    --=================================--
    hCaster:AddNewModifier(hCaster, self, "modifier_leonidas_enomotia_shield", {duration = nShieldDuration, nDamageBlock = nPreviousStacks + nDamageBlock})
end







---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_enomotia_shield", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_enomotia_shield = modifier_leonidas_enomotia_shield or class({})

function modifier_leonidas_enomotia_shield:IsHidden()                                                                       return false end
function modifier_leonidas_enomotia_shield:IsDebuff()                                                                       return false end
function modifier_leonidas_enomotia_shield:IsPurgable()                                                                     return false end
function modifier_leonidas_enomotia_shield:IsPurgeException()                                                               return false end
function modifier_leonidas_enomotia_shield:RemoveOnDeath()                                                                  return true end
function modifier_leonidas_enomotia_shield:GetTexture()
    return "anime_hero_leonidas/leonidas_enomotia_shield"
end
function modifier_leonidas_enomotia_shield:DeclareFunctions()
    local hFunc =   { 
                        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
                        MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR
                    }
    return hFunc
end
function modifier_leonidas_enomotia_shield:GetModifierTotal_ConstantBlock(keys)
    if IsServer() then
        if self.hParent:HasModifier("modifier_leonidas_bc_immortal") then --NOTE: BASICALY NOT NEED BUT WANNA PREVENT SHOWING DAMAGE VALUES
            return math.ceil(keys.damage) + 1
        end

        local iBlockNow   = self:GetStackCount()
        local iBlockCheck = iBlockNow - keys.damage
        if iBlockCheck > 0 then
            self:SetStackCount(iBlockCheck)
        elseif not self.bIsComboShield then
            self:Destroy()
        end

        if IsNotNull(keys.attacker) then
            self.tStoreEnemies[tostring(keys.attacker:entindex()).."_"..keys.attacker:GetName()] = keys.attacker
        end

        return iBlockNow
    end
end
function modifier_leonidas_enomotia_shield:GetModifierIgnorePhysicalArmor(keys)
    return self.nIgnoreArmor
end
function modifier_leonidas_enomotia_shield:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    --self.nIgnoreArmor = 0 --NOTE: Prediction for recast and reupdate armor?
    self.nIgnoreArmor = self.hCaster == self.hParent
                        and GetAttributeValue(self.hCaster, "leonidas_army_attribute", "enomotia_nullify_armor_on_shield", -1, 0, false)
                        or 0

    if IsServer() then
        self.bIsComboShield = (tTable.nIsComboShield or 0) > 0
        self.tStoreEnemies  = self.tStoreEnemies or {}

        local nDamageBlock = math.ceil(tTable.nDamageBlock or 0)

        self:SetStackCount(nDamageBlock)
    end

    if IsClient()
        and not self.nShield_PFX then
        self.nShield_PFX =  ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                            ParticleManager:SetParticleControlEnt(
                                                                    self.nShield_PFX, 
                                                                    0, 
                                                                    self.hParent, 
                                                                    PATTACH_POINT_FOLLOW, 
                                                                    "attach_hitloc", 
                                                                    Vector(0, 0, 0), 
                                                                    false
                                                                )

        self:AddParticle(self.nShield_PFX, false, false, -1, false, false)
    end
end
function modifier_leonidas_enomotia_shield:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_leonidas_enomotia_shield:GetStoreEnemies()
    if IsServer() then
        return self.tStoreEnemies
    end
end








---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_enomotia_slow", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_enomotia_slow = modifier_leonidas_enomotia_slow or class({})

function modifier_leonidas_enomotia_slow:IsHidden()                                                                       return false end
function modifier_leonidas_enomotia_slow:IsDebuff()                                                                       return true end
function modifier_leonidas_enomotia_slow:IsPurgable()                                                                     return true end
function modifier_leonidas_enomotia_slow:IsPurgeException()                                                               return true end
function modifier_leonidas_enomotia_slow:RemoveOnDeath()                                                                  return true end
function modifier_leonidas_enomotia_slow:GetPriority()                                                                    return MODIFIER_PRIORITY_NORMAL end
function modifier_leonidas_enomotia_slow:GetAttributes()                                                                  return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_leonidas_enomotia_slow:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
                        MODIFIER_PROPERTY_TOOLTIP,
                        MODIFIER_PROPERTY_TOOLTIP2
                    }
    return tFunc
end
function modifier_leonidas_enomotia_slow:GetModifierMoveSpeedBonus_Percentage(keys)
    return self:GetStackCount()
end
function modifier_leonidas_enomotia_slow:OnTooltip(keys)
    return "WTF"
end
function modifier_leonidas_enomotia_slow:OnTooltip2(keys)
    return "WTF2"
end
function modifier_leonidas_enomotia_slow:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.nDuration = self:GetDuration()

        self:SetStackCount(tTable.nSlow or 0)

        if ( tTable.nDisarmed or 0 ) > 0 then
            giveUnitDataDrivenModifier(self.hCaster, self.hParent, "disarmed", self.nDuration)
        end

        if ( tTable.nRevoked or 0 ) > 0 then
            giveUnitDataDrivenModifier(self.hCaster, self.hParent, "revoked", self.nDuration)
        end

        if ( tTable.nLocked or 0 ) > 0 then
            giveUnitDataDrivenModifier(self.hCaster, self.hParent, "locked", self.nDuration)
        end

        if ( tTable.nRooted or 0 ) > 0 then
            giveUnitDataDrivenModifier(self.hCaster, self.hParent, "rooted", self.nDuration)
        end

        if ( tTable.nStunned or 0 ) > 0 then
            giveUnitDataDrivenModifier(self.hCaster, self.hParent, "stunned", self.nDuration)
        end

        if ( tTable.nSilenced or 0 ) > 0 then
            giveUnitDataDrivenModifier(self.hCaster, self.hParent, "silenced", self.nDuration)
        end

        if ( tTable.nMuted or 0 ) > 0 then
            self.hParent:AddNewModifier(self.hCaster, self.hAbility, "modifier_muted", {duration = self.nDuration})
        end
    end
end
function modifier_leonidas_enomotia_slow:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_leonidas_enomotia_slow:GetEffectName()
    return "particles/heroes/anime_hero_leonidas/leonidas_enomotia_slow_debuff.vpcf"
end
function modifier_leonidas_enomotia_slow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end











































---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
leonidas_enomotia_combo = leonidas_enomotia_combo or class({})

function leonidas_enomotia_combo:IsStealable()                                         return true end
function leonidas_enomotia_combo:IsHiddenWhenStolen()                                  return false end
function leonidas_enomotia_combo:GetIntrinsicModifierName()
    return "modifier_leonidas_enomotia_combo_indicator"
end
function leonidas_enomotia_combo:GetAOERadius()
    local hCaster = self:GetCaster()
    local nScale  = 1
    if type(hCaster.GetIntellect) == "function" then
        nScale = nScale + ( GetAttributeValue(hCaster, "leonidas_math_attribute", "enomotia_radius_pct_scale_per_int", -1, 0, false) * hCaster:GetIntellect() * 0.01 )
    end
    return self:GetSpecialValueFor("radius") * nScale
end
function leonidas_enomotia_combo:OnAbilityPhaseStart()
    EmitSoundOn("Leonidas.Enomotia.Combo.Cast.1", self:GetCaster())
    return true
end
function leonidas_enomotia_combo:OnAbilityPhaseInterrupted()
    StopSoundOn("Leonidas.Enomotia.Combo.Cast.1", self:GetCaster())
end
function leonidas_enomotia_combo:StopShields_PFX(nParticleIndex, bNow)
    if type(nParticleIndex) == "number" then
        ParticleManager:DestroyParticle(nParticleIndex, bNow)
        ParticleManager:ReleaseParticleIndex(nParticleIndex)
    end
end
function leonidas_enomotia_combo:OnSpellStart()
    local hCaster  = self:GetCaster()
    --=================================--
    local vForward = hCaster:GetForwardVector()
    local vRight   = hCaster:GetRightVector()
    local vUp      = hCaster:GetUpVector()
    --=================================--
    local vCasterLoc = hCaster:GetAbsOrigin()
    local vCasterGnd = GetGroundPosition(vCasterLoc, hCaster)
    --=================================--
    local nDamageType = self:GetAbilityDamageType()
    --=================================--
    local nRadius     = self:GetAOERadius()
    local nPushRadius = nRadius * self:GetSpecialValueFor("push_radius")
    --=================================--
    local nPushDuration         = math.max(self:GetSpecialValueFor("push_duration"), 0.1)
    local nPushSlowDuration     = self:GetSpecialValueFor("push_slow_duration")
    local nPushSlowPct          = self:GetSpecialValueFor("push_slow_pct")
    --=================================--
    local nShieldDuration       = self:GetSpecialValueFor("shield_duration")
    local nShieldDamage         = self:GetSpecialValueFor("shield_damage")
    local nShieldCount          = self:GetSpecialValueFor("shield_count")
    local nShieldRows           = math.max(self:GetSpecialValueFor("shield_rows"), 1)
    local nBaseBlockPerShield   = self:GetSpecialValueFor("base_block_per_shield")
    local nBonusBlockPerPushed  = self:GetSpecialValueFor("bonus_block_per_pushed")
    --=================================--
    local nPFX_AnimStartTime   = math.max(self:GetSpecialValueFor("pfx_anim_start_time"), 0.1)
    local nPFX_AnimLoopTime    = self:GetSpecialValueFor("pfx_anim_loop_time")
    local nPFX_AnimReleaseTime = self:GetSpecialValueFor("pfx_anim_release_time")
    --=================================--
    local vPFX_SpawnOrigin  = (vCasterGnd + vForward * -100) + Vector(0, 0, 440)
    local vPFX_MoveToOrigin = (vCasterGnd + vForward * -100) + Vector(0, 0, 270)
    local vPFX_MoveSpeed    = nRadius
    --=================================--
    local nPFX_AnimationSequence = ACT_DOTA_CHANNEL_ABILITY_6
    --=================================--
    local bCasterBerserked = hCaster:HasModifier("modifier_leonidas_berserk")
    --=================================--
    --EmitSoundOn("Leonidas.Enomotia.Cast.Shields", hCaster)
    EmitGlobalSound("Leonidas.Enomotia.Cast.Shields")
    --=================================--
    if not bCasterBerserked then
        EmitGlobalSound("Leonidas.Enomotia.Combo.Cast.2")
        EmitGlobalSound("Leonidas.Enomotia.Combo.Cast.3")

        local nDefenceBonusBlockPerShield = self:GetSpecialValueFor("defence_bonus_block_per_shield")

        nPFX_AnimLoopTime = self:GetSpecialValueFor("defence_duration")

        vPFX_SpawnOrigin  = (vCasterGnd + vForward * 100) + Vector(0, 0, 440)
        vPFX_MoveToOrigin = (vCasterGnd + vForward * 100) + Vector(0, 0, 170)
        vPFX_MoveSpeed    = nRadius * 0.5

        nPFX_AnimationSequence = ACT_DOTA_CHANNEL_ABILITY_7
        --=================================--
        local nShowShields = nShieldCount - 12
        local _nShieldsPFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_shields.vpcf", PATTACH_WORLDORIGIN, nil)
                                ParticleManager:SetParticleShouldCheckFoW(_nShieldsPFX, false)
                                ParticleManager:SetParticleControlOrientationFLU(_nShieldsPFX, 0, vForward, -vRight, vUp)
                                ParticleManager:SetParticleControlOrientationFLU(_nShieldsPFX, 1, vForward, -vRight, vUp)
                                ParticleManager:SetParticleControl(_nShieldsPFX, 0, hCaster:GetAttachmentOrigin(hCaster:ScriptLookupAttachment("ATTACH_HITLOC")))
                                ParticleManager:SetParticleControl(_nShieldsPFX, 1, vPFX_SpawnOrigin)
                                ParticleManager:SetParticleControl(_nShieldsPFX, 2, vPFX_MoveToOrigin)
                                ParticleManager:SetParticleControl(_nShieldsPFX, 3, Vector(nPFX_AnimLoopTime, ( nShowShields / nShieldRows ), nShieldRows))
                                ParticleManager:SetParticleControl(_nShieldsPFX, 4, Vector(vPFX_MoveSpeed, nRadius, ( nShowShields * 0.1 ) / nPFX_AnimStartTime ))
        --=================================--
        --=================================--
        --=================================--
        local nPreviousStacks = hCaster:GetModifierStackCount("modifier_leonidas_enomotia_shield", hCaster)
        --=================================--
        hCaster:RemoveModifierByNameAndCaster("modifier_leonidas_enomotia_shield", hCaster)
        --=================================--
        nBaseBlockPerShield = nBaseBlockPerShield + ( GetAttributeValue(hCaster, "leonidas_army_attribute", "enomotia_damage_block_from_armor_pct", -1, 0, false) * hCaster:GetPhysicalArmorValue(false) * 0.01 )
        --=================================--
        local nDamageBlock = nShieldCount * ( nBaseBlockPerShield + nDefenceBonusBlockPerShield )
        --=================================--
        local hEnomotiaComboShield = hCaster:AddNewModifier(hCaster, self, "modifier_leonidas_enomotia_shield", {duration = nPFX_AnimStartTime + nPFX_AnimLoopTime + nPFX_AnimReleaseTime, nDamageBlock = nDamageBlock, nIsComboShield = 1})
        --=================================--
        --=================================--
        --=================================--
        local nDefenceSphereSpawnDistance = self:GetSpecialValueFor("defence_sphere_spawn_distance") * nRadius
        local vDefenceSphereSpawnPosition = vCasterGnd + vForward * nDefenceSphereSpawnDistance

        local nDefenceAuraModifierThinker = CreateModifierThinker(hCaster, self, "modifier_leonidas_enomotia_combo", {duration = nPFX_AnimStartTime + nPFX_AnimLoopTime + nPFX_AnimReleaseTime, _nShieldsPFX = _nShieldsPFX}, vDefenceSphereSpawnPosition, hCaster:GetTeamNumber(), false)
        --=================================--
        local hPrideAbility = hCaster:FindAbilityByName("leonidas_pride")
        --=================================--
        Timers:CreateTimer(nPFX_AnimStartTime + nPFX_AnimLoopTime * 0.5, function()  --NOTE: Just begining moving shields
            if IsNotNull(nDefenceAuraModifierThinker) then --NOTE: Stop functions in modifier so if not exist modifier we does nothing
                self:StopShields_PFX(_nShieldsPFX, false)
                --=================================--
                Timers:CreateTimer(nPFX_AnimLoopTime * 0.5, function()
                    if IsNotNull(nDefenceAuraModifierThinker) then --NOTE: Again checks 1
                        EndAnimation(hCaster)
                        StartAnimation(hCaster, {duration = nPFX_AnimReleaseTime, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 0.3/(nPFX_AnimReleaseTime)})
                        --=================================--
                        if IsNotNull(hEnomotiaComboShield) then --NOTE: Maybe in future will add anti expire hmhmhm... TODO: Make when all shields is gone same releasing, so again rework anything but only in anime... now i'm tired
                            local tComboStoreEnemies  = hEnomotiaComboShield:GetStoreEnemies() or {}
                            local nTotalDamageBlocked = nDamageBlock - hEnomotiaComboShield:GetStackCount()
                            Timers:CreateTimer(nPFX_AnimReleaseTime * 0.5, function()
                                --if IsNotNull(nDefenceAuraModifierThinker) then --NOTE: Again checks 2
                                --end
                                --print("RELEASING SPEARS TO TARGETS??? ", nTotalDamageBlocked, TableLength(tComboStoreEnemies))

                                ScreenShake(vCasterGnd, 7, 3, 2, 300 * 5, 0, true)

                                if IsNotNull(hPrideAbility) then
                                    local nBonusDamageToAll = ( nTotalDamageBlocked / math.max(TableLength(tComboStoreEnemies), 1) )
                                    for _, hEnemy in pairs(tComboStoreEnemies) do
                                        if IsNotNull(hEnemy) then --MB ADD CHECK FOR ALIVE BUT NOT WANT KEK
                                            hPrideAbility:ReleaseSpear(hEnemy:GetAbsOrigin(), hEnemy, nBonusDamageToAll, false)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end)
            end
        end)
        --=================================--
    else --(1/nPFX_AnimLoopTime)
        --EmitSoundOn("Leonidas.Enomotia.Combo.Cast.2", hCaster)
        EmitGlobalSound("Leonidas.Enomotia.Combo.Cast.2")
        --=================================--
        local nShowShields = nShieldCount - 12
        local _nShieldsPFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_shields.vpcf", PATTACH_WORLDORIGIN, nil)
                                ParticleManager:SetParticleShouldCheckFoW(_nShieldsPFX, false)
                                ParticleManager:SetParticleControlOrientationFLU(_nShieldsPFX, 0, vForward, -vRight, vUp)
                                ParticleManager:SetParticleControlOrientationFLU(_nShieldsPFX, 1, vForward, -vRight, vUp)
                                ParticleManager:SetParticleControl(_nShieldsPFX, 0, hCaster:GetAttachmentOrigin(hCaster:ScriptLookupAttachment("ATTACH_HITLOC")))
                                ParticleManager:SetParticleControl(_nShieldsPFX, 1, vPFX_SpawnOrigin)
                                ParticleManager:SetParticleControl(_nShieldsPFX, 2, vPFX_MoveToOrigin)
                                ParticleManager:SetParticleControl(_nShieldsPFX, 3, Vector(nPFX_AnimLoopTime, ( nShowShields / nShieldRows ), nShieldRows))
                                ParticleManager:SetParticleControl(_nShieldsPFX, 4, Vector(vPFX_MoveSpeed, nRadius, ( nShowShields * 0.1 ) / nPFX_AnimStartTime ))
        --=================================--
        Timers:CreateTimer(nPFX_AnimStartTime, function()
            if IsNotNull(hCaster)
                and hCaster:IsAlive() then
                self:StopShields_PFX(_nShieldsPFX, false)
                --EndAnimation(hCaster)
                --StartAnimation(hCaster, {duration = nPFX_AnimLoopTime, activity = ACT_DOTA_CHANNEL_ABILITY_6, rate = 1.0})
                --EmitSoundOn("Leonidas.Enomotia.Combo.Cast.3", hCaster)
                EmitGlobalSound("Leonidas.Enomotia.Combo.Cast.3")
                --=================================--
                Timers:CreateTimer(nPFX_AnimLoopTime, function()
                    if IsNotNull(hCaster)
                        and hCaster:IsAlive() then
                        self:ReleaseEnomotia(hCaster, nPFX_AnimReleaseTime, nPushRadius, nRadius, nPushDuration, nPushSlowDuration, nPushSlowPct, nShieldDuration, nDamageType, nShieldDamage, nShieldCount, nBaseBlockPerShield, nBonusBlockPerPushed)
                    end
                end)
            else
                self:StopShields_PFX(_nShieldsPFX, true)
            end
        end)
    end
    --=================================--
    giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealenabled", nPFX_AnimStartTime + nPFX_AnimLoopTime + nPFX_AnimReleaseTime)
    --=================================--
    StartAnimation(hCaster, {duration = nPFX_AnimStartTime + nPFX_AnimLoopTime, activity = nPFX_AnimationSequence, rate = 1.0})
    --=================================--
end
function leonidas_enomotia_combo:ReleaseEnomotia(hCaster, nPFX_AnimReleaseTime, nPushRadius, nRadius, nPushDuration, nPushSlowDuration, nPushSlowPct, nShieldDuration, nDamageType, nShieldDamage, nShieldCount, nBaseBlockPerShield, nBonusBlockPerPushed)
    local vCasterLoc = hCaster:GetAbsOrigin()
    local vCasterGnd = GetGroundPosition(vCasterLoc, hCaster)

    local nTeamNumber = hCaster:GetTeamNumber()

    local nBaseDamage, bBaseCritical = GetPrideAndBerserkedScaledDamage(hCaster, nShieldCount * nShieldDamage)

    local nPushedUnits = 0

    local bCasterBerserked = hCaster:HasModifier("modifier_leonidas_berserk")

    local nDisarmed = 1
    local nLocked   = 1
    local nStunned  = bCasterBerserked and 1 or 0

    EndAnimation(hCaster)
    StartAnimation(hCaster, {duration = nPFX_AnimReleaseTime, activity = ACT_DOTA_CHANNEL_END_ABILITY_6, rate = 2.0})

    ScreenShake(vCasterGnd, 7, 3, 2, nRadius * 5, 0, true)

    EmitSoundOnLocationWithCaster(vCasterGnd, "Leonidas.Enomotia.Release.1", hCaster)
    EmitSoundOn("Leonidas.Enomotia.Release.2", hCaster)

    local nLightning_PFX =  ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_lightning.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleShouldCheckFoW(nLightning_PFX, false)
                            ParticleManager:SetParticleControl(nLightning_PFX, 0, vCasterGnd + Vector(0, 0, 1500))
                            ParticleManager:SetParticleControl(nLightning_PFX, 1, vCasterGnd + Vector(0, 0, 100))
                            --ParticleManager:DestroyParticle(nLightning_PFX, false)
                            ParticleManager:ReleaseParticleIndex(nLightning_PFX)

    local nExplode_PFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
                            ParticleManager:SetParticleShouldCheckFoW(nExplode_PFX, false)
                            ParticleManager:SetParticleControl(nExplode_PFX, 0, vCasterGnd)
                            ParticleManager:SetParticleControl(nExplode_PFX, 1, Vector(nRadius, 0, 0))
                            --ParticleManager:DestroyParticle(nExplode_PFX, false)
                            ParticleManager:ReleaseParticleIndex(nExplode_PFX)
        
    local tKnockBackTable = {
                                should_stun         = 0,
                                knockback_duration  = 1,
                                duration            = 1,
                                knockback_distance  = 1,
                                knockback_height    = 0,
                                center_x            = vCasterGnd.x,
                                center_y            = vCasterGnd.y,
                                center_z            = vCasterGnd.z
                            }

    local hEntities = FindUnitsInRadius(
                                            nTeamNumber,
                                            vCasterGnd,
                                            nil,
                                            nRadius,
                                            self:GetAbilityTargetTeam(),
                                            self:GetAbilityTargetType(),
                                            self:GetAbilityTargetFlags(),
                                            FIND_ANY_ORDER,
                                            false
                                        )
    --=================================--
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity)
            and hEntity ~= hCaster then
            local nTeamNumberEntity = hEntity:GetTeamNumber()
            local nDistanceToEntity = GetDistance(vCasterGnd, hEntity)
            if nDistanceToEntity <= nPushRadius then
                tKnockBackTable.knockback_distance = math.floor(nPushRadius - nDistanceToEntity)
                tKnockBackTable.knockback_duration = nPushDuration--(tKnockBackTable.knockback_distance / math.max(nRadius, 1)) * 0.5
                tKnockBackTable.duration = tKnockBackTable.knockback_duration
                --=================================--
                --hEntity:AddNewModifier(hCaster, self, "modifier_knockback", tKnockBackTable) -- MB SWAP TO PHYSICS BECAUSE IDK
                --hEntity:AddNewModifier(hCaster, self, "modifier_rooted", {duration = tKnockBackTable.duration})
                --=================================--
                if nTeamNumberEntity ~= nTeamNumber then
                    local hSlowMod = hEntity:AddNewModifier(hEntity, self, "modifier_leonidas_enomotia_slow", {duration = nPushSlowDuration, nSlow = nPushSlowPct, nStunned = nStunned, nLocked = nLocked, nDisarmed = nDisarmed})
                    if IsNotNull(hSlowMod)
                        and not hSlowMod.nDisarmed_PFX then
                        hSlowMod.nDisarmed_PFX = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_debuff.vpcf", PATTACH_OVERHEAD_FOLLOW, hEntity)

                        hSlowMod:AddParticle(hSlowMod.nDisarmed_PFX, false, false, -1, false, true)
                    end

                    EmitSoundOn("Leonidas.Enomotia.Impact.1", hEntity)
                end
                --=================================--
                if not IsKnockbackImmune(hEntity) then
                    local sTimerNameUnique = self:GetAbilityName()..DoUniqueString(tostring(hEntity:entindex())) --.."_"
                    --=================================--
                    local hPhysicsThingReturn = Physics:Unit(hEntity)

                    hEntity:PreventDI(true)
                    hEntity:SetPhysicsFriction(0)
                    hEntity:SetPhysicsVelocity(GetDirection(hEntity, vCasterGnd) * (tKnockBackTable.knockback_distance / tKnockBackTable.duration))
                    hEntity:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
                    hEntity:SetGroundBehavior(PHYSICS_GROUND_LOCK)
                    hEntity:FollowNavMesh(true)
                    --=================================--
                    Timers:CreateTimer(sTimerNameUnique,
                    {
                        endTime  = tKnockBackTable.knockback_duration,
                        callback = function()
                            hEntity:OnPreBounce(nil)
                            hEntity:SetBounceMultiplier(0)
                            hEntity:PreventDI(false)
                            hEntity:SetPhysicsVelocity(Vector(0,0,0))
                            hEntity:OnPhysicsFrame(nil)
                            hEntity:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
                            FindClearSpaceForUnit(hEntity, hEntity:GetAbsOrigin(), true)
                        end
                    })
                    --=================================--
                    hEntity:OnPreBounce(function(hUnit, vNormal)
                        Timers:RemoveTimer(sTimerNameUnique)

                        hUnit:OnPreBounce(nil)
                        hUnit:SetBounceMultiplier(0)
                        hUnit:PreventDI(false)
                        hUnit:SetPhysicsVelocity(Vector(0,0,0))
                        hUnit:OnPhysicsFrame(nil)
                        hUnit:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
                        FindClearSpaceForUnit(hUnit, hUnit:GetAbsOrigin(), true)
                    end)
                end
                --=================================--
                nPushedUnits = nPushedUnits + 1
            end
            --=================================--
            if nTeamNumberEntity ~= nTeamNumber then
                EmitSoundOn("Leonidas.Enomotia.Impact.2", hEntity)
                --=================================--
                local vEntityLoc = GetGroundPosition(hEntity:GetAbsOrigin(), hEntity)
                local nLightningEntity_PFX =    ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_lightning.vpcf", PATTACH_WORLDORIGIN, nil)
                                                ParticleManager:SetParticleShouldCheckFoW(nLightningEntity_PFX, false)
                                                ParticleManager:SetParticleControl(nLightningEntity_PFX, 0, vEntityLoc + Vector(0, 0, 1500))
                                                ParticleManager:SetParticleControl(nLightningEntity_PFX, 1, vEntityLoc + Vector(0, 0, 100))
                                                --ParticleManager:DestroyParticle(nLightning_PFX, false)
                                                ParticleManager:ReleaseParticleIndex(nLightningEntity_PFX)
                --=================================--
                DoDamage(hCaster, hEntity, nBaseDamage, nDamageType, DOTA_DAMAGE_FLAG_NONE, self, false)
                --=================================--
                if bBaseCritical then
                    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DEADLY_BLOW, hEntity, nBaseDamage, nil)
                end
            end
        end
    end
    --=================================--
    local nPreviousStacks = hCaster:GetModifierStackCount("modifier_leonidas_enomotia_shield", hCaster)
    --=================================--
    hCaster:RemoveModifierByNameAndCaster("modifier_leonidas_enomotia_shield", hCaster)
    --=================================--
    nBaseBlockPerShield = nBaseBlockPerShield + ( GetAttributeValue(hCaster, "leonidas_army_attribute", "enomotia_damage_block_from_armor_pct", -1, 0, false) * hCaster:GetPhysicalArmorValue(false) * 0.01 )
    --=================================--
    local nDamageBlock = nShieldCount * ( nBaseBlockPerShield + ( nPushedUnits * nBonusBlockPerPushed ) )
    --=================================--
    hCaster:AddNewModifier(hCaster, self, "modifier_leonidas_enomotia_shield", {duration = nShieldDuration, nDamageBlock = nDamageBlock})
end



---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_enomotia_combo", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_enomotia_combo = modifier_leonidas_enomotia_combo or class({})

function modifier_leonidas_enomotia_combo:IsHidden()                                      return true end
function modifier_leonidas_enomotia_combo:IsDebuff()                                      return false end
function modifier_leonidas_enomotia_combo:IsPurgable()                                    return false end
function modifier_leonidas_enomotia_combo:IsPurgeException()                              return false end
function modifier_leonidas_enomotia_combo:RemoveOnDeath()                                 return false end
function modifier_leonidas_enomotia_combo:IsAura()                                        return true end
function modifier_leonidas_enomotia_combo:IsAuraActiveOnDeath()                           return false end
function modifier_leonidas_enomotia_combo:IsPermanent()                                   return true end
function modifier_leonidas_enomotia_combo:GetAuraEntityReject(hEntity)
    if IsServer() then
        return hEntity == self.hCaster--PlayerResource:GetSelectedHeroEntity(self.hParent:GetMainControllingPlayer())
    end
end
function modifier_leonidas_enomotia_combo:GetAuraRadius()
    return self.nRadius
end
function modifier_leonidas_enomotia_combo:GetAuraSearchTeam()
    return self.nABILITY_TARGET_TEAM
end
function modifier_leonidas_enomotia_combo:GetAuraSearchType()
    return self.nABILITY_TARGET_TYPE
end
function modifier_leonidas_enomotia_combo:GetAuraSearchFlags()
    return self.nABILITY_TARGET_FLAGS
end
function modifier_leonidas_enomotia_combo:GetModifierAura()
    return "modifier_leonidas_enomotia_combo_translator"
end
function modifier_leonidas_enomotia_combo:CheckState()
    local tState =  {
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
                    }
    return tState
end
function modifier_leonidas_enomotia_combo:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nRadius = self.hAbility:GetAOERadius()

    if IsServer() then
        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = bit.bxor(self.hAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_ENEMY)
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        local vCasterGnd = GetGroundPosition(self.hParent:GetAbsOrigin(), self.hParent)

        if not self.nSphere_PFX then
            self.nSphere_PFX = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_sphere.vpcf", PATTACH_WORLDORIGIN, nil)
                               ParticleManager:SetParticleShouldCheckFoW(self.nSphere_PFX, false)
                               ParticleManager:SetParticleControl(self.nSphere_PFX, 0, vCasterGnd)
                               ParticleManager:SetParticleControl(self.nSphere_PFX, 1, Vector(self.nRadius, self.nRadius, self.nRadius))

            self:AddParticle(self.nSphere_PFX, false, false, -1, false, false)
        end

        self._nShieldsPFX = tTable._nShieldsPFX --NOTE: Idk using -1 will be fine or not so just not using

        self.hAbility:CreateVisibilityNode(vCasterGnd, self.nRadius, self:GetDuration())

        self:StartIntervalThink(FrameTime())
    end
end
function modifier_leonidas_enomotia_combo:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_leonidas_enomotia_combo:OnIntervalThink()
    if IsServer()
        and not ( IsNotNull(self.hCaster) and self.hCaster:IsAlive() ) then
        EndAnimation(self.hCaster)
        self.hAbility:StopShields_PFX(self._nShieldsPFX, true)
        self:Destroy()
    end
end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_leonidas_enomotia_combo_translator", "abilities/anime_hero_leonidas", LUA_MODIFIER_MOTION_NONE)

modifier_leonidas_enomotia_combo_translator = modifier_leonidas_enomotia_combo_translator or class({})

function modifier_leonidas_enomotia_combo_translator:IsHidden()                                             return false end
function modifier_leonidas_enomotia_combo_translator:IsDebuff()                                             return false end
function modifier_leonidas_enomotia_combo_translator:IsPurgable()                                           return false end
function modifier_leonidas_enomotia_combo_translator:IsPurgeException()                                     return false end
function modifier_leonidas_enomotia_combo_translator:RemoveOnDeath()                                        return true end
function modifier_leonidas_enomotia_combo_translator:GetAttributes()                                        return MODIFIER_ATTRIBUTE_AURA_PRIORITY + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_leonidas_enomotia_combo_translator:DeclareFunctions()
    local tFunc =   {   
                        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
                        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
                        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
                    }
    return tFunc
end
function modifier_leonidas_enomotia_combo_translator:GetAbsoluteNoDamagePhysical(keys) --TODO: CHANGE TO RECORD EXCEPT SELF.B-VALUE
    if IsServer()
        and keys.damage_type ~= DAMAGE_TYPE_NONE then
        self.__iNullifyDamageType = self:GetTotalDamageNullify(keys)
        if bit.band(DAMAGE_TYPE_PHYSICAL, self.__iNullifyDamageType) ~= 0 then
            return 1
        end
    end
end
function modifier_leonidas_enomotia_combo_translator:GetAbsoluteNoDamageMagical(keys)
    if IsServer() then
        if bit.band(DAMAGE_TYPE_MAGICAL, self.__iNullifyDamageType) ~= 0 then
            return 1
        end
    end
end
function modifier_leonidas_enomotia_combo_translator:GetAbsoluteNoDamagePure(keys)
    if IsServer() then
        if bit.band(DAMAGE_TYPE_PURE, self.__iNullifyDamageType) ~= 0 then
            return 1
        end
    end
end
function modifier_leonidas_enomotia_combo_translator:GetTotalDamageNullify(keys)
    if IsServer()
        and IsNotNull(self.hCaster)
        and self.hCaster:IsAlive()
        and keys.original_damage > 0 then --IDK WHY BUT WHEN CLEAVE HITS DAMAGE IS 0

        -- local hDamageTable =    {
        --                             victim       = self.hCaster,
        --                             attacker     = keys.attacker,
        --                             damage       = keys.damage,
        --                             damage_type  = keys.damage_type,
        --                             ability      = keys.inflictor or self.hAbility,
        --                             damage_flags = keys.damage_flags
        --                         }

        -- ApplyDamage(hDamageTable)
        --=================================--
        DoDamage(keys.attacker, self.hCaster, keys.damage, keys.damage_type, keys.damage_flags, keys.inflictor or self.hAbility, false)
        --=================================--

        return DAMAGE_TYPE_ALL
    end
end
function modifier_leonidas_enomotia_combo_translator:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
end
function modifier_leonidas_enomotia_combo_translator:OnRefresh(tTable)
    self:OnCreated(tTable)
end


