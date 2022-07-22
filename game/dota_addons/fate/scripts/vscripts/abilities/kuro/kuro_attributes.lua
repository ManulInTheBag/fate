kuro_attribute_eagle_eye = class({})
kuro_attribute_projection_overpower = class({})
kuro_attribute_projection = class({})
kuro_attribute_overedge = class({})

LinkLuaModifier("modifier_kuro_projection", "abilities/kuro/modifiers/modifier_kuro_projection", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kuro_eagle_eye", "abilities/kuro/modifiers/modifier_kuro_eagle_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kuro_projection_overpower", "abilities/kuro/modifiers/modifier_kuro_projection_overpower", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kuro_overedge", "abilities/kuro/modifiers/modifier_kuro_overedge", LUA_MODIFIER_MOTION_NONE)
function kuro_attribute_eagle_eye:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_kuro_eagle_eye", {})
			return nil
		else
			return 1
		end
	end)
	hero:FindAbilityByName("kuro_clairvoyance"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function kuro_attribute_projection_overpower:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_kuro_projection_overpower", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function kuro_attribute_projection:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_kuro_projection", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function kuro_attribute_overedge:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_kuro_overedge", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end