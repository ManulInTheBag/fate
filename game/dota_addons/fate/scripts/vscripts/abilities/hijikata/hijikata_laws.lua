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
end

function modifier_hijikata_laws:OnCreated()
    self:SetStackCount(0)
end
function modifier_hijikata_laws:OnStackCountChanged(stacks)
    if stacks == 5 then return end
    if stacks == 4 then
        giveUnitDataDrivenModifier(self:GetParent(),self:GetParent() , "stunned", self:GetAbility():GetSpecialValueFor("stun_duration"))
        Timers:CreateTimer(3, function()
            self:SetStackCount(0)
            self:GetAbility().used = false
        end)
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
   	return {	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_hijikata_laws:GetModifierPreAttack_BonusDamage()
	return (self:GetAbility():GetSpecialValueFor("damage_per_stack") * self:GetStackCount())
end
