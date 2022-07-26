cu_chulain_battle_cont_attribute = class({})
cu_chulain_prot_arrows_attribute = class({})
cu_chulain_death_flight_attribute = class({})
cu_chulain_heartseeker_attribute = class({})
cu_chulain_celtic_runes_attribute = class({})

LinkLuaModifier("modifier_celtic_rune_attribute", "abilities/cu_chulain/modifiers/modifier_celtic_rune_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_improve_throw_attribute", "abilities/cu_chulain/modifiers/modifier_improve_throw_attribute", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_battle_cont_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	hero:FindAbilityByName("cu_chulain_battle_continuation"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function cu_chulain_prot_arrows_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	hero:FindAbilityByName("cu_chulain_protection_from_arrows"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function cu_chulain_death_flight_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_improve_throw_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function cu_chulain_heartseeker_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	hero.HeartSeekerImproved = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function cu_chulain_celtic_runes_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_celtic_rune_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end