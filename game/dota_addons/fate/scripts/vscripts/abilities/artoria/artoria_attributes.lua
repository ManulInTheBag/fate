artoria_improve_excalibur_attribute = class({})
artoria_improve_instinct_attribute = class({})
artoria_mana_burst_attribute = class({})
artoria_strike_air_attribute = class({})
artoria_avalon_attribute = class({})

LinkLuaModifier("modifier_artoria_improve_excalibur_attribute", "abilities/artoria/modifiers/modifier_artoria_improve_excalibur_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artoria_improve_instinct_attribute", "abilities/artoria/modifiers/modifier_artoria_improve_instinct_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artoria_mana_burst_attribute", "abilities/artoria/modifiers/modifier_artoria_mana_burst_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artoria_strike_air_attribute", "abilities/artoria/modifiers/modifier_artoria_strike_air_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artoria_avalon_attribute", "abilities/artoria/modifiers/modifier_artoria_avalon_attribute", LUA_MODIFIER_MOTION_NONE)

function artoria_improve_excalibur_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
	
	self.excalibur = ParticleManager:CreateParticle("particles/custom/artoria/excalibur_ambient.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
	ParticleManager:SetParticleControlEnt(self.excalibur, 0, hero, PATTACH_POINT_FOLLOW, "attach_excalibur", hero:GetOrigin(), true)
	ParticleManager:SetParticleControl(self.excalibur, 1, hero:GetOrigin())	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_artoria_improve_excalibur_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.ImproveExcaliburAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function artoria_improve_instinct_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_artoria_improve_instinct_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.ImproveInstinctAcquired = true
	
	hero:SwapAbilities("artoria_improved_instinct", "artoria_instinct", true, false)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function artoria_mana_burst_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_artoria_mana_burst_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.ManaBurstAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function artoria_strike_air_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_artoria_strike_air_attribute", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.StrikeAirAcquired = true
	
	--hero:FindAbilityByName("artoria_strike_air"):SetLevel(hero:FindAbilityByName("artoria_invisible_air"):GetLevel())
	--hero:SwapAbilities("artoria_strike_air", "artoria_charisma", true, false)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end

function artoria_avalon_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_artoria_avalon_attribute", {})
			return nil
		else
			return 1
		end
	end)

	hero:FindAbilityByName("artoria_avalon"):SetLevel(2)
	
	hero.AvalonAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end