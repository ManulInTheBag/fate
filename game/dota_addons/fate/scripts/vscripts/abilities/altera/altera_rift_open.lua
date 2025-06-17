altera_rift_open = class({})

function altera_rift_open:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self:GetCaster():FindAbilityByName("altera_rift_travel")

	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")

	local ori = caster:GetAbsOrigin()

	ability:CreateRift(ori, radius, duration)
end