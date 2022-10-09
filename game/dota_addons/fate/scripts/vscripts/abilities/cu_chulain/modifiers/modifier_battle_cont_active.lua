modifier_battle_cont_active = class({})
function modifier_battle_cont_active:IsHidden() return false end
function modifier_battle_cont_active:IsDebuff() return false end
function modifier_battle_cont_active:IsPurgable() return false end
function modifier_battle_cont_active:IsPurgeException() return false end
function modifier_battle_cont_active:RemoveOnDeath() return true end
function modifier_battle_cont_active:CheckState()
    local state = { [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,}
    return state
end
function modifier_battle_cont_active:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MIN_HEALTH,
                    MODIFIER_PROPERTY_DISABLE_HEALING,
                    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,}
    return func
end
function modifier_battle_cont_active:GetMinHealth(keys)
    if IsServer() then
        return self.min_hp
    end
end
function modifier_battle_cont_active:GetDisableHealing()
    if IsServer() then
        return 1
    end
end
function modifier_battle_cont_active:OnCreated(table)
    if IsServer() then
        LoopOverPlayers(function(player, playerID, playerHero)
             --print("looping through " .. playerHero:GetName())
                if playerHero.music == true then
                -- apply legion horn vsnd on their client
                    CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Swordland"})
                --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
                end
            end)
        --EmitSoundOn("Swordland", self:GetParent())

        --[[if table.killer == nil then
            self.killer = self:GetParent()
        else]]
            self.min_hp = 1

            self.killer = EntIndexToHScript(tonumber(table.killer))
        --end
    end
end
function modifier_battle_cont_active:OnRefresh(table)
    if IsServer() then
        self:OnCreated(table)
    end
end
function modifier_battle_cont_active:OnDestroy()
    if IsServer() then
        --StopSoundOn("Swordland", self:GetParent())

        self:GetParent():RemoveModifierByName("modifier_rho_aias")

        self:GetParent():Kill(self:GetAbility(), self.killer)
    end
end