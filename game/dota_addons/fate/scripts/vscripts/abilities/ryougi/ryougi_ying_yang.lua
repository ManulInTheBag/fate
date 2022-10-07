LinkLuaModifier("modifier_ryougi_ying_yang_texture", "abilities/ryougi/ryougi_ying_yang", LUA_MODIFIER_MOTION_NONE)

ryougi_ying_yang = class({})

local ying = {
    "ryougi_knife_fan",
    "ryougi_glass_moon",
    "ryougi_double_belfry",
    "ryougi_backflip",
    "ryougi_ying_yang",
    "ryougi_mystic_eyes",
    "attribute_bonus_custom"
}

local yang = {
    "ryougi_knife_throw",
    "ryougi_avidya_moon",
    "ryougi_kimono",
    "ryougi_backflip",
    "ryougi_ying_yang",
    "ryougi_mystic_eyes",
    "attribute_bonus_custom"
}

function ryougi_ying_yang:GetAbilityTextureName()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_ryougi_ying_yang_texture") then
		return "custom/ryougi/ryougi_yang"
	else
		return "custom/ryougi/ryougi_ying"
	end
end

function ryougi_ying_yang:OnSpellStart()
    local caster = self:GetCaster()
    
    if not self.form then
    	self.form = 1
    end
    
    caster:RemoveModifierByName("modifier_ryougi_double_belfry_tracker")
    caster:RemoveModifierByName("modifier_ryougi_combo_window")

    if self.form == 1 then
    	UpdateAbilityLayout(caster, yang)
    	self.form = 2
    	caster:AddNewModifier(caster, self, "modifier_ryougi_ying_yang_texture", {})
    else
    	UpdateAbilityLayout(caster, ying)
    	self.form = 1
    	caster:RemoveModifierByName("modifier_ryougi_ying_yang_texture")
    end
end

modifier_ryougi_ying_yang_texture = class({})

function modifier_ryougi_ying_yang_texture:IsHidden() return true end
function modifier_ryougi_ying_yang_texture:IsDebuff() return false end
function modifier_ryougi_ying_yang_texture:RemoveOnDeath() return false end
function modifier_ryougi_ying_yang_texture:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end