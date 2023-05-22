emiya_caladbolg = emiya_caladbolg or class({})


function emiya_caladbolg:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self

	if caster:FindAbilityByName("emiya_overedge_circle"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_overedge_circle"):SetLevel(self:GetLevel())
    end
	if caster:FindAbilityByName("emiya_crane_wings"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_crane_wings"):SetLevel(self:GetLevel())
    end
 
end



 
function emiya_caladbolg:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
    caster:FindAbilityByName("emiya_crane_wings"):SetLevel(self:GetLevel())    
end

function emiya_caladbolg:OnSpellStart()
	if(not self.frames or self.frames == 0) then
		self.frames = 0
		self.maxtime = self:GetSpecialValueFor("max_channel")
		self:StartCharging()
	end
end

function emiya_caladbolg:StartCharging()
    local caster = self:GetCaster()
	caster:AddNewModifier(caster,self,"modifier_emiya_caladbolg", {duration = self.maxtime})
	StartAnimation(caster, {duration=3, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
	self.charge = ParticleManager:CreateParticle("particles/emiya/emiya_caladbolg_charge.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.charge, 0, caster:GetAbsOrigin())
	Timers:CreateTimer(0.5, function()
		if(caster:GetAbilityByIndex(2):GetName() == "emiya_caladbolg") and caster:HasModifier("modifier_emiya_caladbolg") then
			caster:SwapAbilities("emiya_caladbolg", "emiya_caladbolg_release", false, true)
		end
	
	end)
end

 
 

function emiya_caladbolg:ReleaseArrow(frames)
	local caster = self:GetCaster()
	EndAnimation(caster)
	caster:EmitSound("Ability.Powershot.Alt")
	caster:RemoveModifierByNameAndCaster("modifier_emiya_caladbolg", caster)
    local casterFX = ParticleManager:CreateParticle("particles/emiya/caladbolg_init.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControlEnt(casterFX, 1, caster, PATTACH_ABSORIGIN, nil, caster:GetOrigin(), false)
    ParticleManager:ReleaseParticleIndex(casterFX)
	local target = caster:GetForwardVector()
	local range = (self:GetSpecialValueFor("range") + (caster.IsEagleEyeAcquired and 1000 or 0))  * (0.5 + frames/(self.maxtime*60))
	caster:EmitSound("Emiya_Caladbolg_" .. math.random(1,2))
	local tProjectile = {
		EffectName = "particles/emiya/caladbolg.vpcf",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = target * self:GetSpecialValueFor("speed") ,
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
		ExtraData = {fDamage = self:GetSpecialValueFor("damage") * frames/(self.maxtime*30), fRadius = self:GetSpecialValueFor("radius")}
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
	--self:StartCooldown(self:GetLevel())	  	
end

function emiya_caladbolg:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	if(hTarget ~= nil) then
		local explosionFx = ParticleManager:CreateParticle("particles/emiya/caladbolg_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(explosionFx, 1, hTarget:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosionFx, 0, hTarget:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosionFx, 3, hTarget:GetAbsOrigin())
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
			DoDamage(hCaster, enemy, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			giveUnitDataDrivenModifier(hCaster,  enemy, "stunned", self:GetSpecialValueFor("stun_duration"))
       	end
		   hTarget:EmitSound("Misc.Crash")

		
	end
   	Timers:CreateTimer(0.033,function()
   		ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	end)
	return true
end

function emiya_caladbolg:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
end

LinkLuaModifier("modifier_emiya_caladbolg", "abilities/emiya/emiya_caladbolg", LUA_MODIFIER_MOTION_NONE)

modifier_emiya_caladbolg = modifier_emiya_caladbolg or class({})

function modifier_emiya_caladbolg:IsHidden() return false end
function modifier_emiya_caladbolg:IsDebuff() return false end
function modifier_emiya_caladbolg:IsPurgable() return false end
function modifier_emiya_caladbolg:RemoveOnDeath() return true end
function modifier_emiya_caladbolg:CheckState()
    local state = { [MODIFIER_STATE_ROOTED] = true,
					[MODIFIER_STATE_SILENCED] = true,
					[MODIFIER_STATE_DISARMED] = true,
					[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true, }
    return state
end

 
function modifier_emiya_caladbolg:OnCreated(hTable)
   self.ability = self:GetAbility()

   self.baseRange =  self.ability:GetSpecialValueFor("range") +(self:GetCaster().IsEagleEyeAcquired and 1000 or 0) - 50
   self.MaxFrames = self.ability.maxtime
   self.caster = self:GetCaster()
   if(not self.arrowFx or self.arrowFx == nil) then
	if IsServer() then
  	 self.arrowFx = ParticleManager:CreateParticleForPlayer("particles/muramasa/vector.vpcf", PATTACH_CUSTOMORIGIN, nil, self.caster:GetPlayerOwner())
  	 ParticleManager:SetParticleControl(self.arrowFx, 0, self.caster:GetAbsOrigin())
	   
	 		ParticleManager:SetParticleControl(self.arrowFx, 1, self.caster:GetAbsOrigin()+ self.caster:GetForwardVector() * self.baseRange *0.5)
			 ParticleManager:SetParticleControl(self.arrowFx, 4, Vector(0,0,254)) -- color
	   end
  	 
   end
   self:StartIntervalThink(FrameTime())
end

 
function modifier_emiya_caladbolg:OnIntervalThink()
	if self.caster:IsStunned() then self:Destroy() return end
	if IsServer() then
    	self.ability.frames = self.ability.frames + 1
		ParticleManager:SetParticleControl(self.arrowFx, 0, self.caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(self.arrowFx, 1, self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * self.baseRange * (0.5 + self.ability.frames/( self.MaxFrames*60)))
		
	end
end
 
function modifier_emiya_caladbolg:OnDestroy()
	if self.arrowFx ~= nil then
		ParticleManager:DestroyParticle(self.arrowFx, true)
		ParticleManager:ReleaseParticleIndex(self.arrowFx)
	end
	if self.ability.charge ~= nil then
		ParticleManager:DestroyParticle( self.ability.charge, true)
		ParticleManager:ReleaseParticleIndex( self.ability.charge)
	end
	self.arrowFx = nil
	if IsServer() then
		self.ability:ReleaseArrow(self.ability.frames)
		self.ability.frames = 0
		if( self.caster:GetAbilityByIndex(2):GetName() == "emiya_caladbolg_release") then
			self.caster:SwapAbilities("emiya_caladbolg", "emiya_caladbolg_release", true, false)
		end
	end
end
