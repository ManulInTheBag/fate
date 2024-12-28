LinkLuaModifier("modifier_aoko_magician_attribute", "abilities/aoko/aoko_attributes", LUA_MODIFIER_MOTION_NONE)

aoko_circuits_attribute = class({})

function aoko_circuits_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.CircuitsAcquired = true
	hero:FindAbilityByName("aoko_circuits"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

aoko_first_star_attribute = class({})

function aoko_first_star_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.FirstStarAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

aoko_bullet_attribute = class({})

function aoko_bullet_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.MagicBulletLoadAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

aoko_incantation_attribute = class({})

function aoko_incantation_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.HighSpeedIncantationAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

aoko_magician_attribute = class({})

function aoko_magician_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_aoko_magician_attribute", {})
			return nil
		else
			return 1
		end
	end)

	hero.MagicianOfFifthAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

modifier_aoko_magician_attribute = class({})

function modifier_aoko_magician_attribute:IsHidden() 
	return true
end

function modifier_aoko_magician_attribute:IsPermanent()
	return true
end

function modifier_aoko_magician_attribute:RemoveOnDeath()
	return false
end

function modifier_aoko_magician_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end