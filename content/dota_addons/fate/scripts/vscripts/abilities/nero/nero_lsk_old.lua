nero_laus_saint_claudius = class({})

LinkLuaModifier("modifier_laus_saint_burn", "abilities/nero/modifiers/modifier_laus_saint_burn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_claudius_cooldown", "abilities/nero/modifiers/modifier_laus_saint_claudius_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_ready_checker", "abilities/nero/modifiers/modifier_laus_saint_ready_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lsk_stunned","abilities/nero/nero_laus_saint_claudius", LUA_MODIFIER_MOTION_NONE)

function nero_laus_saint_claudius:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function nero_laus_saint_claudius:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Cannot_Target_Wards"
	elseif not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then
		return "#Target_Not_In_Theatre"
	else
		return "#Invalid_Target"
	end
end

function nero_laus_saint_claudius:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local damage = self:GetSpecialValueFor("damage")
	local ability = self

	caster:EmitSound("Nero_NP4")
	EmitGlobalSound("Devil_Trigger")
	--caster:SwapAbilities("nero_laus_saint_claudius", "nero_aestus_domus_aurea", false, true)

	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(1))

	caster:AddNewModifier(caster, ability, "modifier_laus_saint_claudius_cooldown", {Duration = ability:GetCooldown(1)})

	if caster:HasModifier("modifier_laus_saint_ready_checker") then
		caster:RemoveModifierByName("modifier_laus_saint_ready_checker")
	end

	target:AddNewModifier(caster, target, "modifier_lsk_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", self:GetSpecialValueFor("stun_duration"))
	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()

	StartAnimation(caster, {duration = 0.4, activity = ACT_DOTA_CAST_ABILITY_5, rate = 3})

	Timers:CreateTimer(1.0, function()		
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.4, activity = ACT_DOTA_ATTACK_EVENT, rate = 1.5})
			--[[local slashFx1 = ParticleManager:CreateParticle("particles/custom/nero/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_ABSORIGIN, caster )
			ParticleManager:SetParticleControl( slashFx1, 0, caster:GetAbsOrigin() + Vector(0,0,300))

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( slashFx1, false )
				ParticleManager:ReleaseParticleIndex( slashFx1 )
			end)]]
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(1200, 1200, 300),target:GetAbsOrigin() + Vector(-1200, -1200, 300))
		end
	end)

	Timers:CreateTimer(2.0, function()		
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK_EVENT_BASH, rate = 1.5})

			--[[local slashFx2 = ParticleManager:CreateParticle("particles/custom/nero/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_ABSORIGIN, caster )
			ParticleManager:SetParticleControl( slashFx1, 0, caster:GetAbsOrigin() + Vector(0,0,300))

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( slashFx2, false )
				ParticleManager:ReleaseParticleIndex( slashFx2 )
			end)]]

			caster:SetAbsOrigin(target:GetAbsOrigin() - diff:Normalized() * 100)
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)		
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(1200, -1200, 300), target:GetAbsOrigin() + Vector(-1200, 1200, 300))	
		end
	end)

	Timers:CreateTimer(self:GetSpecialValueFor("stun_duration"), function()
		if caster:IsAlive() then			
			target:EmitSound("Hero_Lion.FingerOfDeath")
			StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1.5})	
			CreateSlashFx(caster, target:GetAbsOrigin() + Vector(1200, 1200, 300),target:GetAbsOrigin() + Vector(-1200, -1200, 300))
			local slashFx = ParticleManager:CreateParticle("particles/custom/nero/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_ABSORIGIN, target )
			ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( slashFx, false )
				ParticleManager:ReleaseParticleIndex( slashFx )
			end)

			DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

			local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

			for i = 1, #enemies do
				enemies[i]:AddNewModifier(caster, self, "modifier_laus_saint_burn", { Duration = self:GetSpecialValueFor("duration"),
																					  BurnDamage = self:GetSpecialValueFor("burn_damage") })				
			end

			caster:RemoveModifierByName("modifier_aestus_domus_aurea_nero")
		end
	end)
end

modifier_lsk_stunned=class({})
function modifier_lsk_stunned:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true,
			 [MODIFIER_STATE_COMMAND_RESTRICTED] = true }
end