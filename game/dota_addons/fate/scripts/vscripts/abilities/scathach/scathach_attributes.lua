scathach_primeval_rune_attribute = class({})
scathach_branches_of_tonelico_attribute = class({})
scathach_pinning_thorn_attribute = class({})
scathach_wisdom_of_dun_scaith_attribute = class({})
scathach_combo_2_proxy = class({})

LinkLuaModifier("modifier_scathach_primeval_rune_attribute", "abilities/scathach/modifiers/modifier_scathach_primeval_rune_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_branches_of_tonelico_attribute", "abilities/scathach/modifiers/modifier_scathach_branches_of_tonelico_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pinning_god_attribute", "abilities/scathach/modifiers/modifier_scathach_pinning_god_attribute", LUA_MODIFIER_MOTION_NONE)

function scathach_primeval_rune_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_scathach_primeval_rune_attribute", {})
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

function scathach_branches_of_tonelico_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_scathach_branches_of_tonelico_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.BB = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function scathach_pinning_thorn_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_scathach_pinning_god_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.IsPT = true
	
	hero:FindAbilityByName("scathach_pinning_thorn"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function scathach_wisdom_of_dun_scaith_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	hero:FindAbilityByName("scathach_wisdom_of_dun_scaith"):SetLevel(1)
	
	hero.IsWoDS = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function scathach_combo_2_proxy:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
end	