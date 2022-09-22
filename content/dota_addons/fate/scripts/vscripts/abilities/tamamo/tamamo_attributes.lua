tamamo_attribute_territory = class({})

function tamamo_attribute_territory:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero.IsTerritoryAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end