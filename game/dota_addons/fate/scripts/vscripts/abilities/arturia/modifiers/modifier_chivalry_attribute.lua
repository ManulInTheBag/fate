modifier_chivalry_attribute = class({})

function modifier_chivalry_attribute:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

if IsServer() then 
	function modifier_chivalry_attribute:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end
		
		local caster = self:GetParent()

		local invisairCD = caster:FindAbilityByName("saber_invisible_air"):GetCooldownTimeRemaining()
		caster:FindAbilityByName("saber_invisible_air"):EndCooldown()
		if invisairCD - 1 > 0 then
			caster:FindAbilityByName("saber_invisible_air"):StartCooldown(invisairCD - 1)
		end 

		local caliburnCD = caster:FindAbilityByName("saber_caliburn"):GetCooldownTimeRemaining()
		caster:FindAbilityByName("saber_caliburn"):EndCooldown()
		if caliburnCD - 1 > 0 then
			caster:FindAbilityByName("saber_caliburn"):StartCooldown(caliburnCD - 1)
		end 
	end
end

function modifier_chivalry_attribute:IsPermanent()
	return true 
end

function modifier_chivalry_attribute:IsHidden()
	return true
end