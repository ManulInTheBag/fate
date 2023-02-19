gawain_attribute_kots = class({})

--LinkLuaModifier("modifier_kots_attribute", "abilties/gawain/modifiers/modifier_kots_attribute", LUA_MODIFIER_MOTION_NONE)

function gawain_attribute_kots:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.KotsAcquired = true

	--[[Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_kots_attribute", {})
			return nil
		else
			return 1
		end
	end)]]

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

gawain_attribute_meltdown = class({})
 
function gawain_attribute_meltdown:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:FindAbilityByName("gawain_artificial_sun"):SetLevel(2)
	hero:SwapAbilities("gawain_artificial_sun", "gawain_meltdown", false, true)
	hero.IsMeltdownAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

gawain_attribute_belt=  class({})
 
function gawain_attribute_belt:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
 
	hero.IsBeltAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end