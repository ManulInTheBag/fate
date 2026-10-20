require("libraries/skin_fx")
modifier_relentless_spear = class({})

if IsServer() then
	function modifier_relentless_spear:OnCreated(args)
		local caster = self:GetParent()
		self.target = self:GetAbility().target
		self.DamagePct = args.DamagePct

		-- a skin may swap the blade trail for slashes on every hit (skin_fx values.w3_slash_fx)
		self.slashFx = SkinValue(caster, "w3_slash_fx")
		if not self.slashFx then
			self.particles = ParticleManager:CreateParticle(SkinParticle(caster, "particles/custom/lancer/lancer_relentless_spear/lancer_relentless_spear.vpcf"), PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(self.particles, 0, caster, PATTACH_POINT_FOLLOW, SkinAttachment(caster, "attach_spear_end"), caster:GetOrigin(), true)
		end
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
			SkinEmitSound(self.target, self:GetCaster(), "Hero_PhantomLancer.Attack")
			if self.slashFx then
				local pos = self.target:GetAbsOrigin() + Vector(0, 0, 50)
				local fx = ParticleManager:CreateParticle(self.slashFx, PATTACH_WORLDORIGIN, nil)
				for _, cp in ipairs({0, 1, 2, 7}) do ParticleManager:SetParticleControl(fx, cp, pos) end
				ParticleManager:ReleaseParticleIndex(fx)
			end

		
		else
			self:Destroy()
		end
	end

	function modifier_relentless_spear:OnDestroy()
		local caster = self:GetParent()
		EndAnimation(caster)
		if self.particles then
			ParticleManager:DestroyParticle(self.particles, true)
			ParticleManager:ReleaseParticleIndex(self.particles)
			self.particles = nil
		end
		caster:RemoveModifierByName("modifier_cu_relentless_tracker")
	end
end

function modifier_relentless_spear:IsHidden()
	return true
end