hijikata_laws = class({})
LinkLuaModifier("modifier_hijikata_laws", "abilities/hijikata/hijikata_laws", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_laws_buff", "abilities/hijikata/hijikata_laws", LUA_MODIFIER_MOTION_NONE)


function hijikata_laws:GetIntrinsicModifierName()
    return "modifier_hijikata_laws"
end

function hijikata_laws:OnSpellStart()
	local caster = self:GetCaster()
    if not caster.IsHijikataEternalMadnessAcquired then 
        if not self.used then
            caster:FindModifierByName("modifier_hijikata_laws"):IncrementStackCount()
            caster:FindModifierByName("modifier_hijikata_laws"):TakeDamage()
        end
        self.used = true
    else
        if self.used_times < 3 then
            caster:FindModifierByName("modifier_hijikata_laws"):IncrementStackCount()
            caster:FindModifierByName("modifier_hijikata_laws"):TakeDamage()
        end
        self.used_times = self.used_times + 1
    end

end


modifier_hijikata_laws = class({})
function modifier_hijikata_laws:IsHidden()
    return false 
end

function modifier_hijikata_laws:OnRespawn(args)
	local caster = self:GetParent() 
    if(caster ~= args.unit) then return end
	self:SetStackCount(0)
    self:GetAbility().used = false
    self:GetAbility().used_times = 0
    self.distance_restriction = false
    self.duel_restriction = false
    self.kill_restriction = false
    self.help_restriction = false
    if caster:GetAbilityByIndex(0):GetName() == "hijikata_dash_recast" then
		caster:SwapAbilities("hijikata_dash_recast", "hijikata_dash", false, true)
	end
end

function modifier_hijikata_laws:OnCreated()
    self:SetStackCount(0)
    self:GetAbility().used = false
    self:GetAbility().used_times = 0
    self.distance_restriction = false
    self.duel_restriction = false
    self.kill_restriction = false
    self.help_restriction = false
end

function modifier_hijikata_laws:CheckBlinkCondition(beforeBlinkPos, AfterblinkPosition)
    if self.distance_restriction == true then return end
    local caster = self:GetParent()
    local checkRange = self:GetAbility():GetSpecialValueFor("check_range")
    local targets = FindUnitsInRadius(caster:GetTeam(), beforeBlinkPos, nil, checkRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_CAN_BE_SEEN, FIND_ANY_ORDER, false) 
    if #targets > 0 then
        local targets2 = FindUnitsInRadius(caster:GetTeam(), AfterblinkPosition, nil, checkRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false) 
        if #targets2 <= 0 then
            self.distance_restriction = true
            self:IncrementStackCount()
            self:TakeDamage()
        end
    end
end

function modifier_hijikata_laws:TakeDamage()
    if self:GetStackCount() == 5 then return end
    local damage = self:GetCaster():GetMaxHealth() * self:GetAbility():GetSpecialValueFor("damage_take_per_stack_percent")/100
    if (self:GetCaster():GetHealth() - damage) <= 0 then
        --self:GetCaster():SetHealth(1)
        damage = self:GetCaster():GetHealth() - 1
    else
        DoDamage( self:GetCaster(),  self:GetCaster(), damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NON_LETHAL, self, false)
    end
end


function modifier_hijikata_laws:OnStackCountChanged(stacks)
    if stacks == 5 then return end
    if stacks == 4 then
        if IsServer() then
            local damage = self:GetCaster():GetMaxHealth() * self:GetAbility():GetSpecialValueFor("last_damage_take_per_stack_percent")/100
            --print(self:GetCaster():HasModifier("round_pause"))
            --print(self:GetCaster():GetModifierStackCount("modifier_hijikata_laws", self:GetCaster()) )
            --print(not( self:GetCaster():GetModifierStackCount("modifier_hijikata_laws", self:GetCaster()) == 0))
            if (not self:GetCaster():HasModifier("round_pause") ) and not( self:GetCaster():GetModifierStackCount("modifier_hijikata_laws", self:GetCaster()) == 0) then
                giveUnitDataDrivenModifier(self:GetParent(),self:GetParent() , "stunned", self:GetAbility():GetSpecialValueFor("stun_duration")-(self:GetCaster().IsHijikataSincerityAcquired and 1.5 or 0))
                self:GetCaster():EmitSound("hijikata_laws_stun")
                if (self:GetCaster():GetHealth() - damage) <= 0 then
                    damage = self:GetCaster():GetHealth() - 1
                    --self:GetCaster():SetHealth(1)
                else
                    DoDamage( self:GetCaster(),  self:GetCaster(), damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NON_LETHAL, self, false)
                end

        end
                if(self:GetCaster().IsHijikataSincerityAcquired) then
                    local targets = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetCaster():GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO,
                                                         DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
                    for k,v in pairs(targets) do
                        if v:GetUnitName() ~= "npc_dota_hero_dark_willow" and v:GetUnitName() ~= "npc_dota_hero_spirit_breaker" and v:GetUnitName() ~= "npc_dota_hero_terrorblade" then
                            v:AddNewModifier(caster, self, "modifier_hijikata_laws_buff", { Duration = 5, damage = 100 })
                        else
                            v:AddNewModifier(caster, self, "modifier_hijikata_laws_buff", { Duration = 5, damage = 150 })
                        end
                    end
                end
        if IsServer() then
                Timers:CreateTimer(self:GetAbility():GetSpecialValueFor("stun_duration")+(self:GetCaster().IsHijikataSincerityAcquired and 2 or 0), function()
                    self:SetStackCount(0)
                    self:GetAbility().used = false
                    self:GetAbility().used_times = 0
                    self.distance_restriction = false
                    self.duel_restriction = false
                    self.kill_restriction = false
                    self.help_restriction = false
                end)
            end
            
        end
    end

end


function modifier_hijikata_laws:RemoveOnDeath()
    return false
end

function modifier_hijikata_laws:IsDebuff()
    return false 
end

function modifier_hijikata_laws:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_hijikata_laws:DeclareFunctions()
   	return {	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
                MODIFIER_PROPERTY_HEALTH_BONUS,
                MODIFIER_EVENT_ON_RESPAWN }
end

function modifier_hijikata_laws:GetModifierPreAttack_BonusDamage()
	return (self:GetAbility():GetSpecialValueFor("dmg_per_stack") * self:GetStackCount())
end

function modifier_hijikata_laws:GetModifierHealthBonus()
	return (self:GetAbility():GetSpecialValueFor("health_per_stack") * self:GetStackCount())
end



modifier_hijikata_laws_buff = class({})

if IsServer() then
	function modifier_hijikata_laws_buff:OnCreated(args)	
        self.damage_buff = args.damage
	end

end

function modifier_hijikata_laws_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end


function modifier_hijikata_laws_buff:GetModifierPreAttack_BonusDamage()
	return self.damage_buff
end

function modifier_hijikata_laws_buff:RemoveOnDeath()
    return true
end

function modifier_hijikata_laws_buff:IsDebuff()
    return false 
end

function modifier_hijikata_laws_buff:IsHidden()
    return false 
end

function modifier_hijikata_laws_buff:GetEffectName()
    return "particles/hijikata/hijikata_laws_buff.vpcf"
end
