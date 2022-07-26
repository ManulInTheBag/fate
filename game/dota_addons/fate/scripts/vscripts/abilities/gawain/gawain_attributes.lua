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