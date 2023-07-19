LinkLuaModifier("modifier_subterranean_grasp", "abilities/tamamo/tamamo_subterranean_grasp", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_subterranean_grasp_fire", "abilities/tamamo/tamamo_subterranean_grasp", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_subterranean_grasp_void", "abilities/tamamo/tamamo_subterranean_grasp", LUA_MODIFIER_MOTION_NONE)

tamamo_subterranean_grasp = class({})

function tamamo_subterranean_grasp:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function tamamo_subterranean_grasp:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local radius = self:GetSpecialValueFor("radius")
	local delay = self:GetSpecialValueFor("delay")
	local duration = self:GetSpecialValueFor("duration")
	local damage = self:GetSpecialValueFor("damage")

	SpawnVisionDummy(caster, target, radius, delay + duration, false)

	local ParticleIndex = ParticleManager:CreateParticle("particles/tamamo/tamamo_grasp_marker.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(ParticleIndex, 0, target) 
	ParticleManager:SetParticleControl(ParticleIndex, 1, Vector(radius, radius, radius))
	ParticleManager:SetParticleControl(ParticleIndex, 2, Vector(delay, 0, 0))

	Timers:CreateTimer(delay, function()
		EmitSoundOnLocationWithCaster(target, "Hero_Visage.GraveChill.Cast", caster)
		local tEnemies = FindUnitsInRadius(caster:GetTeam(), target, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for i = 1, #tEnemies do
			if caster.IsTerritoryAcquired and caster:HasModifier("modifier_amaterasu_ally") then
				giveUnitDataDrivenModifier(caster, tEnemies[i], "revoked", duration)
			end

			tEnemies[i]:AddNewModifier(caster, self, "modifier_subterranean_grasp", {duration = duration})

			giveUnitDataDrivenModifier(caster, tEnemies[i], "rooted", duration)

			if caster:HasModifier("modifier_fiery_heaven_indicator") then
				tEnemies[i]:AddNewModifier(caster, self, "modifier_subterranean_grasp_fire", {duration = duration})
			elseif caster:HasModifier("modifier_frigid_heaven_indicator") then 
				giveUnitDataDrivenModifier(caster, tEnemies[i], "locked", duration)
			elseif caster:HasModifier("modifier_gust_heaven_indicator") then
				giveUnitDataDrivenModifier(caster, tEnemies[i], "silenced", duration)
			elseif caster:HasModifier("modifier_void_heaven_indicator") then
				tEnemies[i]:AddNewModifier(caster, self, "modifier_subterranean_grasp_void", {duration = duration})
			end

			DoDamage(caster, tEnemies[i], damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		ParticleManager:DestroyParticle(ParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(ParticleIndex)
	end)
end

modifier_subterranean_grasp = class({})

function modifier_subterranean_grasp:IsDebuff() return true end

function modifier_subterranean_grasp:GetEffectName()
	return "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff.vpcf"
end

function modifier_subterranean_grasp:GetEffectAttachType()
	return PATTACH_ORIGIN_FOLLOW
end

modifier_subterranean_grasp_void = class({})

function modifier_subterranean_grasp_void:IsDebuff() return true end
function modifier_subterranean_grasp_void:IsHidden() return false end
function modifier_subterranean_grasp_void:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_subterranean_grasp_void:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("void_mr_reduction")
end

modifier_subterranean_grasp_fire = class({})

function modifier_subterranean_grasp_fire:IsDebuff() return true end
function modifier_subterranean_grasp_fire:IsHidden() return false end

function modifier_subterranean_grasp_fire:RemoveOnDeath()
	return true
end

function modifier_subterranean_grasp_fire:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_subterranean_grasp_fire:GetModifierHealAmplify_PercentageTarget()
	return self:GetAbility():GetSpecialValueFor("heal_reduction")
end

function modifier_subterranean_grasp_fire:GetModifierHPRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("heal_reduction")
end