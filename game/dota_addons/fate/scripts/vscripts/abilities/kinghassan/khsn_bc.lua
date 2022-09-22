LinkLuaModifier("modifier_khsn_bc", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_bc_pepega", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_bc_cooldown", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)

khsn_bc = khsn_bc or class({})

function khsn_bc:GetIntrinsicModifierName()
    return "modifier_khsn_bc_pepega"
end

modifier_khsn_bc_pepega = class({})

function modifier_khsn_bc_pepega:IsHidden()         return true end
function modifier_khsn_bc_pepega:IsPermanent()      return true end
function modifier_khsn_bc_pepega:RemoveOnDeath()    return false end
function modifier_khsn_bc_pepega:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
                    }
    return hFunc
end
function modifier_khsn_bc_pepega:GetModifierTotal_ConstantBlock(keys)
    if IsServer()
        and ( ( self.hParent.BattleContinuationAcquired and not self.hParent:HasModifier("modifier_khsn_bc_cooldown") ) or Convars:GetBool("dota_ability_debug") ) then
        local fHealth = keys.target:GetHealth() - keys.damage
        if fHealth < 10 then
            keys.target:ModifyHealth(fHealth, self.hAbility, false, DOTA_DAMAGE_FLAG_NONE)

            local fHeal = keys.target:GetMaxHealth() * 0.25

            keys.target:Heal(fHeal, self.hAbility)
            
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCKED, keys.target, keys.damage, nil)
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, keys.target, fHeal, nil)

            local hMDE_Ability = self.hCaster:FindAbilityByName("khsn_mde")
            if hMDE_Ability
                and hMDE_Ability:IsTrained() then
                local hModifier = keys.target:AddNewModifier(self.hCaster, hMDE_Ability, "modifier_khsn_bc_active", {duration = hMDE_Ability:GetSpecialValueFor("duration")})
            end

            if not Convars:GetBool("dota_ability_debug") then
                keys.target:AddNewModifier(self.hCaster, self.hAbility, "modifier_khsn_bc_cooldown", {duration = self.hAbility:GetEffectiveCooldown(-1)})
            
                self.hAbility:UseResources(false, false, true)
            end

            LoopOverPlayers(
                function(hPlayer, nPlayerID, hPlayerHero)
                    if hPlayerHero.voice == true then
                        CustomGameEventManager:Send_ServerToPlayer(hPlayer, "emit_horn_sound", {sound="fucking_invincible"})
                    end
                end)

            return math.ceil(keys.damage + 10)
        end
    end
end
function modifier_khsn_bc_pepega:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
end
function modifier_khsn_bc_pepega:OnRefresh(hTable)
    self:OnCreated(hTable)
end

modifier_khsn_bc_cooldown = modifier_khsn_bc_cooldown or class({})

function modifier_khsn_bc_cooldown:IsHidden()           return false end
function modifier_khsn_bc_cooldown:IsDebuff()           return true end
function modifier_khsn_bc_cooldown:IsPurgable()         return false end
function modifier_khsn_bc_cooldown:IsPurgeException()   return false end
function modifier_khsn_bc_cooldown:RemoveOnDeath()      return false end

































































----------------------- inactive part, "live while attacking" version

--[[LinkLuaModifier("modifier_khsn_bc_active", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)

modifier_khsn_bc = class({})
function modifier_khsn_bc:IsHidden() return true end
function modifier_khsn_bc:IsDebuff() return false end
function modifier_khsn_bc:RemoveOnDeath() return false end
function modifier_khsn_bc:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MIN_HEALTH,
                    MODIFIER_PROPERTY_AVOID_DAMAGE,}
    return func
end
function modifier_khsn_bc:GetMinHealth()
    if IsServer() then
        if self:GetParent():HasModifier("modifier_khsn_bc_active")
            or not self:GetParent():IsRealHero()
            or not self:GetParent().BattleContinuationAcquired
            or not self:GetAbility():IsFullyCastable()
            or not self:GetParent():IsAlive() then
            return nil
        end

        if self:GetParent():GetHealth() <= 2 then
        	HardCleanse(self:GetParent())
			--self:GetParent():EmitSound("Cu_Battlecont")
            self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_khsn_bc_active", {duration = 2, killer = self.killer})

            self:GetAbility():StartCooldown(self:GetAbility():GetSpecialValueFor("cooldown"))
        end

        return self.min_hp
    end
end
function modifier_khsn_bc:GetModifierAvoidDamage(keys)
    if IsServer() then
        if self:GetParent():HasModifier("modifier_khsn_bc_active")
            or not self:GetParent():IsRealHero()
            or not self:GetAbility():IsFullyCastable()
            or not self:GetParent():IsAlive() then
            return nil
        end

        local Player = PlayerResource:GetPlayer(keys.attacker:GetPlayerOwnerID()):GetAssignedHero()

        self.killer = tostring(Player:GetEntityIndex())
    end
end
function modifier_khsn_bc:OnCreated()
    if IsServer() then
        self.min_hp = 1

        self.killer = tostring(self:GetParent():GetEntityIndex())
    end
end

modifier_khsn_bc_active = class({})
function modifier_khsn_bc_active:IsHidden() return false end
function modifier_khsn_bc_active:IsDebuff() return false end
function modifier_khsn_bc_active:RemoveOnDeath() return true end
function modifier_khsn_bc_active:CheckState()
    local state = { [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,}
    return state
end
function modifier_khsn_bc_active:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MIN_HEALTH,
                    MODIFIER_PROPERTY_DISABLE_HEALING,
                    --MODIFIER_EVENT_ON_ATTACK_LANDED
                }
    return func
end
function modifier_khsn_bc_active:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end

	self:GetParent():AddNewModifier(self:GetParent(), self:GetParent():FindAbilityByName("khsn_bc"), "modifier_khsn_bc_active", {duration = 2, killer = self.killer_number})
end
function modifier_khsn_bc_active:GetMinHealth(keys)
    if IsServer() then
        return self.min_hp
    end
end
function modifier_khsn_bc_active:GetDisableHealing()
    if IsServer() then
        return 1
    end
end
function modifier_khsn_bc_active:OnCreated(table)
    if IsServer() then
        --EmitSoundOn("Swordland", self:GetParent())

        if table.killer == nil then
            self.killer = self:GetParent()
        else
            self.min_hp = 1

            self.killer = EntIndexToHScript(tonumber(table.killer))
            self.killer_number = table.killer
        --end
    end
end
function modifier_khsn_bc_active:OnRefresh(table)
    if IsServer() then
        self:OnCreated(table)
    end
end
function modifier_khsn_bc_active:OnDestroy()
    if IsServer() then
        --StopSoundOn("Swordland", self:GetParent())

        self:GetParent():RemoveModifierByName("modifier_rho_aias")

        self:GetParent():Kill(self:GetParent():FindAbilityByName("khsn_bc"), self.killer)
    end
end]]