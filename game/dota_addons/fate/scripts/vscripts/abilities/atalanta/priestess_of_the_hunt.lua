atalanta_priestess_of_the_hunt = class({})
LinkLuaModifier("modifier_priestess_of_the_hunt", "abilities/atalanta/modifier_priestess_of_the_hunt", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_priestess_of_the_hunt_progress", "abilities/atalanta/modifier_priestess_of_the_hunt_progress", LUA_MODIFIER_MOTION_NONE)

function atalanta_priestess_of_the_hunt:GetManaCost()
	local caster = self:GetCaster()

	local count = caster:GetModifierStackCount("modifier_priestess_of_the_hunt", caster)
	local cost = self:GetSpecialValueFor("cost")
	local arrows = self:GetSpecialValueFor("arrows")

	return (arrows-count)*cost
end

function atalanta_priestess_of_the_hunt:OnUpgrade()
    local hero = self:GetCaster()
    if not hero:HasModifier("modifier_priestess_of_the_hunt_progress") then
        hero:AddNewModifier(hero, self, "modifier_priestess_of_the_hunt_progress", {})
    end
end
function atalanta_priestess_of_the_hunt:OnSpellStart()
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_priestess_of_the_hunt")

	local count = modifier:GetStackCount()
	local cost = self:GetSpecialValueFor("cost")
	local arrows = self:GetSpecialValueFor("arrows")
	--[[if caster:GetMana()<(arrows-count)*cost then
		return
	end
	caster:SpendMana((arrows-count)*cost, self)]]
	modifier:SetStackCount(arrows)
end
function atalanta_priestess_of_the_hunt:GetIntrinsicModifierName()
    return "modifier_priestess_of_the_hunt"
end

function atalanta_priestess_of_the_hunt:GetAbilityTextureName()
    return "custom/atalanta_priestess_of_the_hunt"
end