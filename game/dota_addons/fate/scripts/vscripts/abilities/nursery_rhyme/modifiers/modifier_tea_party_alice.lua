modifier_tea_party_alice = class({})
if IsServer() then
	function modifier_tea_party_alice:OnCreated(args)
	
		self.PartyCenterX = args.PartyCenterX
		self.PartyCenterY = args.PartyCenterY
		self.PartyCenterZ = args.PartyCenterZ
		self.PartySize = args.PartySize

		self:StartIntervalThink(0.05)
	end

	function modifier_tea_party_alice:OnIntervalThink()
		local caster = self:GetParent()
		caster:SetMana(caster:GetMana() + self:GetAbility():GetSpecialValueFor("mana_per_second")/20)
		local PartyCenter = Vector(self.PartyCenterX, self.PartyCenterY, self.PartyCenterZ)

		local enemies = FindUnitsInRadius(caster:GetTeam(), PartyCenter, nil, self.PartySize, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		--local duration = self:GetRemainingTime()
		for i = 1, #enemies do
			if enemies[i]:IsAlive() and not enemies[i]:HasModifier("modifier_tea_party_enemy") then
				enemies[i]:AddNewModifier(caster, self:GetAbility(), "modifier_tea_party_enemy", { PartyCenterX = self.PartyCenterX,
																								PartyCenterY = self.PartyCenterY,
																								PartyCenterZ = self.PartyCenterZ,
																								PartySize = self.PartySize,
																								Duration = self:GetRemainingTime()})
			end
		end
	end
end

function modifier_tea_party_alice:IsHidden()
	return false
end

function modifier_tea_party_alice:IsDebuff()
	return false
end

function modifier_tea_party_alice:RemoveOnDeath()
	return true
end

function modifier_tea_party_alice:GetAttributes()
  	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_tea_party_alice:GetTexture()
	return "custom/alice/alice_tea_party"
end