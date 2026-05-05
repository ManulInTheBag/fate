ozy_sa_1 = class({})
ozy_sa_2 = class({})
ozy_sa_3 = class({})
ozy_sa_4 = class({})
--ozy_sa_5 = class({})




function ozy_sa_1:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()


	hero.ozySa1Acquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function ozy_sa_2:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()


	hero.ozySa2Acquired = true
	hero:FindAbilityByName("ozy_spawn_boat"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
function ozy_sa_3:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.ozySa3Acquired = true
	hero:FindAbilityByName("ozy_mystic_eyes"):SetLevel(1)
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
function ozy_sa_4:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()


	hero.ozySa4Acquired = true


	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
-- function ozy_sa_5:OnSpellStart()
-- 	local caster = self:GetCaster()
-- 	local hero = caster:GetPlayerOwner():GetAssignedHero()


-- 	hero.ozySa1Acquired = true

-- 	-- Set master 1's mana 
-- 	local master = hero.MasterUnit
-- 	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
-- end