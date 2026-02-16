
okada_combo = class({})
LinkLuaModifier("modifier_okada_combo_cd", "abilities/okada/okada_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okada_combo_true_invis", "abilities/okada/okada_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_3", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
function okada_combo:PerformComboAttack(unit, caster, target, dmgMod)
    local initorigin = target:GetForwardVector()*200 + target:GetAbsOrigin()
    unit:SetAbsOrigin(initorigin)
    local diff = (target:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
    unit:FaceTowards(target:GetAbsOrigin())
    unit:SetForwardVector(Vector(diff.x, diff.y, 0))
    unit:AddNewModifier(caster, nil, "modifier_phased", {duration = 1.9})
	giveUnitDataDrivenModifier(unit, caster, "dragged", 1.9)
    caster:Stop()
    local damage = self:GetSpecialValueFor("damage_first")
    StartAnimation( unit, {duration=0.3, activity=ACT_DOTA_CAST_ICE_WALL , rate=3})
    local sImagePFX = "particles/okada/okada_dash_slashes.vpcf"
    giveUnitDataDrivenModifier(unit, unit, "pause_sealenabled", 1.9)
    if caster:HasModifier("modifier_okada_manslayer") then
        sImagePFX = "particles/okada/okada_dash_slashes_red.vpcf"
    end
    self:CreateSlashParticle(target:GetAbsOrigin() + Vector(0,0, 50),sImagePFX )
    DoDamage(caster, target, damage* dmgMod, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self, false)
    caster:EmitSound("okada_combo_strike_1")
    target:EmitSound("okada_combo_slash_1")
            local particle_blood = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_phantom.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_blood, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleControlTransformForward(particle_blood, 1, target:GetAbsOrigin(), diff)
        ParticleManager:SetParticleShouldCheckFoW(particle_blood, false)
        local particle_blood2 = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_mist.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(particle_blood2, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleShouldCheckFoW(particle_blood2, false)
        Timers:CreateTimer(3, function()
            ParticleManager:DestroyParticle(particle_blood, true)
            ParticleManager:ReleaseParticleIndex(particle_blood)
            ParticleManager:DestroyParticle(particle_blood2, true)
            ParticleManager:ReleaseParticleIndex(particle_blood2)
        
        end)
     Timers:CreateTimer(0.3, function()
        StartAnimation( unit, {duration=0.3, activity=ACT_DOTA_ICE_VORTEX , rate=3}) 
        target:EmitSound("okada_combo_slash_2")
        initorigin = target:GetRightVector()*150 + target:GetAbsOrigin()
        unit:SetAbsOrigin(initorigin)
        diff = (target:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
        unit:FaceTowards(target:GetAbsOrigin())
        unit:SetForwardVector(Vector(diff.x, diff.y, 0))
        self:CreateSlashParticle(target:GetAbsOrigin() + Vector(0,0, 50),sImagePFX )
        DoDamage(caster, target, damage* dmgMod, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self, false)
        local particle_blood = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_phantom.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_blood, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleControlTransformForward(particle_blood, 1, target:GetAbsOrigin(), diff)
        ParticleManager:SetParticleShouldCheckFoW(particle_blood, false)
        local particle_blood2 = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_mist.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(particle_blood2, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleShouldCheckFoW(particle_blood2, false)
        Timers:CreateTimer(3, function()
            ParticleManager:DestroyParticle(particle_blood, true)
            ParticleManager:ReleaseParticleIndex(particle_blood)
            ParticleManager:DestroyParticle(particle_blood2, true)
            ParticleManager:ReleaseParticleIndex(particle_blood2)
        end)
     end)

    Timers:CreateTimer(0.5, function()
        caster:EmitSound("okada_combo_strike_2")
        
        StartAnimation( unit, {duration=0.65, activity=ACT_DOTA_LIFESTEALER_RAGE , rate=1.5}) 
        initorigin = target:GetForwardVector()*-200 + target:GetAbsOrigin()
        unit:SetAbsOrigin(initorigin)
        diff = (target:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
        unit:FaceTowards(target:GetAbsOrigin())
        unit:SetForwardVector(Vector(diff.x, diff.y, 0))
        self:CreateSlashParticle(target:GetAbsOrigin() + Vector(0,0, 50),sImagePFX )
        target:AddNewModifier(caster, nil, "modifier_kb_immune", {duration = 1.9})
        giveUnitDataDrivenModifier(unit, target, "pause_sealenabled", 1.3)
        DoDamage(caster, target, damage* dmgMod, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self, false)
        local particle_blood = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_phantom.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_blood, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleControlTransformForward(particle_blood, 1, target:GetAbsOrigin(), diff)
        ParticleManager:SetParticleShouldCheckFoW(particle_blood, false)
        local particle_blood2 = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_mist.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(particle_blood2, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleShouldCheckFoW(particle_blood2, false)
        Timers:CreateTimer(3, function()
            ParticleManager:DestroyParticle(particle_blood, true)
            ParticleManager:ReleaseParticleIndex(particle_blood)
            ParticleManager:DestroyParticle(particle_blood2, true)
            ParticleManager:ReleaseParticleIndex(particle_blood2)
        
        end)
     end)

     Timers:CreateTimer(0.7, function()
        local particle_name = "particles/okada/okada_pierce.vpcf"
        if caster:HasModifier("modifier_okada_manslayer") then
            particle_name = "particles/hijikata/hijikata_demon_pierce.vpcf"
        end
        target:EmitSound("okada_combo_slash_3")
        local particle = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, nil)
        local vec = -(unit:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
	    ParticleManager:SetParticleControlTransformForward(particle, 0, unit:GetAbsOrigin() + Vector(0,0,130), vec)
        ParticleManager:SetParticleControlTransformForward(particle, 1, unit:GetAbsOrigin()+ Vector(0,0,130), vec)
        DoDamage(caster, target, damage* dmgMod, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self, false)
        local particle_blood = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_phantom.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_blood, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleControlTransformForward(particle_blood, 1, target:GetAbsOrigin(), diff)
        ParticleManager:SetParticleShouldCheckFoW(particle_blood, false)
        Timers:CreateTimer(3, function()
            ParticleManager:DestroyParticle(particle_blood, true)
            ParticleManager:ReleaseParticleIndex(particle_blood)
        
        end)
     end)

      Timers:CreateTimer(1.1, function()
        StartAnimation( unit, {duration=0.8, activity=ACT_DOTA_LIFESTEALER_INFEST , rate=1.4}) 
       

      end)

    Timers:CreateTimer(1.3, function()
         target:EmitSound("okada_combo_slash_4")
        target:EmitSound("okada_combo_blood")
        target:EmitSound("okada_combo_blood_2")
        caster:EmitSound("okada_combo_strike_3")
        local particle_blood_big = ParticleManager:CreateParticle("particles/okada/okada_combo_blood.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_blood_big, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleShouldCheckFoW(particle_blood_big, false)
        Timers:CreateTimer(3, function()
            ParticleManager:DestroyParticle(particle_blood_big, true)
            ParticleManager:ReleaseParticleIndex(particle_blood_big)
        
        end)
      end)
    local counterMax = 4
    local counter = 0
    Timers:CreateTimer(1.3, function()
        if counter >= counterMax then
            return
        else
            counter = counter + 1
            DoDamage(caster, target, self:GetSpecialValueFor("damage_last")* dmgMod / (counterMax), DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self, false)
            return 0.1
        end
    
    end)

     Timers:CreateTimer(1.9, function()

        unit:RemoveModifierByName("modifier_kb_immune")
        target:RemoveModifierByName("modifier_kb_immune")
        FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
        if target:IsAlive() then
            target:AddNewModifier(caster, self, "modifier_heal_reduction_tier_3", {duration = self:GetSpecialValueFor("healres_duration")})
        end
    end)

end
function okada_combo:CreateSlashParticle(location, particle)
    local fx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(fx, 7, location)
    ParticleManager:SetParticleControl(fx, 0, location)
    ParticleManager:SetParticleControl(fx, 1, location)
    ParticleManager:SetParticleControl(fx, 2, location)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:ReleaseParticleIndex(fx)

end

function okada_combo:performInvisCombo()
    local maxInvisDuration = self:GetSpecialValueFor("max_invis_duration")
    local timeToActivate = self:GetSpecialValueFor("invis_activation_delay")
    local radius = self:GetSpecialValueFor("invis_activation_radius")
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_okada_combo_true_invis", {duration = maxInvisDuration, timeToStartMove  = timeToActivate, checkRadius = radius})
    EmitSoundOnLocationForAllies(caster:GetAbsOrigin(), "okada_combo_activate", caster)
    StartAnimation( caster, {duration=3.2, activity=ACT_DOTA_CAST_ABILITY_6 , rate=1})
    caster:AddNewModifier(caster,self, "modifier_kb_immune", {duration = maxInvisDuration})
end

function okada_combo:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- if caster:HasModifier("modifier_okada_manslayer") then
    --     self:performInstaCombo()
    -- else
        self:performInvisCombo()
    --end
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))

	caster:AddNewModifier(caster, self, "modifier_okada_combo_cd", {duration = self:GetCooldown(1)})
    
end




modifier_okada_combo_cd = class({})

function modifier_okada_combo_cd:GetTexture()
    return "custom/okada/okada_combo"
end

function modifier_okada_combo_cd:IsHidden()
    return false 
end

function modifier_okada_combo_cd:RemoveOnDeath()
    return false
end

function modifier_okada_combo_cd:IsDebuff()
    return true 
end

function modifier_okada_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


modifier_okada_combo_true_invis = class({})


function modifier_okada_combo_true_invis:DeclareFunctions()

    local funcs = { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
                    MODIFIER_EVENT_ON_ATTACK,
                    MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
                    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
                  }

    return funcs
end

    function modifier_okada_combo_true_invis:OnCreated(table)     
        self.movespeedAbsolute = 1
        self.state = { [MODIFIER_STATE_INVISIBLE] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
                    [MODIFIER_STATE_SILENCED] = true,
                    [MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_DISARMED] = true,
                    [MODIFIER_STATE_ROOTED] = true,
                    }
        self.timeToStartMove =  table.timeToStartMove
        self.TimeTotal = 0
        self.checkRadius = table.checkRadius
        self.fTime = 0.1
        self.iParticleCreated = 0
        self.fx = ParticleManager:CreateParticleForTeam("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent(), self:GetParent():GetTeamNumber())
		ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
		ParticleManager:SetParticleControl(self.fx, 1, Vector(0.7,0.1,0.2))
		ParticleManager:SetParticleControl(self.fx, 2, Vector(self.checkRadius - 100,self:GetDuration(),0))
        self:StartIntervalThink(self.fTime)


    end

    function modifier_okada_combo_true_invis:OnIntervalThink()
    	local caster = self:GetParent()
        caster:RemoveModifierByName("modifier_hijikata_combo_buff")
        caster:RemoveModifierByName("modifier_aoko_blue_ms")
        self.TimeTotal = self.TimeTotal + self.fTime
        if self.TimeTotal >= self.timeToStartMove then
            if self.iParticleCreated <= 1 then
                local fx  = ParticleManager:CreateParticleForTeam("particles/okada/okada_combo_flash.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent(), self:GetParent():GetTeamNumber())
                ParticleManager:SetParticleControl(fx, 0, self:GetParent():GetAbsOrigin())
                ParticleManager:ReleaseParticleIndex(fx)
                self.iParticleCreated = self.iParticleCreated + 1
            end

            self.movespeedAbsolute = 250
            self.state = { [MODIFIER_STATE_INVISIBLE] = true,
                            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                            }
            local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self.checkRadius + 50, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
            if #targets > 0 then
                if targets[1]:IsRealHero() then
                    self:GetAbility():PerformComboAttack(caster, caster, targets[1], 1)
                    self:Destroy()
                    
                else
                    if #targets> 1 then
                        if targets[2]:IsRealHero() then
                            self:GetAbility():PerformComboAttack(caster, caster, targets[2], 1)
                            self:Destroy()
                        end
                    end
                end
            end
        end
    end

    function modifier_okada_combo_true_invis:OnAttackLanded(args)	
        local caster = self:GetParent()
        if args.attacker ~= self:GetParent() then return end
        local target = args.target
        if caster == target then return end
        self:Destroy()
    end

    function modifier_okada_combo_true_invis:OnAbilityFullyCast(args)
        if args.unit == self:GetParent() then
            if args.ability:GetName() ~= "okada_combo" and args.ability:GetName() ~= "okada_manslayer" then
                self:Destroy()
            end

        end
    end

    function modifier_okada_combo_true_invis:CheckState()
    	return self.state
    end

    function modifier_okada_combo_true_invis:OnDestroy()
        if self.fx then
            ParticleManager:DestroyParticle(self.fx, true)
            ParticleManager:ReleaseParticleIndex(self.fx)
            self.fx = nil
        end

    end

    



function modifier_okada_combo_true_invis:GetModifierIncomingDamage_Percentage() 
	return -self:GetAbility():GetSpecialValueFor("damage_reduction_pct")
end

function modifier_okada_combo_true_invis:GetModifierMoveSpeed_Absolute()
    return self.movespeedAbsolute
end

function modifier_okada_combo_true_invis:GetEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_okada_combo_true_invis:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end



function modifier_okada_combo_true_invis:IsPurgable()
    return false
end

function modifier_okada_combo_true_invis:IsDebuff()
    return false
end

function modifier_okada_combo_true_invis:RemoveOnDeath()
    return true
end

function modifier_okada_combo_true_invis:GetPriority()                                                                    return MODIFIER_PRIORITY_ULTRA end
