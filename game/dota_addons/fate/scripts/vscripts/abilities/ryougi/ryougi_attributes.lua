LinkLuaModifier("modifier_ryougi_black_moon", "abilities/ryougi/ryougi_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_pure_knowledge", "abilities/ryougi/ryougi_attributes", LUA_MODIFIER_MOTION_NONE)

ryougi_selfless_knowledge_attribute = class({})

function ryougi_selfless_knowledge_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.SelflessKnowledgeAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

ryougi_pure_knowledge_attribute = class({})

function ryougi_pure_knowledge_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_ryougi_pure_knowledge", {})
			return nil
		else
			return 1
		end
	end)

	hero.PureKnowledgeAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

ryougi_black_moon_attribute = class({})

function ryougi_black_moon_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_ryougi_black_moon", {})
			return nil
		else
			return 1
		end
	end)

	hero.BlackMoonAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

ryougi_demise_attribute = class({})

function ryougi_demise_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.DemiseAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

ryougi_kiyohime_passing_attribute = class({})

function ryougi_kiyohime_passing_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.KiyohimePassingAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

modifier_ryougi_black_moon = class({})

function modifier_ryougi_black_moon:IsHidden() 
	return true
end

function modifier_ryougi_black_moon:IsPermanent()
	return true
end

function modifier_ryougi_black_moon:RemoveOnDeath()
	return false
end

function modifier_ryougi_black_moon:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_ryougi_pure_knowledge = class({})

function modifier_ryougi_pure_knowledge:IsHidden() 
	return true
end

function modifier_ryougi_pure_knowledge:IsPermanent()
	return true
end

function modifier_ryougi_pure_knowledge:RemoveOnDeath()
	return false
end

function modifier_ryougi_pure_knowledge:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end