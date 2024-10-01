hijikata_madness = class({})

LinkLuaModifier("modifier_hijikata_madness_active", "abilities/hijikata/hijikata_madness", LUA_MODIFIER_MOTION_NONE)



function hijikata_madness:OnSpellStart()
	local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_hijikata_madness_active", { Duration = duration })

    caster:SwapAbilities("hijikata_madness", "hijikata_combo", false, true)
    Timers:CreateTimer(4, function()
      		caster:SwapAbilities("hijikata_madness", "hijikata_combo", true, false)
    end)
    -- if self.eyes_particle_left ~= nil then
    --     ParticleManager:DestroyParticle(self.eyes_particle_left, true)
    --     ParticleManager:ReleaseParticleIndex(self.eyes_particle_left)
    -- end
    -- if self.eyes_particle_right ~= nil then
    --     ParticleManager:DestroyParticle(self.eyes_particle_right, true)
    --     ParticleManager:ReleaseParticleIndex(self.eyes_particle_right)
    -- end

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

function modifier_hijikata_madness_active:DeclareFunctions()
   	return {	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end
