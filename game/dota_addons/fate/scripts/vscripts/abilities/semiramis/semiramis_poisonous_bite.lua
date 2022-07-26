semiramis_poisonous_bite = class({})

LinkLuaModifier("modifier_poisonous_bite", "abilities/semiramis/modifiers/modifier_poisonous_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_poisonous_bite_slow", "abilities/semiramis/modifiers/modifier_poisonous_bite_slow", LUA_MODIFIER_MOTION_NONE)

function semiramis_poisonous_bite:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())

	return filter
end

function semiramis_poisonous_bite:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function semiramis_poisonous_bite:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	target:AddNewModifier(caster, self, "modifier_poisonous_bite", { Duration = self:GetSpecialValueFor("duration"),
																	 Damage = self:GetSpecialValueFor("damage"),
																	 AOE = self:GetSpecialValueFor("radius") })

	if not IsImmuneToSlow(target) then
		target:AddNewModifier(caster, self, "modifier_poisonous_bite_slow", { Duration = self:GetSpecialValueFor("duration"),																	 
																			  Slow = self:GetSpecialValueFor("slow"),
																			  SlowInc = self:GetSpecialValueFor("slow_inc")})
	end
end