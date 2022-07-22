hanging_gardens_bombard = class({})

function hanging_gardens_bombard:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function hanging_gardens_bombard:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local beam_numbers = self:GetSpecialValueFor("beam_numbers")
	local beamAoE = self:GetSpecialValueFor("beam_aoe")
	local damage = self:GetSpecialValueFor("damage")
	local curBeam = 1

	Timers:CreateTimer(function()
		if curBeam <= beam_numbers then
			curBeam = curBeam + 1

			local beamLoc = RandomPointInCircle(targetPoint, self:GetAOERadius)

			self:DropBeam(beamLoc, beamAoE, damage)

			return 0.1
		else
			return
		end			
	end)
end

function hanging_gardens_bombard:DropBeam(vLoc, fAoE, fDamage)
	local caster = self:GetCaster()

	local targets = FindUnitsInRadius(caster:GetTeam(), vLoc, nil, fAoE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

	for i = 1, #targets do
		DoDamage(caster, targets[i], fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	local beamFx = ParticleManager:CreateParticle("particles/custom/semiramis/beam/semiramis_beam.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(beamFx, 0, vLoc)
	ParticleManager:SetParticleControl(beamFx, 1, vLoc)
	ParticleManager:SetParticleControl(beamFx, 5, vLoc)
	ParticleManager:SetParticleControl(beamFx, 6, vLoc)
	
	Timers:CreateTimer(0.5, function()
		ParticleManager:DestroyParticle(beamFx, false)
		ParticleManager:ReleaseParticleIndex(beamFx)
		return
	end)
end