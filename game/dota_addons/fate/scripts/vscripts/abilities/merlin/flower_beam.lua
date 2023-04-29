LinkLuaModifier("modifier_merlin_self_slow","abilities/merlin/flower_beam", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_slow","abilities/merlin/flower_beam", LUA_MODIFIER_MOTION_NONE)
flower_beam = class({})

function flower_beam:GetAnimeVectorTargetingRange()
    return 360
end
function flower_beam:GetAnimeVectorTargetingStartRadius()
    return 150
end
function flower_beam:GetAnimeVectorTargetingEndRadius()
    return 150
end
function flower_beam:IsAnimeVectorTargetingIgnoreWidth()
	return false
end
function flower_beam:GetAnimeVectorTargetingColor()
    return Vector(0, 255, 255)
end




 

 
function flower_beam:OnSpellStart()
    local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local pepelength = (caster:GetAbsOrigin() - target):Length2D()
	if pepelength > self:GetCastRange(target, caster) then
		target = GetGroundPosition(caster:GetAbsOrigin() - (caster:GetAbsOrigin() - target):Normalized()*self:GetCastRange(target, caster), caster)
	end
	local ability = self
	local direction = self:GetAnimeVectorTargetingMainDirection()
	caster:EmitSound("merlin_beam_1")

	if(caster.RapidChantingAcquired) then
		local cd1 = caster:GetAbilityByIndex(1):GetCooldownTimeRemaining()
		
		local cd3 = caster:GetAbilityByIndex(5):GetCooldownTimeRemaining()
		caster:GetAbilityByIndex(1):EndCooldown()
		
		caster:GetAbilityByIndex(5):EndCooldown()
		if(cd1 > 0 ) then
			caster:GetAbilityByIndex(1):StartCooldown(cd1 -1)
		end
		if(caster:GetAbilityByIndex(2):GetName() ~= "merlin_garden_of_avalon") then
			local cd2 = caster:GetAbilityByIndex(2):GetCooldownTimeRemaining()
			caster:GetAbilityByIndex(2):EndCooldown()
			if(cd2 > 0 ) then
				caster:GetAbilityByIndex(2):StartCooldown(cd2 -1)
			end
		end
		if(cd3 > 0 ) then
			caster:GetAbilityByIndex(5):StartCooldown(cd3 -1)
		end
	end
	caster:FindAbilityByName("merlin_charisma"):AttStack() 
	local radius = self:GetSpecialValueFor("beam_radius")
	local point = target
	local beam_counter = self:GetSpecialValueFor("ticks")
	local beam_counter_starting = beam_counter
	local damage = self:GetSpecialValueFor("damage")+(caster.RapidChantingAcquired and caster:GetIntellect()*self:GetSpecialValueFor("att_dmg_per_int") or 0)
	local move_per_tick = self:GetSpecialValueFor("beam_movement")
	local movement_time = self:GetSpecialValueFor("movement_time")
	local tick_time = movement_time/beam_counter_starting
	local illusion  = CreateIllusions(caster,caster,nil,1,0,false,false)
	local beam_particle
	 illusion[1]:AddNewModifier(caster, self, "modifier_merlin_self_slow", {duration = movement_time-0.2 })
	 
	 Timers:CreateTimer( 0 +movement_time, function()
 
			ParticleManager:DestroyParticle( beam_particle, true)
			ParticleManager:ReleaseParticleIndex( beam_particle)
 
	
	 end)
	 illusion[1]:SetForwardVector(caster:GetForwardVector())
	 StartAnimation( illusion[1], {duration=1, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
	 
	Timers:CreateTimer(0.1, function() 
		if( not caster:IsAlive()) then return end
		local start_location = illusion[1]:GetAttachmentOrigin(2) 
		illusion[1]:SetForwardVector((target - illusion[1]:GetAbsOrigin()):Normalized()) 
		if(beam_counter == beam_counter_starting) then
			 beam_particle = ParticleManager:CreateParticle("particles/merlin/merlin_beam.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( beam_particle, 1, start_location) 
		end
		if(beam_counter == 0 ) then 	ParticleManager:DestroyParticle( beam_particle, true)  return end
		beam_counter = beam_counter - 1

		local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do       
      
			DoDamage(caster, v, damage +v:GetMaxHealth()*self:GetSpecialValueFor("damage_per_hp")/100 , DAMAGE_TYPE_MAGICAL, 0, ability, false)
			v:AddNewModifier(caster, self, "modifier_merlin_slow", {Duration = 0.2})   
		end
		ParticleManager:SetParticleControl( beam_particle, 1, start_location) 
		ParticleManager:SetParticleControl( beam_particle, 0, point) 
		local flower_particle = ParticleManager:CreateParticle("particles/merlin/merlin_beam_flowers.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(flower_particle, 0, point) 
		point = GetGroundPosition(point + direction *move_per_tick, caster)
		return tick_time
	end)

end

modifier_merlin_self_slow = class({})

function modifier_merlin_self_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING,
	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE  }

	return funcs
end

function modifier_merlin_self_slow:GetModifierDisableTurning() 
	return 1
end
function modifier_merlin_self_slow:GetModifierMagicalResistanceBonus()
    return 100
end

function modifier_merlin_self_slow:CheckState()
    local state =   { 
                       
						[MODIFIER_STATE_INVULNERABLE] = true,
						[MODIFIER_STATE_ROOTED] = true,
						[MODIFIER_STATE_DISARMED] = true,
						[MODIFIER_STATE_UNTARGETABLE] = true,
						[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
						[MODIFIER_STATE_NO_HEALTH_BAR] = true,
						[MODIFIER_STATE_STUNNED] = true,
						[MODIFIER_STATE_UNSELECTABLE] = true

                    }
    return state
end



function modifier_merlin_self_slow:OnDestroy() 
	if(IsServer) then
		self:GetParent():ForceKill(false)
	end
end

 
function modifier_merlin_self_slow:IsHidden() return true end
function modifier_merlin_self_slow:RemoveOnDeath() return true end


modifier_merlin_slow = class({})

function modifier_merlin_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_merlin_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_merlin_slow:IsHidden()
	return false 
end