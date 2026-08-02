hijikata_dash_recast = class({})
LinkLuaModifier("modifier_hijikata_rush", "abilities/hijikata/hijikata_dash_recast", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_hijikata_rotation_lock","abilities/hijikata/hijikata_dash_recast", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------
-- Что можно кастовать прямо в полёте Battle drive.
-- Значение = прерывает ли каст деш (Madness не прерывает, остальные останавливают
-- Хиджикату на текущем месте).
HIJIKATA_RUSH_CASTABLE = {
	["hijikata_demon"]         = true,  -- ZloDemon of the battlefield
	["hijikata_demon_recast"]  = true,
	["hijikata_duel"]          = true,  -- Duel
	["hijikata_duel_recast"]   = true,
	["hijikata_ult"]           = true,  -- Shinsengumi
	["hijikata_madness"]       = false, -- Madness — деш продолжается
}

local HIJIKATA_RUSH_CAST_ORDERS = {
	[DOTA_UNIT_ORDER_CAST_POSITION]          = true,
	[DOTA_UNIT_ORDER_CAST_TARGET]            = true,
	[DOTA_UNIT_ORDER_CAST_TARGET_TREE]       = true,
	[DOTA_UNIT_ORDER_CAST_NO_TARGET]         = true,
	[DOTA_UNIT_ORDER_CAST_TOGGLE]            = true,
	[DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION] = true,
}

-- Зовётся из FateGameMode:ExecuteOrderFilter. Возвращает false, чтобы съесть приказ.
-- Раньше полёт закрывался MODIFIER_STATE_COMMAND_RESTRICTED и не пропускал вообще
-- ничего; теперь состояние снято, и роль «нельзя командовать» играет этот фильтр.
function HijikataRushOrderFilter(hUnit, hAbility, iOrder)
	local rush = hUnit:FindModifierByName("modifier_hijikata_rush")
	if rush == nil then return true end

	if not HIJIKATA_RUSH_CAST_ORDERS[iOrder] then return false end
	if not IsNotNull(hAbility) then return false end

	local interrupts = HIJIKATA_RUSH_CASTABLE[hAbility:GetAbilityName()]
	if interrupts == nil then return false end

	-- деш рвём только если каст реально состоится
	if interrupts and hAbility:IsFullyCastable() then
		rush:StopRush()
	end

	return true
end
--------------------------------------------------------------------------------

--[[
function hijikata_dash_recast:CastFilterResult()
	local caster = self:GetCaster()
	local target = caster.dash_target
    local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() 
	if distance > self:GetSpecialValueFor("distance") then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function hijikata_dash_recast:GetCustomCastError()
	return "not in the radius"
end
]]
function hijikata_dash_recast:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end

function hijikata_dash_recast:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
	if caster:FindAbilityByName("hijikata_dash"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("hijikata_dash"):SetLevel(self:GetLevel())
    end
 

end



function hijikata_dash_recast:OnSpellStart()
    local caster = self:GetCaster()
	local target = caster.dash_target
	if not IsNotNull(target) or not target:IsAlive() then
		caster:RemoveModifierByName("modifier_hijikata_dash_recast_enable")
		return
	end
    local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
	if distance > self:GetSpecialValueFor("distance") then
		return
	end
    caster:AddNewModifier(caster, self, "modifier_hijikata_rotation_lock", {Duration = 0.1})
    StartAnimation(caster, {duration=0.1, activity=ACT_DOTA_CAST_ABILITY_1_END, rate=3})
    --caster:EmitSound("hijikata_shut_up")
    Timers:CreateTimer(0.1, function() 
        local ring_fx = caster:FindAbilityByName("hijikata_dash").radius_ring_fx
        if ring_fx ~= nil then 
            ParticleManager:DestroyParticle(ring_fx, true)
            ParticleManager:ReleaseParticleIndex(ring_fx)
        end
        
        --caster:EmitSound("mordred_rush")

        self.damage = self:GetSpecialValueFor("damage")
        self.speed = self:GetSpecialValueFor("speed")
        caster:AddNewModifier(caster, self, "modifier_hijikata_rush", {damage = self.damage,
                                                                        speed = self.speed })
        caster:RemoveModifierByName("modifier_hijikata_dash_recast_enable")
    end)                                                                
	
end




modifier_hijikata_rush = class({})

function modifier_hijikata_rush:OnCreated(hui)
    if not IsServer() then return end
    self.bSoundReady = true
	self.parent = self:GetParent()
    self.parent:Stop() 
	self.ability = self:GetAbility()
    self.damage_dealth = false
    self.parent:StartGesture(ACT_DOTA_AMBUSH)
    --self.parent:SetAnimation(ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END) 
	self.target = self.parent.dash_target
	if not IsNotNull(self.target) then
		self:Destroy()
		return
	end
	self.swordfx = ParticleManager:CreateParticle("particles/hijikata/hijikata_sword_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.parent )
    ParticleManager:SetParticleControlEnt(self.swordfx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_sword_base", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.swordfx, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_sword_end", Vector(0,0,0), true)
    if IsServer() then
		self.damage = hui.damage
		self.speed = hui.speed
       

        self.targetpos = self.target:GetAbsOrigin()

		self:StartIntervalThink(FrameTime())
		if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end
	end
end
function modifier_hijikata_rush:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_hijikata_rush:IsHidden() return false end
function modifier_hijikata_rush:IsDebuff() return false end
function modifier_hijikata_rush:RemoveOnDeath() return true end
function modifier_hijikata_rush:GetPriority() return MODIFIER_PRIORITY_HIGH end

function modifier_hijikata_rush:CheckState()
    -- COMMAND_RESTRICTED снят: приказы фильтрует HijikataRushOrderFilter,
    -- иначе движок не дал бы скастовать ничего прямо в полёте.
    -- MUTED закрывает предметы, которые под тем же снятым состоянием иначе стали бы доступны
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_MUTED] = true, }

    if self.target and not self.target:IsNull() and self.target:HasFlyMovementCapability() then
        state[MODIFIER_STATE_FLYING] = true
    else
        state[MODIFIER_STATE_FLYING] = false
    end
    
    return state
end

 

-- Обрыв деша ради другой способности: без добивающей анимации и без
-- rotation_lock, иначе собственный сайленс съел бы каст, ради которого прервались
function modifier_hijikata_rush:StopRush()
    if not IsServer() then return end
    self.cancelled_by_spell = true
    self:Destroy()
end

function modifier_hijikata_rush:OnDestroy()
    if not IsServer() then return end
    if not IsNotNull(self.parent) then return end

    self.parent:RemoveGesture(ACT_DOTA_AMBUSH)

    if not self.cancelled_by_spell then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_hijikata_rotation_lock", {duration = 0.15})
        StartAnimation( self.parent, {duration=0.5, activity=ACT_DOTA_ALCHEMIST_CONCOCTION, rate=1.0})

        local attackFx = ParticleManager:CreateParticle("particles/hijikata/hijikata_dash_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW ,self.parent)
        ParticleManager:ReleaseParticleIndex(attackFx)
    end

    self.parent:InterruptMotionControllers(true)
    if self.parent:HasModifier("jump_pause_nosilence") then
        self.parent:RemoveModifierByName("jump_pause_nosilence")
    end

    if self.swordfx then
        ParticleManager:DestroyParticle(self.swordfx, false)
        ParticleManager:ReleaseParticleIndex(self.swordfx)
        self.swordfx = nil
    end
end

function modifier_hijikata_rush:UpdateHorizontalMotion(me, dt)
    local UFilter = UnitFilter( self.target,
                                self.ability:GetAbilityTargetTeam(),
                                self.ability:GetAbilityTargetType(),
                                self.ability:GetAbilityTargetFlags(),
                                self.parent:GetTeamNumber() )

    if UFilter ~= UF_SUCCESS then
        self:Destroy()

        return nil
    end

    if (self.targetpos - self.target:GetAbsOrigin()):Length2D() > 300 then
        self:Destroy()

        return nil
    end

    self.targetpos = self.target:GetAbsOrigin() 
    self.distance = (self.target:GetOrigin() - self.parent:GetOrigin()):Length2D()

    if self.distance < 600 and self.damage_dealth == false and self.bSoundReady == true then
        self.parent:EmitSound("hijikata_shut_up")
        self.bSoundReady = false
    end
 
    if self.distance < 200 and self.damage_dealth == false then
        self:BOOM()

        return nil
    end
    if self.distance < 100 then
        self:Destroy()
        return nil
    end
    self:Rush(me, dt)
end
function modifier_hijikata_rush:BOOM()
    local position = self.target:GetAbsOrigin()
    local damage = self.damage
    self.damage_dealth = true
    if IsSpellBlocked(self.target, self.parent) then return end
   
    


        local blow_fx =     ParticleManager:CreateParticle("particles/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step_dmg_blood.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
                            ParticleManager:SetParticleControl(blow_fx, 0, position)
                            ParticleManager:ReleaseParticleIndex(blow_fx)
    	if not self.target:IsMagicImmune() then
            Timers:CreateTimer(0.1, function()
                if not IsNotNull(self.parent) or not IsNotNull(self.target) then return end
                if self.parent.IsShinsengumiAcquired then
                    DoDamage(self.parent, self.target, self.parent:GetAverageTrueAttackDamage(self.parent) * self.ability:GetSpecialValueFor("sa_atk_dmg_mod"), DAMAGE_TYPE_PHYSICAL, 0, self.ability, false)
                end
                DoDamage(self.parent, self.target, damage, DAMAGE_TYPE_PHYSICAL, 0, self.ability, false)
                if self.parent:GetHealth() < self.parent:GetMaxHealth() then
                    local diff = self.parent:GetMaxHealth() - self.parent:GetHealth()
            
                    if diff > self.parent:GetMaxHealth() * 0.1 then 
                        diff = self.parent:GetMaxHealth() * 0.1
                    end
                    self.parent:Heal(diff, self.parent)
                 end
            end)
            
        end
    
        EmitSoundOnLocationWithCaster(position, "hijikata_dash_recast_sfx", self.parent)


end
function modifier_hijikata_rush:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.target:GetOrigin()

    local direction = targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(target)
    self.parent:FaceTowards(self.targetpos)

end

function modifier_hijikata_rush:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end

function modifier_hijikata_rush:GetEffectName()
    return "particles/hijikata/hijikata_dash_effects.vpcf"
end

function modifier_hijikata_rush:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
 

modifier_hijikata_rotation_lock = class({})


function modifier_hijikata_rotation_lock:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING  }

	return funcs
end

function modifier_hijikata_rotation_lock:GetModifierDisableTurning() 
	return 1
end
 


function modifier_hijikata_rotation_lock:CheckState()
    local state =   { 
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		
                    }
    return state
end
 
function modifier_hijikata_rotation_lock:IsHidden() return true end
function modifier_hijikata_rotation_lock:RemoveOnDeath() return true end
