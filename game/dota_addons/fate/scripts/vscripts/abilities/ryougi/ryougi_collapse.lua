LinkLuaModifier("modifier_ryougi_collapse_cd", "abilities/ryougi/ryougi_collapse", LUA_MODIFIER_MOTION_NONE)

ryougi_collapse = class({})

function ryougi_collapse:OnSpellStart()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local damage = self:GetSpecialValueFor("damage")
	local damage_per_line = self:GetSpecialValueFor("damage_per_line")
	local line_count = self:GetSpecialValueFor("line_count")
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")
	local max_dist = self:GetSpecialValueFor("range")
    local width = self:GetSpecialValueFor("width")
	local point = self:GetCursorPosition()
    local direction = (point-origin)
    if point == origin then
    	direction = caster:GetForwardVector()
    end
    local dist = max_dist--math.min( max_dist, direction:Length2D() )
    direction.z = 0
    direction = direction:Normalized()
	local target = GetGroundPosition( origin + direction*dist, nil )
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    local abil = caster:FindAbilityByName("ryougi_collapse")
    abil:StartCooldown(abil:GetCooldown(abil:GetLevel() - 1))

    caster:RemoveModifierByName("modifier_ryougi_combo_window")

    caster:AddNewModifier(caster, self, "modifier_ryougi_collapse_cd", {duration = self:GetCooldown(1)})
	local particleName  = "particles/ryougi/ryougi_slash_red_big.vpcf"
	if caster:HasModifier("modifier_hero_selection_skin") then
        if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
          particleName = "particles/ryougi/tingtang_slash_red_big.vpcf"
		end
    end
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
	ParticleManager:SetParticleControl(particle, 10, Vector(0, 180, -60))

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)
    local combo_enemy = nil
	if caster:HasModifier("modifier_hero_selection_skin") then
			if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
				EmitGlobalSound("tingtang_combo_cast")
			else
				EmitGlobalSound("ryougi_combo_start")
			end
	else
    	EmitGlobalSound("ryougi_combo_start")
	end


    local affected = false

    self.AffectedTargets = {}

   local enemies = FATE_FindUnitsInLine(
								        caster:GetTeamNumber(),
								        origin,
								        target,
								        width,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_HERO,
										DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
										FIND_CLOSEST
    								)

    if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
					EmitSoundOn("tingtang_slash_combo", caster)
				else
					EmitSoundOn("jtr_slash", caster)
				end
			else
				EmitSoundOn("jtr_slash", caster)
			end

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
	
	if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
					EmitSoundOn("tingtang_slash_3", caster)
				else
					EmitSoundOn("jtr_slash", caster)
				end
			else
				EmitSoundOn("jtr_slash", caster)
			end

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


    
	combo_enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })


	local stacks = combo_enemy:FindModifierByName("modifier_ryougi_lines") and combo_enemy:FindModifierByName("modifier_ryougi_lines"):GetStackCount() or 0
	stacks = stacks + line_count
	local execute = self:GetSpecialValueFor("execute")
	damage = damage + stacks*damage_per_line

	combo_enemy:RemoveModifierByName("modifier_ryougi_lines")

	local eorigin = combo_enemy:GetAbsOrigin()
	local direction = (eorigin - origin):Normalized()

	local target = eorigin + direction*150

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

			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
					EmitSoundOn("tingtang_slash_2", caster)
				else
					EmitSoundOn("jtr_slash", caster)
				end
			else
				EmitSoundOn("jtr_slash", caster)
			end
			combo_enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })
			local particleName  = "particles/ryougi/ryougi_slash_red_big.vpcf"
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
				particleName = "particles/ryougi/tingtang_slash_red_big.vpcf"
				end
			end
			local particle2 = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
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
		if caster:HasModifier("modifier_hero_selection_skin") then
			if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
				EmitGlobalSound("tingtang_combo_voice")
			else
				EmitGlobalSound("ryougi_combo")
			end
		else
			EmitGlobalSound("ryougi_combo")
		end
		
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
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
					EmitSoundOn("tingtang_slash_3", caster)
				else
					EmitSoundOn("jtr_slash", caster)
				end
			else
				EmitSoundOn("jtr_slash", caster)
			end
			
			combo_enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })
			local particleName  = "particles/ryougi/ryougi_slash_red_big.vpcf"
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
				particleName = "particles/ryougi/tingtang_slash_red_big.vpcf"
				end
			end
			local particle3 = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle3, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle3, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
			ParticleManager:SetParticleControl(particle3, 10, Vector(0, 180, -60))
			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(particle3, false)
				ParticleManager:ReleaseParticleIndex(particle3)
			end)
		end)
		Timers:CreateTimer(0.3, function()
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then

					EmitSoundOn("tingtang_combo_voice", caster)
					EmitSoundOn("tingtang_combo_last", combo_enemy)
					Timers:CreateTimer(0.2, function()
						EmitSoundOn("tingtang_combo_slashes", combo_enemy)

					end)
				end
			end
		end)
		Timers:CreateTimer(0.5, function()
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
					local fxIndex1 = ParticleManager:CreateParticle( "particles/ryougi/tingtang_combo_ring.vpcf", PATTACH_ABSORIGIN, combo_enemy)
					ParticleManager:SetParticleControl( fxIndex1, 0, combo_enemy:GetAbsOrigin())
					ParticleManager:ReleaseParticleIndex(fxIndex1)
				end

			end

			
			for i = 1, line_count do
				Timers:CreateTimer(i*FrameTime()*2, function()
					DoDamage(caster, combo_enemy, damage/line_count, DAMAGE_TYPE_PURE, 0, self, false)
					local fxIndex = ParticleManager:CreateParticle( "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_slash_tgt_serrakura.vpcf", PATTACH_ABSORIGIN, caster)
					local random_vector = RandomVector(200)
					random_vector.z = 0
			        ParticleManager:SetParticleControl( fxIndex, 0, combo_enemy:GetAbsOrigin()+random_vector + Vector(0, 0, 300))
			        ParticleManager:SetParticleControl( fxIndex, 1, combo_enemy:GetAbsOrigin()-random_vector)
					--CreateSlashFx(caster, combo_enemy:GetAbsOrigin()+RandomVector(200), combo_enemy:GetAbsOrigin()+RandomVector(200))
					eyes:CutLine(combo_enemy, "collapse_"..i)
					
					if caster:HasModifier("modifier_hero_selection_skin") then
						if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
							
						else
							EmitSoundOn("ryougi_hit", combo_enemy)
						end
					else
						EmitSoundOn("ryougi_hit", combo_enemy)
					end
					combo_enemy:RemoveModifierByName("modifier_ryougi_lines")
					if caster.SelflessKnowledgeAcquired and combo_enemy:GetHealthPercent() < execute and not (combo_enemy:IsMagicImmune() or combo_enemy:HasModifier("modifier_avalon")) then
						combo_enemy:Execute(self, caster, { bExecution = true })
					end
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