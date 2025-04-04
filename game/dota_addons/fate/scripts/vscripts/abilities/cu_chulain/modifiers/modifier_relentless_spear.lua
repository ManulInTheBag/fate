modifier_relentless_spear = class({})

if IsServer() then
	function modifier_relentless_spear:OnCreated(args)
		local caster = self:GetParent()
		self.target = self:GetAbility().target
		self.DamagePct = args.DamagePct

		self.particles = ParticleManager:CreateParticle("particles/custom/lancer/lancer_relentless_spear/lancer_relentless_spear.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(self.particles, 0, caster, PATTACH_POINT_FOLLOW, "attach_spear_end", caster:GetOrigin(), true)	
		StartAnimation(caster, {duration=self:GetDuration(), activity=ACT_DOTA_RAZE_1 , rate=1})	
		self:StartIntervalThink(0.125)
	end

	function modifier_relentless_spear:OnRefresh(args)
		self:OnDestroy()
		self:OnCreated(args)
	end

	function modifier_relentless_spear:OnIntervalThink()
		if self.target:IsAlive() then
			local caster = self:GetParent()
			local damage = caster:GetAverageTrueAttackDamage(self.target) * self.DamagePct / 100

			DoDamage(caster, self.target, damage, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
			caster:PerformAttack(self.target, true, true, true, true, false, true, true)
			self.target:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", { Duration = 0.15})
			self.target:EmitSound("Hero_PhantomLancer.Attack")

		
		else
			self:Destroy()
		end
	end

	function modifier_relentless_spear:OnDestroy()
		local caster = self:GetParent()
		EndAnimation(caster)
		ParticleManager:DestroyParticle(self.particles, true)
		ParticleManager:ReleaseParticleIndex(self.particles)
		caster:RemoveModifierByName("modifier_cu_relentless_tracker")
	end
end

function modifier_relentless_spear:IsHidden()
	return true
end