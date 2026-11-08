item_eggman_mount = class({})

LinkLuaModifier("modifier_mount", "items/item_eggman_mount", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mount_caster", "items/item_eggman_mount", LUA_MODIFIER_MOTION_NONE)

function item_eggman_mount:OnSpellStart()
    local mount = self:GetCaster()
    
    local hero
    if mount:IsHero() then
        hero = mount
    else
        hero = mount:GetOwner()
        if not hero or not hero:IsHero() then
            local pid = mount:GetPlayerOwnerID()
            if pid then
                hero = PlayerResource:GetPlayer(pid):GetAssignedHero()
            end
        end
    end
    
    if not hero or not hero:IsHero() then
        self:EndCooldown()
        return
    end
    
    if not mount:IsAlive() or hero:HasModifier("jump_pause") then
        self:EndCooldown()
        return
    end
    
    if hero.IsMounted then
        if GridNav:IsBlocked(mount:GetAbsOrigin()) or not GridNav:IsTraversable(mount:GetAbsOrigin()) then
            self:EndCooldown()
            SendErrorMessage(hero:GetPlayerOwnerID(), "#Cannot_Unmount")
            return                                
        end
        
        local arcaneWrath = mount:FindAbilityByName("caster_5th_eggmobile_arcane_wrath")
        local fateEmpty2 = mount:FindAbilityByName("fate_empty2")
        
        if arcaneWrath then
            arcaneWrath:SetHidden(true)
        end
        if fateEmpty2 then
            fateEmpty2:SetHidden(false)
        end
        
        hero:RemoveModifierByName("modifier_mount_caster")
        mount:RemoveModifierByName("modifier_mount")
        
        mount:SetBodygroup(0, 0)
        
        hero.IsMounted = false
        SendMountStatus(hero)
        
        self:StartCooldown(2)
        
    else
        local dist = (mount:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D()
        
        if dist < 400 and not hero:HasModifier("modifier_stunned") and not hero:HasModifier("stunned") then
            hero.IsMounted = true
        
            local arcaneWrath = mount:FindAbilityByName("caster_5th_eggmobile_arcane_wrath")
            local fateEmpty2 = mount:FindAbilityByName("fate_empty2")
            
            if arcaneWrath then
                arcaneWrath:SetHidden(false)
            end
            if fateEmpty2 then
                fateEmpty2:SetHidden(true)
            end
            
            hero:AddNewModifier(mount, self, "modifier_mount_caster", {})
            mount:AddNewModifier(mount, self, "modifier_mount", {}) 
            
            mount:SetBodygroup(0, 1)
            
            SendMountStatus(hero)
            
            self:StartCooldown(2)
        else
            self:EndCooldown()
        end
    end
end


modifier_mount = class({})

function modifier_mount:IsHidden() return false end
function modifier_mount:IsDebuff() return false end
function modifier_mount:IsPurgable() return false end
function modifier_mount:RemoveOnDeath() return true end

function modifier_mount:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_purifyingflames_heal.vpcf"
end

function modifier_mount:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_mount:OnDestroy()
    if not IsServer() then return end
    
    local mount = self:GetParent()
    local hero = mount:GetOwner()
    
    if hero and hero:IsHero() and hero.IsMounted then
        local arcaneWrath = mount:FindAbilityByName("caster_5th_eggmobile_arcane_wrath")
        local fateEmpty = mount:FindAbilityByName("fate_empty2")

        if arcaneWrath then
            arcaneWrath:SetHidden(true)
        end
        if fateEmpty then
            fateEmpty:SetHidden(false)
        end
        
        hero:RemoveModifierByName("modifier_mount_caster")
        
        mount:SetBodygroup(0, 0)
        
        hero.IsMounted = false
        SendMountStatus(hero)
    end
end


modifier_mount_caster = class({})

function modifier_mount_caster:IsHidden() return true end
function modifier_mount_caster:IsPurgable() return false end
function modifier_mount_caster:RemoveOnDeath() return true end

function modifier_mount_caster:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_FLYING] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
    }
end

function modifier_mount_caster:OnCreated(kv)
    if not IsServer() then return end
    self:StartIntervalThink(0.03)
    
    local hero = self:GetParent()
    if hero and not hero:IsNull() then
        hero:AddNoDraw()
    end
end

function modifier_mount_caster:OnDestroy()
    local hero = self:GetParent()
    local mount = self:GetCaster()
    
    if hero and not hero:IsNull() and hero:IsHero() then
        hero:RemoveNoDraw()
    end
    
    if hero and not hero:IsNull() and hero:IsHero() and 
       mount and not mount:IsNull() and mount:IsAlive() then
        
        local targetPos = mount:GetAbsOrigin() + Vector(100, 0, 0)
        FindClearSpaceForUnit(hero, targetPos, true)
    end
end

function modifier_mount_caster:OnIntervalThink()
    local hero = self:GetParent()
    local mount = self:GetCaster()
    
    if hero and not hero:IsNull() and hero:IsHero() and 
       mount and not mount:IsNull() and mount:IsAlive() then
        hero:SetAbsOrigin(mount:GetAbsOrigin() + Vector(0, 0, 300))
    end
end