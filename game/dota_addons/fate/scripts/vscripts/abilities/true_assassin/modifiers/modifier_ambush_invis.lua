modifier_ambush_invis = class({})
modifier_ambush_attack_speed = class({})

LinkLuaModifier("modifier_ambush_attack_speed", "abilities/true_assassin/modifiers/modifier_ambush_invis", LUA_MODIFIER_MOTION_NONE)

function modifier_ambush_invis:DeclareFunctions()
    local funcs = {}
    if self:GetParent().IsPCImproved then
        funcs = { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
                 MODIFIER_EVENT_ON_ATTACK,
                 --MODIFIER_EVENT_ON_ATTACK_LANDED,
                 MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
                 --MODIFIER_EVENT_ON_TAKEDAMAGE
                  }
    else
        funcs = {MODIFIER_EVENT_ON_ATTACK,
                 --MODIFIER_EVENT_ON_ATTACK_LANDED,
                 MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
                 --MODIFIER_EVENT_ON_TAKEDAMAGE
                  }
    end
    return funcs
end
if IsServer() then
    function modifier_ambush_invis:OnCreated(table)     
        self.fixedMoveSpeed = 0
        CustomNetTables:SetTableValue("sync","ambush_movement", {movespeed_bonus = self.fixedMoveSpeed})
        self.bonusDamage = table.bonusDamage
        self.Faded = false
        self.radius = self:GetAbility():GetSpecialValueFor("invis_radius")
        self:StartIntervalThink(table.fadeDelay)
        local k = 0
        --self:GetParent():AddDagger(self:GetAbility():GetSpecialValueFor("recover_dagger"))
        --self:GetParent():FindAbilityByName("true_assassin_dirk"):EndCooldown()
    end

    function modifier_ambush_invis:OnIntervalThink()
    	local caster = self:GetParent()


        self.fixedMoveSpeed = 450
        if caster.IsPCImproved then
            self.fixedMoveSpeed = 550
        end
        if self.Faded == true then
            local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
            if #units > 0 or caster:HasModifier("modifier_inside_marble") or caster:HasModifier("modifier_jeanne_vision") then
                self.state = { [MODIFIER_STATE_INVISIBLE] = false,
                           [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                           [MODIFIER_STATE_TRUESIGHT_IMMUNE] = false,}

                if not self.fx then
                    self.fx = ParticleManager:CreateParticleForTeam("particles/true_assassin/ambush_found.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), self:GetParent():GetTeamNumber()) --i am kinda drunk right now so particle radius is written in particle itself (position along ring -> initial radius) cause no freaking idea how to make it linked to CP and i don't want to fuck with it right now (i know it's possible and maybe easy, but i'm a lazy ass)
                    ParticleManager:SetParticleControl(self.fx, 4, Vector(26, 0, 0))   
                end
            else
                self.state = { [MODIFIER_STATE_INVISIBLE] = true,
                           [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                           [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,}
                if self.fx then
                    ParticleManager:DestroyParticle(self.fx, true)
                    ParticleManager:ReleaseParticleIndex(self.fx)
                    self.fx = nil
                end
            end
            self:StartIntervalThink(FrameTime())
        else
    		self.state = { [MODIFIER_STATE_INVISIBLE] = true,
    					   [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    					   [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
    					 }
            self:StartIntervalThink(0.2)
            --[[Timers:CreateTimer(0.2, function()
                self.state = { [MODIFIER_STATE_INVISIBLE] = true,
                           [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                           [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,}
                         end)]]
    	end
        
        self.Faded = true
    end

    function modifier_ambush_invis:OnAttackLanded(args)	
        local caster = self:GetParent()
        if args.attacker ~= self:GetParent() then return end
        if not self.Faded then return end

        local target = args.target
        if caster == target then return end

        --DoDamage(caster, target, self.bonusDamage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
        --target:EmitSound("Hero_TemplarAssassin.Meld.Attack")
        self:Destroy()
    end

    function modifier_ambush_invis:OnAbilityFullyCast(args)
        if args.unit == self:GetParent() then
            if not self.Faded then return end
            --if args.ability:GetName() ~= "true_assassin_ambush" and args.ability:GetName() ~= "true_assassin_combo" and args.ability:GetName() ~= "true_assassin_selfmod" then
            --[[if args.ability:IsItem() then
                self:Destroy()
            end]]
            --end
        end
    end

    function modifier_ambush_invis:CheckState()
    	return self.state
    end

    function modifier_ambush_invis:OnTakeDamage(args)
        if args.unit ~= self:GetParent() then return end

        local damageTaken = args.original_damage
        if damageTaken > self:GetAbility():GetSpecialValueFor("break_threshold") then
            self:Destroy()
        end
    end

    function modifier_ambush_invis:OnDestroy()
        if self.fx then
            ParticleManager:DestroyParticle(self.fx, true)
            ParticleManager:ReleaseParticleIndex(self.fx)
            self.fx = nil
        end

        local hCaster = self:GetParent()
        hCaster:AddNewModifier(hCaster, self:GetAbility(), "modifier_ambush_attack_speed", { Duration = 1.5 })
    end
end

function modifier_ambush_invis:GetModifierMoveSpeed_Absolute()
    if IsServer() then
        CustomNetTables:SetTableValue("sync","ambush_movement", {movespeed_bonus = self.fixedMoveSpeed})       
        return self.fixedMoveSpeed
    elseif IsClient() then
        local ambush_movement = CustomNetTables:GetTableValue("sync","ambush_movement").movespeed_bonus
        return ambush_movement 
    end
end

-----------------------------------------------------------------------------------
function modifier_ambush_invis:GetEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_ambush_invis:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ambush_invis:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_ambush_invis:IsPurgable()
    return true
end

function modifier_ambush_invis:IsDebuff()
    return false
end

function modifier_ambush_invis:RemoveOnDeath()
    return true
end

function modifier_ambush_invis:GetTexture()
    return "custom/true_assassin_ambush"
end
-----------------------------------------------------------------------------------

function modifier_ambush_attack_speed:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_ambush_attack_speed:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed")
end