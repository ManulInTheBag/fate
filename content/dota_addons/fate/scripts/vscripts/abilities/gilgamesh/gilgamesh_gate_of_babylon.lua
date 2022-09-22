gilgamesh_gate_of_babylon = class({})
modifier_gob_thinker = class({})

function gilgamesh_gate_of_babylon:OnSpellStart()
	self.DummyGate = CreateUnitByName("dummy_unit", caster:GetAbsOrigin() - 250 * frontward, false, caster, caster, caster:GetTeamNumber())
	self.DummyGate:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.DummyGate:SetForwardVector(caster:GetForwardVector())
	
	local portalFxIndex = ParticleManager:CreateParticle( "particles/custom/gilgamesh/gilgamesh_gob.vpcf", PATTACH_CUSTOMORIGIN, self.DummyGate )
	ParticleManager:SetParticleControlEnt( portalFxIndex, 0, self.DummyGate, PATTACH_ABSORIGIN, nil, self.DummyGate:GetAbsOrigin(), false )
	ParticleManager:SetParticleControl( portalFxIndex, 1, Vector( 300, 300, 300 ) )
end

function gilgamesh_gate_of_babylon:FireProjectile(vOrigin, vForwardVector)
	self.DummyGate

	local gobWeapon = 
	{
		Ability = self,
        EffectName = "particles/custom/gilgamesh/gilgamesh_gob_model.vpcf",
        vSpawnOrigin = vOrigin,
        fDistance = self:GetSpecialValueFor("range"),
        fStartRadius = 100,
        fEndRadius = 100,
        Source = self:GetCaster(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 1.5,
		bDeleteOnHit = true,
		vVelocity = vForwardVector * 3000
	}

	ProjectileManager:CreateLinearProjectile(gobWeapon)
end

function gilgamesh_gate_of_babylon:OnProjectileHit_ExtraData(hTarget, vLocation, table)	
	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")	

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	local particle = ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_charlie/sniper_assassinate_impact_blood_charlie.vpcf", PATTACH_ABSORIGIN, hTarget)
	ParticleManager:SetParticleControl(particle, 1, hTarget:GetAbsOrigin())
	hTarget:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
end


if IsServer() then
	function modifier_gob_thinker:OnCreated(args)
		self.GateLocation = self:GetParent():GetAbsOrigin()
		self.ForwardVector = self:GetParent():GetForwardVector()
		self:StartIntervalThink(0.033)
	end

	function modifier_gob_thinker:OnIntervalThink()
		local sword_spawn = self.GateLocation

		local leftvec = Vector(-self.ForwardVector.y, self.ForwardVector.x, 0)
		local rightvec = Vector(self.ForwardVector.y, -self.ForwardVector.x, 0)

		local random1 = RandomInt(0, 300) -- position of weapon spawn
		local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero

		if random2 == 0 then 
			sword_spawn = sword_spawn + leftvec * random1
		else 
			sword_spawn = sword_spawn + rightvec * random1
		end

		self:GetAbility():FireProjectile(sword_spawn, self.ForwardVector)
	end
end