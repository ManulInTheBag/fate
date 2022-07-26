modifier_pepevision = class({})

function modifier_pepevision:DeclareFunctions()
 local func = { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION, }
    return func
end
function modifier_pepevision:GetModifierProvidesFOWVision()
return 1
end


