lu_bu_fangtian_huaji_attribute = class({})
lu_bu_ruthless_warrior_attribute = class({})
lu_bu_restless_soul_attribute = class({})
lu_bu_bravery_attribute = class({})
lu_bu_insurmountable_assault_attribute = class({})
lu_bu_combo_list = class({})

LinkLuaModifier("modifier_lu_bu_fangtian_huaji_attribute", "abilities/lu_bu/modifiers/modifier_lu_bu_fangtian_huaji_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lu_bu_ruthless_warrior_attribute", "abilities/lu_bu/modifiers/modifier_lu_bu_ruthless_warrior_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lu_bu_restless_soul_attribute", "abilities/lu_bu/modifiers/modifier_lu_bu_restless_soul_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lu_bu_bravery_attribute", "abilities/lu_bu/modifiers/modifier_lu_bu_bravery_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lu_bu_insurmountable_assault_attribute", "abilities/lu_bu/modifiers/modifier_lu_bu_insurmountable_assault_attribute", LUA_MODIFIER_MOTION_NONE)

function lu_bu_fangtian_huaji_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_lu_bu_fangtian_huaji_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.FH = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function lu_bu_ruthless_warrior_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_lu_bu_ruthless_warrior_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.RW = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function lu_bu_restless_soul_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_lu_bu_restless_soul_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.IsRS = true
	
	hero:FindAbilityByName("lu_bu_restless_soul"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function lu_bu_bravery_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_lu_bu_bravery_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.IsB = true
	
	hero:FindAbilityByName("lu_bu_rebellious_spirit"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function lu_bu_insurmountable_assault_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_lu_bu_insurmountable_assault_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.IsIS = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function lu_bu_combo_list:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
end