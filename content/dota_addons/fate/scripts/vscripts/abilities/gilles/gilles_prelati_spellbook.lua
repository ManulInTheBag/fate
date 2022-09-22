gilles_prelati_spellbook = class({})

LinkLuaModifier("modifier_prelati_regen", "abilities/gilles/modifiers/modifier_prelati_regen", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_selfish_self_invul", "abilities/gilles/modifiers/modifier_selfish_self_invul", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_prelati_regen_block", "abilities/gilles/modifiers/modifier_prelati_regen_block", LUA_MODIFIER_MOTION_NONE)

function gilles_prelati_spellbook:IsHiddenAbilityCastable()
    return true
end

function gilles_prelati_spellbook:OnSpellStart()
	local caster = self:GetCaster()

	caster:EmitSound("Hero_Warlock.ShadowWord")
	caster:AddNewModifier(caster, self, "modifier_selfish_self_invul", { Duration = self:GetSpecialValueFor("duration") })
    caster:AddNewModifier(caster, self, "modifier_prelati_regen_block", { Duration = self:GetSpecialValueFor("block_duration") })
	
	self.ShieldFX = ParticleManager:CreateParticle("particles/custom/gilles_prelati_shield_aura.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(self.ShieldFX, 0, caster:GetAbsOrigin())
end

function gilles_prelati_spellbook:OnChannelFinish(bInterrupted)
    local caster = self:GetCaster()
    
    caster:StopSound("Hero_Warlock.ShadowWord")
    caster:RemoveModifierByName("modifier_selfish_self_invul")

    ParticleManager:DestroyParticle( self.ShieldFX, false )
    ParticleManager:ReleaseParticleIndex( self.ShieldFX )
end

function gilles_prelati_spellbook:GetIntrinsicModifierName()
    return "modifier_prelati_regen"
end