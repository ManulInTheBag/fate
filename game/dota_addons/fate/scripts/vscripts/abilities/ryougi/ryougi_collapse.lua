LinkLuaModifier("modifier_ryougi_collapse_cd", "abilities/ryougi/ryougi_collapse", LUA_MODIFIER_MOTION_NONE)

ryougi_collapse = class({})

function ryougi_collapse:OnSpellStart()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local damage = self:GetSpecialValueFor("damage")
	local line_count = self:GetSpecialValueFor("line_count")
	local point = self:GetCursorPosition()
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    local abil = caster:FindAbilityByName("ryougi_collapse")
    abil:StartCooldown(abil:GetCooldown(abil:GetLevel() - 1))

    caster:RemoveModifierByName("modifier_ryougi_combo_window")

    caster:AddNewModifier(caster, self, "modifier_ryougi_collapse_cd", {duration = self:GetCooldown(1)})

	local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_red_big.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
	ParticleManager:SetParticleControl(particle, 10, Vector(0, 180, -60))

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	local max_dist = self:GetSpecialValueFor("range")
    local width = self:GetSpecialValueFor("width")

    local direction = (point-origin)
    local dist = math.min( max_dist, direction:Length2D() )
    direction.z = 0
    direction = direction:Normalized()

    local target = GetGroundPosition( origin + direction*dist, nil )

    local combo_enemy = nil

    EmitGlobalSound("ryougi_combo_start")

    local affected = false

    self.AffectedTargets = {}

	--[[local enemies2 = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies2) do
    	if not self.AffectedTargets[enemy:entindex()] then
			self.AffectedTargets[enemy:entindex()] = true

	        local caster_angle = caster:GetAnglesAsVector().y
	        local origin_difference = caster:GetAbsOrigin() - enemy:GetAbsOrigin()

	        local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)

	        origin_difference_radian = origin_difference_radian * 180
	        local enemy_angle = origin_difference_radian / math.pi

	        enemy_angle = enemy_angle + 180.0

	        local result_angle = enemy_angle - caster_angle
	        result_angle = math.abs(result_angle)

	        if result_angle <= 90 then
			    DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
			    EmitSoundOn("ryougi_hit", enemy)
			    eyes:CutLine(enemy, "kimono_1")
	        end
	   	end
    end]]

    local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        origin,
								        target,
								        nil,
								        width,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_HERO,
										DOTA_UNIT_TARGET_FLAG_NONE
    								)

    EmitSoundOn("jtr_slash", caster)

    if caster and IsValidEntity(caster) and enemies and #enemies>0 then
	    for _, enemy in pairs(enemies) do
	    	if not affected then
	    		affected = true
		    	self.AffectedTargets[enemy:entindex()] = true
		    	combo_enemy = enemy
		    	enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })
		        --DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		        --EmitSoundOn("ryougi_hit", enemy)
		        --eyes:CutLine(enemy, "kimono_1")
		    end
	    end
	end

	EmitSoundOn("jtr_slash", caster)

	if not combo_enemy then
		FindClearSpaceForUnit( caster, target, true )
		local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_red.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
	  	ParticleManager:SetParticleControl( effect_cast, 0, origin )
	    ParticleManager:SetParticleControl( effect_cast, 1, target)
	    ParticleManager:SetParticleControl( effect_cast, 2, target )
	    Timers:CreateTimer(1.0, function()
	        ParticleManager:DestroyParticle(effect_cast, true)
	        ParticleManager:ReleaseParticleIndex( effect_cast )
	    end)
		return
	end

	target = combo_enemy:GetAbsOrigin() + direction*150

	FindClearSpaceForUnit( caster, target, true)
	local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_red.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
  	ParticleManager:SetParticleControl( effect_cast, 0, origin )
    ParticleManager:SetParticleControl( effect_cast, 1, target)
    ParticleManager:SetParticleControl( effect_cast, 2, target )
    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(effect_cast, true)
        ParticleManager:ReleaseParticleIndex( effect_cast )
    end)

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1.2)
	StartAnimation(caster, {duration=0.25, activity=ACT_DOTA_RAZE_1, rate=2})
	Timers:CreateTimer(0.5, function()
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_RAZE_2, rate=2})
		Timers:CreateTimer(0.05, function()
			local origin2 = caster:GetAbsOrigin()
			local point2 = combo_enemy:GetAbsOrigin()
			local direction2 = (point2-origin2)
		    direction2.z = 0
		    direction2 = direction2:Normalized()
		    target = point2 + direction2*150

		    FindClearSpaceForUnit( caster, target, true)

		    effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_red.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		  	ParticleManager:SetParticleControl( effect_cast, 0, origin2 )
		    ParticleManager:SetParticleControl( effect_cast, 1, target)
		    ParticleManager:SetParticleControl( effect_cast, 2, target )
		    Timers:CreateTimer(1.0, function()
		        ParticleManager:DestroyParticle(effect_cast, true)
		        ParticleManager:ReleaseParticleIndex( effect_cast )
		    end)

			EmitSoundOn("jtr_slash", caster)
			combo_enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })
			local particle2 = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_red_big.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle2, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
			ParticleManager:SetParticleControl(particle2, 10, Vector(0, 180, 120))

			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(particle2, false)
				ParticleManager:ReleaseParticleIndex(particle2)
			end)
		end)
	end)
	Timers:CreateTimer(0.5, function()
		EmitGlobalSound("ryougi_combo")
	end)
	Timers:CreateTimer(0.7, function()
		StartAnimation(caster, {duration=1.1, activity=ACT_DOTA_RAZE_3, rate=1})
		Timers:CreateTimer(0.2, function()
			local origin3 = caster:GetAbsOrigin()
			local point3 = combo_enemy:GetAbsOrigin()
			local direction3 = (point3-origin3)
		    direction3.z = 0
		    direction3 = direction3:Normalized()
		    target = point3 + direction3*150

		    FindClearSpaceForUnit( caster, target, true)

		    effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_red.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		  	ParticleManager:SetParticleControl( effect_cast, 0, origin3 )
		    ParticleManager:SetParticleControl( effect_cast, 1, target)
		    ParticleManager:SetParticleControl( effect_cast, 2, target )
		    Timers:CreateTimer(1.0, function()
		        ParticleManager:DestroyParticle(effect_cast, true)
		        ParticleManager:ReleaseParticleIndex( effect_cast )
		    end)

			EmitSoundOn("jtr_slash", caster)
			combo_enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })
			local particle3 = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_red_big.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle3, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle3, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
			ParticleManager:SetParticleControl(particle3, 10, Vector(0, 180, -60))
			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(particle3, false)
				ParticleManager:ReleaseParticleIndex(particle3)
			end)
		end)
		Timers:CreateTimer(0.5, function()
			for i = 1, line_count do
				Timers:CreateTimer(i*FrameTime()*2, function()
					DoDamage(caster, combo_enemy, damage/line_count, DAMAGE_TYPE_PHYSICAL, 0, self, false)
					local fxIndex = ParticleManager:CreateParticle( "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_slash_tgt_serrakura.vpcf", PATTACH_ABSORIGIN, caster)
					local random_vector = RandomVector(200)
					random_vector.z = 0
			        ParticleManager:SetParticleControl( fxIndex, 0, combo_enemy:GetAbsOrigin()+random_vector + Vector(0, 0, 300))
			        ParticleManager:SetParticleControl( fxIndex, 1, combo_enemy:GetAbsOrigin()-random_vector)
					--CreateSlashFx(caster, combo_enemy:GetAbsOrigin()+RandomVector(200), combo_enemy:GetAbsOrigin()+RandomVector(200))
					eyes:CutLine(combo_enemy, "collapse_"..i)
					EmitSoundOn("ryougi_hit", combo_enemy)
				end)
			end
		end)
	end)
end

modifier_ryougi_collapse_cd = class({})

function modifier_ryougi_collapse_cd:GetTexture()
	return "custom/ryougi/ryougi_collapse"
end

function modifier_ryougi_collapse_cd:IsHidden()
	return false 
end

function modifier_ryougi_collapse_cd:RemoveOnDeath()
	return false
end

function modifier_ryougi_collapse_cd:IsDebuff()
	return true 
end

function modifier_ryougi_collapse_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end