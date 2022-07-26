gilles_eye_for_art_attribute = class({})
gilles_outer_god_attribute = class({})
gilles_demonic_horde_attribute = class({})
gilles_sunken_city_attribute = class({})
gilles_abyssal_connection_attribute = class({})

LinkLuaModifier("modifier_demonic_horde_attribute", "abilities/gilles/modifiers/modifier_demonic_horde_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sunken_city_attribute", "abilities/gilles/modifiers/modifier_sunken_city_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_abyssal_connection_attribute", "abilities/gilles/modifiers/modifier_abyssal_connection_attribute", LUA_MODIFIER_MOTION_NONE)

function gilles_eye_for_art_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then hero = caster.HeroUnit end

	hero:FindAbilityByName("gilles_eye_for_art_passive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function gilles_outer_god_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then hero = caster.HeroUnit end

	hero:FindAbilityByName("gilles_prelati_spellbook"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function gilles_demonic_horde_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then hero = caster.HeroUnit end

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_demonic_horde_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function gilles_sunken_city_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then hero = caster.HeroUnit end

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_sunken_city_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function gilles_abyssal_connection_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then hero = caster.HeroUnit end

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_abyssal_connection_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end