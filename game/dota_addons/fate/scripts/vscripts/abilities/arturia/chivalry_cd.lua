chivalry_cd = class({})

LinkLuaModifier("modifier_chivalry_attribute","abilities/arturia/modifiers/modifier_chivalry_attribute.lua",LUA_MODIFIER_MOTION_NONE)

function chivalry_cd:GetIntrinsicModifierName()
    return "modifier_chivalry_attribute"
end