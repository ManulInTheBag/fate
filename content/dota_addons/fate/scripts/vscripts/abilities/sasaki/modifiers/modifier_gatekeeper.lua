modifier_gatekeeper = class({})

function modifier_gatekeeper:OnCreated(keys)
	if IsServer() then
		local caster = self:GetParent()
		self.Anchor = self:GetParent():GetAbsOrigin()
		self.LeashDistance = keys.LeashDistance
		self.BonusAttack = keys.BonusAttack

		self.CircleDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		local gkdummypassive = self.CircleDummy:FindAbilityByName("dummy_unit_passive")
		gkdummypassive:SetLevel(1)

		self:GetParent().IsEyeOfSerenityActive = true

		self.CircleFx = ParticleManager:CreateParticle( "particles/custom/archer/archer_clairvoyance_circle.vpcf", PATTACH_CUSTOMORIGIN, self.CircleDummy )
		ParticleManager:SetParticleControl( self.CircleFx, 0, self.CircleDummy:GetAbsOrigin() )
		ParticleManager:SetParticleControl( self.CircleFx, 1, Vector( self.LeashDistance, self.LeashDistance, self.LeashDistance ) )
		ParticleManager:SetParticleControl( self.CircleFx, 2, Vector( self:GetDuration(), 0, 0 ) )
		ParticleManager:SetParticleControl( self.CircleFx, 3, Vector( 255, 1, 255 ) )
	
		CustomNetTables:SetTableValue("sync","gatekeeper", { bonus_damage = self.BonusAttack })
	end
end

function modifier_gatekeeper:OnRefresh(args)
	if IsServer() then
		self:RemoveParticlesAndDummy()
		self:OnCreated(args)
	end
end

function modifier_gatekeeper:GetModifierMoveSpeed_Absolute()
	return 550
end

function modifier_gatekeeper:GetModifierPreAttack_BonusDamage()
	if IsServer() then
		return self.BonusAttack
	elseif IsClient() then
		local bonus_damage = CustomNetTables:GetTableValue("sync","gatekeeper").bonus_damage
        return bonus_damage 
	end
end

function modifier_gatekeeper:DeclareFunctions()
	local funcs = { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
					MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
					--MODIFIER_EVENT_ON_ATTACK_LANDED,
					MODIFIER_EVENT_ON_UNIT_MOVED }

	return funcs
end

function modifier_gatekeeper:OnUnitMoved()
	if IsServer() then
		local caster = self:GetParent()

		if math.abs((caster:GetAbsOrigin() - self.Anchor):Length2D()) > self.LeashDistance then
			self:Destroy()
		end
	end
end

function modifier_gatekeeper:OnAttackLanded(args)
	if IsServer() then
		if args.attacker ~= self:GetParent() then return end

		local caster = self:GetParent()

		caster:Heal(self.BonusAttack, caster)

		if caster:HasModifier("modifier_minds_eye_attribute") and (not caster:HasModifier("modifier_exhausted")) then
			caster:GiveMana(10)
		end
	end
end

function modifier_gatekeeper:OnDestroy()
	if IsServer() then
		self:RemoveParticlesAndDummy()

		self:GetParent().IsEyeOfSerenityActive = false

		local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 10000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for k,v in pairs(targets) do
			v:RemoveModifierByName("modifier_sasaki_vision")
		end
	end
end

function modifier_gatekeeper:RemoveParticlesAndDummy()
	if IsServer() then
		local caster = self:GetParent()

		ParticleManager:DestroyParticle(self.CircleFx, false)
	    ParticleManager:ReleaseParticleIndex(self.CircleFx)
		self.CircleDummy:RemoveSelf()

		if math.abs((caster:GetAbsOrigin() - self.Anchor):Length2D()) > self.LeashDistance then
			caster:EmitSound("Sasaki_Gatekeeper_1")
		end
	end
end

------------------------------------------------------------------------------------

function modifier_gatekeeper:IsHidden()
	return false
end

function modifier_gatekeeper:IsDebuff()
	return false
end

function modifier_gatekeeper:RemoveOnDeath()
	return true
end

function modifier_gatekeeper:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_gatekeeper:GetTexture()
	return "custom/false_assassin_gate_keeper"
end

------------------------------------------------------------------------------------