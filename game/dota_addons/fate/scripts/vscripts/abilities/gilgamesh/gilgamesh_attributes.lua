gilgamesh_attribute_rain_of_swords = class({})
gilgamesh_combo_proxy = class({})

function gilgamesh_attribute_rain_of_swords:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero:FindAbilityByName("gilgamesh_rain_of_swords_passive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

gilgamesh_attribute_chains_of_heaven = class({})

function gilgamesh_attribute_chains_of_heaven:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end
	hero.IsChainsAcquired = true
	hero:FindAbilityByName("gilgamesh_enkidu"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end