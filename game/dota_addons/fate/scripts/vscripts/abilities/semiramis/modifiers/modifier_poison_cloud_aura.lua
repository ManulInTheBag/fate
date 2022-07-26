modifier_poison_cloud_aura = class({})

LinkLuaModifier("modifier_poison_cloud_debuff", "abilities/semiramis/modifiers/modifier_poison_cloud_debuff", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_poison_cloud_aura:OnCreated(args)
		self.PoisonDamage = args.PoisonDamage
		self.AOE = args.AOE
		self.PoisonDuration = args.PoisonDuration
		self.ResistReduc = args.ResistReduc

		
	end

	function modifier_poison_cloud_aura:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_poison_cloud_aura:OnIntervalThink()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		local enemies = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil, self.AOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		for i = 1, #enemies do
			DoDamage(caster, enemies[i], self.PoisonDamage, DAMAGE_TYPE_MAGICAL, 0, ability, false) 

			enemies[i]:AddNewModifier(caster, ability, "modifier_poison_cloud_debuff", { Duration = self.PoisonDuration,
																						 ResistReduc = self.ResistReduc })
		end		
	end
end