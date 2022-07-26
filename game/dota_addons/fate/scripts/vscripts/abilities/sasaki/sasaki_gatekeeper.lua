sasaki_gatekeeper = class({})

LinkLuaModifier("modifier_gatekeeper", "abilities/sasaki/modifiers/modifier_gatekeeper", LUA_MODIFIER_MOTION_NONE)

function sasaki_gatekeeper:GetAOERadius()
	return self:GetSpecialValueFor("leash_range")
end

function sasaki_gatekeeper:OnSpellStart()
	local caster = self:GetCaster()

	caster:EmitSound("Hero_TemplarAssassin.Refraction")
	caster:RemoveModifierByName("modifier_gatekeeper")		

	local radius = self:GetSpecialValueFor("leash_range")
	
	--if caster.IsEyeOfSerenityAcquired then caster.IsEyeOfSerenityActive = true end

	caster:AddNewModifier(caster, self, "modifier_gatekeeper", { Anchor = caster:GetAbsOrigin(),
																 LeashDistance = self:GetSpecialValueFor("leash_range"),
																 BonusAttack = self:GetSpecialValueFor("bonus_damage"),
																 Duration = self:GetSpecialValueFor("duration")--,
																 --CircleDummy = gkdummy:GetEntityHandle(),
																 --CircleFx = circleFxIndex
	})

	if caster.IsQuickdrawAcquired and not caster:HasModifier("modifier_quickdraw_cooldown") then 
		caster:SwapAbilities("sasaki_gatekeeper", "sasaki_quickdraw", false, true) 
		Timers:CreateTimer(5, function()
			    if (caster:GetAbilityByIndex(0):GetName()~="sasaki_gatekeeper") then
			        caster:SwapAbilities("sasaki_gatekeeper", "sasaki_quickdraw", true, false) 
		    	end
			end)
	end

	self:CheckCombo()
end

function sasaki_gatekeeper:CheckCombo()
	local caster = self:GetCaster()
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 
	and caster:FindAbilityByName("sasaki_heart_of_harmony"):IsCooldownReady() 
	and caster:FindAbilityByName("false_assassin_tsubame_mai"):IsCooldownReady()
	and (caster:GetAbilityByIndex(1):GetName()~="false_assassin_tsubame_mai") then
		caster:SwapAbilities("sasaki_heart_of_harmony", "false_assassin_tsubame_mai", false, true) 

		Timers:CreateTimer(3.0, function()
			local ability = caster:GetAbilityByIndex(1)
			if (ability:GetName() ~= "sasaki_heart_of_harmony") or not caster:IsAlive() then
				caster:SwapAbilities("sasaki_heart_of_harmony", "false_assassin_tsubame_mai", true, false) 
			end				
		end)
	end
end