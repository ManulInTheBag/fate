hijikata_target_dash = class({})


function hijikata_target_dash:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local target_flag = DOTA_UNIT_TARGET_FLAG_NONE
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or (IsServer() and IsLocked(caster)) then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end


function hijikata_target_dash:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end -- Linken effect checker

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	if((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > self:GetSpecialValueFor("range")) then
		self:EndCooldown()
		return
	end

	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

	StartAnimation(caster, {duration=0.35, activity=ACT_DOTA_CAST_SUN_STRIKE_ORB, rate=2})
	

	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
    	DoDamage(caster, v, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	end

	target:AddNewModifier(caster, v, "modifier_stunned", {Duration = duration})
	caster:PerformAttack(target, true, true, true, true, false, false, false)

	--particle
	caster:EmitSound("Hero_Huskar.Life_Break")
    local attackFx = ParticleManager:CreateParticle("particles/hijikata/hijikata_dash_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW , caster)  
    ParticleManager:ReleaseParticleIndex(attackFx)
end

