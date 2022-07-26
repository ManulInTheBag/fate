emiya_attribute_eagle_eye = class({})
emiya_attribute_hrunting = class({})
emiya_attribute_shroud_of_martin = class({})
emiya_attribute_projection = class({})
emiya_attribute_overedge = class({})

LinkLuaModifier("modifier_hrunting_attribute", "abilities/emiya/modifiers/modifier_hrunting_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shroud_of_martin", "abilities/emiya/modifiers/modifier_shroud_of_martin", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eagle_eye", "abilities/emiya/modifiers/modifier_eagle_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overedge_attribute", "abilities/emiya/modifiers/modifier_overedge_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_projection_attribute", "abilities/emiya/modifiers/modifier_projection_attribute", LUA_MODIFIER_MOTION_NONE)

function emiya_attribute_eagle_eye:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:FindAbilityByName("emiya_clairvoyance"):SetLevel(2)

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_eagle_eye", {})
			return nil
		else
			return 1
		end
	end)

	hero.IsEagleEyeAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function emiya_attribute_hrunting:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_hrunting_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function emiya_attribute_shroud_of_martin:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:FindAbilityByName("emiya_rho_aias"):SetLevel(1)

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_shroud_of_martin", { Armor = self:GetSpecialValueFor("armor"),
																	   	   MagicResist = self:GetSpecialValueFor("magic_resist")})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function emiya_attribute_projection:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_projection_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function emiya_attribute_overedge:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()		

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_overedge_attribute", {})
			return nil
		else
			return 1
		end
	end)	

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end