LinkLuaModifier("modifier_atalanta_ora", "abilities/alter_atalanta/atalanta_ora", LUA_MODIFIER_MOTION_NONE)

atalanta_ora = class({})

function atalanta_ora:OnSpellStart()
	local caster = self:GetCaster()

    caster:EmitSound("atalanta_ora")

	caster:AddNewModifier(caster, self, "modifier_atalanta_ora", {duration = self:GetSpecialValueFor("duration")})
end

modifier_atalanta_ora = class({})
function modifier_atalanta_ora:IsHidden() return false end
function modifier_atalanta_ora:IsDebuff() return false end
function modifier_atalanta_ora:IsPurgable() return false end
function modifier_atalanta_ora:IsPurgeException() return false end
function modifier_atalanta_ora:RemoveOnDeath() return true end
function modifier_atalanta_ora:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_atalanta_ora:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_atalanta_ora:CheckState()
    local state = { --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                    --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                    --[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_ROOTED] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                }
    return state
end
function modifier_atalanta_ora:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
                	MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
                MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
                --MODIFIER_EVENT_ON_ATTACK_LANDED,
                MODIFIER_PROPERTY_ATTACK_RANGE_BONUS}
    return func
end
function modifier_atalanta_ora:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end
function modifier_atalanta_ora:OnAttackLanded(args)
    if args.attacker ~= self:GetParent() then return end

    local slashFx = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_fury_sweep_cross.vpcf", PATTACH_ABSORIGIN, self.parent )
    ParticleManager:SetParticleControl( slashFx, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl( slashFx, 1, self.parent:GetAbsOrigin())
   
   DoDamage(args.attacker, args.target, self.ability:GetSpecialValueFor("base_damage") + (args.target:HasModifier("modifier_atalanta_curse") and args.target:FindModifierByName("modifier_atalanta_curse"):GetStackCount() or 0), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end
function modifier_atalanta_ora:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("as_bonus")
end
--[[function modifier_atalanta_ora:GetOverrideAnimation()
	return ACT_DOTA_OVERRIDE_ABILITY_2
end]]
--[[function modifier_atalanta_ora:GetOverrideAnimationRate()
	return self:GetAbility():GetSpecialValueFor("attack_rate")/self:GetParent():GetSecondsPerAttack()
end]]
function modifier_atalanta_ora:OnCreated(table)
    if IsServer() then
        self.caster = self:GetCaster()
        self.parent = self:GetParent()
        self.ability = self:GetAbility()

        self.radius = self.ability:GetSpecialValueFor("radius")
        self.duration = self.ability:GetSpecialValueFor("duration")
        self.width = self.ability:GetSpecialValueFor("width")
        self.total_damage = self.ability:GetSpecialValueFor("total_damage")
        self.reduce_damage = self.ability:GetSpecialValueFor("reduce_damage")
        --self.interval = 1/((1/self.parent:GetSecondsPerAttack() + self.ability:GetSpecialValueFor("base_attack_count")/self.duration)*self.ability:GetSpecialValueFor("attack_rate"))

        --self.furyFx = ParticleManager:CreateParticle("particles/atalanta/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
		--ParticleManager:SetParticleControl( self.furyFx, 0, self.parent:GetAbsOrigin())
		--ParticleManager:SetParticleControl( self.furyFx, 5, Vector(self.radius, 1, 1))

        --self:SetAttacking()
    end
end
function modifier_atalanta_ora:SetAttacking()
    if IsServer() then

        self:StartIntervalThink(self.interval)

        --EmitSoundOn("SP.Do.Ora", self.parent)
    end
end
function modifier_atalanta_ora:OnIntervalThink()
    if IsServer() then
        local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                            GetGroundPosition(self.parent:GetAbsOrigin(), self:GetParent()),
                                            nil,
                                            self.radius,
                                            self.ability:GetAbilityTargetTeam(),
                                            self.ability:GetAbilityTargetType(),
                                            self.ability:GetAbilityTargetFlags(),
                                            FIND_CLOSEST,
                                            false)

        if self.parent:IsHexed() or self.parent:IsStunned() then
            self:Destroy()
            return nil
        end

        --self.parent:Stop()
        for _, enemy in pairs(enemies) do
            self.parent:PerformAttack(enemy, true, true, true, true, false, false, false)
            DoDamage(self.parent, enemy, self.ability:GetSpecialValueFor("base_damage"), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            if self.parent.EvolutionAcquired and enemy:HasModifier("modifier_atalanta_curse") then
              	DoDamage(self.parent, enemy, enemy:FindModifierByName("modifier_atalanta_curse"):GetStackCount(), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            end
            local slashFx = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_fury_sweep_cross.vpcf", PATTACH_ABSORIGIN, self.parent )
			ParticleManager:SetParticleControl( slashFx, 0, self.parent:GetAbsOrigin())
			ParticleManager:SetParticleControl( slashFx, 1, self.parent:GetAbsOrigin())
        end
    end
end
function modifier_atalanta_ora:OnDestroy()
	--ParticleManager:DestroyParticle(self.furyFx, false)
	--ParticleManager:ReleaseParticleIndex(self.furyFx)
   --StopSoundOn("SP.Do.Ora", self.parent)
end