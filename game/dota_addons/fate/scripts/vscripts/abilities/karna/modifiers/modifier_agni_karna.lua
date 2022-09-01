modifier_agni_karna = class({})

LinkLuaModifier("modifier_agni_burn", "abilities/karna/modifiers/modifier_agni_burn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bash_counter", "abilities/karna/modifiers/modifier_agni_karna", LUA_MODIFIER_MOTION_NONE)

function modifier_agni_karna:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

if IsServer() then
	function modifier_agni_karna:OnCreated(args)
		self.OnHitDamage = args.OnHitDamage
		self.BurnDamage = args.BurnDamage
		self.BurnDuration = args.BurnDuration
		self.BurnAOE = args.BurnAOE
		self.ExplodeAOE = args.ExplodeAOE
		self.ExplodeDamage = args.ExplodeDamage

		self:AttachParticle()
	end

	function modifier_agni_karna:OnRefresh(args)
		self:DetachParticle()
		self:OnCreated(args)
	end

	function modifier_agni_karna:OnDestroy()
		self:DetachParticle()
	end

	function modifier_agni_karna:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		local caster = self:GetParent()
		local target = args.target
		local ability = self:GetAbility()

		local burn_targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, self.BurnAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

		
			for i = 1, #burn_targets do
				burn_targets[i]:AddNewModifier(caster, ability, "modifier_agni_burn", { Duration = self.BurnDuration,
																		   				BurnDamage = self.BurnDamage})
			end
		

		local stacks  = target:GetModifierStackCount( "modifier_agni_burn", caster)

		local damage = self.OnHitDamage
		
		damage = damage + (damage * stacks-1)
		DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		target:AddNewModifier(caster, ability, "modifier_bash_counter", { Duration = self.BurnDuration})
				
		if caster.ManaBurstAttribute and target:GetModifierStackCount( "modifier_bash_counter", caster) == 6 then
			target:AddNewModifier(caster, target, "modifier_stunned", {Duration = 0.35 })
			target:RemoveModifierByName("modifier_bash_counter")
			local enemies = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, self.ExplodeAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(enemies) do
		        DoDamage(caster, v, self.ExplodeDamage * stacks, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		        target:EmitSound("karna_agni_explosion")		        

		        local particle = ParticleManager:CreateParticle("particles/custom/karna/agni/agni_explosion.vpcf", PATTACH_ABSORIGIN, target)
				ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()) 

				Timers:CreateTimer(2, function()
					ParticleManager:DestroyParticle(particle, false)
					ParticleManager:ReleaseParticleIndex(particle)

					return
				end)
		    end
		end
	end

	function modifier_agni_karna:AttachParticle()
		local caster = self:GetParent()

		self.particle = ParticleManager:CreateParticle("particles/custom/karna/agni/agni_fire_ambient.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	    ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_CUSTOMORIGIN_FOLLOW, "attach_body", caster:GetOrigin(), true)
	end

	function modifier_agni_karna:DetachParticle()
		ParticleManager:DestroyParticle(self.particle, true)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end
end



function modifier_agni_karna:IsDebuff()
	return false
end

function modifier_agni_karna:RemoveOnDeath()
	return true 
end

modifier_bash_counter = class({})



function modifier_bash_counter:IsDebuff()
	return true
end

function modifier_bash_counter:RemoveOnDeath()
	return true 
end

function modifier_bash_counter:OnRefresh(args)
	self:SetStackCount(self:GetStackCount() + 1)
end

function modifier_bash_counter:OnCreated(args)
	self:SetStackCount(args.Stacks or 1)

end