jtr_murderer_mist = class({})

LinkLuaModifier("modifier_murderer_mist_aura", "abilities/jtr/modifiers/modifier_murderer_mist_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_murderer_mist_invis", "abilities/jtr/modifiers/modifier_murderer_mist_invis", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_murderer_mist_in", "abilities/jtr/modifiers/modifier_murderer_mist_in", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_murderer_mist_invis_cd", "abilities/jtr/modifiers/modifier_murderer_mist_invis_cd", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_murderer_mist_armor", "abilities/jtr/modifiers/modifier_murderer_mist_armor", LUA_MODIFIER_MOTION_NONE)

function jtr_murderer_mist:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function jtr_murderer_mist:GetCastRange()
	return self:GetSpecialValueFor("radius")
end

function jtr_murderer_mist:GetCastPoint()
	return 0.4
end

function jtr_murderer_mist:OnSpellStart()
	local caster = self:GetCaster()

	if self.AuraDummy ~= nil and not self.AuraDummy:IsNull() then 
		self.AuraDummy:RemoveSelf()
	end

	self.AuraDummy = CreateUnitByName("sight_dummy_unit", self:GetCursorPosition(), false, nil, nil, caster:GetTeamNumber())
	self.AuraDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.AuraDummy:SetDayTimeVisionRange(0)
	self.AuraDummy:SetNightTimeVisionRange(0)

	self.AuraDummy:EmitSound("jtr_smoke")
	caster:EmitSound("jtr_invis")
	caster:EmitSound("jtr_laugh_1")
	self:CheckCombo()


	--[[local enemy = PickRandomEnemy(caster)
	if enemy ~= nil then
		SpawnVisionDummy(enemy, caster:GetAbsOrigin(), 25, 5, false)
	end	]]

	self.AuraDummy:AddNewModifier(caster, self, "modifier_murderer_mist_aura", { Duration = self:GetSpecialValueFor("duration"), --aura for aura modifiers
																				 AuraRadius = self:GetSpecialValueFor("radius")})

	self.AuraDummy:AddNewModifier(caster, self, "modifier_kill", { Duration = self:GetSpecialValueFor("duration") })

	caster:AddNewModifier(caster, self, "modifier_murderer_mist_invis", { Duration = self:GetSpecialValueFor("duration"), --now only for vision, previously for invisibility
																		  SlowPct = self:GetSpecialValueFor("slow_pct"),
																		  AgiDmg = 0,
																		  BaseAgiDmg = 0
																		})
end

function jtr_murderer_mist:CheckCombo()
	local caster = self:GetCaster()
	local ability = self
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
    	if caster:FindAbilityByName("jtr_whitechapel_murderer"):IsCooldownReady() then
    		caster:AddNewModifier(caster, self, "modifier_whitechapel_window", { Duration = 4 })
        end
    end
end