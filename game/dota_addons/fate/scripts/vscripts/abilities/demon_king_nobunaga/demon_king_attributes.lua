

demon_king_attribute_1 = class({}) -- CLASSIC NOBU /// FIRE GROUND SA  FUNC IS WRITTEN INSIDE MATERIALIZATION 
function demon_king_attribute_1:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.demon_king_attribute_1 = true


	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

demon_king_attribute_2 = class({}) -- KIPPOSHI NOBU

function demon_king_attribute_2:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.demon_king_attribute_2 = true


	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

demon_king_attribute_3 = class({}) -- KAISERE NOBu

function demon_king_attribute_3:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.demon_king_attribute_3 = true


	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

demon_king_attribute_4 = class({}) -- SUMMER NOBU

function demon_king_attribute_4:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.demon_king_attribute_4 = true


	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

demon_king_attribute_5 = class({}) -- HUMAN NOBU

function demon_king_attribute_5:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.demon_king_attribute_5 = true


	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
