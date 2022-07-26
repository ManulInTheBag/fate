diarmuid_attribute_love_spot = class({})
diarmuid_attribute_minds_eye = class({})
diarmuid_attribute_golden_rose = class({})
diarmuid_attribute_crimson_rose = class({})
diarmuid_attribute_doublespear = class({})
diarmuid_rampant_warrior_proxy = class({})

LinkLuaModifier("modifier_minds_eye_attribute", "abilities/diarmuid/modifiers/modifier_minds_eye_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_golden_rose_attribute", "abilities/diarmuid/modifiers/modifier_golden_rose_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crimson_rose_attribute", "abilities/diarmuid/modifiers/modifier_crimson_rose_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doublespear_attribute", "abilities/diarmuid/modifiers/modifier_doublespear_attribute", LUA_MODIFIER_MOTION_NONE)

function diarmuid_attribute_love_spot:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:FindAbilityByName("diarmuid_love_spot"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function diarmuid_attribute_minds_eye:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
	hero:FindAbilityByName("diarmuid_minds_eye"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function diarmuid_attribute_golden_rose:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_golden_rose_attribute", {})
	    	hero.IsGoldenRoseAcquired = true
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function diarmuid_attribute_crimson_rose:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_crimson_rose_attribute", {})
	    	hero.IsCrimsonRoseAcquired = true
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function diarmuid_attribute_doublespear:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()		

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_doublespear_attribute", {})
			return nil
		else
			return 1
		end
	end)	

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end