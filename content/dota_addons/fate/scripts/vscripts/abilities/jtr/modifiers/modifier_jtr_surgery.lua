modifier_jtr_surgery = class({})
function modifier_jtr_surgery:IsHidden() return false end
function modifier_jtr_surgery:IsDebuff() return false end
function modifier_jtr_surgery:RemoveOnDeath() return true end
function modifier_jtr_surgery:CheckState()
    local state = { --[MODIFIER_STATE_INVULNERABLE] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_UNSELECTABLE] = true,
                    [MODIFIER_STATE_UNTARGETABLE] = true}
    return state
end
function modifier_jtr_surgery:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE}
    return func
end
function modifier_jtr_surgery:GetOverrideAnimation()
    return ACT_DOTA_RUN
end
function modifier_jtr_surgery:GetModifierBaseAttack_BonusDamage()
    return -300
end
function modifier_jtr_surgery:IsMotionController() return true end
function modifier_jtr_surgery:OnCreated(args)
    if IsServer() then
        self.radius = 300
        self.parent = self:GetParent()
        self.time_elapsed = 0.2
        self.kappa = 1
        self.forward = self.parent:GetForwardVector()
        self.quadrant = 1

        self.target = self:GetAbility():GetCursorTarget()
        --print(self.bonus_slashes)
        --print(self.radius)
        self.slashes = self:GetAbility():GetSpecialValueFor("slashes")

        if self.parent:HasModifier("modifier_jtr_bloody_thirst_active") then
            self.swing_fx = ParticleManager:CreateParticle("particles/jtr/jtr_slashes_b.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())

            ParticleManager:SetParticleControlEnt(self.swing_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(self.swing_fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)

            self.swing2_fx = ParticleManager:CreateParticle("particles/jtr/jtr_slashes_b.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())

            ParticleManager:SetParticleControlEnt(self.swing2_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(self.swing2_fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
        else
            self.swing_fx = ParticleManager:CreateParticle("particles/jtr/jtr_slashes_a.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())

            ParticleManager:SetParticleControlEnt(self.swing_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(self.swing_fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)

            self.swing2_fx = ParticleManager:CreateParticle("particles/jtr/jtr_slashes_b.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())

            ParticleManager:SetParticleControlEnt(self.swing2_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(self.swing2_fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
        end

        self:AddParticle(self.swing_fx, false, false, -1, false, false)

        self:AddParticle(self.swing2_fx, false, false, -1, false, false)

        --EmitSoundOn("Kirito.Sao.Slashes", self:GetParent())

        FindClearSpaceForUnit(self:GetParent(), self.target:GetAbsOrigin(), true)

        self:StartIntervalThink(FrameTime())
    end
end
function modifier_jtr_surgery:OnIntervalThink()
    if IsServer() then
        if self.time_elapsed >= 0.1 then
            self.time_elapsed = 0.01
            if self.slashes <= 0 then
                self:Destroy()
            end

            if self.target == nil then
                self:Destroy()
                return nil
            end

            if self.target:IsNull() then
                self:Destroy()
                return nil
            end

            if not self.target:IsAlive() then
                self:Destroy()
                return nil
            end

            --FindClearSpaceForUnit(self:GetParent(), self.target:GetAbsOrigin(), true)

            local enemies = FindUnitsInRadius(  self:GetParent():GetTeamNumber(), 
                                                self.target:GetAbsOrigin(), 
                                                nil, 
                                                self.radius, 
                                                self:GetAbility():GetAbilityTargetTeam(), 
                                                self:GetAbility():GetAbilityTargetType(), 
                                                self:GetAbility():GetAbilityTargetFlags(), 
                                                FIND_ANY_ORDER, 
                                                false)

            for _,enemy in pairs(enemies) do
                --[[local damage_table = {  victim = enemy,
                                        attacker = self:GetParent(),
                                        damage = 100,
                                        damage_type = self:GetAbility():GetAbilityDamageType(),
                                        ability = self:GetAbility() }

                ApplyDamage(damage_table)]]
                DoDamage(self:GetParent(), enemy, self:GetAbility():GetSpecialValueFor("base_damage"), DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_NONE, self:GetAbility(), false)
            
                self:GetParent():PerformAttack(enemy, true, true, true, true, false, false, false)

                --EmitSoundOn("Kirito.Sao.Slashhit", enemy)
            end
            local currentpoint = self.parent:GetAbsOrigin()
            local newpoint = currentpoint+vectorsV2[self.slashes+1]*0.5 
            self.parent:SetAbsOrigin(newpoint)
            --local trailFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
            --ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
            --ParticleManager:SetParticleControl( trailFx, 0, newpoint )

            self.slashes = self.slashes - 1
            self.parent:SetForwardVector((self.target:GetAbsOrigin() - self.parent:GetAbsOrigin()):Normalized())
            if self.slashes < 1 then
                FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
                self.parent:SetForwardVector(self.forward)
            end
        end
        self.time_elapsed = self.time_elapsed + FrameTime()
        self:HorizontalMotion(self.parent, FrameTime())
    end
end

function modifier_jtr_surgery:HorizontalMotion(me, dt)
    local new_location = self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*8000*dt
    if self.target and not self.target:IsNull() then
        if self.slashes < 1 then
            new_location = self.target:GetAbsOrigin()
        end
    end
    self.parent:SetAbsOrigin(new_location)
    FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
end