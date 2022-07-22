iskandar_arrow_bombard = class({})

function iskandar_arrow_bombard:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function iskandar_arrow_bombard:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTarget = self:GetCursorPosition()
	local fDamage = self:GetSpecialValueFor("damage")
	local fRootDuration = self:GetSpecialValueFor("root_dur")	

	local iParticleIndex = ParticleManager:CreateParticle("particles/custom/iskandar/arrow_volley.vpcf", PATTACH_CUSTOMORIGIN, nil) 
    ParticleManager:SetParticleControl(iParticleIndex, 0, vTarget)
    ParticleManager:SetParticleControl(iParticleIndex, 1, hCaster:GetAbsOrigin() + Vector(0, 0, 500))
    ParticleManager:SetParticleControl(iParticleIndex, 3, hCaster:GetAbsOrigin() + Vector(0, 0, 500))
    ParticleManager:SetParticleControl(iParticleIndex, 4, Vector(self:GetAOERadius(), 1, 1))

    EmitSoundOnLocationWithCaster(vTarget, "Hero_LegionCommander.Overwhelming.Location", hCaster)

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vTarget, nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for i = 1, #tEnemies do
		DoDamage(hCaster, tEnemies[i], fDamage, DAMAGE_TYPE_PHYSICAL, 0, self, false)		
		giveUnitDataDrivenModifier(hCaster, tEnemies[i], "rooted", fRootDuration)
	end

	Timers:CreateTimer(0.75, function()
		ParticleManager:DestroyParticle(iParticleIndex, true)
		ParticleManager:ReleaseParticleIndex(iParticleIndex)
	end)
end