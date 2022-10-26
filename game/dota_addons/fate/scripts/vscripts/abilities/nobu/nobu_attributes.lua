nobu_strategy_attribute = class({})

function nobu_strategy_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
 

	hero.StrategyAcquired = true
	hero.IsStrategyReady = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

nobu_expanding_attribute = class({})
LinkLuaModifier("modifier_nobu_expanding_attribute", "abilities/nobu/nobu_attributes", LUA_MODIFIER_MOTION_NONE)
modifier_nobu_expanding_attribute = class({})

 

function modifier_nobu_expanding_attribute:IsHidden()
	return true
end

function modifier_nobu_expanding_attribute:IsPermanent()
	return true
end

function modifier_nobu_expanding_attribute:RemoveOnDeath()
	return false
end

function modifier_nobu_expanding_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function nobu_expanding_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.Expanded = true
 	local master = hero.MasterUnit
	 Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_nobu_expanding_attribute", {})
			return nil
		else
			return 1
		end
	end)

	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


nobu_3000_attribute = class({})

function nobu_3000_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.is3000Acquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


nobu_unifying_attribute = class({})

function nobu_unifying_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.UnifyingAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end




nobu_independent_action = class({})

function nobu_independent_action:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.NobuActionAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

 
 