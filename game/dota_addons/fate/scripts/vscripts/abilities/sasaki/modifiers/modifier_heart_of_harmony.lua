modifier_heart_of_harmony = class({})
modifier_heart_of_harmony_invis = class({})

LinkLuaModifier("modifier_heart_of_harmony_invis", "abilities/sasaki/modifiers/modifier_heart_of_harmony", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heart_of_harmony_speed", "abilities/sasaki/modifiers/modifier_heart_of_harmony_speed", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heart_of_harmony_linger", "abilities/sasaki/modifiers/modifier_heart_of_harmony_linger", LUA_MODIFIER_MOTION_NONE)

function modifier_heart_of_harmony:OnCreated(keys)
    local caster = self:GetParent()
    self.DamageReduc = keys.DamageReduc
    self.ManaRegenBonus = keys.ManaRegenBonus
    self.SlashCount = keys.SlashCount
    self.Threshold = keys.Threshold
    self.ManaThreshold = keys.ManaThreshold
    self.StunDuration = keys.StunDuration

    if IsServer() then
        self.particle = ParticleManager:CreateParticle( "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster )
        ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
        ParticleManager:SetParticleControl(self.particle, 1, Vector( 100, 100, 100 ) )

        --if caster.IsVitrificationAcquired then
            --caster:AddNewModifier(caster, self:GetAbility(), "modifier_heart_of_harmony_invis", { Duration = 3 })
        --end
    
        CustomNetTables:SetTableValue("sync","heart_of_harmony", { damage_reduc = self.DamageReduc, 
                                                                   mana_regen = self.ManaRegenBonus })
    end
end

function modifier_heart_of_harmony:OnRefresh(args)
    self:DestroyAttachedParticle()
    self:OnCreated(args)
end

function modifier_heart_of_harmony:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        --MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
 
    return funcs
end

function modifier_heart_of_harmony:CheckState()
    return self.State
end

function modifier_heart_of_harmony:GetModifierIncomingDamage_Percentage() 
    if IsServer() then        
        return self.DamageReduc
    elseif IsClient() then
        local damage_reduc = CustomNetTables:GetTableValue("sync","heart_of_harmony").damage_reduc
        return damage_reduc 
    end
end

function modifier_heart_of_harmony:GetModifierConstantManaRegen() 
    if IsServer() then        
        return self.ManaRegenBonus
    elseif IsClient() then
        local mana_regen = CustomNetTables:GetTableValue("sync","heart_of_harmony").mana_regen
        return mana_regen 
    end
end

function modifier_heart_of_harmony:FilterUnits(caster, target)    
    local filter = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS, caster:GetTeamNumber())

    if (filter == UF_SUCCESS) then
        if ((caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() < 1500) then
            return true
        end
    end

    return false
end

function modifier_heart_of_harmony:OnTakeDamage(args)
    --for k,v in pairs(args) do print(k,v) end
    if IsServer() then 
        local caster = self:GetParent()
        local target = args.attacker

        if args.unit ~= self:GetParent() then return end

        local ability = self:GetAbility()
        local damageTaken = args.original_damage
        local threshold = self.Threshold
        local slashcount = self.SlashCount

        if damageTaken >= threshold and caster:GetHealth() ~= 0 and self:FilterUnits(caster, target) then
            local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
            local position = target:GetAbsOrigin() - diff * 100
            FindClearSpaceForUnit(caster, position, true)             

            --if caster:GetMana() > self.ManaThreshold then
                target:EmitSound("Sasaki_Counter_Success_" .. math.random(1,2))
                LoopOverPlayers(function(player, playerID, playerHero)
                    --print("looping through " .. playerHero:GetName())
                    if playerHero.zlodemon == true then
                        -- apply legion horn vsnd on their client
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="moskes_block".. math.random(1,2)})
            
                        --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
                    end
            
                end)
                target:AddNewModifier(caster, target, "modifier_stunned", {Duration = self.StunDuration})
            --else
              --  caster:EmitSound("Sasaki_Counter_Fail_" .. math.random(1,2))
            --end

            Timers:CreateTimer(0.033, function()                
                HardCleanse(caster)
                return
            end)

            caster:RemoveModifierByName("modifier_heart_of_harmony_invis")
            caster:RemoveModifierByName("modifier_heart_of_harmony_disarm")
            caster:AddNewModifier(caster, self:GetAbility(), "modifier_heart_of_harmony_speed", { duration = 3.0})
            caster:AddNewModifier(caster, self:GetAbility(), "modifier_camera_follow", { duration = 1.0})

            local counter = 0
            Timers:CreateTimer(function()
                if counter == slashcount or not caster:IsAlive() then return end 
                caster:PerformAttack( target, true, true, true, true, false, false, false )
                caster:AddNewModifier(caster, caster, "modifier_camera_follow", {duration = 1.0})
                CreateSlashFx(caster, target:GetAbsOrigin()+RandomVector(500), target:GetAbsOrigin()+RandomVector(500))
                counter = counter + 1  
                return 0.05
            end)
            
            EmitGlobalSound("FA.Quickdraw")

            self:Destroy()
        end
    end
end

function modifier_heart_of_harmony:OnDestroy()
    self:DestroyAttachedParticle()
end

function modifier_heart_of_harmony:DestroyAttachedParticle()
    if IsServer() then
        if self.particle ~= nil then
            ParticleManager:DestroyParticle( self.particle, false )
            ParticleManager:ReleaseParticleIndex( self.particle )
        end
    end
end

-----------------------------------------------------------------------------------
function modifier_heart_of_harmony:GetEffectName()
    return "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance.vpcf"
end

function modifier_heart_of_harmony:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_heart_of_harmony:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_heart_of_harmony:IsPurgable()
    return false
end

function modifier_heart_of_harmony:IsDebuff()
    return false
end

function modifier_heart_of_harmony:RemoveOnDeath()
    return true
end

function modifier_heart_of_harmony:GetTexture()
    return "custom/false_assassin_heart_of_harmony"
end
-----------------------------------------------------------------------------------


-----------------------------------------------------------------------------------
if IsServer() then
    function modifier_heart_of_harmony_invis:OnAttackLanded(args)
        if args.attacker == self:GetParent() then self:Destroy() end
    end

    function modifier_heart_of_harmony_invis:OnAbilityFullyCast(args)
        if args.unit == self:GetParent() then self:Destroy() end
    end

    function modifier_heart_of_harmony_invis:DeclareFunctions()
        return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
                 MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
    end
end

function modifier_heart_of_harmony_invis:CheckState()
    return { [MODIFIER_STATE_INVISIBLE] = true,
             [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

function modifier_heart_of_harmony_invis:GetEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_heart_of_harmony_invis:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_heart_of_harmony_invis:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_heart_of_harmony_invis:IsHidden()
    return true
end
