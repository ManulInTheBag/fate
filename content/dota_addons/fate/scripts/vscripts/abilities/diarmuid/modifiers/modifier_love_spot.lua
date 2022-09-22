modifier_love_spot = class({})

LinkLuaModifier("modifier_love_spot_charmed", "abilities/diarmuid/modifiers/modifier_love_spot_charmed", LUA_MODIFIER_MOTION_NONE)

function modifier_love_spot:OnCreated(args)
	if IsServer() then
		local caster = self:GetParent()
		caster:EmitSound("Hero_Warlock.ShadowWord")

		self.Radius = args.Radius

		self:StartIntervalThink(0.25)
	end
end

function modifier_love_spot:OnRefresh(args)
	if IsServer() then
		self:OnDestroy()
		self:OnCreated(args)
	end
end

function modifier_love_spot:OnDestroy()
	if IsServer() then
		--print("stopping sound")
		local caster = self:GetCaster()
		caster:StopSound("Hero_Warlock.ShadowWord")
	end
end

function modifier_love_spot:OnIntervalThink()
	local caster = self:GetParent()
	local ability = self:GetAbility()
	local forcemove = {
		UnitIndex = nil,
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION ,
		Position = nil
	}
	--print("thinking")

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		--print("found unit")
		if IsFemaleServant(v) then
			--print("moving dis chick")
			v:AddNewModifier(caster, self:GetAbility(), "modifier_love_spot_charmed", { Duration = 0.25 })
			giveUnitDataDrivenModifier(caster, v, "silenced", 0.25)
			forcemove.UnitIndex = v:entindex()
			forcemove.Position = caster:GetAbsOrigin() 
			v:Stop()
			ExecuteOrderFromTable(forcemove) 
		    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, v)
		    ParticleManager:SetParticleControl(particle, 0, v:GetAbsOrigin())
		end
	end
    local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
end