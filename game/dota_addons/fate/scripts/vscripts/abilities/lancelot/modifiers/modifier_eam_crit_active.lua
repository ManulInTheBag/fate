LinkLuaModifier("modifier_lancelot_eternal_procked", "abilities/lancelot/modifiers/modifier_eam_crit_active", LUA_MODIFIER_MOTION_NONE)

modifier_eam_crit_active = class({})

function modifier_eam_crit_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_eam_crit_active:GetModifierPreAttack_CriticalStrike()
	return 200
end

function modifier_eam_crit_active:IsHidden()
	return false 
end

function modifier_eam_crit_active:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_eam_crit_active:OnLinkenProcked()
	local parent = self:GetParent()
	parent:AddNewModifier(parent, self:GetAbility(), "modifier_lancelot_eternal_procked", {duration = 0.5} )
end

modifier_lancelot_eternal_procked = class({})

function modifier_lancelot_eternal_procked:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, }
							
end



function modifier_lancelot_eternal_procked:IsHidden() return false end
function modifier_lancelot_eternal_procked:RemoveOnDeath() return true end
function modifier_lancelot_eternal_procked:IsDebuff() return false end


function modifier_lancelot_eternal_procked:GetModifierIncomingDamage_Percentage() 
	return -self:GetAbility():GetSpecialValueFor("proc_dmg_reduct")
end