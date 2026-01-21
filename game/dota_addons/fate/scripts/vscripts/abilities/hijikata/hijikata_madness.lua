hijikata_madness = class({})

LinkLuaModifier("modifier_hijikata_madness_active", "abilities/hijikata/hijikata_madness", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_swift","abilities/hijikata/hijikata_madness", LUA_MODIFIER_MOTION_NONE)
function hijikata_madness:GetIntrinsicModifierName()
    return "modifier_hijikata_swift"
end

--[[
function hijikata_madness:GetBehavior()
    if self:GetCaster():GetHealthPercent() < 25 then
        return self.BaseClass.GetBehavior(self) + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
    end
    if self:GetCaster():GetHealthPercent() < 40 and self:GetCaster().IsHijikataTacticsAcquired then
        return self.BaseClass.GetBehavior(self) + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
    end
    return self.BaseClass.GetBehavior(self)
end
]]
function hijikata_madness:OnSpellStart()
	local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local delay = 0.5
    if self:GetCaster():GetHealthPercent() < 25 then
        delay = 0
    end
    if self:GetCaster():GetHealthPercent() < 40 and self:GetCaster().IsHijikataTacticsAcquired then
        delay = 0
    end

    StartAnimation(caster, {duration=delay , activity=ACT_DOTA_DISABLED, rate=1})
    if delay > 0 then
	    caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = delay}) 
    end
    Timers:CreateTimer(delay, function()
        caster:AddNewModifier(caster, self, "modifier_hijikata_madness_active", { Duration = duration })
        caster:EmitSound("hijikata_scream")
    end)
    if self:CheckCombo() then
        caster:SwapAbilities("hijikata_madness", "hijikata_combo", false, true)
        Timers:CreateTimer(4, function()
                if not caster:FindAbilityByName("hijikata_combo"):IsHidden() then
                    caster:SwapAbilities("hijikata_madness", "hijikata_combo", true, false)
                end
        end)
    end
    -- if self.eyes_particle_left ~= nil then
    --     ParticleManager:DestroyParticle(self.eyes_particle_left, true)
    --     ParticleManager:ReleaseParticleIndex(self.eyes_particle_left)
    -- end
    -- if self.eyes_particle_right ~= nil then
    --     ParticleManager:DestroyParticle(self.eyes_particle_right, true)
    --     ParticleManager:ReleaseParticleIndex(self.eyes_particle_right)
    -- end

end

function hijikata_madness:CheckCombo()
	local caster = self:GetCaster()
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("hijikata_combo"):IsCooldownReady()  then
			return true
		end
	end
    return false
end
modifier_hijikata_madness_active = class({})

function modifier_hijikata_madness_active:GetEffectName()
    return "particles/custom/lancelot/lancelot_arondite_ambient.vpcf"
end

function modifier_hijikata_madness_active:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_hijikata_madness_active:IsHidden()
    return false 
end

function modifier_hijikata_madness_active:OnCreated()
    local caster = self:GetCaster()
    self.eyes_particle_left = ParticleManager:CreateParticle("particles/hijikata/hijikata_eye.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlEnt(self.eyes_particle_left, 0, caster, PATTACH_POINT_FOLLOW, "left_eye", Vector(0,0,0), true)
    self.eyes_particle_right = ParticleManager:CreateParticle("particles/hijikata/hijikata_eye.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlEnt(self.eyes_particle_right, 0, caster, PATTACH_POINT_FOLLOW, "right_eye", Vector(0,0,0), true)
    self.ability = self:GetAbility()
end

function modifier_hijikata_madness_active:OnDestroy()
    --if not IsServer() then return end
    ParticleManager:DestroyParticle(self.eyes_particle_left, true)
    ParticleManager:ReleaseParticleIndex(self.eyes_particle_left)
    ParticleManager:DestroyParticle(self.eyes_particle_right, true)
    ParticleManager:ReleaseParticleIndex(self.eyes_particle_right)
    self.eyes_particle_left = nil
    self.eyes_particle_right = nil
end

function modifier_hijikata_madness_active:RemoveOnDeath()
    return true
end

function modifier_hijikata_madness_active:IsDebuff()
    return false 
end

function modifier_hijikata_madness_active:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_hijikata_madness_active:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = false,
        [MODIFIER_STATE_SILENCED] = false}
end




modifier_hijikata_swift = class({})

function modifier_hijikata_swift:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_MAX_OVERRIDE ,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_MOVESPEED_LIMIT    }
end

function modifier_hijikata_swift:GetModifierMoveSpeedBonus_Constant()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("ms_per_stack")
end
function modifier_hijikata_swift:GetModifierMoveSpeed_Limit()
    if self:GetCaster():HasModifier("modifier_hijikata_combo_ticker") then
        return 1800
    else
        return 650
    end
end

function modifier_hijikata_swift:GetModifierMoveSpeed_MaxOverride()
    if self:GetCaster():HasModifier("modifier_hijikata_combo_ticker") then
        return 1800
    else
        return 650
    end
end
function modifier_hijikata_swift:OnAttackLanded(args)
    if args.attacker ~= self:GetParent() then return end
	local caster = self:GetParent()
    if IsNotNull(args.target) then
		if args.target:IsAlive() then
			DoDamage(caster, args.target, caster:GetAttackDamage() * self:GetAbility():GetSpecialValueFor("max_attack_damage") * self:GetStackCount()/10000, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
            self:SetStackCount(0)
		end
	end

end

if IsServer() then 
	function modifier_hijikata_swift:OnCreated(args)
		self.vLocation = self:GetParent():GetAbsOrigin()
		self.MsFromStacks = self:GetAbility():GetSpecialValueFor("ms_per_stack")
        self.DistanceToStacks = self:GetAbility():GetSpecialValueFor("distance_for_stack")
		self:StartIntervalThink(0.2)


	end

	function modifier_hijikata_swift:OnRefresh(args)
		self:OnCreated()

	end


	function modifier_hijikata_swift:OnIntervalThink()
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		local fDistance = (self:GetParent():GetAbsOrigin() - self.vLocation):Length2D()
        local stackcount = self:GetStackCount()
        if fDistance > 2000 then
            self:SetStackCount(stackcount + 20)
            if self:GetStackCount() > 100 then
                self:SetStackCount(100)
            end
        else
            self:SetStackCount(stackcount + fDistance/self.DistanceToStacks)
            if self:GetStackCount() > 100 then
                self:SetStackCount(100)
            end
        end

		self.vLocation = self:GetParent():GetAbsOrigin()
	end
end

function modifier_hijikata_swift:IsDebuff()
	return false
end

function modifier_hijikata_swift:IsHidden() 
	return false 
end

function modifier_hijikata_swift:RemoveOnDeath() 
	return false 
end