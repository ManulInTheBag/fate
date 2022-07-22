modifier_double_spearmanship_active = class({})


if IsServer() then
	function modifier_double_spearmanship_active:OnCreated(args)	
		local caster = self:GetParent()
		self.ProcReady = true
		self.AttackSpeed = args.AttackSpeed
		self.OnHit = args.OnHit

		CustomNetTables:SetTableValue("sync","double_spearmanship", { attack_speed = self.AttackSpeed })
		
		--[[self.RedTrail = ParticleManager:CreateParticle("particles/custom/diarmuid/diarmuid_red_trail.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	    ParticleManager:SetParticleControlEnt(self.RedTrail, 0, caster, PATTACH_CUSTOMORIGIN_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)

	    self.YellowTrail = ParticleManager:CreateParticle("particles/custom/diarmuid/diarmuid_yellow_trail.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	    ParticleManager:SetParticleControlEnt(self.YellowTrail, 0, caster, PATTACH_CUSTOMORIGIN_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	]]
	end

	function modifier_double_spearmanship_active:OnRefresh(args)
		--self:DestroySpearParticles()
		self:OnCreated(args)
	end

	--[[function modifier_double_spearmanship_active:OnDestroy()	
		self:DestroySpearParticles()	
	end

	function modifier_double_spearmanship_active:DestroySpearParticles()	
		ParticleManager:DestroyParticle( self.RedTrail, false )
		ParticleManager:ReleaseParticleIndex( self.RedTrail )
		ParticleManager:DestroyParticle( self.YellowTrail, false )
		ParticleManager:ReleaseParticleIndex( self.YellowTrail )	
	end]]

	function modifier_double_spearmanship_active:OnAttackLanded(args)	
		if args.attacker ~= self:GetParent() or self:GetParent():HasModifier("modifier_rampant_warrior") then 
			return 
		end
		local target = args.target
		local caster = self:GetParent()

		if self.ProcReady then
			self.ProcReady = false
			self:StartIntervalThink(0.1)
			caster:PerformAttack(target, true, true, true, true, false, false, false)
			DoDamage(caster, target, self.OnHit, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			DoDamage(caster, target, self.OnHit, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
		end	
	end

	function modifier_double_spearmanship_active:OnIntervalThink()
		self.ProcReady = true
		self:StartIntervalThink(-1)
	end
end

function modifier_double_spearmanship_active:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.AttackSpeed
	elseif IsClient() then
		local attack_speed = CustomNetTables:GetTableValue("sync","double_spearmanship").attack_speed
        return attack_speed 
	end
end

function modifier_double_spearmanship_active:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_double_spearmanship_active:IsHidden()
	return false
end

function modifier_double_spearmanship_active:RemoveOnDeath()
	return true
end

function modifier_double_spearmanship_active:GetTexture()
	return "custom/diarmuid_double_spearsmanship"
end

function modifier_double_spearmanship_active:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_alacrity_buff.vpcf"
end

function modifier_double_spearmanship_active:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end