iskander_brilliance_of_the_king = class({})



function iskander_brilliance_of_the_king:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local duration = self:GetSpecialValueFor("duration")

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		giveUnitDataDrivenModifier(caster, v, "silenced",2)
	end

	EmitGlobalSound("Waver_NP_" .. math.random(1,2))
	if hero:HasModifier("modifier_annihilate_caster") then
		for k,v in pairs(targets) do
			giveUnitDataDrivenModifier(caster, v, "rooted",2)
		end
	end
end
