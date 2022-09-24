gilgamesh_gate_of_babylon = class({})
LinkLuaModifier("modifier_gob_thinker","abilities/gilgamesh/gilgamesh_gate_of_babylon", LUA_MODIFIER_MOTION_NONE)


 



function gilgamesh_gate_of_babylon:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Gilgamesh.GOB")
	caster:EmitSound("Saber_Alter.Derange")
	caster:EmitSound("Archer.UBWAmbient")
	local frontward = caster:GetForwardVector()
	self.dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin() - 60 * frontward, false, caster, caster, caster:GetTeamNumber())
	self.dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.dummy:SetForwardVector(caster:GetForwardVector())
	self.dummy:AddNewModifier(caster,self, "modifier_gob_thinker", {Duration  = self:GetSpecialValueFor("duration")})
	self.lastgobdummy = self.dummy 

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if self == caster:FindAbilityByName("gilgamesh_gate_of_babylon") and caster:FindAbilityByName("gilgamesh_enuma_elish"):IsCooldownReady() and caster:FindAbilityByName("gilgamesh_max_enuma_elish"):IsCooldownReady() then
			caster:SwapAbilities("gilgamesh_enuma_elish", "gilgamesh_max_enuma_elish", false, true) 
			Timers:CreateTimer({
				endTime = 5,
				callback = function()
				caster:SwapAbilities("gilgamesh_enuma_elish", "gilgamesh_max_enuma_elish", true, false) 
			end
			})			
		end
	end

end

function gilgamesh_gate_of_babylon:FireProjectile(vOrigin, vForwardVector, dummy)
	local caster = self:GetCaster()
 
	local portalFxIndex = ParticleManager:CreateParticle( "particles/gilgamesh/gob.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy )
	ParticleManager:SetParticleControl(portalFxIndex, 3, vOrigin ) 
	ParticleManager:SetParticleControl(portalFxIndex, 10, Vector(1,0,0)) 
	Timers:CreateTimer(0.4, function()
		ParticleManager:DestroyParticle(portalFxIndex, true)
		ParticleManager:ReleaseParticleIndex(portalFxIndex)

	end)
	local gobWeapon = 
	{
		Ability = self,
        EffectName = "particles/gilgamesh/gob_weapon.vpcf",
        vSpawnOrigin = vOrigin +vForwardVector * -60,
        --fDistance = self:GetSpecialValueFor("range"),
		fDistance = 1000,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = self:GetCaster(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 0.5,
		bDeleteOnHit = true,
		vVelocity = vForwardVector * 3000
	}

	ProjectileManager:CreateLinearProjectile(gobWeapon)
end

function gilgamesh_gate_of_babylon:OnProjectileHit_ExtraData(hTarget, vLocation, table)	
	if(hTarget == nil) then return end
	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")	
	local damage1 = 0
	if hCaster.IsSumerAcquired then
		damage1 = hCaster:GetAttackDamage() * 0.175
		DoDamage(hCaster, hTarget, damage1, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	end
	
	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	local particle = ParticleManager:CreateParticle("particles/custom_game/heroes/gilgamesh/gilgamesh_enlarge_gate_hit/gilgamesh_enlarge_gate_hit.vpcf", PATTACH_ABSORIGIN, hTarget)
	ParticleManager:SetParticleControl(particle, 0, hTarget:GetAbsOrigin())
	Timers:CreateTimer(0.3,function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	
	end)
	hTarget:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
end


modifier_gob_thinker = class({})

function modifier_gob_thinker:IsDebuff()
return false
end

function modifier_gob_thinker:IsHidden()
	return false
end
 


if IsServer() then
	function modifier_gob_thinker:OnCreated(args)
	
		self:StartIntervalThink(0.033)
	end


	function modifier_gob_thinker:OnDestroy()
		self:GetParent():RemoveSelf()
		 
	end


	function modifier_gob_thinker:OnIntervalThink()
		
		local caster = self:GetParent()
		local gil = self:GetCaster()
		if not gil:IsAlive() then return end 
		
		local ForwardVector= caster:GetForwardVector()
		if gil.IsSumerAcquired and self:GetAbility().lastgobdummy == caster and self:GetAbility():GetAutoCastState() == true  then
			caster:SetAbsOrigin(gil:GetAbsOrigin() - gil:GetForwardVector() )
			caster:SetForwardVector( gil:GetForwardVector() )
		end
	
 
		local sword_spawn = caster:GetAbsOrigin() + 	ForwardVector *-50 
		local leftvec = Vector(-ForwardVector.y, ForwardVector.x, 0)
		local rightvec = Vector(ForwardVector.y, -ForwardVector.x, 0)

		local random1 = RandomInt(0, 300) -- position of weapon spawn
		local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		local random3 = RandomInt(100,300)*Vector(0,0,1) --  
		

		if random2 == 0 then 
			sword_spawn = sword_spawn + leftvec * random1 + random3
		else 
			sword_spawn = sword_spawn + rightvec * random1 + random3
		end
		 
		self:GetAbility():FireProjectile(sword_spawn, ForwardVector,caster	)
	end
end