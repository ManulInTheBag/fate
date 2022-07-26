modifier_rho_aias = class({})

LinkLuaModifier("modifier_rho_aias_particle", "abilities/emiya/modifiers/modifier_rho_aias_particle", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_rho_aias:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end
		local rhoTarget = self:GetParent()
		local currentHealth = rhoTarget:GetHealth() 

		-- Create particles
		local onHitParticleIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_templar_assassin/templar_assassin_refract_hit_sphere.vpcf", PATTACH_CUSTOMORIGIN, rhoTarget )
		ParticleManager:SetParticleControl( onHitParticleIndex, 2, rhoTarget:GetAbsOrigin() )
		
		Timers:CreateTimer( 0.5, function()
			ParticleManager:DestroyParticle( onHitParticleIndex, false )
			ParticleManager:ReleaseParticleIndex( onHitParticleIndex )
		end)

		rhoTarget.rhoShieldAmount = rhoTarget.rhoShieldAmount - args.damage

		if rhoTarget.rhoShieldAmount <= 0 then
			rhoTarget:SetHealth(math.min(currentHealth + args.damage, self.rhoTargetHealth) + rhoTarget.rhoShieldAmount)
			rhoTarget.rhoShieldAmount = 0
			self:Destroy()
		else			
			rhoTarget:SetHealth(math.min(currentHealth + args.damage, self.rhoTargetHealth))
			self:SetStackCount(rhoTarget.rhoShieldAmount / 10)
		end
	end

	function modifier_rho_aias:OnCreated(args)			
		self.rhoTargetHealth = self:GetParent():GetHealth()
		self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_rho_aias_particle", { Duration = self:GetDuration() })
		self:SetStackCount((self:GetParent().rhoShieldAmount or 0) / 10)
		self:StartIntervalThink(0.033)		
	end

	function modifier_rho_aias:OnRefresh(args)
		self:OnDestroy()
		self:OnCreated(args)
	end

	function modifier_rho_aias:OnIntervalThink()
		self.rhoTargetHealth = self:GetParent():GetHealth()
	end

	function modifier_rho_aias:OnDestroy()	
		self:GetParent():RemoveModifierByName("modifier_rho_aias_particle")
	end
end

function modifier_rho_aias:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end

function modifier_rho_aias:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE
	 }
end

function modifier_rho_aias:RemoveOnDeath()
	return true 
end

function modifier_rho_aias:GetTexture()
	return "custom/archer_5th_rho_aias"
end