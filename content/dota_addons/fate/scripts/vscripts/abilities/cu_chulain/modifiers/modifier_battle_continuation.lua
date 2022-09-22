LinkLuaModifier("modifier_battle_cont_active", "abilities/cu_chulain/modifiers/modifier_battle_cont_active", LUA_MODIFIER_MOTION_NONE)

modifier_cu_battle_continuation = class({})
function modifier_cu_battle_continuation:IsHidden() return true end
function modifier_cu_battle_continuation:IsDebuff() return false end
function modifier_cu_battle_continuation:IsPurgable() return false end
function modifier_cu_battle_continuation:IsPurgeException() return false end
function modifier_cu_battle_continuation:RemoveOnDeath() return false end
function modifier_cu_battle_continuation:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MIN_HEALTH,
                    MODIFIER_PROPERTY_AVOID_DAMAGE,}
    return func
end
function modifier_cu_battle_continuation:GetMinHealth()
    if IsServer() then
        if self:GetParent():HasModifier("modifier_battle_cont_active")
            or not self:GetParent():IsRealHero()
            or not self:GetAbility():IsFullyCastable()
            or not self:GetParent():IsAlive() then
            return nil
        end

        if self:GetParent():GetHealth() <= 2 then
        	HardCleanse(self:GetParent())
			self:GetParent():EmitSound("Cu_Battlecont")
            self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_battle_cont_active", {duration = (self:GetAbility():GetSpecialValueFor("duration")), killer = self.killer})

            self:GetAbility():StartCooldown(self:GetAbility():GetSpecialValueFor("cooldown"))
        end

        return self.min_hp
    end
end
function modifier_cu_battle_continuation:GetModifierAvoidDamage(keys)
    if IsServer() then
        if self:GetParent():HasModifier("modifier_battle_cont_active")
            or not self:GetParent():IsRealHero()
            or not self:GetAbility():IsFullyCastable()
            or not self:GetParent():IsAlive() then
            return nil
        end

        local Player = PlayerResource:GetPlayer(keys.attacker:GetPlayerOwnerID()):GetAssignedHero()

        self.killer = tostring(Player:GetEntityIndex())
    end
end
function modifier_cu_battle_continuation:OnCreated()
    if IsServer() then
        self.min_hp = 1

        self.killer = tostring(self:GetParent():GetEntityIndex())
    end
end