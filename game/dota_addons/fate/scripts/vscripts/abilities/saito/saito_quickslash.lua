LinkLuaModifier("modifier_saito_quickslash","abilities/saito/saito_quickslash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_quickslash_bonus","abilities/saito/saito_quickslash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_quickslash_lock","abilities/saito/saito_quickslash", LUA_MODIFIER_MOTION_NONE)

saito_quickslash = class({})

function saito_quickslash:GetAOERadius()
    return self:GetSpecialValueFor("dist")
end


function saito_quickslash:GetCastPoint()
	 
	local Caster = self:GetCaster() 
	local stack_count = 0
	 
	if(Caster:HasModifier("modifier_saito_fdb_repeated")) then
		stack_count = Caster:GetModifierStackCount("modifier_saito_fdb_repeated", Caster) 
	end
	if(Caster:HasModifier("modifier_saito_fdb_lastQ")) then
		return 0.6
	end
	if stack_count <=2 then
		return 0.25
	elseif stack_count > 2 and stack_count < 4 then
		return 0.2
	else
		return 0.15
	end
end

local hitFlag = 0
function saito_quickslash:OnUpgrade()
    local Caster = self:GetCaster() 
	if(Caster:FindAbilityByName("saito_inv_sword"):GetLevel()< self:GetLevel()) then
		Caster:FindAbilityByName("saito_inv_sword"):SetLevel(self:GetLevel())
	end
	if(Caster:FindAbilityByName("saito_clap"):GetLevel()< self:GetLevel()) then
			Caster:FindAbilityByName("saito_clap"):SetLevel(self:GetLevel())
	end
end


 

function saito_quickslash:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local point  = self:GetCursorPosition()+caster:GetForwardVector()
	local lastq = false
	local direction      = (point - caster:GetAbsOrigin()):Normalized()
	direction.z = 0
	local modifier_jopa = caster:FindModifierByName("modifier_saito_fdb")
	local dist = self:GetSpecialValueFor("dist")
 
 
	 
	modifier_jopa:SpendStack()
 
	caster:SetForwardVector(direction)
	if( not caster:IsAlive()) then return end
	if(IsServer )then
		if(caster:HasModifier("modifier_saito_fdb_lastQ")) then
			dist = dist/2
		end
	end
	ProjectileManager:ProjectileDodge(caster)
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true and playerHero == self:GetCaster() then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_neow"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    hitFlag = 0
	local anim_rate = 1+(0.35-self:GetCastPoint())*2
	--StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1+anim_rate})  
	local target = point

 
 
    
	  
	 
	 
	if (target - caster:GetAbsOrigin()):Length2D() > dist then
		target = caster:GetAbsOrigin() + (((target - caster:GetAbsOrigin()):Normalized()) * dist)
	end
	self.fx = ParticleManager:CreateParticle("particles/saito/saito_quickslash_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.fx, 0, caster:GetAbsOrigin())
	local debuf_duration = ((target - caster:GetAbsOrigin()):Length2D()/self:GetSpecialValueFor("speed"))- 0.1
	caster:AddNewModifier(caster, caster, "modifier_saito_quickslash_lock", {duration = debuf_duration})
	giveUnitDataDrivenModifier(caster, caster, "locked", debuf_duration)
 
	caster:AddNewModifier(caster, caster, "modifier_saito_fdb_lastQ",{duration = 15})
	caster:RemoveModifierByName("modifier_saito_fdb_lastW")
	caster:RemoveModifierByName("modifier_saito_fdb_lastE")
	caster:EmitSound("saito_dash")
	local speed =self:GetSpecialValueFor("speed")
	if(caster.ShinsengumiAcquired and modifier_jopa:GetStackCount() == 0) then
		speed = 4000
	end
 
	local qdProjectile = 
	{
		Ability = ability,
        --EffectName = "particles/saito/saitoquickslash.vpcf",
        iMoveSpeed = self:GetSpecialValueFor("speed"),
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = (target - caster:GetAbsOrigin()):Length2D(),
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector()*speed
	}

	--caster:EmitSound("Astolfo_Slide_" .. math.random(1,5))

	local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
	if(speed < 3000) then
		local sin = Physics:Unit(caster)
		caster:SetPhysicsFriction(0)
		caster:SetPhysicsVelocity(caster:GetForwardVector() * speed)
		caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		--local startpos = self:GetAbsOrigin()
		Timers:CreateTimer( (target - caster:GetAbsOrigin()):Length2D()/speed/2, function()
			if(hitFlag  == 0 ) then
				caster:StopAnimation()
				StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_1_END, rate=1+anim_rate})
			end
		end)
		Timers:CreateTimer("saito_dash", {
			endTime = (target - caster:GetAbsOrigin()):Length2D()/(speed),
			callback = function()
			caster:OnPreBounce(nil)
			caster:SetBounceMultiplier(0)
			caster:PreventDI(false)
			caster:SetPhysicsVelocity(Vector(0,0,0))
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			caster:AddNewModifier(caster, self, "modifier_saito_quickslash", {duration = self:GetSpecialValueFor("dist")/self:GetSpecialValueFor("speed")/4})
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false) 
			if(targets[1] ~= nil ) then
				 
				--caster:SetForwardVector((targets[1]:GetAbsOrigin() -caster:GetAbsOrigin()):Normalized())
				caster:MoveToTargetToAttack(targets[1])
			else
				 
				caster:FaceTowards(target)
				
			end
			caster:RemoveModifierByName("modifier_saito_quickslash_lock")
			ParticleManager:DestroyParticle(self.fx, false)
			ParticleManager:ReleaseParticleIndex(self.fx)
		end})
	else
		if (point - caster:GetAbsOrigin()):Length2D() > dist then
			point = caster:GetAbsOrigin() + (((point - caster:GetAbsOrigin()):Normalized()) * dist)
		end
		FindClearSpaceForUnit( caster, point, true )
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false) 
		if(targets[1] ~= nil ) then
			caster:Stop()
			--caster:SetForwardVector((targets[1]:GetAbsOrigin() -caster:GetAbsOrigin()):Normalized())
			caster:MoveToTargetToAttack(targets[1])
		else
			caster:Stop()
			caster:FaceTowards(target)
		end
		
	end

	
	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("saito_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		hitFlag = 1
		unit:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
        ProjectileManager:DestroyLinearProjectile(projectile)
		EndAnimation(unit)
		unit:RemoveModifierByName("modifier_saito_quickslash_lock")
		ParticleManager:DestroyParticle(self.fx, false)
		ParticleManager:ReleaseParticleIndex(self.fx)
	end)
 
end

function saito_quickslash:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage") + caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
	if(caster.FreestyleAcquired) then
        damage = damage + caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
		
    end
	if(caster.MasteryAcquired) then
		caster:AddNewModifier(caster, self, "modifier_saito_quickslash_bonus",{duration = 2})
	end
	--hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	giveUnitDataDrivenModifier(caster,hTarget, "rooted", 0.2)
	--local slashes = ParticleManager:CreateParticle("particles/saito/saito_slash_enemy.vpcf", PATTACH_CUSTOMORIGIN, nil)
	--ParticleManager:SetParticleControl(slashes, 0, hTarget:GetAbsOrigin())

end





modifier_saito_quickslash = class({})
function modifier_saito_quickslash:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE }

	return funcs
end

function modifier_saito_quickslash:GetModifierTurnRate_Percentage()
	return 300
end
function modifier_saito_quickslash:IsHidden() return true end
function modifier_saito_quickslash:IsDebuff() return false end
function modifier_saito_quickslash:RemoveOnDeath() return true end

modifier_saito_quickslash_lock = class({})
function modifier_saito_quickslash_lock:CheckState()
    local state =   { 
                        
						[MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,

                    }
    return state
end

function modifier_saito_quickslash_lock:OnCreated()
	
	--	ParticleManager:SetParticleControl(self.fx, 3, self:GetParent():GetAbsOrigin())
end

 

function modifier_saito_quickslash_lock:IsHidden() return true end
function modifier_saito_quickslash_lock:IsDebuff() return false end
function modifier_saito_quickslash_lock:RemoveOnDeath() return true end




modifier_saito_quickslash_bonus = class({})


function modifier_saito_quickslash_bonus:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE }

	return funcs
end

function modifier_saito_quickslash_bonus:GetModifierTurnRate_Percentage()
	return self:GetAbility():GetSpecialValueFor("turnrate_bonus")
end
function modifier_saito_quickslash_bonus:IsHidden() return false end
function modifier_saito_quickslash_bonus:IsDebuff() return false end
function modifier_saito_quickslash_bonus:RemoveOnDeath() return true end




 