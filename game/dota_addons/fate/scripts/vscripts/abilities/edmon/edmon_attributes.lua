LinkLuaModifier("modifier_edmon_escape", "abilities/edmon/edmon_attributes", LUA_MODIFIER_MOTION_NONE)

edmon_flames_attribute = class({})

function edmon_flames_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.FlamesAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

edmon_hellfire_attribute = class({})

function edmon_hellfire_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.HellfireAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

edmon_escape_attribute = class({})

function edmon_escape_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.EscapeAcquired = true

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_edmon_escape", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

edmon_vengeance_attribute = class({})

function edmon_vengeance_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.VengeanceAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

modifier_edmon_escape = class({})

function modifier_edmon_escape:IsHidden() 
	return true
end

function modifier_edmon_escape:IsPermanent()
	return true
end

function modifier_edmon_escape:RemoveOnDeath()
	return false
end

function modifier_edmon_escape:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end