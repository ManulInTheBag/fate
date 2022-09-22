gilgamesh_gram = class({})

function gilgamesh_gram:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
	
	return filter
end

function gilgamesh_gram:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function gilgamesh_gram:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local gramDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	gramDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	gramDummy:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0, 0, 250))

	local info = {
		Target = target,
		Source = gramDummy, 
		Ability = self,
		EffectName = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.vpcf",
		vSpawnOrigin = gramDummy:GetAbsOrigin(),
		iMoveSpeed = 2000
	}	

	local target_origin = target:GetAbsOrigin()
	local right_vec = caster:GetForwardVector()
	right_vec = Vector(right_vec.y, -right_vec.x, 0)

	local extra_swords = self:GetSpecialValueFor("extra_swords")
	local radius = self:GetSpecialValueFor("radius")

	if extra_swords > 0 then
		gramDummy:SetAbsOrigin(gramDummy:GetAbsOrigin() + right_vec * -80)
		info.vSpawnOrigin = gramDummy:GetAbsOrigin()
	end

	ProjectileManager:CreateTrackingProjectile(info) 
	caster:EmitSound("Hero_SkywrathMage.ConcussiveShot.Cast")

	Timers:CreateTimer(0.2, function()
		if extra_swords <= 0 or not caster:IsAlive() then return end 
		local targets = FindUnitsInRadius(caster:GetTeam(), target_origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		
		if #targets >= 1 then
			info.Target = targets[1]
			gramDummy:SetAbsOrigin(gramDummy:GetAbsOrigin() + right_vec * 40)
			info.vSpawnOrigin = gramDummy:GetAbsOrigin()

			ProjectileManager:CreateTrackingProjectile(info) 
			caster:EmitSound("Hero_SkywrathMage.ConcussiveShot.Cast")
		end

		extra_swords = extra_swords - 1

		return 0.2
	end)
end

function gilgamesh_gram:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
	if hTarget == nil then return end

	if IsSpellBlocked(hTarget) then return end

	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

	if not hTarget:IsMagicImmune() then
		hTarget:AddNewModifier(hCaster, hTarget, "modifier_stunned", { Duration = self:GetSpecialValueFor("stun_duration") })
	end
end