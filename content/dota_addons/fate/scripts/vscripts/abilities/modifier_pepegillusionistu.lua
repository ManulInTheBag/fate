modifier_pepegillusionist = class({})


function modifier_pepegillusionist:CheckState()
local state = {[MODIFIER_STATE_UNSELECTABLE] = true,  [MODIFIER_STATE_NO_HEALTH_BAR] = true, [MODIFIER_STATE_INVULNERABLE] = true}
return state
end

function modifier_pepegillusionist:DeclareFunctions()
local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
                 MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
                 MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
	}
        
	return funcs
end

function modifier_pepegillusionist:OnCreated()
self.bonus = 500
self.reduction = 250
self.attack_sound = "pepeg.spank2"
end

function modifier_pepegillusionist:GetModifierBaseAttackTimeConstant()
    return 0.3
end

function modifier_pepegillusionist:GetModifierAttackSpeedBonus_Constant()
return self.bonus
end

function modifier_pepegillusionist:GetModifierDamageOutgoing_Percentage()
return self.reduction
end

function modifier_pepegillusionist:GetModifierProvidesFOWVision()
return 1
end

function modifier_pepegillusionist:GetAttackSound()
return self.attack_sound
end

function modifier_pepegillusionist:OnDestroy()
if IsServer() then
self:GetParent():RemoveSelf()
end
end

