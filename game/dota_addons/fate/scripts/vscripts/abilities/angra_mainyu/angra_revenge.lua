LinkLuaModifier("modifier_angra_revenge", "abilities/angra_mainyu/angra_revenge", LUA_MODIFIER_MOTION_NONE)

angra_revenge = class({})

function angra_revenge:GetIntrinsicModifierName()
	return "modifier_angra_revenge"
end

modifier_angra_revenge = class({})

function modifier_angra_revenge:DeclareFunctions()
	return {MODIFIER_EVENT_ON_HERO_KILLED }
end

if IsServer() then 
	function modifier_angra_revenge:OnHeroKilled(args)
		if not self:GetParent().IsRevengeAcquired then return end

		if args.target == self:GetParent() and args.attacker ~= self:GetParent() and args.attacker:IsHero() then
			self:GetParent():FindAbilityByName("angra_puddle"):DeathPuddle(self:GetParent():GetAbsOrigin())
		end

	end
end

function modifier_angra_revenge:IsHidden() return true end
function modifier_angra_revenge:IsDebuff() return false end