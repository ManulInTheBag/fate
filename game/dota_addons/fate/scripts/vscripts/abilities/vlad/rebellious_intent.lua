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
	if caster.BloodletterAcquired and not self.BloodLetterActivated and  self:GetToggleState() then
		if caster:GetHealth()/caster:GetMaxHealth() <= 0.6 then
		
		  local saDamage = caster.MasterUnit2:FindAbilityByName("vlad_attribute_bloodletter"):GetSpecialValueFor("damage")
		  local saBleed = caster.MasterUnit2:FindAbilityByName("vlad_attribute_bloodletter"):GetSpecialValueFor("bleed")
		  local explosionFx = ParticleManager:CreateParticle("particles/vlad/vlad_impale_fort.vpcf", PATTACH_WORLDORIGIN, nil)
		  ParticleManager:SetParticleControl(explosionFx, 3, caster:GetAbsOrigin())
		  ParticleManager:ReleaseParticleIndex(explosionFx)
		  caster:EmitSound("Hero_Lycan.Attack")
		  local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 450, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
			for k,v in pairs(targets) do
			  DoDamage(caster, v, saDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			  caster:AddBleedStack(v, false, saBleed)
			  giveUnitDataDrivenModifier(caster, v, "rooted", 0.5)
	  
			end
		  self.BloodLetterActivated = true
		  Timers:CreateTimer(2, function()
			self.BloodLetterActivated = false
		
		  end)
		end
	  end
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
