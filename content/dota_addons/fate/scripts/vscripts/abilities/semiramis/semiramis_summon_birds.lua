semiramis_summon_birds = class({})

function semiramis_summon_birds:OnSpellStart()
	local caster = self:GetCaster()

	local bird = CreateUnitByName("semiramis_bird", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())	
end