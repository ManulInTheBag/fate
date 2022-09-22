LinkLuaModifier("modifier_khsn_bc", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_bc_pepega", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_bc_cooldown", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)

khsn_bc = class({})

function khsn_bc:GetIntrinsicModifierName()
    return "modifier_khsn_bc_pepega"
end

modifier_khsn_bc_pepega = class({})


function modifier_khsn_bc_pepega:DeclareFunctions()
    return { --MODIFIER_EVENT_ON_TAKEDAMAGE,
             }
end

function modifier_khsn_bc_pepega:IsHidden() 
    return true 
end

function modifier_khsn_bc_pepega:IsPermanent()
    return true
end

function modifier_khsn_bc_pepega:RemoveOnDeath()
    return false
end

function modifier_khsn_bc_pepega:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_khsn_bc_pepega:OnTakeDamage(args)
    self.parent = self:GetParent()
    local caster = self:GetParent()
    if not caster.BattleContinuationAcquired then return end
    if args.unit ~= self.parent then return end
    if caster:HasModifier("modifier_khsn_bc_cooldown") then return end

    if self.parent:GetHealth()<=0 then
         LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
            if playerHero.voice == true then
                -- apply legion horn vsnd on their client
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fucking_invincible"})
                --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
            end
        end)
        self.parent:SetHealth(self.parent:GetMaxHealth()*0.25)
        self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(1))
        caster:AddNewModifier(caster, caster:FindAbilityByName("khsn_mde"), "modifier_khsn_mde_active", {duration = caster:FindAbilityByName("khsn_mde"):GetSpecialValueFor("duration")})
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_khsn_bc_cooldown", {duration = self:GetAbility():GetCooldown(1)})
    end
end

modifier_khsn_bc_cooldown = class({})

function modifier_khsn_bc_cooldown:IsHidden()
    return false 
end

function modifier_khsn_bc_cooldown:RemoveOnDeath()
    return false
end

function modifier_khsn_bc_cooldown:IsDebuff()
    return true 
end

function modifier_khsn_bc_cooldown:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


----------------------- inactive part, "live while attacking" version

LinkLuaModifier("modifier_khsn_bc_active", "abilities/kinghassan/khsn_bc", LUA_MODIFIER_MOTION_NONE)

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
--[[function modifier_khsn_bc_active:CheckState()
    local state = { [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,}
    return state
end]]
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

        --[[if table.killer == nil then
            self.killer = self:GetParent()
        else]]
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
end