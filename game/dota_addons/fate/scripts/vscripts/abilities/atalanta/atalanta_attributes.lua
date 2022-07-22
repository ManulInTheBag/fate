atalanta_calydonian_snipe_attribute = class({})

function atalanta_calydonian_snipe_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero or hero:GetName() ~= "npc_dota_hero_drow_ranger" then 
		hero = caster.HeroUnit
	end

	hero.CalydonianSnipeAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end