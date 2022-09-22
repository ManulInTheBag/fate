atalanta_evolution_attribute = class({})

function atalanta_evolution_attribute:OnSpellStart()
	local caster = self:GetCaster()
	--local ply = caster:GetPlayerOwner()
	local hero = caster.HeroUnit--caster:GetPlayerOwner():GetAssignedHero() (what? okay, i just fixed the bug someone told me "is unfixable, surrender". Or am i wrong? ok, let's just see.)

	hero.EvolutionAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

atalanta_moon_attribute = class({})

function atalanta_moon_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.CursedMoonAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

atalanta_tornado_attribute = class({})

function atalanta_tornado_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.TornadoAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

atalanta_vision_attribute = class({})

function atalanta_vision_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.VisionAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end