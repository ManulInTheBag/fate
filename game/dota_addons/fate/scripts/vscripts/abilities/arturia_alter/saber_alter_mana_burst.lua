saber_alter_mana_burst = class({})

function saber_alter_mana_burst:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	return true
end

function saber_alter_mana_burst:OnSpellStart()
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local radius = self:GetSpecialValueFor("radius")
	local stunDuration = 0.2

	if caster.IsManaBlastAcquired then
		damage = damage + (caster:GetMana() * 0.1)
		caster:SpendMana(caster:GetMana() * 0.1, self)
		stunDuration = 0.5
		radius = radius + 200
	end

	caster:EmitSound("Saber_Alter.ManaBurst")
	caster:EmitSound("saber_alter_attack_03")
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius
			, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)

	local info = {
		Target = nil,
		Source = caster,
		Ability = self,
		EffectName = "particles/items2_fx/skadi_projectile.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 500
	}

	if caster.IsManaBlastAcquired and #targets ~= 0 then
		-- catalyst stacks are built by arturia_alter_derange (modifier_catalyst)
		while caster:GetModifierStackCount("modifier_catalyst", nil) ~= 0 do
			info.Target = targets[math.random(#targets)]
			ProjectileManager:CreateTrackingProjectile(info)
			caster:SetModifierStackCount("modifier_catalyst", nil, caster:GetModifierStackCount("modifier_catalyst", nil) - 1)
		end
	end

	-- 1.24c particle fix
	-- Slight fix to make the particle size respect the actual AoE after obtaining SA
	local mbParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(mbParticle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(mbParticle, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(mbParticle, 2, Vector(1.0, 0, 0))

	for k,v in pairs(targets) do
		DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		v:AddNewModifier(caster, v, "modifier_stunned", {Duration = stunDuration})
	end
end

function saber_alter_mana_burst:OnProjectileHit(hTarget, vLocation)
	if not hTarget then return end
	DoDamage(self:GetCaster(), hTarget, 100, DAMAGE_TYPE_MAGICAL, 0, self, false)
end
