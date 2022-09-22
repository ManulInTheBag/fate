karna_poor_attribute = class({})
karna_ucm_attribute = class({})
karna_mana_burst_attribute = class({})
karna_divinity_attribute = class({})
karna_indra_attribute = class({})
karna_divinity_proxy = class({})

LinkLuaModifier("modifier_uncrowned_martial_arts", "abilities/karna/modifiers/modifier_uncrowned_martial_arts", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_divinity", "abilities/karna/modifiers/modifier_karna_divinity", LUA_MODIFIER_MOTION_NONE)

function karna_poor_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	--hero:FindAbilityByName("karna_discern_poor"):SetLevel(1)

	hero:SwapAbilities("karna_discern_poor", "fate_empty1", true, false)

	hero.DiscernPoorAttribute = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function karna_ucm_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_uncrowned_martial_arts", {})
			return nil
		else
			return 1
		end
	end)

	hero.UncrownedAttribute = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function karna_mana_burst_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.ManaBurstAttribute = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function karna_divinity_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	--hero:FindAbilityByName("karna_divinity_proxy"):SetLevel(1)

	--hero:SwapAbilities("gawain_excalibur_galatine", "karna_divinity_proxy", false, true)

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_karna_divinity", {})
			return nil
		else
			return 1
		end
	end)
	
	hero.KarnaDivinityAttribute = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function karna_indra_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.IndraAttribute = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end