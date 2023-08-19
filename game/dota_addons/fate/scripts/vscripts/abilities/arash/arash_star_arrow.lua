arash_star_arrow = arash_star_arrow or class({})


LinkLuaModifier("modifier_arash_slow", "abilities/arash/arash_star_arrow", LUA_MODIFIER_MOTION_NONE)


modifier_arash_slow = class({})

function modifier_arash_slow:IsDebuff() return true end
function modifier_arash_slow:IsHidden() return false end
function modifier_arash_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_arash_slow:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetAbility():GetSpecialValueFor("ms_slow"))
end

 

function arash_star_arrow:OnSpellStart()
	local caster = self:GetCaster()
	if(not self.frames or self.frames == 0) then
		self.frames = 0
		self.maxtime = self:GetSpecialValueFor("charge_duration")
		self:StartCharging()
	end
	caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
end

function arash_star_arrow:StartCharging()
    local caster = self:GetCaster()
	caster:AddNewModifier(caster,self,"modifier_arash_star_arrow", {duration = self.maxtime + 3})
	--StartAnimation(caster, {duration=3, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})

	Timers:CreateTimer(0.1, function()
		if(caster:GetAbilityByIndex(0):GetName() == "arash_star_arrow") and caster:HasModifier("modifier_arash_star_arrow") then
			caster:SwapAbilities("arash_star_arrow", "arash_star_arrow_release", false, true)
		end
	
	end)

end

 
 

function arash_star_arrow:ReleaseArrow(vector)
	local caster = self:GetCaster()
	EndAnimation(caster)
	local enemy = PickRandomEnemy(caster)
	local frames = self.frames
	if frames > 60 then frames = 60 end
    if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 1 })
    end
	local color  = Vector(255,255,255)
	if(frames > 30 and frames <60 ) then 
		color = Vector(80,255,255)
	elseif frames >=60 then
		color = Vector(0,100,255)
	end
	caster:EmitSound("Ability.Powershot.Alt")
	caster:RemoveModifierByNameAndCaster("modifier_arash_star_arrow", caster)
    local casterFX = ParticleManager:CreateParticle("particles/arash/arash_star_arrow_init.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControlEnt(casterFX, 1, caster, PATTACH_ABSORIGIN, nil, caster:GetOrigin(), false)
	ParticleManager:SetParticleControl(casterFX, 6,Vector(1,0,0))
	ParticleManager:SetParticleControl(casterFX, 15, color)
    ParticleManager:ReleaseParticleIndex(casterFX)
	local range = (self:GetSpecialValueFor("max_range") + (caster.ArashClairvoyance and caster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("star_arrow_bonus_range") or 0))  * (0.5 + frames/(self.maxtime*60))
	local speed = self:GetSpecialValueFor("speed")
	local vSpawnLoc = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))
	local sParticle = "particles/arash/arash_star_arrow.vpcf" 
     self.nParticle =  ParticleManager:CreateParticle(sParticle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW( self.nParticle, false)
    ParticleManager:SetParticleAlwaysSimulate( self.nParticle)
    ParticleManager:SetParticleControl( self.nParticle, 0, vSpawnLoc)
    --ParticleManager:SetParticleControl( self.nParticle, 1, GetGroundPosition(vPoint, nil))
    ParticleManager:SetParticleControl( self.nParticle, 1, speed * vector)
    ParticleManager:SetParticleControl( self.nParticle, 6, Vector(1, 0, 0))
    ParticleManager:SetParticleControl( self.nParticle, 15, color)
	Timers:CreateTimer(range/speed + 0.05, function()
		if type( self.nParticle) == "number" then
			ParticleManager:DestroyParticle( self.nParticle, false)
			ParticleManager:ReleaseParticleIndex( self.nParticle)
		end
	
	end)
	local tProjectile = {
		EffectName = "",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = vector * speed ,
		fDistance = range,
		fStartRadius = 100,
		fEndRadius = 100,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = 0,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		--bProvidesVision = true,
		bDeleteOnHit = true,
		--iVisionRadius = 500,
		--bFlyingVision = true,
		--iVisionTeamNumber = caster:GetTeamNumber(),
		ExtraData = {fDamage = self:GetSpecialValueFor("damage") * frames/(self.maxtime*30),
					 fRadius = self:GetSpecialValueFor("radius"), fDamagePct = self:GetSpecialValueFor("damage_pct"), 
					 colortype = 0 + (frames > 30 and 1 or 0) + (frames >=60 and 1 or 0)}
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
	--self:StartCooldown(self:GetLevel())	  	
end
 
function arash_star_arrow:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	if(hTarget ~= nil) then
		if type( self.nParticle) == "number" then
			ParticleManager:DestroyParticle( self.nParticle, false)
			ParticleManager:ReleaseParticleIndex( self.nParticle)
		end
		local explosionFx =  ParticleManager:CreateParticle("particles/arash/arash_star_arrow_explosion_hit.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleShouldCheckFoW(explosionFx, false)
		ParticleManager:SetParticleAlwaysSimulate( explosionFx)
		ParticleManager:SetParticleControl( explosionFx, 3, hTarget:GetAbsOrigin() + Vector(0,0,50))
		ParticleManager:SetParticleControl( explosionFx, 6, Vector(1,0,0))
		local color  = Vector(255,255,255)
		if(tData.colortype == 1 ) then 
			color = Vector(80,255,255)
		elseif tData.colortype == 2  then
			color = Vector(0,100,255)
		end
		ParticleManager:SetParticleControl( explosionFx, 15, color)
		ParticleManager:ReleaseParticleIndex(explosionFx)
		local enemies = FindUnitsInRadius(  hCaster:GetTeamNumber(),
						hTarget:GetAbsOrigin(),
                        nil,
                        tData.fRadius,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
    
     	for _,enemy in pairs(enemies) do
			DoDamage(hCaster, enemy, tData.fDamage * (1 + (hCaster.ArashClairvoyance and hCaster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("star_arrow_bonus_damage")/100 or 0)), DAMAGE_TYPE_MAGICAL, 0, self, false)
			DoDamage(hCaster, enemy, enemy:GetMaxHealth()*tData.fDamagePct/100 * (1 + (hCaster.ArashClairvoyance and hCaster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("star_arrow_bonus_damage")/100 or 0)), DAMAGE_TYPE_MAGICAL, 0, self, false)
			hCaster:AddNewModifier(enemy, self, "modifier_arash_slow", {duration  = self:GetSpecialValueFor("ms_slow_duration")})
			print(tData.fDamage * (1 + (hCaster.ArashClairvoyance and hCaster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("star_arrow_bonus_damage")/100 or 0)))
			print(enemy:GetMaxHealth()*tData.fDamagePct/100 * (1 + (hCaster.ArashClairvoyance and hCaster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("star_arrow_bonus_damage")/100 or 0)))
		end
		if hCaster.ArashClairvoyance then 
			self:CreateClair(hTarget:GetAbsOrigin())
		end
		hTarget:EmitSound("arash_attack_hit")

		
	end
   	Timers:CreateTimer(0.033,function()
   		ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	end)
	return true
end

function arash_star_arrow:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

	AddFOWViewer(2, location, 40, 0.4, false)
    AddFOWViewer(3, location, 40, 0.4, false)
end

function arash_star_arrow:CreateClair(position)
	local caster = self:GetCaster()
	local duration =  caster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("clair_duration")
	local radius = caster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("clair_radius")
	local visiondummy = SpawnVisionDummy(caster, position, radius, duration, true)
	
	local circleFxIndexEnemyTeam = ParticleManager:CreateParticleForTeam( "particles/custom/archer/archer_clairvoyance_circle_enemyteam.vpcf",  PATTACH_WORLDORIGIN, nil, caster:GetOpposingTeamNumber() )
	ParticleManager:SetParticleShouldCheckFoW(circleFxIndexEnemyTeam, false)
	ParticleManager:SetParticleControl( circleFxIndexEnemyTeam, 0, visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( circleFxIndexEnemyTeam, 1, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( circleFxIndexEnemyTeam, 2, Vector( 8, 0, 0 ) )

	local circleFxIndexTeam = ParticleManager:CreateParticleForTeam( "particles/custom/archer/archer_clairvoyance_circle_yourteam.vpcf", PATTACH_WORLDORIGIN, nil,caster:GetTeamNumber() )
	ParticleManager:SetParticleControl( circleFxIndexTeam, 0, visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( circleFxIndexTeam, 1, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( circleFxIndexTeam, 2, Vector( 8, 0, 0 ) )
	ParticleManager:SetParticleControl( circleFxIndexTeam, 3, Vector( 100, 255, 255 ) )
	
	local dustFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_clairvoyance_dust.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleShouldCheckFoW(dustFxIndex, false)
	ParticleManager:SetParticleControl( dustFxIndex, 0, visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( dustFxIndex, 1, Vector( radius, radius, radius ) )
	
	visiondummy.circle_fx = circleFxIndex
	visiondummy.dust_fx = dustFxIndex
	ParticleManager:SetParticleControl( dustFxIndex, 1, Vector( radius, radius, radius ) )
			
	-- Destroy particle after delay
	Timers:CreateTimer(duration, function()
		ParticleManager:DestroyParticle( circleFxIndexEnemyTeam, true )
			ParticleManager:DestroyParticle( dustFxIndex, true )
			ParticleManager:ReleaseParticleIndex( circleFxIndexEnemyTeam )
			ParticleManager:ReleaseParticleIndex( dustFxIndex )
			ParticleManager:DestroyParticle( circleFxIndexTeam, true )
			ParticleManager:ReleaseParticleIndex( circleFxIndexTeam )
		return nil
	end)

	EmitSoundOnLocationWithCaster(position, "Hero_KeeperOfTheLight.BlindingLight", visiondummy)

end

LinkLuaModifier("modifier_arash_star_arrow", "abilities/arash/arash_star_arrow", LUA_MODIFIER_MOTION_NONE)

modifier_arash_star_arrow = modifier_arash_star_arrow or class({})

function modifier_arash_star_arrow:IsHidden() return false end
function modifier_arash_star_arrow:IsDebuff() return false end
function modifier_arash_star_arrow:IsPurgable() return false end
function modifier_arash_star_arrow:RemoveOnDeath() return true end
function modifier_arash_star_arrow:CheckState()
    local state = { [MODIFIER_STATE_ROOTED] = false,
					[MODIFIER_STATE_SILENCED] = false,
					[MODIFIER_STATE_DISARMED] = true,
					[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = false, }
    return state
end

function modifier_arash_star_arrow:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
						MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
						   
                    }
    return hFunc
end
function modifier_arash_star_arrow:GetActivityTranslationModifiers(keys)
    return  "star_arrow"
end

function modifier_arash_star_arrow:GetModifierMoveSpeedBonus_Percentage(keys)
    return  -50
end
 
 
function modifier_arash_star_arrow:OnCreated(hTable)
   self.ability = self:GetAbility()

   self.baseRange =  self.ability:GetSpecialValueFor("range") +(self:GetCaster().IsEagleEyeAcquired and 1000 or 0) - 50
   self.MaxFrames = self.ability.maxtime
   self.caster = self:GetCaster()
   if IsServer() then
   	self.nParticle =  ParticleManager:CreateParticle("particles/arash/arash_star_arrow_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
   	ParticleManager:SetParticleControlEnt(self.nParticle, 0, self.caster, PATTACH_POINT_FOLLOW, "arrow_pos", Vector(0,0,0), true)
   	ParticleManager:SetParticleControl(self.nParticle, 6, Vector(1,0,0))
   	ParticleManager:SetParticleControl(self.nParticle, 1, Vector(5,50,0)) -- radius
   	ParticleManager:SetParticleControl(self.nParticle, 15, Vector(255,255,255)) -- color
   end
   self:StartIntervalThink(FrameTime())
end

 
function modifier_arash_star_arrow:OnIntervalThink()
	if IsServer() then
    	self.ability.frames = self.ability.frames + 1	
		if(self.ability.frames == 30) then
			ParticleManager:SetParticleControl(self.nParticle, 1, Vector(5,75,0)) -- radius
			ParticleManager:SetParticleControl(self.nParticle, 15, Vector(0,255,255)) -- color
		end
		if(self.ability.frames == 60) then
			ParticleManager:SetParticleControl(self.nParticle, 1, Vector(5,150,0)) -- radius
			ParticleManager:SetParticleControl(self.nParticle, 15, Vector(0,100,255)) -- color
		end
	end
end
 
function modifier_arash_star_arrow:OnDestroy()
	if type(self.nParticle) == "number" then
		ParticleManager:DestroyParticle(self.nParticle, false)
		ParticleManager:ReleaseParticleIndex(self.nParticle)
	end
	if IsServer() then
		self.ability.frames = 0
		if( self.caster:GetAbilityByIndex(0):GetName() == "arash_star_arrow_release") then
			self.caster:SwapAbilities("arash_star_arrow", "arash_star_arrow_release", true, false)
		end
	end
end
