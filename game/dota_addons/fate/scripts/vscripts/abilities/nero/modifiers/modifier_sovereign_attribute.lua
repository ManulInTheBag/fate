modifier_sovereign_attribute = class({})

function modifier_sovereign_attribute:IsHidden()
	return true
end

function modifier_sovereign_attribute:IsPermanent()
	return true
end

function modifier_sovereign_attribute:RemoveOnDeath()
	return false
end

function modifier_sovereign_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_sovereign_attribute:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

if IsServer() then 
	function modifier_sovereign_attribute:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end
		--if not self:GetParent():HasModifier("modifier_aestus_domus_aurea_nero") then return end
		
		local caster = self:GetParent()

		--[[local tresFontCD = caster:FindAbilityByName("nero_tres_fontaine_ardent"):GetCooldownTimeRemaining()
		caster:FindAbilityByName("nero_tres_fontaine_ardent"):EndCooldown()
		if tresFontCD - 1 > 0 then
			caster:FindAbilityByName("nero_tres_fontaine_ardent"):StartCooldown(tresFontCD - 1)
		end 

		local glaudiusCD = caster:FindAbilityByName("nero_gladiusanus_blauserum"):GetCooldownTimeRemaining()
		caster:FindAbilityByName("nero_gladiusanus_blauserum"):EndCooldown()
		if glaudiusCD - 1 > 0 then
			caster:FindAbilityByName("nero_gladiusanus_blauserum"):StartCooldown(glaudiusCD - 1)
		end 

		local rosaCD = caster:FindAbilityByName("nero_rosa_ichthys"):GetCooldownTimeRemaining()
		caster:FindAbilityByName("nero_rosa_ichthys"):EndCooldown()
		if rosaCD - 1 > 0 then
			caster:FindAbilityByName("nero_rosa_ichthys"):StartCooldown(rosaCD - 1)
		end]]

		DoDamage(caster, args.target, 35 + caster:GetAgility(), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end