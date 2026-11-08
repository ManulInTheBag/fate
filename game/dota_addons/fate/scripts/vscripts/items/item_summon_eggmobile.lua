item_summon_eggmobile = class({})

function item_summon_eggmobile:OnSpellStart()
    local caster = self:GetCaster()
    local hero

    if caster:IsHero() then
        hero = caster
    else
        hero = caster:GetOwner()
        if not hero or not hero:IsHero() then
            local pid = caster:GetPlayerOwnerID()
            if pid then
                hero = PlayerResource:GetPlayer(pid):GetAssignedHero()
            end
        end
    end
    
    if not hero or not hero:IsHero() then
        self:EndCooldown()
        return
    end
    
    local pid = hero:GetPlayerOwnerID()

    if hero.IsMobilized then 
        self:EndCooldown()
        return 
    end 

    if hero.__hMedeyaDragonCringe and not hero.__hMedeyaDragonCringe:IsNull() then
        hero.__hMedeyaDragonCringe:Kill(nil, hero)
        hero.__hMedeyaDragonCringe = nil
    end

    local spawnPos = hero:GetAbsOrigin()
    
    if hero.Territory and not hero.Territory:IsNull() and hero.Territory:IsAlive() then
        spawnPos = hero.Territory:GetAbsOrigin()
    end

    local mount = CreateUnitByName("eggman_eggmobile", spawnPos, true, hero, hero, hero:GetTeamNumber())
    
    hero.__hMedeyaDragonCringe = mount
    
    mount:SetControllableByPlayer(pid, true)
    mount:SetOwner(hero)
    
    if LevelAllAbility then
        LevelAllAbility(mount)
    else
        for i = 0, mount:GetAbilityCount() - 1 do
            local ability = mount:GetAbilityByIndex(i)
            if ability and not ability:IsHidden() then
                ability:SetLevel(1)
            end
        end
    end
    
    FindClearSpaceForUnit(mount, mount:GetAbsOrigin(), true)
    Timers:CreateTimer(0.5, function()
        if not mount or mount:IsNull() then
            return
        end
        
        mount:SetBodygroup(0, 0)
    end)

    mount:AddItem(CreateItem("item_eggman_mount", nil, nil))

    local baseHealth = self:GetSpecialValueFor("health")
    local baseDamage = self:GetSpecialValueFor("damage")
    local healthMult = self:GetSpecialValueFor("bonus_health_multiplier")
    local manaMult = self:GetSpecialValueFor("bonus_mana_multiplier")
    local msMult = self:GetSpecialValueFor("bonus_ms_multiplier")
    local heroInt = hero:GetIntellect() or 0

    mount:SetMaxHealth(baseHealth)
    mount:SetHealth(baseHealth)
    mount:SetBaseDamageMax(baseDamage)
    mount:SetBaseDamageMin(baseDamage)
    mount:SetMana(mount:GetMaxMana() + (heroInt * manaMult))

    Timers:CreateTimer(0.1, function()
        if not mount or mount:IsNull() then return end
        
        local newHealth = mount:GetMaxHealth() + (heroInt * healthMult)
        mount:SetMaxHealth(newHealth)
        mount:SetHealth(newHealth)
        mount:SetBaseMoveSpeed(mount:GetBaseMoveSpeed() + (heroInt * msMult))
    end)

    local skillLevel = math.floor(1 + (hero:GetLevel() - 1) / 3)
    skillLevel = math.max(1, math.min(8, skillLevel))

    local ability1 = mount:FindAbilityByName("caster_5th_dragon_frostbite")
    if ability1 then ability1:SetLevel(skillLevel) end
    
    local ability2 = mount:FindAbilityByName("caster_5th_eggmobile_arcane_wrath")
    if ability2 then ability2:SetLevel(skillLevel) end

    mount:AddNewModifier(mount, self, "modifier_kill", { duration = 60.0 })
    mount:AddNewModifier(mount, self, "modifier_medea_dragon", { duration = 60.0 })

    CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "player_summoned_transport", {
        transport = mount:entindex()
    })

    hero:EmitSound("sfx_eggmobile_startup")
    
    self:StartCooldown(5)
end