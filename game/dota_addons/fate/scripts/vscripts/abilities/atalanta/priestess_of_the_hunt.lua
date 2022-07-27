atalanta_priestess_of_the_hunt = class({})
LinkLuaModifier("modifier_priestess_of_the_hunt", "abilities/atalanta/modifier_priestess_of_the_hunt", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_priestess_of_the_hunt_progress", "abilities/atalanta/modifier_priestess_of_the_hunt_progress", LUA_MODIFIER_MOTION_NONE)

function atalanta_priestess_of_the_hunt:OnUpgrade()
    local hero = self:GetCaster()
    if not hero:HasModifier("modifier_priestess_of_the_hunt_progress") then
        hero:AddNewModifier(hero, self, "modifier_priestess_of_the_hunt_progress", {})
    end
end

 
 

function atalanta_priestess_of_the_hunt:OnSpellStart()
    self:RefundManaCost()
    local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_priestess_of_the_hunt")

	local count = modifier:GetStackCount()
	local cost = self:GetSpecialValueFor("cost")
	if caster:GetMana()<(10-count)*cost then
		return
	end
	caster:SpendMana((10-count)*cost, self)
	modifier:SetStackCount(10)
end
 
function atalanta_priestess_of_the_hunt:GetIntrinsicModifierName()
    return "modifier_priestess_of_the_hunt"
end

function atalanta_priestess_of_the_hunt:GetAbilityTextureName()
    return "custom/atalanta_priestess_of_the_hunt"
end


function atalanta_priestess_of_the_hunt:GetManaCost(iLevel)
    local hCaster      = self:GetCaster()
    local iArrowsNow = hCaster:GetModifierStackCount("modifier_priestess_of_the_hunt", hCaster)
    local iArrowCost = self:GetSpecialValueFor("cost")
 
    local iMaxArrows = self:GetSpecialValueFor("arrows")
 

    local iNeedArrows = iMaxArrows - iArrowsNow

 

    return iNeedArrows * iArrowCost
end
