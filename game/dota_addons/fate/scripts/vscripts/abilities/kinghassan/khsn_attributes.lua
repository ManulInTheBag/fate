LinkLuaModifier("modifier_khsn_presence_attribute", "abilities/kinghassan/khsn_attributes", LUA_MODIFIER_MOTION_NONE)

khsn_boundary_attribute = class({})

function khsn_boundary_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.BoundaryAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_bc_attribute = class({})

function khsn_bc_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:FindAbilityByName("khsn_bc"):SetLevel(1)

	hero.BattleContinuationAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_presence_attribute = class({})

function khsn_presence_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	--hero:SwapAbilities("fate_empty_nothidden", "khsn_presence", false, true)

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_khsn_presence_attribute", {})
			return nil
		else
			return 1
		end
	end)

	hero.PresenceAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_azrael_attribute = class({})

function khsn_azrael_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.AzraelAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_flame_attribute = class({})

function khsn_flame_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.FlameAcquired = true

	hero:FindAbilityByName("khsn_grab"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


modifier_khsn_presence_attribute = class({})

function modifier_khsn_presence_attribute:IsHidden() 
	return true
end

function modifier_khsn_presence_attribute:IsPermanent()
	return true
end

function modifier_khsn_presence_attribute:RemoveOnDeath()
	return false
end

function modifier_khsn_presence_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end