true_assassin_ambush = class({})

LinkLuaModifier("modifier_ambush_invis", "abilities/true_assassin/modifiers/modifier_ambush_invis", LUA_MODIFIER_MOTION_NONE)

function true_assassin_ambush:OnSpellStart()
	local ability = self
	local caster = ability:GetCaster()	

	caster:EmitSound("Hero_BountyHunter.WindWalk")

	if caster.IsPCImproved then
		caster:AddNewModifier(caster, self, "modifier_ambush_invis", {fadeDelay = self:GetSpecialValueFor("fade_delay"),
														    	fixedMoveSpeed = self:GetSpecialValueFor("attribute_movement_speed"),
													    		duration = self:GetSpecialValueFor("duration"),
													    		bonusDamage = self:GetSpecialValueFor("damage")})
	else
	    caster:AddNewModifier(caster, self, "modifier_ambush_invis", {fadeDelay = self:GetSpecialValueFor("fade_delay"),
														    	fixedMoveSpeed = self:GetSpecialValueFor("attribute_movement_speed"),
													    		duration = self:GetSpecialValueFor("duration"),
													    		bonusDamage = self:GetSpecialValueFor("damage")})
	end

	self:CheckCombo()
end

function true_assassin_ambush:OnOwnerDied()
	local caster = self:GetCaster()

	caster.IsInMarble = false
end

function true_assassin_ambush:CheckCombo()
	local caster = self:GetCaster()
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("true_assassin_combo"):IsCooldownReady() then
			caster:SwapAbilities("true_assassin_ambush", "true_assassin_combo", false, true)
				Timers:CreateTimer({
					endTime = 4,
					callback = function()
					caster:SwapAbilities("true_assassin_ambush", "true_assassin_combo", true, false)
				end
				})
		end

		--[[if ability == caster:FindAbilityByName("true_assassin_self_modification") then
			AmbushUsed = true
			Timers:CreateTimer({
				endTime = 5,
				callback = function()
				AmbushUsed = false
			end
			})
		elseif ability == caster:FindAbilityByName("true_assassin_ambush") and caster:FindAbilityByName("true_assassin_combo"):IsCooldownReady()  then
			if AmbushUsed == true then 
				caster:SwapAbilities("true_assassin_ambush", "true_assassin_combo", false, true)
				Timers:CreateTimer({
					endTime = 4,
					callback = function()
					caster:SwapAbilities("true_assassin_ambush", "true_assassin_combo", true, false)
				end
				})
			end
		end]]
	end
end