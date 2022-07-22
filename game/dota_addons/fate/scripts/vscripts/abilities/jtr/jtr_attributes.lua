jtr_holy_mother_attribute = class({})
jtr_information_erase_attribute = class({})
jtr_mental_pollution_attribute = class({})
jtr_surgical_procedure_attribute = class({})
jtr_efficient_killer_attribute = class({})

function jtr_holy_mother_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero.HolyMotherAcquired = true

	hero:FindAbilityByName("jtr_holy_mother_passive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function jtr_information_erase_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero.InformationErasureAcquired = true

	--hero:FindAbilityByName("jtr_mental_pollution_passive"):SetLevel(1)
	--hero:SwapAbilities("fate_empty1", "jtr_mental_pollution_passive", false, true)

	hero:FindAbilityByName("jtr_information_erase"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function jtr_surgical_procedure_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero.SurgicalProcedureAcquired = true

	hero:FindAbilityByName("jtr_surgical_procedure_passive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function jtr_mental_pollution_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero.MentalPollutionAcquired = true

	hero:FindAbilityByName("jtr_bloody_thirst"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function jtr_efficient_killer_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero.EfficientKillerAcquired = true

	hero:FindAbilityByName("jtr_efficient_killer_passive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end