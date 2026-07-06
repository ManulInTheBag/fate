iskander_attribute_improve_charisma = class({})
iskander_attribute_thundergods_wrath = class({})
iskander_attribute_via_expugnatio = class({})
iskander_attribute_bond_beyond_time = class({})
iskander_attribute_tactics = class({})

function iskander_attribute_improve_charisma:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsCharismaImproved = true

	hero:FindAbilityByName("iskandar_charisma"):SetLevel(2)

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function iskander_attribute_thundergods_wrath:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsThundergodAcquired = true

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function iskander_attribute_via_expugnatio:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsVEAcquired = true

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function iskander_attribute_bond_beyond_time:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsBeyondTimeAcquired = true

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function iskander_attribute_tactics:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsTacticsAcquired = true

	if hero:GetAbilityByIndex(4):GetName() == "fate_empty1" then
		hero:SwapAbilities("fate_empty1", "iskander_trap", false, true)
	end

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
