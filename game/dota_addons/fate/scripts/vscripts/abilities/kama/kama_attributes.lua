
kama_sa_1 = class({})

function kama_sa_1:OnSpellStart()
    local caster = self:GetCaster()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    -- Флаг читают способности героя: `if caster.Sa1Acquired then ... end`
    hero.Sa1Acquired = true

    -- Пример: поднять уровень скрытой способности, которую открывает атрибут
    --hero:FindAbilityByName("kama_something"):SetLevel(1)
    -- Пример: выдать постоянный модификатор
    --hero:AddNewModifier(hero, self, "modifier_kama_something", {})

    -- ⚠️ Цена атрибута — мана Мастера 1, списывается вручную
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


kama_sa_2 = class({})

function kama_sa_2:OnSpellStart()
    local caster = self:GetCaster()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    -- Флаг читают способности героя: `if caster.Sa2Acquired then ... end`
    hero.Sa2Acquired = true

    -- Пример: поднять уровень скрытой способности, которую открывает атрибут
    --hero:FindAbilityByName("kama_something"):SetLevel(1)
    -- Пример: выдать постоянный модификатор
    --hero:AddNewModifier(hero, self, "modifier_kama_something", {})

    -- ⚠️ Цена атрибута — мана Мастера 1, списывается вручную
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


kama_sa_3 = class({})

function kama_sa_3:OnSpellStart()
    local caster = self:GetCaster()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    -- Флаг читают способности героя: `if caster.Sa3Acquired then ... end`
    hero.Sa3Acquired = true

    -- Пример: поднять уровень скрытой способности, которую открывает атрибут
    --hero:FindAbilityByName("kama_something"):SetLevel(1)
    -- Пример: выдать постоянный модификатор
    --hero:AddNewModifier(hero, self, "modifier_kama_something", {})

    -- ⚠️ Цена атрибута — мана Мастера 1, списывается вручную
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


kama_sa_4 = class({})

function kama_sa_4:OnSpellStart()
    local caster = self:GetCaster()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    -- Флаг читают способности героя: `if caster.Sa4Acquired then ... end`
    hero.Sa4Acquired = true

    -- Пример: поднять уровень скрытой способности, которую открывает атрибут
    --hero:FindAbilityByName("kama_something"):SetLevel(1)
    -- Пример: выдать постоянный модификатор
    --hero:AddNewModifier(hero, self, "modifier_kama_something", {})

    -- ⚠️ Цена атрибута — мана Мастера 1, списывается вручную
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
