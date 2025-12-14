demon_king_materialization = class({})

LinkLuaModifier("modifier_demon_king_materialization", "abilities/demon_king_nobunaga/demon_king_materialization", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_demon_king_sa2_spell_amp", "abilities/demon_king_nobunaga/demon_king_materialization", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_demon_king_sa_aura", "abilities/demon_king_nobunaga/demon_king_materialization", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_demon_king_sa_auramod", "abilities/demon_king_nobunaga/demon_king_materialization", LUA_MODIFIER_MOTION_NONE)
function demon_king_materialization:IncreaseStackCount(count)
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName("modifier_demon_king_materialization")
    if modifier  ~= nil then
        local stackCount = caster:GetModifierStackCount("modifier_demon_king_materialization", caster)
        local potentialStackCount  = stackCount + count
        if potentialStackCount > self:GetSpecialValueFor("maximum_stack_count") then 
            potentialStackCount =  self:GetSpecialValueFor("maximum_stack_count") 
        end
        caster:SetModifierStackCount("modifier_demon_king_materialization", caster, potentialStackCount)
    else
        caster:AddNewModifier(caster,self, "modifier_demon_king_materialization", {})
         caster:SetModifierStackCount("modifier_demon_king_materialization", caster, math.min(count, self:GetSpecialValueFor("maximum_stack_count")))
    end
end
function demon_king_materialization:CreateFireGroundSa(position)
   local caster = self:GetCaster()
   local aoe_radius = self:GetSpecialValueFor("sa_aoe_radius")
   local damage_per_sec  = self:GetSpecialValueFor("sa_dps")
   local duration = self:GetSpecialValueFor("sa_duration")
   local tick_time = 0.5
   local ticks_total = duration/tick_time
   local tick_counter = 0
   local effect_ground = ParticleManager:CreateParticle("particles/demon_king_nobunaga/fire_ground.vpcf", PATTACH_WORLDORIGIN, nil)
   ParticleManager:SetParticleControl(effect_ground, 0, position)
   ParticleManager:SetParticleControl(effect_ground, 1, Vector(aoe_radius, 0,0))
   ParticleManager:SetParticleControl(effect_ground, 2, Vector(duration, 0,0))
   ParticleManager:SetParticleControl(effect_ground, 16, position)
   Timers:CreateTimer(0, function()
        if tick_counter >= ticks_total then 
            ParticleManager:DestroyParticle(effect_ground, false)
            ParticleManager:ReleaseParticleIndex(effect_ground)
            return 
        end
        tick_counter = tick_counter + 1
        local targets = FindUnitsInRadius(caster:GetTeamNumber(), position, caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, damage_per_sec*tick_time, DAMAGE_TYPE_MAGICAL, 0, self, false)	
		end
        if (caster:GetAbsOrigin() - position):Length2D() <= aoe_radius then
            self:ProckSpellAmpBonus()
        end

        return tick_time


   end)

end
function demon_king_materialization:ProckSpellAmpBonus()
    local caster = self:GetCaster()
    if caster.demon_king_attribute_2  and caster:IsAlive() then
       caster:AddNewModifier(caster,self, "modifier_demon_king_sa2_spell_amp", {duration = self:GetSpecialValueFor("sa_2_spell_amp_duration")})
    end
end

function demon_king_materialization:GetIntrinsicModifierName()
    return "modifier_demon_king_sa_aura"
end

 
-------------------------------------SA 1 AURA-----------------------------
  
modifier_demon_king_sa_aura = class({})

 

function modifier_demon_king_sa_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH 
end

function modifier_demon_king_sa_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_demon_king_sa_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_demon_king_sa_aura:GetAuraRadius()
	return 500
end

function modifier_demon_king_sa_aura:GetModifierAura()
	return "modifier_demon_king_sa_auramod"
end

function modifier_demon_king_sa_aura:IsHidden()
	return true
end

function modifier_demon_king_sa_aura:RemoveOnDeath()
	return false
end

function modifier_demon_king_sa_aura:IsDebuff()
	return false 
end

function modifier_demon_king_sa_aura:IsAura()
	return true 
end

function modifier_demon_king_sa_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end



-----------------------------------------------SA 1 aura modificator ----------------------------------------


  
modifier_demon_king_sa_auramod = class({})

function modifier_demon_king_sa_auramod:RemoveOnDeath()
	return true
end

function modifier_demon_king_sa_auramod:IsDebuff()
	return true 
end
function modifier_demon_king_sa_auramod:IsHidden()
	return true
end

function modifier_demon_king_sa_auramod:OnTakeDamage(args)
    if IsServer() then 
        if not self:GetCaster().demon_king_attribute_1 then return end
        if args.damage < self:GetAbility():GetSpecialValueFor("sa_1_damage_min")  then return end
        if self:GetCaster().DemonKingSa1Flag then return end
        if args.unit == self:GetCaster() then return end
        
        local caster = self:GetCaster()
        caster:GiveMana(self:GetAbility():GetSpecialValueFor("sa_1_mana"))
        caster.DemonKingSa1Flag = true
        Timers:CreateTimer(self:GetAbility():GetSpecialValueFor("sa_1_cd"), function()
             caster.DemonKingSa1Flag = false
        end)
    end


end
------------------------------------------------ STACKS ------------------------------------------------------
modifier_demon_king_materialization = class({})

 



function modifier_demon_king_materialization:OnCreated()
    local caster = self:GetParent()
    --self:SetStackCount(0)
    self:SaveSaStatParams(caster.demon_king_attribute_4 and 1 or 0)
end

function modifier_demon_king_materialization:SaveSaStatParams(modifierSa4)
    local stackCount = self:GetStackCount()
    local statBonusPerStack = self:GetAbility():GetSpecialValueFor("sa_4_stat_bonus")
    self.StrengthBonus = statBonusPerStack * stackCount * modifierSa4
	self.AgilityBonus = statBonusPerStack * stackCount * modifierSa4
	self.IntelligenceBonus = statBonusPerStack * stackCount * modifierSa4
    if IsServer() then
        CustomNetTables:SetTableValue("sync","demon_king_madness_stats", { str_bonus = self.StrengthBonus,
                                                                agi_bonus = self.AgilityBonus,
                                                                int_bonus = self.IntelligenceBonus})
    end
end

function modifier_demon_king_materialization:OnStackCountChanged(iStackCount)
    self:SaveSaStatParams(self:GetParent().demon_king_attribute_4 and 1 or 0)

end

 
function modifier_demon_king_materialization:GetAttributes()
    return  MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_demon_king_materialization:RemoveOnDeath() return true end 
function modifier_demon_king_materialization:IsDebuff() 	return false end
function modifier_demon_king_materialization:IsHidden() 	return false end
 
function modifier_demon_king_materialization:DeclareFunctions()
	return { 
			 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,

 }
end

function modifier_demon_king_materialization:GetModifierBonusStats_Strength()
	if IsServer() then       
        return self.StrengthBonus
    elseif IsClient() then
        local str_bonus = CustomNetTables:GetTableValue("sync","demon_king_madness_stats").str_bonus
        return str_bonus 
    end
end

function modifier_demon_king_materialization:GetModifierBonusStats_Agility()
	if IsServer() then       
        return self.AgilityBonus
    elseif IsClient() then
        local agi_bonus = CustomNetTables:GetTableValue("sync","demon_king_madness_stats").agi_bonus
        return agi_bonus 
    end
end

function modifier_demon_king_materialization:GetModifierBonusStats_Intellect()
	if IsServer() then       
        return self.IntelligenceBonus
    elseif IsClient() then
        local int_bonus = CustomNetTables:GetTableValue("sync","demon_king_madness_stats").int_bonus
        return int_bonus 
    end
end


-----__-------------------------------------------------SA 2 SPELL AMP BONUS --------------------------

modifier_demon_king_sa2_spell_amp = class({})

 



function modifier_demon_king_sa2_spell_amp:OnCreated()
    local caster = self:GetParent()
    self.SpellAmpBonus = self:GetAbility():GetSpecialValueFor("sa_2_spell_amp")
end



 
function modifier_demon_king_sa2_spell_amp:GetAttributes()
    return  MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_demon_king_sa2_spell_amp:RemoveOnDeath() return true end 
function modifier_demon_king_sa2_spell_amp:IsDebuff() 	return false end

function modifier_demon_king_sa2_spell_amp:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE}
end
function modifier_demon_king_sa2_spell_amp:GetModifierTotalDamageOutgoing_Percentage()
	return self.SpellAmpBonus
end


function modifier_demon_king_sa2_spell_amp:IsHidden() 	return false end