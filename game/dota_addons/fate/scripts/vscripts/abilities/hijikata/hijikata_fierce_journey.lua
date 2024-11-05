LinkLuaModifier("modifier_hijikata_bc", "abilities/hijikata/hijikata_fierce_journey", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_bc_cooldown", "abilities/hijikata/hijikata_fierce_journey", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_bc_resist", "abilities/hijikata/hijikata_fierce_journey", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_madness_active", "abilities/hijikata/hijikata_madness", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
hijikata_fierce_journey = hijikata_fierce_journey or class({})

function hijikata_fierce_journey:GetIntrinsicModifierName()
    return "modifier_hijikata_bc"
end

modifier_hijikata_bc = class({})

function modifier_hijikata_bc:IsHidden()         return true end
function modifier_hijikata_bc:IsPermanent()      return true end
function modifier_hijikata_bc:RemoveOnDeath()    return false end
function modifier_hijikata_bc:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
                    }
    return hFunc
end
function modifier_hijikata_bc:GetModifierTotal_ConstantBlock(keys)
    if IsServer()
        and  ( self.hParent.IsHijikataBcAcquired and not self.hParent:HasModifier("modifier_hijikata_bc_cooldown") ) then
        local fHealth = keys.target:GetHealth() - keys.damage
        if fHealth < 10 then
            --keys.target:ModifyHealth(fHealth, self.hAbility, false, DOTA_DAMAGE_FLAG_NONE)

            local fHeal = keys.target:GetMaxHealth() * 0.25

            --keys.target:Heal(fHeal, self.hAbility)
            keys.target:ModifyHealth(fHeal, self.hAbility, false, DOTA_DAMAGE_FLAG_NONE)
            self.hCaster:EmitSound("hijikata_bc")
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCKED, keys.target, keys.damage, nil)
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, keys.target, fHeal, nil)
			keys.target:AddNewModifier(self.hCaster, self.hAbility, "modifier_hijikata_bc_resist", {duration = 1})  
			keys.target:AddNewModifier(self.hCaster, self.hAbilit, "modifier_merlin_self_pause", {Duration = 1}) 
			StartAnimation(self.hCaster, {duration=1, activity=ACT_DOTA_DISABLED, rate=1})
			Timers:CreateTimer(1, function()
				keys.target:AddNewModifier(self.hCaster, self.hAbility, "modifier_hijikata_madness_active", { Duration = 1 })
			
			end)
            keys.target:AddNewModifier(self.hCaster, self.hAbility, "modifier_hijikata_bc_cooldown", {duration = self.hAbility:GetEffectiveCooldown(-1)})   
            self.hAbility:UseResources(false, false, false, true)

            return math.ceil(keys.damage + 10)
        end
    end
end
function modifier_hijikata_bc:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
end
function modifier_hijikata_bc:OnRefresh(hTable)
    self:OnCreated(hTable)
end

modifier_hijikata_bc_cooldown = modifier_hijikata_bc_cooldown or class({})

function modifier_hijikata_bc_cooldown:IsHidden()           return false end
function modifier_hijikata_bc_cooldown:IsDebuff()           return true end
function modifier_hijikata_bc_cooldown:IsPurgable()         return false end
function modifier_hijikata_bc_cooldown:IsPurgeException()   return false end
function modifier_hijikata_bc_cooldown:RemoveOnDeath()      return false end

modifier_hijikata_bc_resist = class({})

function modifier_hijikata_bc_resist:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_hijikata_bc_resist:GetModifierIncomingDamage_Percentage()
	return -100
end

function modifier_hijikata_bc_resist:IsHidden()           return true end
function modifier_hijikata_bc_resist:IsDebuff()           return false end
function modifier_hijikata_bc_resist:IsPurgable()         return false end
function modifier_hijikata_bc_resist:RemoveOnDeath()      return true end

function modifier_hijikata_bc_resist:GetEffectName()
    return "particles/hijikata/hijikata_bc_proc_particle.vpcf"
end

function modifier_hijikata_bc_resist:GetEffectAttachType()
    return PATTACH_CUSTOMORIGIN_FOLLOW
end