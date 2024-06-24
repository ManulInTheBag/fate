LinkLuaModifier("modifier_jeanne_vision", "abilities/jeanne/modifiers/modifier_jeanne_vision", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_gods_resolution_active_buff", "abilities/jeanne/jeanne_gods_resolution", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_gods_resolution_slow", "abilities/jeanne/jeanne_gods_resolution", LUA_MODIFIER_MOTION_NONE)

jeanne_gods_resolution = class({})

function jeanne_gods_resolution:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function jeanne_gods_resolution:OnSpellStart()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_jeanne_gods_resolution_active_buff") then
		caster:RemoveModifierByName("modifier_jeanne_gods_resolution_active_buff")
		return
	end
	local duration = self:GetSpecialValueFor("active_duration")
	if caster.IsPunishmentAcquired then
		duration = duration + 1
	end

	local soundQueue = math.random(9,12)

	caster:EmitSound("Jeanne_Skill_" .. soundQueue)
	--giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", duration)
	caster:AddNewModifier(caster, self, "modifier_jeanne_gods_resolution_active_buff", {duration = duration})

	self.resolutionFx = ParticleManager:CreateParticle("particles/custom/jeanne/jeanne_god_resolution_reborn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   	ParticleManager:SetParticleControl( self.resolutionFx, 0, caster:GetAbsOrigin())
   	ParticleManager:SetParticleControl( self.resolutionFx, 1, Vector(duration, 0, 0))

end

jeanne_gods_resolution_end = class({})

function jeanne_gods_resolution_end:OnSpellStart()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_jeanne_gods_resolution_active_buff") then
		caster:RemoveModifierByName("modifier_jeanne_gods_resolution_active_buff")
	else
		caster:SwapAbilities("jeanne_gods_resolution", "jeanne_gods_resolution_end", true, false)
	end
end

modifier_jeanne_gods_resolution_active_buff = class({})

function modifier_jeanne_gods_resolution_active_buff:IsDebuff() return false end
function modifier_jeanne_gods_resolution_active_buff:IsHidden() return false end
function modifier_jeanne_gods_resolution_active_buff:RemoveOnDeath() return false end

function modifier_jeanne_gods_resolution_active_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_DISABLE_TURNING,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
			MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
			MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
end

function modifier_jeanne_gods_resolution_active_buff:CheckState()
	local state = {[MODIFIER_STATE_SILENCED] = true,
			--[MODIFIER_STATE_MUTED] = true
		}

	if self:GetCaster().IsPunishmentAcquired then
		state = {[MODIFIER_STATE_SILENCED] = true,
						--[MODIFIER_STATE_MUTED] = true,
						[MODIFIER_STATE_UNSLOWABLE] = true,
						[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
	end
	return state
end

function modifier_jeanne_gods_resolution_active_buff:GetModifierDisableTurning()
	return 1
end

function modifier_jeanne_gods_resolution_active_buff:GetModifierIgnoreCastAngle()
	return 1
end

function modifier_jeanne_gods_resolution_active_buff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_bonus")
end

function modifier_jeanne_gods_resolution_active_buff:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mr_bonus")
end

function modifier_jeanne_gods_resolution_active_buff:GetOverrideAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_3
end

function modifier_jeanne_gods_resolution_active_buff:GetOverrideAnimationRate()
	return 1.0
end

function modifier_jeanne_gods_resolution_active_buff:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.caster:EmitSound("Hero_ArcWarden.MagneticField")

	self.interval = 0.2

	self.tickDamage = self.ability:GetSpecialValueFor("active_dps")*self.interval
	self.tickSinDamage = self.ability:GetSpecialValueFor("sin_damage")*self.interval

	self.radius = self.ability:GetSpecialValueFor("radius")

	self.caster:SwapAbilities("jeanne_gods_resolution", "jeanne_gods_resolution_end", false, true)
	self.caster:FindAbilityByName("jeanne_gods_resolution_end"):StartCooldown(0.2)
	self:StartIntervalThink(self.interval)
end

function modifier_jeanne_gods_resolution_active_buff:OnIntervalThink()
	if not IsServer() then return end

	local targets = FindUnitsInRadius(self.caster:GetTeam(), self.caster:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
	    DoDamage(self.caster, v, self.tickDamage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	    if not IsImmuneToSlow(v) then v:AddNewModifier(self.caster, self.ability, "modifier_jeanne_gods_resolution_slow", {duration = 0.5}) end
        if self.caster.IsRevelationAcquired then
        	v:AddNewModifier(self.caster, self.ability, "modifier_jeanne_vision", { Duration = self.ability:GetSpecialValueFor("reveal_duration") })
        end
    end
end

function modifier_jeanne_gods_resolution_active_buff:OnDestroy()
	if IsServer() then
		self.caster:SwapAbilities("jeanne_gods_resolution", "jeanne_gods_resolution_end", true, false)
		self.caster:StopSound("Hero_ArcWarden.MagneticField")
		if type(self.ability.resolutionFx) == "number" then
			ParticleManager:DestroyParticle(self.ability.resolutionFx, false)
			ParticleManager:ReleaseParticleIndex(self.ability.resolutionFx)
		end
	end
end

modifier_jeanne_gods_resolution_slow = class({})

function modifier_jeanne_gods_resolution_slow:DeclareFunctions()
	return {	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE	}
end

function modifier_jeanne_gods_resolution_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_amount")
end