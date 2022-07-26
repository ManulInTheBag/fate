hanging_gardens_orbital_strike = class({})

function hanging_gardens_orbital_strike:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function hanging_gardens_orbital_strike:OnSpellStart()
	local caster = self:GetCaster()
	local target_loc = self:GetCursorPosition()
	local delay = self:GetSpecialValueFor("delay")
	local damage = self:GetSpecialValueFor("damage")

	

	Timers:CreateTimer(delay, function()  
		if caster:IsAlive() then
			local enemies = FindUnitsInRadius(caster:GetTeam(), target_loc, nil, self:GetAOERadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		
			for i = 1, #enemies do
				DoDamage(caster, targets[i], damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end

			local dummy = CreateUnitByName("dummy_unit", target_loc, false, caster, caster, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

			local fxIndex = ParticleManager:CreateParticle("particles/custom/semiramis/laser/semiramis_laser.vpcf", PATTACH_POINT, dummy)
			ParticleManager:SetParticleControlEnt(fxIndex, 0, dummy, PATTACH_POINT, "attach_hitloc", dummy:GetAbsOrigin(), true)
		end
	return end)
end