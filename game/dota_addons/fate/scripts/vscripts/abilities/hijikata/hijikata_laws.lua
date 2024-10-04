hijikata_laws = class({})
LinkLuaModifier("modifier_hijikata_laws", "abilities/hijikata/hijikata_laws", LUA_MODIFIER_MOTION_NONE)


function hijikata_laws:GetIntrinsicModifierName()
    return "modifier_hijikata_laws"
end

function hijikata_laws:OnSpellStart()
	local caster = self:GetCaster()
    if not self.used then
        caster:FindModifierByName("modifier_hijikata_laws"):IncrementStackCount()
    end
    self.used = true

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
    self.distance_restriction = false
    self.duel_restriction = false
    self.kill_restriction = false
end

function modifier_hijikata_laws:OnCreated()
    self:SetStackCount(0)
    self:GetAbility().used = false
    self.distance_restriction = false
    self.duel_restriction = false
    self.kill_restriction = false
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
        end
    end
end

function modifier_hijikata_laws:OnStackCountChanged(stacks)
    if stacks == 5 then return end
    if stacks == 4 then
        if IsServer() then
            giveUnitDataDrivenModifier(self:GetParent(),self:GetParent() , "stunned", self:GetAbility():GetSpecialValueFor("stun_duration"))
            Timers:CreateTimer(3, function()
                self:SetStackCount(0)
                self:GetAbility().used = false
            end)
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
                MODIFIER_EVENT_ON_RESPAWN }
end

function modifier_hijikata_laws:GetModifierPreAttack_BonusDamage()
	return (self:GetAbility():GetSpecialValueFor("damage_per_stack") * self:GetStackCount())
end
