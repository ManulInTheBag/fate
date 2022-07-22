modifier_surgical_procedure = class({})

function modifier_surgical_procedure:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_HERO_KILLED }
end

if IsServer() then 
	function modifier_surgical_procedure:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		local caster = self:GetParent()
		local ability = self:GetAbility()
		local healing = ability:GetSpecialValueFor("base_healing") + caster:GetAgility()

		healing = math.min(caster:GetMaxHealth() * 0.08, healing)
		local allies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)

		for k, v in pairs(allies) do
			v:Heal(healing, caster)
		end
	end
	function modifier_surgical_procedure:OnHeroKilled(args)
		local ability = self:GetAbility()
		if args.target:IsHero() and args.attacker == self:GetParent() then
			print(self:GetParent():GetMaxHealth()*ability:GetSpecialValueFor("kill_heal")*0.01)
			print(self:GetParent():GetMaxMana()*ability:GetSpecialValueFor("kill_mana")*0.01)
			self:GetParent():Heal(self:GetParent():GetMaxHealth()*ability:GetSpecialValueFor("kill_heal")*0.01, self:GetParent())
			self:GetParent():GiveMana(self:GetParent():GetMaxMana()*ability:GetSpecialValueFor("kill_mana")*0.01)
		end
	end
end

function modifier_surgical_procedure:GetTexture()
	return "custom/jtr/surgical_procedure"
end