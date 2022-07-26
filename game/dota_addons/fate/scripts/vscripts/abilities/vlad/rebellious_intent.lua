vlad_rebellious_intent = class({})
LinkLuaModifier("modifier_rebellious_intent", "abilities/vlad/modifier_rebellious_intent", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_q_used", "abilities/vlad/modifier_q_used", LUA_MODIFIER_MOTION_NONE)

if not IsServer() then
  return
end

function vlad_rebellious_intent:GetManaCost(iLevel)
	--[[local caster = self:GetCaster()
	local condition_free_mana = 40
	
	if caster:GetHealthPercent() <= condition_free_mana then
		return 0
	else
		return 100
	end]]

	return 0
end

function vlad_rebellious_intent:OnToggle()
  local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_q_used",{duration = 5}) -- both toggle and untoggle count toward combo

	if not self:GetToggleState() and caster:HasModifier("modifier_rebellious_intent") then		
		caster:RemoveModifierByName("modifier_rebellious_intent")
	else
		caster:AddNewModifier(caster, self, "modifier_rebellious_intent",{})
	end
end

function vlad_rebellious_intent:ResetToggleOnRespawn()
  return true
end
function vlad_rebellious_intent:GetCastAnimation()
  return nil
end
function vlad_rebellious_intent:GetAbilityTextureName()
  return "shadow_demon_demonic_purge"
end
