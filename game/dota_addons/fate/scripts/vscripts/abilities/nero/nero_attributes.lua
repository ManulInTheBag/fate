nero_attribute_pari_tenu_blauserum = class({})
nero_attribute_soverigns_glory = class({})
nero_aestus_estus_attribute = class({})
nero_attribute_diabolis_vectis = class({})

LinkLuaModifier("modifier_ptb_attribute", "abilities/nero/modifiers/modifier_ptb_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sovereign_attribute", "abilities/nero/modifiers/modifier_sovereign_attribute", LUA_MODIFIER_MOTION_NONE)

function nero_attribute_pari_tenu_blauserum:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_ptb_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function nero_attribute_soverigns_glory:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_sovereign_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function nero_aestus_estus_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:FindAbilityByName("nero_aestus_estus_passive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function nero_attribute_diabolis_vectis:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.DiabolisVectisAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end