modifier_aestus_estus = class({})

function modifier_aestus_estus:OnCreated()
	Timers:CreateTimer(6.0, function()
		EmitGlobalSound("nero_move_01")
		return 6
		end)
end
--function modifier_aestus_estus:DeclareFunctions()
--	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
--end

--if IsServer() then 
--	function modifier_aestus_estus:OnAttackLanded(args)
--		if args.attacker ~= self:GetParent() then return end
--		
--		local caster = self:GetParent()
--
--		local tresFontCD = caster:FindAbilityByName("nero_tres_fontaine_ardent"):GetCooldownTimeRemaining()
--		caster:FindAbilityByName("nero_tres_fontaine_ardent"):EndCooldown()
--		if tresFontCD - 1 > 0 then
--			caster:FindAbilityByName("nero_tres_fontaine_ardent"):StartCooldown(tresFontCD - 1)
--		end 
--
--		local glaudiusCD = caster:FindAbilityByName("nero_gladiusanus_blauserum"):GetCooldownTimeRemaining()
--		caster:FindAbilityByName("nero_gladiusanus_blauserum"):EndCooldown()
--		if glaudiusCD - 1 > 0 then
--			caster:FindAbilityByName("nero_gladiusanus_blauserum"):StartCooldown(glaudiusCD - 1)
--		end 
--
--		local rosaCD = caster:FindAbilityByName("nero_rosa_ichthys"):GetCooldownTimeRemaining()
--		caster:FindAbilityByName("nero_rosa_ichthys"):EndCooldown()
--		if rosaCD - 1 > 0 then
--			caster:FindAbilityByName("nero_rosa_ichthys"):StartCooldown(rosaCD - 1)
--		end 
--
--		DoDamage(caster, args.target, 35 + caster:GetAgility(), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
--	end
--end

function modifier_aestus_estus:IsPermanent()
	return true 
end

function modifier_aestus_estus:IsHidden()
	return true
end