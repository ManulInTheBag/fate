-- caster_5th_rule_breaker — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_rule_breaker = class({})

LinkLuaModifier("modifier_c_rule_breaker", "abilities/medea/caster_5th_rule_breaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dagger_of_treachery", "abilities/medea/caster_5th_rule_breaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_l_rule_breaker", "abilities/lancelot/lancelot_rule_breaker", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua, scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnRBStart, OnRBSealStolen, ArsenalReturnMana

OnRBStart = function(keys)
	ArsenalReturnMana(keys.caster)
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()
	if IsSpellBlocked(keys.target, caster) then return end -- Linken effect checker
	ApplyStrongDispel(target)
	if caster:GetName() == "npc_dota_hero_crystal_maiden" then
		caster:EmitSound("Medea_Rule_Breaker_" .. math.random(1,2))		
		target:AddNewModifier(caster, keys.ability, "modifier_c_rule_breaker", {}) 
		if (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > 200 then
			local afterBlinkPos = AbilityBlink(caster, caster:GetAbsOrigin() -(caster:GetAbsOrigin()-target:GetAbsOrigin()):Normalized()*250,
			 math.min((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()-250, 250))
		end

		if caster.IsRBImproved then
			keys.ability:EndCooldown()
			keys.ability:StartCooldown(25)
			giveUnitDataDrivenModifier(caster, target, "revoked", 5)
			target:AddNewModifier(caster, keys.ability, "modifier_dagger_of_treachery", {}) 

			if target.MasterUnit:GetMana() > 1 then
				target.MasterUnit:SetMana(target.MasterUnit:GetMana() - 1) 
				target.MasterUnit2:SetMana(target.MasterUnit2:GetMana() - 1) 
				
				caster.MasterUnit:SetMana(caster.MasterUnit:GetMana() + 1)
				caster.MasterUnit2:SetMana(caster.MasterUnit2:GetMana() + 1)
			end		
		end
		-- revoke даёт ТОЛЬКО атрибут Dagger of Treachery (так написано в его тултипе);
		-- раньше базовая способность вешала revoked на 3с, и атрибут лишь продлевал его до 5с
	else
		target:AddNewModifier(caster, keys.ability, "modifier_l_rule_breaker", {}) 
		EmitZlodemonTrueSoundEveryone("moskes_lanc_rb")
	end
	--EmitGlobalSound("Caster.RuleBreaker") 
	
	
	--print(caster:GetName())
	--print(keys.StunDuration)
	keys.target:AddNewModifier(caster, target, "modifier_muted", {Duration = keys.StunDuration})

end

OnRBSealStolen = function(keys)
	local victim = keys.unit
	local caster = keys.caster

	victim:EmitSound("Hero_Silencer.LastWord.Cast")
	caster:EmitSound("Medea_Steal_" .. math.random(1,2))

	if victim.MasterUnit:GetHealth() > 1 then
		victim.MasterUnit:SetHealth(victim.MasterUnit:GetHealth() - 1) 
		--victim.MasterUnit2:SetHealth(victim.MasterUnit2:GetHealth() - 1) 
		
		if caster.MasterUnit:GetHealth() < caster.MasterUnit:GetMaxHealth() then
			caster.MasterUnit:SetHealth(caster.MasterUnit:GetHealth() + 1)
			--caster.MasterUnit2:SetHealth(caster.MasterUnit2:GetHealth() + 1)
		end
	end
end

ArsenalReturnMana = function(caster)
    if caster:GetName() == "npc_dota_hero_sven" and caster.ArsenalLevel == 2 then
        caster:GiveMana(caster:FindAbilityByName("lancelot_knight_of_honor_arsenal"):GetSpecialValueFor("mana_return"))
    end
end


function caster_5th_rule_breaker:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: caster_ability / OnRBStart
	OnRBStart({
		caster = caster,
		ability = self,
		target = target,
		StunDuration = self:GetSpecialValueFor("stun_duration")
	})
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_weave.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl(fx, 0, Vector(200, 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
end

modifier_c_rule_breaker = class({})

function modifier_c_rule_breaker:IsDebuff() return true end
function modifier_c_rule_breaker:GetEffectName() return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf" end
function modifier_c_rule_breaker:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end

function modifier_c_rule_breaker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_c_rule_breaker:GetModifierMagicalResistanceDecrepifyUnique()
	return -100
end
function modifier_c_rule_breaker:GetAbsoluteNoDamagePhysical()
	return 1
end
function modifier_c_rule_breaker:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_c_rule_breaker:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_c_rule_breaker:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_c_rule_breaker:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_dagger_of_treachery = class({})

function modifier_dagger_of_treachery:IsDebuff() return true end
function modifier_dagger_of_treachery:GetEffectName() return "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf" end
function modifier_dagger_of_treachery:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_dagger_of_treachery:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_dagger_of_treachery:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "3" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(3, true)
	end
end

function modifier_dagger_of_treachery:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_dagger_of_treachery:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: caster_ability / OnRBSealStolen
	OnRBSealStolen({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		Target = "TARGET"
	})
end
