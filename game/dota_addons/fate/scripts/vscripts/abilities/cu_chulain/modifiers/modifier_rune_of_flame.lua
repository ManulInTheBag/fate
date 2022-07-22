modifier_rune_of_flame = class({})

if IsServer() then
	function modifier_rune_of_flame:OnCreated(args)
		self.Radius = args.Radius
		self.Damage = args.Damage
		self.StunDuration = args.StunDuration

		self:StartIntervalThink(0.25)
	end

	function modifier_rune_of_flame:OnIntervalThink()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local targets = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
		if #targets > 0 then
			for i = 1, #targets do
				DoDamage(caster, targets[i], self.Damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				targets[i]:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", { Duration = self.StunDuration })
			end

			parent:EmitSound("Hero_TemplarAssassin.Trap.Explode")

			local fxDummy = CreateUnitByName("dummy_unit", parent:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			fxDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)	

			local trapFX = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_trap_explode.vpcf", PATTACH_ABSORIGIN_FOLLOW, fxDummy)
			ParticleManager:SetParticleControl(trapFX, 0, fxDummy:GetAbsOrigin())

			Timers:CreateTimer(2, function()
				ParticleManager:DestroyParticle(trapFX, false )
				fxDummy:RemoveSelf()
			end)

			self:Destroy()
		end
	end

	function modifier_rune_of_flame:OnDestroy()
		local parent = self:GetParent()
		parent:ForceKill(true)
	end
end

function modifier_rune_of_flame:RemoveOnDeath()
	return true 
end

function modifier_rune_of_flame:IsHidden()
	return true 
end