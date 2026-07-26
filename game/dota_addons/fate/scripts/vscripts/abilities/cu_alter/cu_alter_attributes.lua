-- Attributes for Cú Chulainn Alter. Cast by the hero, paid from the Master's mana pool.
-- Each sets a flag the abilities branch on (and levels its additional ability where relevant):
--   1  Ríastrad          -> War Cry (D) to lvl 2; end-barrier grows with damage taken during it
--   2  Cursed Gáe Bolg   -> Spear Throw (W) applies uncleansable heal reduction (tier 3)
--   3  Roar of the Hound -> Roar (F) to lvl 2; enemies who endure the whole roar are feared
--   4  Battle Continuation-> survive an otherwise lethal blow; Battle Stance (E) grants a barrier
--        (the survival itself lives in cu_alter_battle_continuation.lua, on a hidden always-on
--         passive: an intrinsic modifier works even if the hero is dead when the attribute is bought)

cu_alter_attribute_1 = class({})
cu_alter_attribute_2 = class({})
cu_alter_attribute_3 = class({})
cu_alter_attribute_4 = class({})

local function acquire(self, flag)
	local hero = self:GetCaster():GetPlayerOwner():GetAssignedHero()
	hero[flag] = true

	-- pay from Master 1's mana pool
	local master = hero.MasterUnit
	if master then
		master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
	end
	return hero
end

function cu_alter_attribute_1:OnSpellStart()
	local hero = acquire(self, "CuAlterAttr1Acquired")
	local d = hero:FindAbilityByName("cu_alter_warcry")
	if d then d:SetLevel(2) end
end

function cu_alter_attribute_2:OnSpellStart()
	acquire(self, "CuAlterAttr2Acquired")
end

function cu_alter_attribute_3:OnSpellStart()
	local hero = acquire(self, "CuAlterAttr3Acquired")
	local f = hero:FindAbilityByName("cu_alter_roar")
	if f then f:SetLevel(2) end
end

function cu_alter_attribute_4:OnSpellStart()
	acquire(self, "CuAlterAttr4Acquired")
end
