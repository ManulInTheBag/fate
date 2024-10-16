iskander_forward = class({})

LinkLuaModifier("modifier_iskandar_infantry_rush", "abilities/iskandar/iskander_forward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskandar_forward", "abilities/iskandar/iskander_forward", LUA_MODIFIER_MOTION_NONE)

function iskander_forward:GetBehavior()
	if self:GetCaster():HasModifier("modifier_gordius_wheel") then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	end
	return DOTA_ABILITY_BEHAVIOR_POINT 
end


function iskander_forward:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner() 
	local castPosition = self:GetCursorPosition()
	local castVector = -(caster:GetAbsOrigin() - castPosition):Normalized()
	castVector.z = 0
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_press_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() )
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)
	local radius = self:GetSpecialValueFor("radius")
	local ability = self	
	if caster.IsCharismaImproved then
		radius = radius*2
	end
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("iskander_ionioi"):IsCooldownReady()  then
			if(caster:GetAbilityByIndex(4):GetName() == "fate_empty1" and not caster.IsAOTKActive) then
				caster:SwapAbilities("iskander_ionioi", "fate_empty1", true, false)
			 end
			   local newTime =  GameRules:GetGameTime()
			   Timers:CreateTimer({
				   endTime = 5,
				   callback = function()
					if(caster:GetAbilityByIndex(4):GetName() == "iskander_ionioi") then
				   		caster:SwapAbilities("iskander_ionioi", "fate_empty1", false, true)
					end
				   
			   end
			   })
		 
	   end
   end
	--print(caster:GetForwardVector())
	
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius
        , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	local soundQueue = math.random(1,4)
	if soundQueue == 3 then soundQueue = 5 end -- i was lazy, but needed to remove 3rd sound. 

	for k,v in pairs(targets) do
		RemoveSlowEffect(v)
		local rightvec = Vector(castVector.y, -castVector.x, 0)
		v:AddNewModifier(caster,ability, "modifier_iskandar_forward", {duration = self:GetSpecialValueFor("duration")})
		if(v:GetUnitName() == "iskander_infantry") and caster.IsBeyondTimeAcquired then
			v:SetForwardVector(castVector)
			
			dot = castVector:Dot(v:GetRightVector())
			if v.num == nil then v.num = 0 end
			if dot > 0 then 
				v.num = - v.num
			end
			local vector = (castVector*1200+v.num*rightvec*75):Normalized()
			v:SetForwardVector(vector)
			local speed = 1800
			v:AddNewModifier(caster,ability, "modifier_iskandar_infantry_rush", {duration = 0.5, speed =speed})
			--v:AddNewModifier(caster,ability, "modifier_phased", {duration = 0.5})
			StartAnimation(v, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
			self:CreateInfantryProjectile(v, speed)

		end
		if(v:GetUnitName() == "iskander_cavalry") and caster.IsBeyondTimeAcquired then
			caster:FindAbilityByName("iskander_cavalry"):Charge(radius, castVector, v)
		end
		if v ~= caster and v:IsHero() then
			v:EmitSound("Hero_LegionCommander.Overwhelming.Location")
		elseif v == caster then
			v:EmitSound("Iskander_Charge_" .. soundQueue)
		end
    end
end

function iskander_forward:CreateInfantryProjectile(unit, speed)
	local ability = self
	local caster = self:GetCaster()
	local qdProjectile = 
	{
		Ability = ability,
        --EffectName = "particles/muramasa/muramasa_throw_projectile.vpcf",
        iMoveSpeed = speed,
        vSpawnOrigin = unit:GetOrigin(),
        fDistance = 925,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = unit:GetForwardVector() * speed
	}
	unit.projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)

end

function iskander_forward:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("sa_damage")
	giveUnitDataDrivenModifier(caster, hTarget, "stunned", 0.6)
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

end


modifier_iskandar_forward = class({})



function modifier_iskandar_forward:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end


function modifier_iskandar_forward:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_iskandar_forward:GetModifierDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end




function modifier_iskandar_forward:IsHidden()
	return false
end
function modifier_iskandar_forward:IsDebuff()
	return false
end

function modifier_iskandar_forward:GetEffectName()
	return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end
function modifier_iskandar_forward:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW 
end


modifier_iskandar_infantry_rush = class({})

function modifier_iskandar_infantry_rush:OnCreated(args)
	self.ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not IsServer() then return end
	local speed  = args.speed
	
	local sin = Physics:Unit(parent)
	parent:SetPhysicsFriction(0)
	parent:SetPhysicsVelocity(parent:GetForwardVector() * speed)
	parent:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer(0.5, function()
		parent:OnPreBounce(nil)
		parent:SetBounceMultiplier(0)
		parent:PreventDI(false)
		parent:SetPhysicsVelocity(Vector(0,0,0))
		parent:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
	return end
	)

	parent:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		ProjectileManager:DestroyLinearProjectile(parent.projectile)
		parent:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end



function modifier_iskandar_infantry_rush:IsHidden()
	return true
end
function modifier_iskandar_infantry_rush:IsDebuff()
	return false
end
 