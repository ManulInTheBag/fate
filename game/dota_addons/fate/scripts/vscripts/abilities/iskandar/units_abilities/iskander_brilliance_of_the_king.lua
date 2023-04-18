iskander_brilliance_of_the_king = class({})



function iskander_brilliance_of_the_king:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local duration = self:GetSpecialValueFor("duration")

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		giveUnitDataDrivenModifier(caster, v, "silenced",2)
	end

	---these 2 are many years old and dont really fit into fate anymore
	--local fx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_aura.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	--ParticleManager:SetParticleControl(fx1, 0, caster:GetAbsOrigin())

	--local fx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_shadow_word_buff.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	--ParticleManager:SetParticleControl(fx2, 0, caster:GetAbsOrigin())

	local fx3 = ParticleManager:CreateParticle("particles/iskander/waver_brilliance.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(fx3, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(fx3, 1, Vector(1500,0,0))
	local fx4 = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_buff_j.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(fx4, 0, caster:GetAbsOrigin())
	Timers:CreateTimer(1.0, function() 
		ParticleManager:DestroyParticle(fx3, true)
		ParticleManager:ReleaseParticleIndex(fx3)

	end)
	EmitGlobalSound("Waver_NP_" .. math.random(1,2))
	for k,v in pairs(targets) do
		giveUnitDataDrivenModifier(caster, v, "rooted",2)
	end
end
