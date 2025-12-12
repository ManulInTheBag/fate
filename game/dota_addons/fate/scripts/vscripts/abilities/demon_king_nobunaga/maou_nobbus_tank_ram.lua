maou_nobbus_tank_ram = class({})

modifier_maou_nobbus_tank_ram = class({})


LinkLuaModifier("modifier_maou_nobbus_tank_ram", "abilities/demon_king_nobunaga/maou_nobbus_tank_ram", LUA_MODIFIER_MOTION_NONE)
function maou_nobbus_tank_ram:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("nobu_tank_2")
	caster:AddNewModifier(caster, self, "modifier_maou_nobbus_tank_ram", {duration = self:GetSpecialValueFor("duration")})

end


function modifier_maou_nobbus_tank_ram:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE  }
end





function modifier_maou_nobbus_tank_ram:GetModifierMoveSpeed_Absolute()
	return self:GetAbility():GetSpecialValueFor("speed_const")
end

function modifier_maou_nobbus_tank_ram:IsHidden()
	return false
end

function modifier_maou_nobbus_tank_ram:IsDebuff()
    return false
end

function modifier_maou_nobbus_tank_ram:RemoveOnDeath()
    return true
end
