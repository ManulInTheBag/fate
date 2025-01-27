li_shuwen_new_w = class({})
LinkLuaModifier("modifier_li_motion_controller_w", "abilities/lishuwen/li_shuwen_new_w", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_li_shuwen_new_w_contoller", "abilities/lishuwen/li_shuwen_new_w", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shuwen_atk_sound","abilities/lishuwen/li_shuwen_new_w", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("li_shuwen_new_w_slow","abilities/lishuwen/li_shuwen_new_w", LUA_MODIFIER_MOTION_NONE)
function li_shuwen_new_w:GetIntrinsicModifierName()
	return "modifier_shuwen_atk_sound"
end


function li_shuwen_new_w:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

modifier_shuwen_atk_sound = class({})



function modifier_shuwen_atk_sound:OnCreated()
	self.sound = "li_attack_sound_new_"..math.random(1,3)
end

function modifier_shuwen_atk_sound:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	self.sound = "li_attack_sound_new_"..math.random(1,3)

end

function modifier_shuwen_atk_sound:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_shuwen_atk_sound:DeclareFunctions()
	local func = {
					MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,

				}
	return func
end

function modifier_shuwen_atk_sound:GetAttackSound()
	return self.sound
end

function modifier_shuwen_atk_sound:IsHidden() return true end
function modifier_shuwen_atk_sound:RemoveOnDeath() return true end



function li_shuwen_new_w:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local total_strikes = self:GetSpecialValueFor("total_strikes")
	local bonus_damage = self:GetSpecialValueFor("bonus_damage")
	local duration = 1.5
	local radius = self:GetSpecialValueFor("radius")
	local slow_dur = self:GetSpecialValueFor("slow_duration")
	local slow_power = self:GetSpecialValueFor("slow_power")
	caster:AddNewModifier(caster, self, "modifier_li_shuwen_new_w_contoller", {duration = duration, total_strikes = total_strikes, duration = duration, radius = radius, slow_dur = slow_dur,
																				slow_power = slow_power, bonus_damage = bonus_damage, target_point_x = target_point.x,
																				target_point_y = target_point.y, target_point_z = target_point.z})
end

modifier_li_shuwen_new_w_contoller = modifier_li_shuwen_new_w_contoller or class({})

function modifier_li_shuwen_new_w_contoller:IsHidden()                                                                       return true end
function modifier_li_shuwen_new_w_contoller:IsDebuff()                                                                       return false end
function modifier_li_shuwen_new_w_contoller:IsPurgable()                                                                     return false end
function modifier_li_shuwen_new_w_contoller:IsPurgeException()                                                               return false end
function modifier_li_shuwen_new_w_contoller:RemoveOnDeath()                                                                  return true end
function modifier_li_shuwen_new_w_contoller:GetPriority()                                                                    return MODIFIER_PRIORITY_HIGH end


function modifier_li_shuwen_new_w_contoller:OnCreated(htable)
		self.hCaster  = self:GetCaster()
		self.hAbility = self:GetAbility()
		self.hAbility:PlayRandomAttackAnimation()
		self.target_point = Vector(htable.target_point_x, htable.target_point_y, htable.target_point_z)
		self.bonus_damage = htable.bonus_damage
		self.slow_dur = htable.slow_dur
		self.slow_power = htable.slow_power
		self.radius = htable.radius
		self.duration = htable.duration
		self.total_strikes = htable.total_strikes
		self.interval = self.duration/self.total_strikes


		self.particle = ParticleManager:CreateParticle("particles/zlodemon/li_new_w/li_new_w_jopa.vpcf", PATTACH_WORLDORIGIN, self.hCaster)
		ParticleManager:SetParticleControl(self.particle, 0, self.target_point)
		ParticleManager:SetParticleControl(self.particle, 1, Vector(self.radius,0,0))
		--ParticleManager:ReleaseParticleIndex(self.particle)
		--self.particle2 = ParticleManager:CreateParticle("particles/zlodemon/li_w_ground.vpcf", PATTACH_ABSORIGIN, self.hCaster)
		--ParticleManager:SetParticleControl(self.particle2, 0, self.target_point)
		--ParticleManager:SetParticleControl(self.particle2, 1, Vector(self.radius,0,0))
		--ParticleManager:ReleaseParticleIndex(self.particle2)
		self.attack_counter = 0
		self:StartIntervalThink(self.interval - 0.033)
end
function modifier_li_shuwen_new_w_contoller:OnIntervalThink()

	if self.attack_counter % 2 == 1 then 
		self.hAbility:PlayRandomSounds()
	end
	if self.attack_counter == self.total_strikes then
		self:Destroy()
	end
	local enemies = FindUnitsInRadius(self.hCaster:GetTeam(), self.target_point, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	if enemies[1] ~= nil then
		local target_enemy = enemies[1]

		local position = PointOnCircle(GetGroundPosition(target_enemy:GetAbsOrigin(), target_enemy), 450, math.random(0,360)) --target_enemy:GetAbsOrigin() + target_enemy:GetForwardVector() * -450
		position.z = 0
		FindClearSpaceForUnit(self.hCaster, position, true)
		local vector_to_target = -(self.hCaster:GetAbsOrigin() - target_enemy:GetAbsOrigin()):Normalized()
		local direction_vector = vector_to_target
		vector_to_target.z = 0
		self.hCaster:SetForwardVector(vector_to_target)
		local animcount = math.random(1,4)
		self.hAbility:PlayRandomAttackAnimation(animcount)
		if animcount == 1 then
			local particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, self.hCaster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, self.hCaster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, self.hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)

		elseif animcount == 2 then
			local particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage_2.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, self.hCaster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, self.hCaster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, self.hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)

		elseif animcount == 3 then
			local particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage_3.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, self.hCaster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, self.hCaster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, self.hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)

		else 
			local particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage_4.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, self.hCaster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, self.hCaster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, self.hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)
	
		end
		self.hCaster:AddNewModifier(self.hCaster, self.hAbility, "modifier_li_motion_controller_w", {duration = 0.1, htarget = target_enemy:entindex()})

		Timers:CreateTimer(0.15, function()

			DoDamage(self.hCaster, target_enemy, self.bonus_damage, DAMAGE_TYPE_MAGICAL, 0, self.hAbility, false)
			target_enemy:AddNewModifier(self.hCaster, self.hAbility, "li_shuwen_new_w_slow", {duration = self.slow_dur})
			self.hCaster:PerformAttack( target_enemy, true, true, true, true, false, false, false )
			self.hCaster:FindAbilityByName("lishuwen_no_second_strike"):AddShock(target_enemy, 2)
			self.hAbility:CreateCritFx(target_enemy)
		
		end)

		self.attack_counter = self.attack_counter + 1
	else 
		self:Destroy()
	end
end
function modifier_li_shuwen_new_w_contoller:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_li_shuwen_new_w_contoller:OnDestroy(hTable)
	ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
	--ParticleManager:DestroyParticle(self.particle2, false)
    --ParticleManager:ReleaseParticleIndex(self.particle2)
end
function modifier_li_shuwen_new_w_contoller:CheckState()
    local state =   { 
 
						[MODIFIER_STATE_ROOTED] = true,
						[MODIFIER_STATE_DISARMED] = true,
 						[MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                        

                    }
    return state
end

function li_shuwen_new_w:PlayRandomAttackAnimation(animation_number)
	local caster = self:GetCaster()
	local duration = 0.142857143*1.5

	if IsServer() then
			local direction_vector = Vector(100,100,100)
		if animation_number == 1 then
			StartAnimation(caster, {duration=duration, activity=ACT_DOTA_CAST_ABILITY_6, rate=6/1.5}) 
			particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)

		elseif animation_number == 2 then
			StartAnimation(caster, {duration=duration, activity=ACT_DOTA_CAST_ABILITY_3, rate=5/1.5})
			particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage_2.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)

		elseif animation_number == 3 then
			StartAnimation(caster, {duration=duration, activity=ACT_DOTA_CAST_ABILITY_2, rate=7/1.5})
			particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage_3.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)

		else 
			StartAnimation(caster, {duration=duration, activity=ACT_DOTA_ATTACK_EVENT, rate=5/1.5})
			particle = ParticleManager:CreateParticle("particles/zlodemon/li_shuwen_w_afterimage_4.vpcf", PATTACH_ABSORIGIN, self.hCaster)
			ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin(),  direction_vector)
			ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + direction_vector * (450 * 0.9))
			ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", direction_vector, true)
			ParticleManager:ReleaseParticleIndex(particle)
	
		end
	end

end




function li_shuwen_new_w:CreateCritFx(target)
	local crit_fx = ParticleManager:CreateParticle( "particles/econ/items/pudge/pudge_ti10_immortal/pudge_ti10_immortal_meathook_blood.vpcf", PATTACH_ABSORIGIN, target )
    --ParticleManager:SetParticleControl( crit_fx, 0, target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl( crit_fx, 1, target:GetAbsOrigin())

    Timers:CreateTimer(0.2, function()
		ParticleManager:DestroyParticle( crit_fx, false )
		ParticleManager:ReleaseParticleIndex( crit_fx )
		return nil
	end)
end

function li_shuwen_new_w:PlayRandomSounds()
	local caster = self:GetCaster()
	local soundQueue = math.random(1,4)

	caster:EmitSound("Lishuwen_Attack" .. soundQueue)
end

li_shuwen_new_w_slow = class({})

function li_shuwen_new_w_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			--MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
			}
end
function li_shuwen_new_w_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power") 
end



modifier_li_motion_controller_w = class({})
function modifier_li_motion_controller_w:IsHidden() return true end
function modifier_li_motion_controller_w:IsDebuff() return false end
function modifier_li_motion_controller_w:IsPurgable() return false end
function modifier_li_motion_controller_w:IsPurgeException() return false end
function modifier_li_motion_controller_w:RemoveOnDeath() return true end
function modifier_li_motion_controller_w:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_li_motion_controller_w:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_li_motion_controller_w:CheckState()
    local state =   { 
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,

                    }
    return state
end

function modifier_li_motion_controller_w:OnCreated(table)
	if IsServer() then
		self.caster = self:GetCaster()
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self.heat_abil = self.parent:FindAbilityByName("nero_heat")
		self.target = EntIndexToHScript(table.htarget)
		--EmitSoundOn("nero_dash", self.parent)

		if IsServer() then
			self.speed          = 4000
			self.distance       = 350
			self.radius = self:GetAbility():GetSpecialValueFor("radius")


			local vector_to_target = -(self.caster:GetAbsOrigin() - self.target:GetAbsOrigin()):Normalized()
			vector_to_target.z = 0
			self.caster:SetForwardVector(vector_to_target)

			self.direction      = vector_to_target
			self.direction.z    = 0



			self.AttackedTargets    = {}
			self.FirstTarget        = nil


			self:StartIntervalThink(FrameTime())

		end
	end
end
function modifier_li_motion_controller_w:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_li_motion_controller_w:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_li_motion_controller_w:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt
            local distance_will = self.distance - units_per_dt
            self.parent:SetOrigin(next_pos)


            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end