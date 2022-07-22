modifier_surgery_heal = class({})

if IsServer() then
	function modifier_surgery_heal:OnCreated(args)
		self.HealAmt = args.HealAmt * 0.1
		self.CooldownReduction = args.CooldownReduction * 0.1

		self:OnIntervalThink()

		self:StartIntervalThink(0.1)
	end

	function modifier_surgery_heal:OnIntervalThink()
		local caster = self:GetParent()

		caster:Heal(self.HealAmt, caster)

		local jtr_dagger_throw = caster:FindAbilityByName("jtr_dagger_throw")
		local jtr_murderer_mist = caster:FindAbilityByName("jtr_murderer_mist")
		local jtr_maria_the_ripper = caster:FindAbilityByName("jtr_maria_the_ripper")

		if not jtr_dagger_throw:IsCooldownReady() then
			local q_cd = jtr_dagger_throw:GetCooldownTimeRemaining()
			jtr_dagger_throw:EndCooldown()
			jtr_dagger_throw:StartCooldown(q_cd - self.CooldownReduction)
		end

		if not jtr_murderer_mist:IsCooldownReady() then
			local e_cd = jtr_murderer_mist:GetCooldownTimeRemaining()
			jtr_murderer_mist:EndCooldown()
			jtr_murderer_mist:StartCooldown(e_cd - self.CooldownReduction)
		end

		if not jtr_maria_the_ripper:IsCooldownReady() then
			local r_cd = jtr_maria_the_ripper:GetCooldownTimeRemaining()
			jtr_maria_the_ripper:EndCooldown()
			jtr_maria_the_ripper:StartCooldown(r_cd - self.CooldownReduction)
		end
	end
end

function modifier_surgery_heal:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_surgery_heal:IsHidden()
    return true
end