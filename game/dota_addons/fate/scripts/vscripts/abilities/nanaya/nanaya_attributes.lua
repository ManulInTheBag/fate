nanaya_blood_attribute = class({})
function nanaya_blood_attribute:OnSpellStart()
local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.BloodAcquired = true
    hero:FindAbilityByName("nanaya_blood"):SetLevel(2)
    local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
	

nanaya_d_attribute = class({})
function nanaya_d_attribute:OnSpellStart()
	local caster = self:GetCaster()
		local ply = caster:GetPlayerOwner()
		local hero = caster:GetPlayerOwner():GetAssignedHero()
		hero:SwapAbilities("nanaya_slashes", "nanaya_blood", true, false)
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
	end

nanaya_r2_attribute = class({})
function nanaya_r2_attribute:OnSpellStart()
	local caster = self:GetCaster()
		local ply = caster:GetPlayerOwner()
		local hero = caster:GetPlayerOwner():GetAssignedHero()
		hero.r2_nanaya = true
		--caster:SwapAbilities("nanaya_q_strike", "nanaya_q2jump", true, false)
		--hero:SwapAbilities("nanaya_slashes", "nanaya_blood", true, false)
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
	end

	nanaya_r_attribute = class({})
function nanaya_r_attribute:OnSpellStart()
	local caster = self:GetCaster()
		local ply = caster:GetPlayerOwner()
		local hero = caster:GetPlayerOwner():GetAssignedHero()
		hero.rnanaya = true
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
	end

	nanaya_e_attribute = class({})
function nanaya_e_attribute:OnSpellStart()
	local caster = self:GetCaster()
		local ply = caster:GetPlayerOwner()
		local hero = caster:GetPlayerOwner():GetAssignedHero()
		hero.enanaya = true
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
	end