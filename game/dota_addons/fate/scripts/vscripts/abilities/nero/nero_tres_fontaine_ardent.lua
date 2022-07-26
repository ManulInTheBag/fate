nero_tres_fontaine_ardent = class({})

LinkLuaModifier("modifier_tres_target_marker", "abilities/nero/modifiers/modifier_tres_target_marker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tres_fontaine_nero", "abilities/nero/modifiers/modifier_tres_fontaine_nero", LUA_MODIFIER_MOTION_NONE)

function nero_tres_fontaine_ardent:GetCooldown(iLevel)
	local caster = self:GetCaster()
	--if caster:HasModifier("modifier_aestus_domus_aurea_nero") and caster:HasModifier("modifier_sovereign_attribute") then
	--	return self:GetSpecialValueFor("aestus_cooldown")
	--else
		return self:GetSpecialValueFor("cooldown")
	--end
end

function nero_tres_fontaine_ardent:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function nero_tres_fontaine_ardent:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local ability = self
	local damage = self:GetSpecialValueFor("damage")

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
			
	local soundType = math.random(1,2)
	local doSound = true

	if soundType == 1 then
		caster:EmitSound("Nero_Skill_" .. math.random(1,4))
		doSound = false
	end

	if caster:HasModifier("modifier_ptb_attribute") then
		damage = damage + (caster:GetAgility() * 2)
	end

	if #targets > 0 then
		local marker_duration = #targets * 0.25

		for i = 1, #targets do
			targets[i]:AddNewModifier(caster, ability, "modifier_tres_target_marker", { Duration = marker_duration})
		end

		caster:AddNewModifier(caster, ability, "modifier_tres_fontaine_nero", { Duration = marker_duration,
																				DamageOnHit = damage,
																				Radius = self:GetSpecialValueFor("max_range"),
																				AttackSound = doSound })
	end
end