astolfo_deafening_blast_attribute = class({})

function astolfo_deafening_blast_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	

	if not hero then hero = caster.HeroUnit end
		
	hero.IsDeafeningBlastAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))	
end