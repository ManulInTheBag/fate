-----------------------------
--    Robin's Attributes    --
-----------------------------

robin_tools_attribute = class({})
robin_independent_action_attribute = class({})
robin_faceless_king_attribute = class({})
robin_of_sherwood_attribute = class({})
robin_yew_bow_attribute = class({})
robin_combo_list = class({})

LinkLuaModifier("modifier_robin_tools_attribute", "abilities/robin/modifiers/modifier_robin_tools_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_robin_independent_action_attribute", "abilities/robin/modifiers/modifier_robin_independent_action_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_robin_of_sherwood_attribute", "abilities/robin/modifiers/modifier_robin_of_sherwood_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_robin_yew_bow_attribute", "abilities/robin/modifiers/modifier_robin_yew_bow_attribute", LUA_MODIFIER_MOTION_NONE)

function robin_tools_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_robin_tools_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.PD = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function robin_independent_action_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_robin_independent_action_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.IA = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function robin_faceless_king_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	hero.FK = true
	
	hero:FindAbilityByName("robin_faceless_king"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function robin_of_sherwood_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_robin_of_sherwood_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.ROS = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function robin_yew_bow_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_robin_yew_bow_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.YB = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end