-- lancelot_rule_breaker — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_rule_breaker = class({})

LinkLuaModifier("modifier_l_rule_breaker", "abilities/lancelot/lancelot_rule_breaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_c_rule_breaker", "abilities/medea/caster_5th_rule_breaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dagger_of_treachery", "abilities/medea/caster_5th_rule_breaker", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua, scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnRBStart, OnKnightUsed, ArsenalReturnMana, OnKnightClosed

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

OnKnightUsed = function(keys)
        local caster = keys.caster
        local ply = caster:GetPlayerOwner()
        local ability = keys.ability

        if not caster.KnightLevel and not caster.ArsenalLevel then
                OnKnightClosed(keys)
                caster:FindAbilityByName("lancelot_knight_of_honor"):StartCooldown(ability:GetCooldown(ability:GetLevel()))
        end
end

ArsenalReturnMana = function(caster)
    if caster:GetName() == "npc_dota_hero_sven" and caster.ArsenalLevel == 2 then
        caster:GiveMana(caster:FindAbilityByName("lancelot_knight_of_honor_arsenal"):GetSpecialValueFor("mana_return"))
    end
end

OnKnightClosed = function(keys)
        local caster = keys.caster
        caster.IsKnightOpen = false
        local a1 = caster:GetAbilityByIndex(0)
        local a2 = caster:GetAbilityByIndex(1)
        local a3 = caster:GetAbilityByIndex(2)
        local a4 = caster:GetAbilityByIndex(3)
        local a5 = caster:GetAbilityByIndex(4)
        local a6 = caster:GetAbilityByIndex(5)
        -- if knight attribute is not taken, caster.KnightLevel~=nil is false and therefore kills off queueing a 2nd skill. 
        caster:SwapAbilities(a1:GetName(), "lancelot_minigun", false ,true) 
        caster:SwapAbilities(a2:GetName(), "lancelot_parry", false, true) 
        caster:SwapAbilities(a3:GetName(), "lancelot_knight_of_honor", false, true)
        if caster.nukeAvail == true then 
            caster:SwapAbilities(a4:GetName(), "lancelot_nuke", false, true) 
        elseif caster:HasAbility("lancelot_blessing_of_fairy") then 
            caster:SwapAbilities(a4:GetName(), "lancelot_blessing_of_fairy", false, true) 
        else 
            caster:SwapAbilities(a4:GetName(), "fate_empty1", false, true) 
        end
        caster:SwapAbilities(a5:GetName(), "lancelot_arms_mastership", false, true) 
        
        if caster:HasModifier("modifier_arondite") then
            caster:SwapAbilities(a6:GetName(), "lancelot_arondight_overload", false, true )     
        else
            caster:SwapAbilities(a6:GetName(), "lancelot_arondite", false, true )     
        end
end


function lancelot_rule_breaker:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: caster_ability / OnRBStart
	OnRBStart({
		caster = caster,
		ability = self,
		target = target,
		StunDuration = self:GetSpecialValueFor("stun_duration")
	})
	-- DD RunScript: lancelot_ability / OnKnightUsed
	OnKnightUsed({ caster = caster, ability = self, target = target })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_weave.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl(fx, 0, Vector(200, 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
end

modifier_l_rule_breaker = class({})

function modifier_l_rule_breaker:IsDebuff() return true end
function modifier_l_rule_breaker:IsPurgable() return true end
function modifier_l_rule_breaker:GetEffectName() return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf" end
function modifier_l_rule_breaker:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end

function modifier_l_rule_breaker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
	}
end

function modifier_l_rule_breaker:GetModifierMagicalResistanceDecrepifyUnique()
	return -100
end

function modifier_l_rule_breaker:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_l_rule_breaker:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_l_rule_breaker:OnRefresh(kv)
	self:OnCreated(kv)
end
