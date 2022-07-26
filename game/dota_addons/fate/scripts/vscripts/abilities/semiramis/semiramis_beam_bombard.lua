semiramis_beam_bombard = class({})

function semiramis_beam_bombard:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function semiramis_beam_bombard:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function semiramis_beam_bombard:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local beam_numbers = self:GetSpecialValueFor("beam_numbers")
	local beamAoE = self:GetSpecialValueFor("beam_aoe")
	local damage = self:GetSpecialValueFor("damage")
	local curBeam = 1

	local magic_circle_loc = caster:GetAbsOrigin() + Vector(0, 0, 200)

	local circlefx = ParticleManager:CreateParticle("particles/custom/semiramis/binding_chains/magic_circle.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(circlefx, 4, magic_circle_loc)

	self.Dummy = CreateUnitByName("dummy_unit", targetPoint, false, caster, caster, caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

	Timers:CreateTimer(function()
		if curBeam <= beam_numbers then
			curBeam = curBeam + 1

			local beamLoc = RandomPointInCircle(targetPoint, self:GetAOERadius())

			self:DropBeam(magic_circle_loc, beamLoc, beamAoE, damage)
			
			return 0.1
		else
			ParticleManager:DestroyParticle(circlefx, false)
			ParticleManager:ReleaseParticleIndex(circlefx)
			self.Dummy:RemoveSelf()

			return
		end			
	end)
end

function semiramis_beam_bombard:DropBeam(magic_circle_loc,vLoc, fAoE, fDamage)
	local caster = self:GetCaster()

	local targets = FindUnitsInRadius(caster:GetTeam(), vLoc, nil, fAoE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

	for i = 1, #targets do
		DoDamage(caster, targets[i], fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	magic_circle_loc = magic_circle_loc + RandomVector(25)

	local beamFx = ParticleManager:CreateParticle("particles/custom/semiramis/beam_bombard/semiramis_beam_bombard.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
	ParticleManager:SetParticleControl(beamFx, 0, magic_circle_loc)
	ParticleManager:SetParticleControl(beamFx, 4, vLoc)

	local groundFx = ParticleManager:CreateParticle("particles/custom/semiramis/beam_bombard/semiramis_beam_bombard_ground.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
	ParticleManager:SetParticleControl(groundFx, 0, vLoc)
	
	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(beamFx, false)
		ParticleManager:ReleaseParticleIndex(beamFx)
		ParticleManager:DestroyParticle(groundFx, false)
		ParticleManager:ReleaseParticleIndex(groundFx)

		return
	end)
end