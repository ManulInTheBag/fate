gilgamesh_combo_final_hour = class({})

LinkLuaModifier("modifier_enkidu_hold", "abilities/gilgamesh/modifiers/modifier_enkidu_hold", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilgamesh_combo_active", "abilities/gilgamesh/modifiers/modifier_gilgamesh_combo_active", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilgamesh_final_hour_cooldown", "abilities/gilgamesh/modifiers/modifier_gilgamesh_final_hour_cooldown", LUA_MODIFIER_MOTION_NONE)

function gilgamesh_combo_final_hour:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
	
	return filter
end

function gilgamesh_combo_final_hour:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function gilgamesh_combo_final_hour:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local masterCombo = caster.MasterUnit2:FindAbilityByName("gilgamesh_combo_proxy")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))

	local maxea = caster:FindAbilityByName("gilgamesh_max_enuma_elish")
	maxea:EndCooldown()
	maxea:StartCooldown(self:GetCooldown(1))

	caster:AddNewModifier(caster, self, "modifier_gilgamesh_final_hour_cooldown", {Duration = self:GetCooldown(1)})
	
	local stopOrder = {
 		UnitIndex = target:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_STOP
 	}

 	caster:EmitSound("Gilgamesh.Enkidu") 
 	EmitGlobalSound("Gilgamesh_Alt_Combo_" .. math.random(1,3))
 	ExecuteOrderFromTable(stopOrder)  	

 	local gramDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	gramDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	gramDummy:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0, 0, 250))

 	target:AddNewModifier(caster, self, "modifier_enkidu_hold", { Duration = 4.1 })
 	caster:AddNewModifier(caster, self, "modifier_gilgamesh_combo_active", { Duration = 4.1 })
 	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 3.5)

	local info = {
		Target = target,
		Source = gramDummy, 
		Ability = self,
		EffectName = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.vpcf",
		vSpawnOrigin = gramDummy:GetAbsOrigin(),
		iMoveSpeed = 2000
	}	

	local remaining_swords = self:GetSpecialValueFor("num_swords")

 	Timers:CreateTimer(1.9, function()
		if remaining_swords <= 0 or not caster:IsAlive() or target:IsNull() or not target:IsAlive() then return end 

		gramDummy:SetAbsOrigin(target:GetAbsOrigin() + RandomVector(450))
		info.vSpawnOrigin = gramDummy:GetAbsOrigin()

		ProjectileManager:CreateTrackingProjectile(info) 

		if remaining_swords % 5 < 1 then
			caster:EmitSound("Hero_SkywrathMage.ConcussiveShot.Cast")
		end		

		remaining_swords = remaining_swords - 1

		return 0.04
	end)
end

function gilgamesh_combo_final_hour:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
	if hTarget == nil then return end

	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end