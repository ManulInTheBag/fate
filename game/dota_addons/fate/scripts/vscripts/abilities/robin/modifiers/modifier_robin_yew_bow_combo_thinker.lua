modifier_robin_yew_bow_combo_thinker = class({})

LinkLuaModifier("modifier_robin_yew_bow_combo_slow", "abilities/robin/modifiers/modifier_robin_yew_bow_combo_slow", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
function modifier_robin_yew_bow_combo_thinker:OnCreated(args)
		self.Damage = args.poison_damage
		self.Radius = args.radius

		self.ThinkCount = 0

		self:StartIntervalThink(1)
end

function modifier_robin_yew_bow_combo_thinker:OnIntervalThink()
		local location = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, self.Radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local damage = self.Damage

		for i = 1, #targets do
			damage = self.Damage

			DoDamage(caster, targets[i], damage * 0.20, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			targets[i]:AddNewModifier(caster, ability, "modifier_robin_yew_bow_combo_slow", { Duration = 1.0 })
		end

		self.ThinkCount = self.ThinkCount + 1

		if self.ThinkCount >= 5 then
			self:Destroy()
		end
	end
end

function modifier_robin_yew_bow_combo_thinker:GetEffectName()
	return "particles/zlodemon/robin_poison.vpcf"
end