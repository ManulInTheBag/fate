muramasa_appreciation_of_swords_attribute = class({})

function muramasa_appreciation_of_swords_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	--hero:FindAbilityByName("merlin_avalon"):SetLevel(2)

	hero.AppreciationOfSwordsAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

muramasa_sword_trial_attribute = class({})

function muramasa_sword_trial_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.SwordTrialAcquired = true
	 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


muramasa_eye_of_karma_attribute = class({})

function muramasa_eye_of_karma_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.EyeOfKarmaAcquired = true
 
	hero:SwapAbilities("muramasa_eye_of_karma", "muramasa_sword_creation", true, false)
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


muramasa_flame_attribute = class({})

function muramasa_flame_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.FlameAcquired = true
	
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

--unused
-------
muramasa_territory_creation_attribute = class({})

function muramasa_territory_creation_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.TerritoryCreationAcquired= true
 	hero:FindAbilityByName("muramasa_sword_creation"):SetLevel(2)
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
--------

muramasa_wicked_sword_attribute = class({})

function muramasa_wicked_sword_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.WickedSwordAcquired = true
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
