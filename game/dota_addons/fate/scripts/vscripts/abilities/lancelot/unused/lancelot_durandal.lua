lancelot_durandal = class({})

LinkLuaModifier("modifier_durandal_armor_shred", "abilities/lancelot/modifier/modifier_durandal_armor_shred", LUA_MODIFIER_MOTION_NONE)

function lancelot_durandal:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local damage = self:GetSpecialValueFor("slash_damage")
    
    Timers:CreateTimer(self:GetSpecialValueFor("slash_interval_1"), function()  
        if caster:IsAlive() and target:IsAlive() then
            self:PerformSlash(caster, target, damage)
        else
            ParticleManager:DestroyParticle(particle, true)
        end
    return end)

    Timers:CreateTimer(self:GetSpecialValueFor("slash_interval_2"), function()  
        if caster:IsAlive() and target:IsAlive() then
            self:PerformSlash(caster, target, damage)
        else
            ParticleManager:DestroyParticle(particle, true)
        end
    return end)
end

function lancelot_durandal:PerformSlash(caster, target, damage)
    local modifier = target:FindModifierByName("modifier_durandal_armor_shred")
    local currentStack = modifier and modifier:GetStackCount() or 0
    
    caster:EmitSound("Hero_DragonKnight.Attack")
    DoDamage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self, false)

    target:RemoveModifierByName("modifier_durandal_armor_shred")
    target:AddNewModifier(caster, self, "modifier_durandal_armor_shred", {
        duration = self:GetSpecialValueFor("duration")
    })
    target:SetModifierStackCount("modifier_durandal_armor_shred", self, math.min(2, currentStack + 1))

    --Some code to make particles
    target:EmitSound("Hero_DragonKnight.Attack.Impact")
end

