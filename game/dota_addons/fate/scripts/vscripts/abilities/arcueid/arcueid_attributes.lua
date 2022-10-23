LinkLuaModifier("modifier_arcueid_recklesness", "abilities/arcueid/arcueid_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_world", "abilities/arcueid/arcueid_attributes", LUA_MODIFIER_MOTION_NONE)

arcueid_mystic_eyes_attribute = class({})

function arcueid_mystic_eyes_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.MysticEyesAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arcueid_monstrous_strength_attribute = class({})

function arcueid_monstrous_strength_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.MonstrousStrengthAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arcueid_regen_attribute = class({})

function arcueid_regen_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:FindAbilityByName("arcueid_regen"):SetLevel(2)

	hero.RegenAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arcueid_recklesness_attribute = class({})

function arcueid_recklesness_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_arcueid_recklesness", {})
			return nil
		else
			return 1
		end
	end)

	hero.RecklesnessAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arcueid_world_attribute = class({})

function arcueid_world_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_arcueid_world", {})
			return nil
		else
			return 1
		end
	end)

	hero:FindAbilityByName("arcueid_impulses"):SetLevel(2)

	hero.WorldBackupAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

modifier_arcueid_recklesness = class({})

function modifier_arcueid_recklesness:IsHidden() 
	return true
end

function modifier_arcueid_recklesness:IsPermanent()
	return true
end

function modifier_arcueid_recklesness:RemoveOnDeath()
	return false
end

function modifier_arcueid_recklesness:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_arcueid_world = class({})

function modifier_arcueid_world:IsHidden() 
	return true
end

function modifier_arcueid_world:IsPermanent()
	return true
end

function modifier_arcueid_world:RemoveOnDeath()
	return false
end

function modifier_arcueid_world:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end