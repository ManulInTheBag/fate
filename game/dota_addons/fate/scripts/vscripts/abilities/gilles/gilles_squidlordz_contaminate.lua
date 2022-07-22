gilles_squidlordz_contaminate = class({})
modifier_contaminate_poison = class({})

LinkLuaModifier("modifier_contaminate_poison", "abilities/gilles/gilles_squidlordz_contaminate", LUA_MODIFIER_MOTION_NONE)

function gilles_squidlordz_contaminate:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gilles_squidlordz_contaminate:OnSpellStart()
	local hCaster = self:GetCaster()

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hCaster:GetAbsOrigin(), nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(tEnemies) do		
		v:AddNewModifier(hCaster, self, "modifier_contaminate_poison", { Damage = self:GetSpecialValueFor("damage"), 
																		 Duration = self:GetSpecialValueFor("duration") })
	end

	hCaster:EmitSound("Hero_Venomancer.PoisonNova")
	local poisonCloud = ParticleManager:CreateParticle("particles/custom/gilles/squidlord_contaminate.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
	ParticleManager:SetParticleControl(poisonCloud, 0, hCaster:GetAbsOrigin())
	ParticleManager:SetParticleControl(poisonCloud, 1, Vector(self:GetAOERadius() + 200,0,0))
	
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( poisonCloud, false )
		ParticleManager:ReleaseParticleIndex( poisonCloud )
	end)
end

if IsServer() then 
	function modifier_contaminate_poison:OnCreated(args)
		self.Damage = args.Damage * 0.33 / self:GetDuration()

		self:StartIntervalThink(0.33)

		self.Particle = ParticleManager:CreateParticle("particles/custom/gilles/contaminate_debuff", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlEnt(self.Particle, 0, self:GetParent(), PATTACH_CUSTOMORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	end

	function modifier_contaminate_poison:OnRefresh(args)
		self.Damage = args.Damage * 0.33 / self:GetDuration()
	end

	function modifier_contaminate_poison:OnDestroy()
		ParticleManager:DestroyParticle( self.Particle, false )
		ParticleManager:ReleaseParticleIndex( self.Particle )
	end

	function modifier_contaminate_poison:OnIntervalThink()
		DoDamage(self:GetCaster(), self:GetParent(), self.Damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end

function modifier_contaminate_poison:IsDebuff()
	return true 
end

function modifier_contaminate_poison:RemoveOnDeath()
	return true 
end

function modifier_contaminate_poison:GetTexture()
	return "custom/gille_contaminate"
end