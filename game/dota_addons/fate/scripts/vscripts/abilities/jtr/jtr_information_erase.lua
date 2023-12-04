jtr_information_erase = class({})

function jtr_information_erase:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function jtr_information_erase:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function jtr_information_erase:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

	local rCooldown = 0
	
	if not IsSpellBlocked(target) then
		target:AddNewModifier(caster, self, "modifier_silence", {duration = 3})
		--[[ for i=0, 5 do 
			local ability = target:GetAbilityByIndex(i)
			if ability ~= nil then
				rCooldown = ability:GetCooldownTimeRemaining()
				ability:EndCooldown()
				ability:StartCooldown(rCooldown + 5)
			else 
				break
			end
		end]]
		--ApplyStrongDispel(target)
		--target:RemoveModifierByName("modifier_a_scroll")
		--target:RemoveModifierByName("modifier_heart_of_harmony")
	end
end