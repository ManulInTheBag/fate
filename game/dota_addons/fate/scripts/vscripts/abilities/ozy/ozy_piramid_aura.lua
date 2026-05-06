ozy_piramid_aura = class({})
modifier_ozy_piramid_passive = class({})
modifier_ozy_piramid_passive_aura = class({})

LinkLuaModifier("modifier_ozy_piramid_passive", "abilities/ozy/ozy_piramid_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_piramid_passive_aura", "abilities/ozy/ozy_piramid_aura", LUA_MODIFIER_MOTION_NONE)

-- Passive
function ozy_piramid_aura:GetIntrinsicModifierName()
	return "modifier_ozy_piramid_passive_aura"
end

function ozy_piramid_aura:OnSpellStart()
	local caster = self:GetCaster()
	if caster.Ozy:GetStrength() >= 29.1 and caster.Ozy:GetAgility() >= 29.1 and caster.Ozy:GetIntellect() >= 29.1 then      
			if not caster.Ozy:HasModifier("modifier_ozy_combo_cd") then --and caster:FindAbilityByName("ozy_piramid_beam"):IsCooldownReady()  then
				if caster:GetAbilityByIndex(5):GetName() ~= "ozy_combo"  then
					caster:SwapAbilities("ozy_combo", "ozy_piramid_beam", true, false)
				end

				Timers:CreateTimer('ozy_combo_trigger_window',{
					endTime = 2,
					callback = function()
					if caster:GetAbilityByIndex(5):GetName() ~= "ozy_piramid_beam"  then
						caster:SwapAbilities("ozy_combo", "ozy_piramid_beam", false, true)
					end
				end
				})
	
			end
		end

end


function modifier_ozy_piramid_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT }
end



function modifier_ozy_piramid_passive:GetModifierConstantHealthRegen()	
	if self:GetParent():GetUnitName() ~= "npc_dota_hero_phoenix" then 
		return self:GetAbility():GetSpecialValueFor("bonus_regen")
	else
		return self:GetAbility():GetSpecialValueFor("bonus_regen") * 3
	end
end

function modifier_ozy_piramid_passive:GetModifierMagicalResistanceBonus()
	if self:GetParent():GetUnitName() ~= "npc_dota_hero_phoenix" then 
		return self:GetAbility():GetSpecialValueFor("bonus_mr")
	else
		return self:GetAbility():GetSpecialValueFor("bonus_mr") * 3
	end
end

function modifier_ozy_piramid_passive:IsHidden()
	return false
end

function modifier_ozy_piramid_passive:IsDebuff()
    return false
end

function modifier_ozy_piramid_passive:RemoveOnDeath()
    return true
end

function modifier_ozy_piramid_passive:GetEffectName()
	return  "particles/ozy/piramid/ozy_piramid_passive_effect.vpcf" 
end

function modifier_ozy_piramid_passive:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end


function modifier_ozy_piramid_passive_aura:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_ozy_piramid_passive_aura:DeclareFunctions()
	local func = {
					MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,

				}
	return func
end

-- Aura
function modifier_ozy_piramid_passive_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ozy_piramid_passive_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

function modifier_ozy_piramid_passive_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_ozy_piramid_passive_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_ozy_piramid_passive_aura:GetModifierAura()
	return "modifier_ozy_piramid_passive"
end

function modifier_ozy_piramid_passive_aura:IsHidden()
	return true 
end

function modifier_ozy_piramid_passive_aura:IsPermanent()
	return false
end

function modifier_ozy_piramid_passive_aura:IsDebuff()
	return false 
end

function modifier_ozy_piramid_passive_aura:IsAura()
	return true 
end
function modifier_ozy_piramid_passive_aura:GetAuraEntityReject(hEntity)
    if IsServer() then
        return hEntity == self:GetParent()
    end
end