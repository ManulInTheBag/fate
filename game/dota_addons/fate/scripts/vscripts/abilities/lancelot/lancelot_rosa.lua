



lancelot_rosa = class({})

function lancelot_rosa:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_EMP, rate=1.5})
end

function lancelot_rosa:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end



function lancelot_rosa:CastFilterResultLocation(vLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_lancelot_minigun") then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function lancelot_rosa:GetCustomCastErrorLocation(vLocation)
    return "#Minigun_Active"
end

function lancelot_rosa:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local vOrigin = hCaster:GetAbsOrigin()
	local aoe_damage = self:GetSpecialValueFor("damage")
	local aoe_radius = self:GetSpecialValueFor("radius")
	local stun_duration = self:GetSpecialValueFor("stun_duration")

	local vector = (self:GetCursorPosition() - hCaster:GetAbsOrigin()):Normalized()
	vector.z = 0
	hCaster:SetForwardVector(vector)
	local right_vector = hCaster:GetRightVector()
	local move_pos = hCaster:GetAbsOrigin() + hCaster:GetForwardVector() * 300 + right_vector * 150
	giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealenabled", 0.3)
	EmitSoundOn("nero_swoosh_1", hCaster)
	if hCaster.ImproveKnightOfOwner then
		aoe_damage = aoe_damage + 200
	end
	Timers:CreateTimer(0.05, function()

		local particle = ParticleManager:CreateParticle("particles/lancelot/lancelot_slash_rosa.vpcf", PATTACH_ABSORIGIN, hCaster)
		ParticleManager:SetParticleControlTransformForward(particle, 0, hCaster:GetAbsOrigin(), hCaster:GetForwardVector())
		ParticleManager:ReleaseParticleIndex(particle)
		
	end)
	if not hCaster.KnightLevel and not hCaster.ArsenalLevel then
		self:OnKnightClosed(keys)
		hCaster:FindAbilityByName("lancelot_knight_of_honor"):StartCooldown(self:GetCooldown(self:GetLevel()))
	end
	Timers:CreateTimer(0.2, function()
		if hCaster:IsAlive() then

			local targets = FindUnitsInRadius(hCaster:GetTeamNumber(), hCaster:GetAbsOrigin(), hCaster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
			for k,v in pairs(targets) do
				if v:GetName() ~= "npc_dota_ward_base" then
					local origin_diff = v:GetAbsOrigin() - hCaster:GetAbsOrigin()
					local origin_diff_norm = origin_diff:Normalized()
					if hCaster:GetForwardVector():Dot(origin_diff_norm) > 0 then
						DoDamage(hCaster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
						if hCaster.ImproveKnightOfOwner then
							hCaster:PerformAttack(v, true, true, true, true, false, false, true)
						end
						local knockback = { should_stun = true,
											knockback_duration = stun_duration,
											duration = stun_duration,
											knockback_distance = -math.min((v:GetAbsOrigin()-move_pos):Length2D(),300),
											knockback_height = 0,
											center_x = move_pos.x,
											center_y = move_pos.y,
											center_z = move_pos.z }
						if( not IsKnockbackImmune(v)) then
							v:AddNewModifier(hCaster, self, "modifier_knockback", knockback)
						end
					end
				end
			end

	
		end
	end)

	
end

function lancelot_rosa:OnKnightClosed(keys)
	local caster = self:GetCaster()
	caster.IsKnightOpen = false
	local a1 = caster:GetAbilityByIndex(0)
	local a2 = caster:GetAbilityByIndex(1)
	local a3 = caster:GetAbilityByIndex(2)
	local a4 = caster:GetAbilityByIndex(3)
	local a5 = caster:GetAbilityByIndex(4)
	local a6 = caster:GetAbilityByIndex(5)
	-- if knight attribute is not taken, caster.KnightLevel~=nil is false and therefore kills off queueing a 2nd skill. 
	caster:SwapAbilities(a1:GetName(), "lancelot_minigun", false ,true) 
	caster:SwapAbilities(a2:GetName(), "lancelot_parry", false, true) 
	caster:SwapAbilities(a3:GetName(), "lancelot_knight_of_honor", false, true)
	if caster.nukeAvail == true then 
		caster:SwapAbilities(a4:GetName(), "lancelot_nuke", false, true) 
	elseif caster:HasAbility("lancelot_blessing_of_fairy") then 
		caster:SwapAbilities(a4:GetName(), "lancelot_blessing_of_fairy", false, true) 
	else 
		caster:SwapAbilities(a4:GetName(), "fate_empty1", false, true) 
	end
	caster:SwapAbilities(a5:GetName(), "lancelot_arms_mastership", false, true) 
	caster:SwapAbilities(a6:GetName(), "lancelot_arondite", false, true )       
end