LinkLuaModifier("modifier_altera_crest", "abilities/altera/altera_attributes", LUA_MODIFIER_MOTION_NONE)

altera_crest_attribute = class({})

function altera_crest_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.CrestAcquired = true

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_altera_crest", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

altera_refraction_attribute = class({})

function altera_refraction_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.RefractionAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

altera_erosion_attribute = class({})

function altera_erosion_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.ErosionAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

altera_adaptive_attribute = class({})

function altera_adaptive_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.AdaptiveAcquired = true

	hero:FindAbilityByName("altera_adaptive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

altera_endless_attribute = class({})

function altera_endless_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.EndlessAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

modifier_altera_crest = class({})

function modifier_altera_crest:IsHidden() 
	return true
end

function modifier_altera_crest:IsPermanent()
	return true
end

function modifier_altera_crest:RemoveOnDeath()
	return false
end

function modifier_altera_crest:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end