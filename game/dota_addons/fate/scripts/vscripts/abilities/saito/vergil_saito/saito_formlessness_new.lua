saito_formlessness_new = saito_formlessness_new or class({})
LinkLuaModifier("saito_formlessness_new_stacks", "abilities/saito/vergil_saito/saito_formlessness_new", LUA_MODIFIER_MOTION_NONE)

local EmitZlodemonTrueSound = function(sSoundName)
    --ALO PIDORASI VI SVOIM EBANIM ZLODEMON_TRUE SLOMALI EBANOGO SAITO
    --return nil
    LoopOverPlayers(function(player, playerID, playerHero)
        if playerHero.zlodemon == true and playerHero:GetName() == "npc_dota_hero_terrorblade" then
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound=sSoundName})
        end
    end)
end
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
--==============
function saito_formlessness_new:OnUpgrade() --Call when ability is upgraded in any way AKA -setlevel or by player or LearnAbility or etc.
    if IsServer() then
        UpgradeShared(self, tSaito_RR)
    end
end
function saito_formlessness_new:GetIntrinsicModifierName()
    return "modifier_saito_formless_slash_counter" --Basically we can handle stacks on the invis modifier because without it this ability can't work...
end
function saito_formlessness_new:GetCastRange(vLocation, hTarget)
    return self.BaseClass.GetCastRange(self, vLocation, hTarget) + GetAttributeValue(self:GetCaster(), "saito_attribute_kunishige", "fls_cast_range", -1, 0)
end
function saito_formlessness_new:GetAbilityTextureName() --Just for the visual difference (spellicons) between each slash, add this...
    local hCaster = self:GetCaster()
    return "custom/saito/saito_formless_slash_4" --.. (hCaster:GetModifierStackCount("modifier_saito_formless_slash_counter", hCaster) + 1)
end
function saito_formlessness_new:GetCastPoint()
    local hCaster = self:GetCaster()
    return 0.3--self.BaseClass.GetCastPoint(self) + ( hCaster:GetModifierStackCount("modifier_saito_formless_slash_counter", hCaster) == 3 and 0.3 or 0 )
end
function saito_formlessness_new:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()

    local nMaxSlashes = self:GetSpecialValueFor("max_slashes")

    --local nStacks = ( hCaster:GetModifierStackCount("modifier_saito_formless_slash_counter", hCaster) + 1 ) % nMaxSlashes
   -- if nStacks == 0 then
        EmitSoundOn("Saito.Formless.Slash.Last.Voice", hCaster)
        EmitZlodemonTrueSound("moskes_saito_rlast")
    --elseif nStacks == 1 then
   --     EmitSoundOn("Saito.Formless.Slash.Cast.Voice", hCaster)
   --     EmitZlodemonTrueSound("moskes_saito_rslash")
   -- end
end
function saito_formlessness_new:OnAbilityPhaseInterrupted()
    local hCaster = self:GetCaster()

    --StopSoundOn("Saito.Formless.Slash.Cast.Voice", hCaster)
    StopSoundOn("Saito.Formless.Slash.Last.Voice", hCaster)
end

function saito_formlessness_new:DoSlash(target,fw )
	local hCaster = self:GetCaster()
	
    local nLockDuration     = self:GetSpecialValueFor("lock_duration")
	local nDamageType = self:GetAbilityDamageType()
	local nSlashDamage = self:GetSpecialValueFor("slash_damage") + hCaster:GetAverageTrueAttackDamage(target) * 0.01 * GetAttributeValue(hCaster, "saito_attribute_kunishige", "fls_dmg_per_atk", self:GetLevel(), 0)
	local nAttrRootDuration     = GetAttributeValue(hCaster, "saito_attribute_freedom", "fls_root_duration", -1, 0)
    local nRevokedScale = GetAttributeValue(hCaster, "saito_attribute_kunishige", "fls_revoked_scale", -1, 1)
	if not target:IsHero() or bIsRevoked(target) then
        nSlashDamage = nSlashDamage * nRevokedScale
    end
	giveUnitDataDrivenModifier(hCaster, target, "locked", nLockDuration)
	if nAttrRootDuration > 0 then
		giveUnitDataDrivenModifier(hCaster, target, "rooted", nAttrRootDuration)
	end
	for i = 1, 2 do
		DoDamage(hCaster, target, nSlashDamage, nDamageType, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, self, false)
	end
	self:DoDoubleSlashEffect(target, fw)

end

function saito_formlessness_new:DoLastSlash(target, fw)
	local hCaster = self:GetCaster()
	

    local nLastLockDuration = self:GetSpecialValueFor("last_lock_duration")
	local nDamageType = self:GetAbilityDamageType()
    local nLastDamage  = self:GetSpecialValueFor("last_damage") + hCaster:GetAverageTrueAttackDamage(hTarget) * 0.01 * GetAttributeValue(hCaster, "saito_attribute_kunishige", "fls_last_dmg_per_atk", self:GetLevel(), 0)
	local nAttrLastRootDuration = GetAttributeValue(hCaster, "saito_attribute_freedom", "fls_last_root_duration", -1, 0)
    local nRevokedScale = GetAttributeValue(hCaster, "saito_attribute_kunishige", "fls_revoked_scale", -1, 1)
	if not target:IsHero() or bIsRevoked(target) then
         nLastDamage = nLastDamage * nRevokedScale
    end
	
	giveUnitDataDrivenModifier(hCaster, target, "locked", nLastLockDuration)
	if nAttrLastRootDuration > 0 then
		giveUnitDataDrivenModifier(hCaster, target, "rooted", nAttrLastRootDuration)
	end
	DoDamage(hCaster, target, nLastDamage, nDamageType, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, self, false)
	self:DoLastSlashEffect(target, fw)
end

function saito_formlessness_new:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()

    if IsSpellBlocked(hTarget) then
        return nil
    end
	hCaster:RemoveModifierByNameAndCaster("modifier_saito_formless_invis", hCaster) --Invis breaks early.
    self:CreateFlash(hCaster)
	local stacks = 0
	if hTarget:HasModifier("saito_formlessness_new_stacks") then
		stacks = hTarget:GetModifierStackCount("saito_formlessness_new_stacks", hCaster)
		hTarget:RemoveModifierByName("saito_formlessness_new_stacks")
	end
	local fw = hCaster:GetForwardVector()
	Timers:CreateTimer(0, function()
		if stacks > 0 then
			self:DoSlash(hTarget, fw)
			stacks = stacks - 1
			return 0.1
		else
			self:DoLastSlash(hTarget, fw)
			return
		end
	
	end)
end
function saito_formlessness_new:CreateFlash(hCaster)
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
function saito_formlessness_new:DoDoubleSlashEffect(hTarget, fw)
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
                       ParticleManager:SetParticleControlTransformForward(nSlashPFX, 1, hTarget:GetAbsOrigin(), -fw)
                        ParticleManager:SetParticleControl(nSlashPFX, 2, hTarget:GetAbsOrigin())
                        ParticleManager:SetParticleControl(nSlashPFX, 3, hTarget:GetAbsOrigin())
                        ParticleManager:ReleaseParticleIndex(nSlashPFX)
	StopSoundOn("Saito.Formless.Slash.Impact", hTarget)
    EmitSoundOn("Saito.Formless.Slash.Impact", hTarget)
 	EmitSoundOn("saito_inv_sword"..math.random(1, 2), hTarget)
end
function saito_formlessness_new:DoLastSlashEffect(hTarget, fw)
    local sSlashPFX = "particles/heroes/saito/saito_formless_slash_last.vpcf"
    local nSlashPFX =   ParticleManager:CreateParticle(sSlashPFX, PATTACH_ABSORIGIN_FOLLOW, hTarget)
                       -- ParticleManager:SetParticleControlForward(nSlashPFX, 1, -self:GetCaster():GetForwardVector())
                        ParticleManager:SetParticleControlTransformForward(nSlashPFX, 1, hTarget:GetAbsOrigin(), -fw)
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





saito_formlessness_new_stacks = class({})

function saito_formlessness_new_stacks:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function saito_formlessness_new_stacks:IsDebuff() return true end
function saito_formlessness_new_stacks:RemoveOnDeath() return true end
function saito_formlessness_new_stacks:OnCreated(args)
	self:SetStackCount(1)
 
end
function saito_formlessness_new_stacks:OnRefresh(args)
	
	if self:GetStackCount() > 9 then
		self:SetStackCount(10)
	else
		self:SetStackCount(self:GetStackCount() + 1)
	end
end
