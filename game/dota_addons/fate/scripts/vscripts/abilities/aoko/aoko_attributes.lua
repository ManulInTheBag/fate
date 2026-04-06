LinkLuaModifier("modifier_aoko_magician_attribute", "abilities/aoko/aoko_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_choice_attribute_picked", "abilities/aoko/aoko_attributes", LUA_MODIFIER_MOTION_NONE)

aoko_combo_proxy = class({})

aoko_first_star_attribute = class({})

function aoko_first_star_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.FirstStarAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

aoko_bullet_attribute = class({})

function aoko_bullet_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.MagicBulletLoadAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

aoko_magician_attribute = class({})

function aoko_magician_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_aoko_magician_attribute", {})
			return nil
		else
			return 1
		end
	end)

	hero.MagicianOfFifthAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

aoko_circuits_attribute = class({})

function aoko_circuits_attribute:GetManaCost()
	if self:GetCaster():HasModifier("modifier_aoko_choice_attribute_picked") then
		return self:GetSpecialValueFor("change_cost")
	end
	return self:GetSpecialValueFor("normal_cost")
end

function aoko_circuits_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))

	hero.CircuitsAcquired = true
	hero.HighSpeedIncantationAcquired = false

	caster:AddNewModifier(caster, self, "modifier_aoko_choice_attribute_picked", {})
	caster:FindAbilityByName("aoko_incantation_attribute"):EndCooldown()
	caster:FindAbilityByName("aoko_incantation_attribute"):StartCooldown(self:GetSpecialValueFor("change_cooldown"))

	hero:FindAbilityByName("aoko_circuits"):SetLevel(1)

	if hero:HasModifier("modifier_aoko_circuits_overload") then
		hero:FindModifierByName("modifier_aoko_circuits_overload"):OnRedEnter()
	end
end

aoko_incantation_attribute = class({})

function aoko_incantation_attribute:GetManaCost()
	if self:GetCaster():HasModifier("modifier_aoko_choice_attribute_picked") then
		return self:GetSpecialValueFor("change_cost")
	end
	return self:GetSpecialValueFor("normal_cost")
end

function aoko_incantation_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))

	hero.HighSpeedIncantationAcquired = true
	hero.CircuitsAcquired = false

	caster:AddNewModifier(caster, self, "modifier_aoko_choice_attribute_picked", {})
	caster:FindAbilityByName("aoko_circuits_attribute"):EndCooldown()
	caster:FindAbilityByName("aoko_circuits_attribute"):StartCooldown(self:GetSpecialValueFor("change_cooldown"))

	hero:FindAbilityByName("aoko_circuits"):SetLevel(3)

	if hero:HasModifier("modifier_aoko_circuits_overload") then
		hero:FindModifierByName("modifier_aoko_circuits_overload"):OnBlueEnter()
	end
end

modifier_aoko_magician_attribute = class({})

function modifier_aoko_magician_attribute:IsHidden() 
	return true
end

function modifier_aoko_magician_attribute:IsPermanent()
	return true
end

function modifier_aoko_magician_attribute:RemoveOnDeath()
	return false
end

function modifier_aoko_magician_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_aoko_choice_attribute_picked = class({})

function modifier_aoko_choice_attribute_picked:IsHidden() 
	return true
end

function modifier_aoko_choice_attribute_picked:IsPermanent()
	return true
end

function modifier_aoko_choice_attribute_picked:RemoveOnDeath()
	return false
end

function modifier_aoko_choice_attribute_picked:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end