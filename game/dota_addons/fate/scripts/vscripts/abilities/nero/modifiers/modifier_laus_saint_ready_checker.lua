modifier_laus_saint_ready_checker = class({})

function modifier_laus_saint_ready_checker:IsHidden()
	return true 
end

function modifier_laus_saint_ready_checker:OnCreated(args)
	if IsServer() then
		local caster = self:GetParent()

		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    	if caster:FindAbilityByName("nero_laus_saint_claudius_new"):IsCooldownReady() and caster:IsAlive() and caster:HasModifier("modifier_aestus_domus_aurea_nero") and caster:GetAbilityByIndex(5) ~= "nero_laus_saint_claudius_new" then	    		
	    		caster:SwapAbilities("nero_laus_saint_claudius_new", "nero_aestus_domus_aurea", true, false)	    		
	    	end
	    end
	    if caster:HasModifier("modifier_ptb_attribute") and caster.UpgradeBase then
	    	if caster:IsAlive() and caster:GetAbilityByIndex(0) ~= "nero_tres_new" then	    		
	    		caster:SwapAbilities("nero_tres_buffed", "nero_tres_new", true, false)	    		
	    	end
	    	if caster:IsAlive() and caster:GetAbilityByIndex(1) ~= "nero_gladiusanus_new" then	    		
	    		caster:SwapAbilities("nero_gladiusanus_buffed", "nero_gladiusanus_new", true, false)	    		
	    	end
	    	if caster:IsAlive() and caster:GetAbilityByIndex(2) ~= "nero_rosa_new" then	    		
	    		caster:SwapAbilities("nero_rosa_buffed", "nero_rosa_new", true, false)	    		
	    	end
	    end
	end
end

--function modifier_laus_saint_ready_checker:OnRefresh(args)
--	self:OnCreated(args)
--end

function modifier_laus_saint_ready_checker:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()

		if caster:GetAbilityByIndex(5):GetName() ~= "nero_aestus_domus_aurea" then
			caster:SwapAbilities("nero_laus_saint_claudius_new", "nero_aestus_domus_aurea", false, true)
		end
		if caster:GetAbilityByIndex(0):GetName() ~= "nero_tres_new" then
			caster:SwapAbilities("nero_tres_buffed", "nero_tres_new", false, true)
		end
		if caster:GetAbilityByIndex(1):GetName() ~= "nero_gladiusanus_new" then
			caster:SwapAbilities("nero_gladiusanus_buffed", "nero_gladiusanus_new", false, true)
		end
		if caster:GetAbilityByIndex(2):GetName() ~= "nero_rosa_new" then
			caster:SwapAbilities("nero_rosa_buffed", "nero_rosa_new", false, true)
		end
		caster.UpgradeLSK = false
		caster.UpgradeBase = false
	end
end

function modifier_laus_saint_ready_checker:RemoveOnDeath()
	return true
end

function modifier_laus_saint_ready_checker:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end