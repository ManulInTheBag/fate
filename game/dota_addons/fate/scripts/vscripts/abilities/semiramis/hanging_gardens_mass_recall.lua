hanging_gardens_mass_recall = class({})

LinkLuaModifier("modifier_mass_recall", "abilities/semiramis/modifiers/modifier_mass_recall", LUA_MODIFIER_MOTION_NONE)

function hanging_gardens_mass_recall:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function hanging_gardens_mass_recall:OnSpellStart()
	local caster = self:GetCaster()
	local targetLoc = self:GetCursorPosition()
	local aoe = self:GetAOERadius()
	local delay = self:GetSpecialValueFor("delay")

	local targets = FindUnitsInRadius(caster:GetTeam(), targetLoc, nil, aoe, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false) 

	for i = 1, #targets do
		targets[i]:AddNewModifier(caster, self, "modifier_mass_recall", { Duration = delay })
	end
end