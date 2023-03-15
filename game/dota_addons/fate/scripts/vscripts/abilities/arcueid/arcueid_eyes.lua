LinkLuaModifier("modifier_arcueid_eyes", "abilities/arcueid/arcueid_eyes", LUA_MODIFIER_MOTION_NONE)

arcueid_eyes = class({})

function arcueid_eyes:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_arcueid_eyes", { Duration = self:GetSpecialValueFor("duration"),	Radius = self:GetSpecialValueFor("radius") })
	
	caster:EmitSound("Hero_Warlock.ShadowWord")
end

modifier_arcueid_eyes = class({})

function modifier_arcueid_eyes:OnCreated(args)
	if IsServer() then
		local caster = self:GetParent()
		caster:EmitSound("Hero_Warlock.ShadowWord")

		self.Radius = args.Radius

		self:StartIntervalThink(0.25)
	end
end

function modifier_arcueid_eyes:OnRefresh(args)
	if IsServer() then
		self:OnDestroy()
		self:OnCreated(args)
	end
end

function modifier_arcueid_eyes:OnDestroy()
	if IsServer() then
		--print("stopping sound")
		local caster = self:GetCaster()
		caster:StopSound("Hero_Warlock.ShadowWord")
	end
end

function modifier_arcueid_eyes:OnIntervalThink()
	local caster = self:GetParent()
	local ability = self:GetAbility()
	local forcemove = {
		UnitIndex = nil,
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET ,
		TargetIndex = nil
	}
	--print("thinking")

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		--print("found unit")
		forcemove.UnitIndex = v:entindex()
		forcemove.TargetIndex = caster:entindex()
		v:Stop()
		ExecuteOrderFromTable(forcemove) 
		local particle = ParticleManager:CreateParticle("particles/arcueid/arc_eyes_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, v)
		ParticleManager:SetParticleControl(particle, 0, v:GetAbsOrigin())
	end

    local particle2 = ParticleManager:CreateParticle("particles/arcueid/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
end