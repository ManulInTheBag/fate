arturia_alter_mana_burst = class({})

LinkLuaModifier("modifier_blast_disjoint", "abilities/arturia_alter/modifiers/modifier_blast_disjoint", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_mana_burst:GetManaCost(iLevel)
	local mana_cost = self:GetSpecialValueFor("mana_cost")
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_mana_blast_attribute") then
		mana_cost = mana_cost + (caster:GetMana() * self:GetSpecialValueFor("attribute_mana_use") / 100)
	end

	return mana_cost
end


function arturia_alter_mana_burst:GetAOERadius()
	local caster = self:GetCaster()
	local baseAoE = self:GetSpecialValueFor("radius")
 
	if caster:HasModifier("modifier_mana_blast_attribute") then
		local manaBonus = caster:GetMana() * self:GetSpecialValueFor("attribute_mana_use") / 100
		manaBonus = manaBonus * self:GetSpecialValueFor("attribute_area_per_mana")

		baseAoE = baseAoE + manaBonus
	end

	return baseAoE
end

function arturia_alter_mana_burst:CalculateDamage()
	local damage = self:GetSpecialValueFor("damage")
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_mana_blast_attribute") then
		damage = damage + self:GetManaCost(self:GetLevel())
	end

	return damage
end

function arturia_alter_mana_burst:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())

	self.Damage = self:CalculateDamage()

	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	return true
end

function arturia_alter_mana_burst:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetAOERadius()

	local damage = self.Damage

	caster:EmitSound("Saber_Alter.ManaBurst") 
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)

	local explode_fx = ParticleManager:CreateParticle("particles/econ/items/puck/puck_alliance_set/puck_illusory_orb_explode_aproset.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(explode_fx, 3, caster:GetAbsOrigin())
	
	local mbParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(mbParticle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(mbParticle, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(mbParticle, 2, Vector(1.5, 0, 0))

	for k,v in pairs(targets) do
	    v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.2 })
	    DoDamage(caster, v, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	local explosionVFX = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_unleashed_ferocity.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(explosionVFX, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(explosionVFX, 1, Vector(radius, 3, 0))
	ParticleManager:SetParticleControl(explosionVFX, 2, Vector(1.5, 0, 0))

	Timers:CreateTimer(2.5, function()
		ParticleManager:DestroyParticle( mbParticle, false )
		ParticleManager:ReleaseParticleIndex(mbParticle)
		ParticleManager:DestroyParticle( explosionVFX, false )
		ParticleManager:ReleaseParticleIndex(explosionVFX)
	end)

	if caster:HasModifier("modifier_mana_blast_attribute") then
		caster:AddNewModifier(caster, self, "modifier_blast_disjoint", { Duration = self:GetSpecialValueFor("attribute_disjoint_duration") })
	end
end