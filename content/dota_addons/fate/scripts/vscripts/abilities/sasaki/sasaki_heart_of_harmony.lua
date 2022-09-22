sasaki_heart_of_harmony = class({})
modifier_heart_of_harmony_disarm = class({})

LinkLuaModifier("modifier_heart_of_harmony_disarm", "abilities/sasaki/sasaki_heart_of_harmony", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heart_of_harmony", "abilities/sasaki/modifiers/modifier_heart_of_harmony", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_exhausted", "abilities/sasaki/modifiers/modifier_exhausted", LUA_MODIFIER_MOTION_NONE)


function sasaki_heart_of_harmony:OnSpellStart()
	local caster = self:GetCaster()	
	local stun_mana = self:GetSpecialValueFor("stun_threshold")

	if caster.IsVitrificationAcquired then
		stun_mana = stun_mana - 20
	end

	caster:SetMana(0)

	caster:EmitSound("Hero_Abaddon.AphoticShield.Cast")
	caster:AddNewModifier(caster, self, "modifier_heart_of_harmony", { Duration = self:GetSpecialValueFor("duration"),
																	   DamageReduc = self:GetSpecialValueFor("damage_reduc"),
																	   ManaRegenBonus = self:GetSpecialValueFor("focus_regen"),
																	   SlashCount = self:GetSpecialValueFor("slash_count"),
																	   Threshold = self:GetSpecialValueFor("threshold"),
																	   StunDuration = self:GetSpecialValueFor("stun_duration"),
																	   ManaThreshold = stun_mana })

	caster:AddNewModifier(caster, self, "modifier_heart_of_harmony_disarm", { Duration = self:GetSpecialValueFor("duration") })
end

function modifier_heart_of_harmony_disarm:IsHidden()
	return true 
end

function modifier_heart_of_harmony_disarm:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true }
end