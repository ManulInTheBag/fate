
ozy_light_pillar = class({})

function ozy_light_pillar:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ozy_light_pillar:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local delay = self:GetSpecialValueFor("delay")
	local baseDamage = self:GetSpecialValueFor("damage")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	

	local markFx = ParticleManager:CreateParticle("particles/ozy/ozy_light_pillar_runes.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( markFx, 0, targetPoint)
	EmitSoundOnLocationWithCaster(targetPoint, "Hero_Chen.PenitenceImpact", caster)	






	Timers:CreateTimer(delay, function()
		ParticleManager:DestroyParticle(markFx, true)
		ParticleManager:ReleaseParticleIndex(markFx)

		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if not v:IsMagicImmune() then				
		        DoDamage(caster, v, baseDamage, self:GetAbilityDamageType(), 0, self, false)
		        giveUnitDataDrivenModifier(caster, v, "stunned", stun_duration)
			end


	    end
	    EmitSoundOnLocationWithCaster(targetPoint, "Hero_Chen.TestOfFaith.Target", caster)		

	end)
end