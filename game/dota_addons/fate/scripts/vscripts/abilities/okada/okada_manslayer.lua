
LinkLuaModifier("modifier_okada_manslayer", "abilities/okada/okada_manslayer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okada_manslayer_passive", "abilities/okada/okada_manslayer", LUA_MODIFIER_MOTION_NONE)

okada_manslayer = class({})



function okada_manslayer:GetIntrinsicModifierName()
	return "modifier_okada_manslayer_passive"
end


function okada_manslayer:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("okada_d")
	caster:AddNewModifier(caster, self, "modifier_okada_manslayer", {duration = self:GetSpecialValueFor("active_duration")})
end


modifier_okada_manslayer = class({})

function modifier_okada_manslayer:IsHidden() 
	return false
end

function modifier_okada_manslayer:RemoveOnDeath()
	return true
end

function modifier_okada_manslayer:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true, }
    
    return state
end

function modifier_okada_manslayer:GetEffectName()
	return "particles/okada/okada_manslayer_ambient.vpcf"
end

function modifier_okada_manslayer:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end




modifier_okada_manslayer_passive = class({})



function modifier_okada_manslayer_passive:IsHidden() 
	return true
end

function modifier_okada_manslayer_passive:IsPermanent()
	return true
end

function modifier_okada_manslayer_passive:RemoveOnDeath()
	return false
end

function modifier_okada_manslayer_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_okada_manslayer_passive:DeclareFunctions()
	return {	MODIFIER_EVENT_ON_HERO_KILLED	}
end
function modifier_okada_manslayer_passive:OnHeroDiedNearby( hVictim, hKiller, kv )
	if hVictim == nil or hKiller == nil then
		return
	end
	if hKiller == self:GetCaster() or ((hVictim:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D() < 300 and hVictim:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() )then
		self:ActivateThirst()
	end
end
function modifier_okada_manslayer_passive:ActivateThirst()
	if not self.pepega then
			self.pepega = 1
			self.parent = self:GetParent()
			self.player_id = self.parent:GetPlayerOwnerID()
			self.player = PlayerResource:GetPlayer(self.player_id)
			self.ability = self:GetAbility()
			self:StartIntervalThink(FrameTime())
	end
	self.parent:AddNewModifier(self.parent, self.ability, "modifier_okada_manslayer", {duration = self.ability:GetSpecialValueFor("passive_duration")})


end
function modifier_okada_manslayer_passive:OnHeroKilled(args)
	if args.target:IsHero() and args.attacker == self:GetParent() then
		if IsServer() then
			self:ActivateThirst()
		end
	end
end
