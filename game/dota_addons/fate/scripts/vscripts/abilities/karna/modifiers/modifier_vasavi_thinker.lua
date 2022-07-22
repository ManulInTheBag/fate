modifier_vasavi_thinker = class({})

LinkLuaModifier("modifier_vasavi_slow", "abilities/karna/modifiers/modifier_vasavi_slow", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_vasavi_thinker:OnCreated(args)
		self.Damage = args.Damage
		self.Radius = args.Radius

		self.ThinkCount = 0

		self:StartIntervalThink(0.1)
	end

	function modifier_vasavi_thinker:OnIntervalThink()
		local location = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local damage = self.Damage

		for i = 1, #targets do
			if IsDivineServant(targets[i]) and caster.IndraAttribute then
				damage = self.Damage * 1.5
			elseif caster.IndraAttribute then
				damage = self.Damage * 1.2
			else
				damage = self.Damage
			end

			DoDamage(caster, targets[i], damage * 0.10, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			targets[i]:AddNewModifier(caster, ability, "modifier_vasavi_slow", { Duration = 0.3 })
		end

		local beamLoc = RandomPointInCircle(location, self.Radius * 0.45)
		
		local beam_particle = ParticleManager:CreateParticle("particles/custom/karna/vasavi_shakti/ground_erupt/karna_fire_eruption.vpcf", PATTACH_CUSTOMORIGIN, caster)
	   	ParticleManager:SetParticleControl(beam_particle, 0, beamLoc) 

		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(beam_particle, true)
			ParticleManager:ReleaseParticleIndex(beam_particle)
			return
		end)

		self.ThinkCount = self.ThinkCount + 1

		if self.ThinkCount >= 10 then
			self:Destroy()
		end
	end
end