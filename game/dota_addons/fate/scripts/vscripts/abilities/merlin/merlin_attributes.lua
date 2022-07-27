merlin_independent_manifestation_attribute = class({})

function merlin_independent_manifestation_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:FindAbilityByName("merlin_avalon"):SetLevel(2)
	hero:FindAbilityByName("merlin_avalon_release"):SetLevel(2)

	hero.IndependentManifestationAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

merlin_dreamlike_charisma_attribute = class({})

function merlin_dreamlike_charisma_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.DreamlikeCharismaAcquired = true
	hero:FindAbilityByName("merlin_charisma"):SetLevel(2)
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


merlin_rapid_chanting_attribute = class({})

function merlin_rapid_chanting_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.RapidChantingAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


merlin_hero_creation_attribute = class({})

function merlin_hero_creation_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.HeroCreationAcquired = true
	hero:SwapAbilities("merlin_hero_creation", "merlin_charisma", true, false) 
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

merlin_king_assistant_attribute = class({})

function merlin_king_assistant_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.KingAssistantAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
