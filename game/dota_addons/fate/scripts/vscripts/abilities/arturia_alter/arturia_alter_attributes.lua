arturia_alter_improve_mana_shroud = class({})

function arturia_alter_improve_mana_shroud:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:FindAbilityByName("arturia_alter_mana_shroud_attribute_passive"):SetLevel(1)
	hero.IsManaShroudImproved = true

	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arturia_alter_improve_mana_burst = class({})

function arturia_alter_improve_mana_burst:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsManaBlastAcquired = true

	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arturia_alter_improve_ferocity = class({})

function arturia_alter_improve_ferocity:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsFerocityImproved = true
	hero:FindAbilityByName("saber_alter_unleashed_ferocity"):SetLevel(2)
	hero:SwapAbilities("saber_alter_unleashed_ferocity","saber_alter_unleashed_ferocity_improved", false, true)

	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arturia_alter_sword_of_ultimate_darklight = class({})

function arturia_alter_sword_of_ultimate_darklight:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsDarklightAcquired = true

	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

arturia_alter_god_is_great = class({})

function arturia_alter_god_is_great:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.GodIsGreatAcquired = true

	hero:SwapAbilities("arturia_alter_mana_shroud","arturia_alter_mana_discharge", false, true)
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end