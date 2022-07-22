karna_discern_poor = class({})

LinkLuaModifier("modifier_discern_poor_knights", "abilities/karna/modifiers/modifier_discern_poor_knights", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_discern_poor_horseman", "abilities/karna/modifiers/modifier_discern_poor_horseman", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_discern_poor_extra", "abilities/karna/modifiers/modifier_discern_poor_extra", LUA_MODIFIER_MOTION_NONE)

function karna_discern_poor:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function karna_discern_poor:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function karna_discern_poor:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

	if not IsSpellBlocked(target) then
		local modifier_name = ""

		if IsKnightClass(target) then
			modifier_name = "modifier_discern_poor_knights"
		elseif IsHorsemanClass(target) then
			modifier_name = "modifier_discern_poor_horseman"
		else
			modifier_name = "modifier_discern_poor_extra"
		end

		caster:EmitSound("karna_discern")
		target:AddNewModifier(caster, self, modifier_name, {Duration = self:GetSpecialValueFor("duration")})
	end
end