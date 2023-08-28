okita_attribute_kiku_ichimonji = class({})

function okita_attribute_kiku_ichimonji:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
 
	hero.IsKikuIchimonjiAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

okita_attribute_mind_eye = class({})

function okita_attribute_mind_eye:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
 
	hero.IsMindEyeAcquired = true
	hero:SwapAbilities("fate_empty1", "okita_mind_eye", false, true)
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

okita_kenjitsu = class({})

function okita_kenjitsu:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
 
	hero.IsTennenAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

okita_attribute_reduced_earth = class({})

function okita_attribute_reduced_earth:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
 
	hero.IsReducedEarthAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

okita_attribute_reduced_wind = class({})

function okita_attribute_reduced_wind:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
 
	hero.IsReducedWindAcquired = true
 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end