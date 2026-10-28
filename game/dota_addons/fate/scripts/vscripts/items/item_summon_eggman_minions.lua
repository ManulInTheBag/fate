local function SummonEggmanMinion(self, unitName, isWarrior)
    local caster = self:GetCaster()
    local hero = caster:GetOwner()
    
    if not hero or not hero:IsHero() then
        local pid = caster:GetPlayerOwnerID()
        if pid then
            hero = PlayerResource:GetPlayer(pid):GetAssignedHero()
        end
    end
    
    if not hero or not hero:IsHero() then 
        self:EndCooldown()
        return 
    end
    
    if hero.IsMobilized then 
        self:EndCooldown()
        return 
    end

    local minion = CreateUnitByName(unitName, caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
    
    if not minion or minion:IsNull() then
        self:EndCooldown()
        return
    end
    
    local pid = hero:GetPlayerOwnerID()
    minion:SetControllableByPlayer(pid, true)
    minion:SetOwner(hero)
    
    if LevelAllAbility then
        LevelAllAbility(minion)
    else
        for i = 0, minion:GetAbilityCount() - 1 do
            local ability = minion:GetAbilityByIndex(i)
            if ability and not ability:IsHidden() then
                ability:SetLevel(1)
            end
        end
    end
    
    FindClearSpaceForUnit(minion, minion:GetAbsOrigin(), true)
    
    minion:AddNewModifier(caster, self, "modifier_kill", { duration = 25.0 })
    Timers:CreateTimer(25.0, function()
        if minion and not minion:IsNull() and minion:IsAlive() then
            minion:ForceKill(false)
        end
    end)

    local baseHealth = self:GetSpecialValueFor("health")
    local baseDamage = self:GetSpecialValueFor("damage")
    local healthMult = self:GetSpecialValueFor("bonus_health_multiplier")
    local msMult = self:GetSpecialValueFor("bonus_ms_multiplier")
    local heroInt = hero:GetIntellect() or 0

    minion:SetMaxHealth(baseHealth)
    minion:SetHealth(baseHealth)
    minion:SetBaseDamageMax(baseDamage)
    minion:SetBaseDamageMin(baseDamage)

    Timers:CreateTimer(0.1, function()
        if not minion or minion:IsNull() then return end

        local bonusHealth = heroInt * healthMult
        minion:SetMaxHealth(baseHealth + bonusHealth)
        minion:SetHealth(baseHealth + bonusHealth)
        minion:SetBaseMoveSpeed(minion:GetBaseMoveSpeed() + (heroInt * msMult))

        if isWarrior then
            local armorMult = self:GetSpecialValueFor("bonus_armor_multiplier")
            minion:SetPhysicalArmorBaseValue(minion:GetPhysicalArmorValue(false) + (heroInt * armorMult))
        else
            local damageMult = self:GetSpecialValueFor("bonus_damage_multiplier")
            local bonusDamage = heroInt * damageMult
            minion:SetBaseDamageMin(baseDamage + bonusDamage)
            minion:SetBaseDamageMax(baseDamage + bonusDamage)
        end
    end)
    
    for i = 0, 5 do
        local item = caster:GetItemInSlot(i)
        if item then
            local itemName = item:GetAbilityName()
            if itemName == "item_summon_buzz_bomber" or itemName == "item_summon_orbinaut" then
                item:StartCooldown(5)
            end
        end
    end
    
    EmitSoundOn("sfx_laser", minion)
    self:StartCooldown(5)
end


item_summon_buzz_bomber = class({})
function item_summon_buzz_bomber:OnSpellStart()
    SummonEggmanMinion(self, "eggman_buzz_bomber", true)
end


item_summon_orbinaut = class({})
function item_summon_orbinaut:OnSpellStart()
    SummonEggmanMinion(self, "eggman_orbinaut", false)
end