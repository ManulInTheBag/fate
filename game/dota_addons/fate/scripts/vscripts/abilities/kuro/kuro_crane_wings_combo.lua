kuro_crane_wings_combo = class({})

LinkLuaModifier("modifier_triple_linked_cooldown", "abilities/kuro/modifiers/modifier_triple_linked_cooldown", LUA_MODIFIER_MOTION_NONE)

function kuro_crane_wings_combo:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base"  then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function kuro_crane_wings_combo:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Cannot_Target_Wards"	
	else
		return "#Invalid_Target"
	end
end

function kuro_crane_wings_combo:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local ability = self

	local crane_ability = caster:FindAbilityByName("kuro_crane_wings")
	local damage = crane_ability:GetDamage()

	target:AddNewModifier(caster, target, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", self:GetSpecialValueFor("stun_duration"))
	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()	

	StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1})
	EmitGlobalSound("chloe_crane_4")

	caster:RemoveModifierByName("modifier_kuro_crane_tracker")
	caster:AddNewModifier(caster, self, "modifier_triple_linked_cooldown", {Duration = self:GetCooldown(1)})

	local masterabil = caster.MasterUnit2:FindAbilityByName("kuro_crane_wings_combo")

	masterabil:EndCooldown()
	masterabil:StartCooldown(self:GetCooldown(1))

	self:FireExtraSwords(target)

	Timers:CreateTimer(0.6, function()		
		if caster:IsAlive() then
			caster:SetAbsOrigin(target:GetAbsOrigin()-(caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()*130)
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			caster:SetForwardVector(target:GetForwardVector())

			StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK_EVENT, rate = 2})			
		end
	end)

	Timers:CreateTimer(1.0, function()		
		if caster:IsAlive() then
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(200, 200, 0), target:GetAbsOrigin() + Vector(-200, -200, 0))
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(250, 250, 25), target:GetAbsOrigin() + Vector(-250, -250, 25))
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(300, 300, 50), target:GetAbsOrigin() + Vector(-300, -300, 50))
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(200, -200, 0), target:GetAbsOrigin() + Vector(-200, 200, 0))
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(250, -250, 25), target:GetAbsOrigin() + Vector(-250, 250, 25))	
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(300, -300, 50), target:GetAbsOrigin() + Vector(-300, 300, 50))	

			DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			caster:EmitSound("Hero_Centaur.DoubleEdge")
		end
	end)
end

function kuro_crane_wings_combo:FireExtraSwords(target)
	local caster = self:GetCaster()
	local spawn_location = caster:GetAbsOrigin()

	for i = 1, 4 do
		targetPoint = spawn_location + RandomVector(125)
		local dummy = CreateUnitByName("dummy_unit", targetPoint, false, caster, caster, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

		Timers:CreateTimer(2, function()
			dummy:RemoveSelf()
		end)

		local projectileSpeed = (targetPoint - target:GetAbsOrigin()):Length2D() / 0.95
		local info = {
			Target = target, 
			Source = dummy,
			Ability = self,
			EffectName = "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf",
			vSpawnOrigin = dummy:GetAbsOrigin(),
			iMoveSpeed = projectileSpeed,
			bDodgeable = false
		}

		ProjectileManager:CreateTrackingProjectile(info) 
	end
end

function kuro_crane_wings_combo:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local kanshou_ability = caster:FindAbilityByName("kuro_kanshou_byakuya")
	local damage = kanshou_ability:GetDamage()

	hTarget:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end