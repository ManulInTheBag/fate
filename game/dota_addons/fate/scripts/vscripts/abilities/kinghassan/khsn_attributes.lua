LinkLuaModifier("modifier_khsn_presence_aura", "abilities/kinghassan/khsn_presence", LUA_MODIFIER_MOTION_NONE)

khsn_boundary_attribute = class({})

function khsn_boundary_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.BoundaryAcquired = true

	--[[Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_mordred_overload", {})
			return nil
		else
			return 1
		end
	end)]]

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_bc_attribute = class({})

function khsn_bc_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:SwapAbilities("fate_empty6", "khsn_bc", false, true)

	hero.BattleContinuationAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_presence_attribute = class({})

function khsn_presence_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	--hero:SwapAbilities("fate_empty_nothidden", "khsn_presence", false, true)

	--[[Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_khsn_presence_aura", {})
			return nil
		else
			return 1
		end
	end)]]

	hero.PresenceAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_azrael_attribute = class({})

function khsn_azrael_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.AzraelAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

khsn_flame_attribute = class({})

function khsn_flame_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.FlameAcquired = true

	hero:SwapAbilities("fate_empty1", "khsn_blink", false, true)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end