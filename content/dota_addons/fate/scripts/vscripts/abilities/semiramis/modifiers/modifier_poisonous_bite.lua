modifier_poisonous_bite = class({})

LinkLuaModifier("modifier_poisonous_bite", "abilities/semiramis/modifiers/modifier_poisonous_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_poisonous_bite_slow", "abilities/semiramis/modifiers/modifier_poisonous_bite_slow", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_poisonous_bite:OnCreated(args)		
		self.Damage = args.Damage
		self.AOE = args.AOE
		
		--target:EmitSound(soundname)
		self:StartIntervalThink(0.25)
	end

	function modifier_poisonous_bite:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_poisonous_bite:OnIntervalThink()
		local damage = self.Damage / 0.25

		DoDamage(self:GetCaster(), self:GetParent(), damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end

	function modifier_poisonous_bite:OnDestroy()
		local parent = self:GetParent()
		local enemies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil, self.AOE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		local ability = self:GetAbility()

		for i = 1, #enemies do
			if enemies[i] ~= self:GetParent() then
				enemies[i]:AddNewModifier(self:GetCaster(), ability, "modifier_poisonous_bite", { Duration = ability:GetSpecialValueFor("duration"),
																								  Damage = ability:GetSpecialValueFor("damage"),
																								  AOE = ability:GetSpecialValueFor("radius")})

				self:CreatePoisonFx(enemies[i])

				if not IsImmuneToSlow(enemies[i]) then
					enemies[i]:AddNewModifier(self:GetCaster(), ability, "modifier_poisonous_bite_slow", { Slow = ability:GetSpecialValueFor("slow"),
																									   		SlowInc = ability:GetSpecialValueFor("slow_inc") })
				end
			end
		end		
	end

	function modifier_poisonous_bite:CreatePoisonFx(target)
		local particle = ParticleManager:CreateParticle("particles/custom/semiramis/semiramis_poison_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
		
		Timers:CreateTimer(1.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
			return nil
		end)
	end
end

function modifier_poisonous_bite:IsHidden()
	return true 
end

function modifier_poisonous_bite:RemoveOnDeath()
	return true
end

function modifier_poisonous_bite:GetAttributes()
	return MODIFIER_ATTRIBUTE_NONE
end

