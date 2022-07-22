lancelot_attribute_eternal_flame = class({})
lancelot_attribute_improve_eternal = class({})
lancelot_attribute_improve_knight_of_honor = class({})
lancelot_attribute_kotl = class({})

LinkLuaModifier("modifier_eternal_flame_attribute", "abilities/lancelot/modifiers/modifier_eternal_flame_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kotl_attribute", "abilities/lancelot/modifiers/modifier_kotl_attribute", LUA_MODIFIER_MOTION_NONE)

function lancelot_attribute_kotl:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_kotl_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function lancelot_attribute_eternal_flame:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_eternal_flame_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function lancelot_attribute_improve_eternal:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	local eternalArms = hero:FindAbilityByName("lancelot_arms_mastership")
	eternalArms:SetLevel(eternalArms:GetLevel() + 1)

	hero.KnightLevel = (hero.KnightLevel or 0) + 1

	if eternalArms:GetLevel() < 2 then
		self:EndCooldown()
	else
		hero.KnightLevel = (hero.KnightLevel or 0) + 1
	end

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function lancelot_attribute_improve_knight_of_honor:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.KnightLevel = (hero.KnightLevel or 0) + 1

	local max_level = 2 

	if caster:FindAbilityByName("lancelot_attribute_improve_eternal"):IsCooldownReady() == false then
		max_level = 3
	end

	if hero.KnightLevel ~= max_level then		
		self:EndCooldown()
	end

	--print("KOH Attribute", hero.KnightLevel)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end