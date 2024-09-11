heracles_fissure = class({})

function heracles_fissure:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "heracles_q_new_2", caster)
	return true
end

function heracles_fissure:OnSpellStart()
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local range = self:GetSpecialValueFor("range")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local width = self:GetSpecialValueFor("width")
	local point = self:GetCursorPosition()
	local vector = -(caster:GetAbsOrigin() - point):Normalized()*range
	local pointEnd = caster:GetAbsOrigin() + vector
	local hEnemies =   FindUnitsInLine(
						caster:GetTeamNumber(),
						caster:GetAbsOrigin(),
						pointEnd,
						nil,
						width,
						DOTA_UNIT_TARGET_TEAM_ENEMY,
						DOTA_UNIT_TARGET_ALL,
						0
	)
	EmitSoundOnLocationWithCaster(pointEnd, "heracles_q_new_1", caster)

	for _, enemy in pairs(hEnemies) do
		DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)	
		giveUnitDataDrivenModifier(caster,enemy , "stunned", stun_duration)
	end
	local particle = ParticleManager:CreateParticle("particles/zlodemon/heracles/heracles_fissure.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin()+caster:GetForwardVector() * 100, caster:GetForwardVector())
	ParticleManager:SetParticleControlTransformForward(particle, 1, caster:GetAbsOrigin()+caster:GetForwardVector() * 100,  caster:GetForwardVector())
	if caster:GetStrength() >= 39.1 and caster:GetAgility() >= 39.1  then
		if self == caster:FindAbilityByName("heracles_fissure") then
			caster.QUsed = true
			QTime = GameRules:GetGameTime()
			Timers:CreateTimer({
				endTime = 4,
				callback = function()
				caster.QUsed = false
			end
			})
		end
	end
end