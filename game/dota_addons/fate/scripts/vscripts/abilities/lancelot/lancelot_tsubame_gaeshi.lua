-- lancelot_tsubame_gaeshi — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_tsubame_gaeshi = class({})

LinkLuaModifier("modifier_tg_baseattack_reduction", "abilities/lancelot/lancelot_tsubame_gaeshi", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/fa_ability.lua, scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local TGPlaySound, OnKnightUsed, OnTGStart, OnKnightClosed

TGPlaySound = function(keys)

	local caster = keys.caster

	local target = keys.target

	if target:GetName() == "npc_dota_ward_base" then

		caster:Interrupt()

		return

	end

	if caster:GetName() == "npc_dota_hero_juggernaut" then

		EmitGlobalSound("FA.TGReady")



	elseif caster:GetName() == "npc_dota_hero_sven" then

		EmitGlobalSound("Lancelot.Growl" )

	end

	EmitZlodemonTrueSoundEveryone("moskes_lanc_tg_precast")

	local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()

	local firstImpactIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )

    ParticleManager:SetParticleControl(firstImpactIndex, 0, caster:GetAbsOrigin() + diff/2)

    ParticleManager:SetParticleControl(firstImpactIndex, 1, Vector(600,0,150))

    ParticleManager:SetParticleControl(firstImpactIndex, 2, Vector(0.4,0,0))

	--[[local firstImpactIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator.vpcf", PATTACH_CUSTOMORIGIN, nil )

    ParticleManager:SetParticleControl(firstImpactIndex, 0, Vector(1,0,0))

    ParticleManager:SetParticleControl(firstImpactIndex, 1, Vector(300-50,0,0))

    ParticleManager:SetParticleControl(firstImpactIndex, 2, Vector(0.5,0,0))

    ParticleManager:SetParticleControl(firstImpactIndex, 3, keys.target:GetAbsOrigin())

    ParticleManager:SetParticleControl(firstImpactIndex, 4, Vector(0,0,0))]]

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

OnTGStart = function(keys)

	local caster = keys.caster

	local casterName = caster:GetName()

	local target = keys.target

	local ability = keys.ability

	EmitZlodemonTrueSoundEveryone("moskes_lanc_tg")

	if IsSpellBlocked(keys.target, caster) then return end -- Linken effect checker

	EmitGlobalSound("FA.Chop")



	-- Check if caster is FA or Lancelot

	if caster:GetName() == "npc_dota_hero_juggernaut" then

		EmitGlobalSound("FA.TG")

		--caster:FindAbilityByName("false_assassin_gate_keeper"):StartCooldown(keys.GCD) 



		-- 1.24c change Vitrification prevents GCD on Heart

		--[[if not caster.IsVitrificationAcquired then

			caster:FindAbilityByName("false_assassin_heart_of_harmony"):StartCooldown(keys.GCD) 

		end]]



		--caster:FindAbilityByName("false_assassin_windblade"):StartCooldown(keys.GCD) 

	elseif caster:GetName() == "npc_dota_hero_sven" then

		Timers:CreateTimer(0.15, function() 

			EmitGlobalSound("Lancelot.Roar2")

			StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK2, rate=2})

			Timers:CreateTimer(0.3, function()

				StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=2})

				Timers:CreateTimer(0.3, function()

					StartAnimation(caster, {duration=0.2, activity=ACT_DOTA_ATTACK2, rate=2})

				end)

			end)

			return

		end)

	end



	caster:AddNewModifier(caster, nil, "modifier_phased", {duration=1.0})

	giveUnitDataDrivenModifier(caster, caster, "dragged", 1.0)

	--giveUnitDataDrivenModifier(caster, caster, "revoked", 1.0)



	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_tg_baseattack_reduction", {})



	local particle = ParticleManager:CreateParticle("particles/custom/false_assassin/tsubame_gaeshi/slashes.vpcf", PATTACH_ABSORIGIN, caster)

	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()) 



	Timers:CreateTimer(0.5, function()  

		if caster:IsAlive() and target:IsAlive() then

			local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 

			caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100) 

			--if IsSpellBlocked(target) then return end

			

			DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_PURE, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, keys.ability, false)

			if caster.ImproveKnightOfOwner then

				--caster:PerformAttack( target, true, true, true, true, false, false, false )

			end

			local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )

		    ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())

		    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))

		    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))



			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

		else

			ParticleManager:DestroyParticle(particle, true)

		end

	return end)



	Timers:CreateTimer(0.7, function()  

		if caster:IsAlive() and target:IsAlive() then

			local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 

			caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100) 

			--if IsSpellBlocked(target) then return end

			

			DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_PURE, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, keys.ability, false)

			if caster.ImproveKnightOfOwner then

				--caster:PerformAttack( target, true, true, true, true, false, false, false )

			end

			local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )

		    ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())

		    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))

		    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

			

			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

		else

			ParticleManager:DestroyParticle(particle, true)

		end

	return end)



	Timers:CreateTimer(0.9, function()  

		if caster:IsAlive() and target:IsAlive() then

			local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 

			caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100)



			--if IsSpellBlocked(target) then return end

			

			DoDamage(caster, target, keys.LastDamage, DAMAGE_TYPE_PURE, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, keys.ability, false)

			if caster.ImproveKnightOfOwner then

				caster:PerformAttack( target, true, true, true, true, false, false, false )

			end

			--target:AddNewModifier(caster, target, "modifier_stunned", {Duration = 1.5})

			local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )

		    ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())

		    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))

		    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))			

		else

			ParticleManager:DestroyParticle(particle, true)

		end

		local position = caster:GetAbsOrigin()

		if keys.Locator then

			local dummyPosition = keys.Locator:GetAbsOrigin()

			if not IsInSameRealm(position, dummyPosition) then

				position = dummyPosition

			end

		end

		FindClearSpaceForUnit(caster, position, true)



	return end)

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


function lancelot_tsubame_gaeshi:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_counterhelix_unused.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	-- DD RunScript: fa_ability / TGPlaySound
	TGPlaySound({ caster = caster, ability = self, target = target })
	return true
end

function lancelot_tsubame_gaeshi:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: lancelot_ability / OnKnightUsed
	OnKnightUsed({ caster = caster, ability = self, target = target })
	-- DD RunScript: fa_ability / OnTGStart
	-- TODO(dd2lua): функция читает keys.Locator — проверить
	OnTGStart({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		LastDamage = self:GetSpecialValueFor("lasthit_damage"),
		StunDuration = self:GetSpecialValueFor("stun_duration"),
		GCD = self:GetSpecialValueFor("global_cooldown")
	})
end

modifier_tg_baseattack_reduction = class({})


function modifier_tg_baseattack_reduction:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_tg_baseattack_reduction:GetModifierBaseDamageOutgoing_Percentage()
	return -100
end

function modifier_tg_baseattack_reduction:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.0, true)
	end
end

function modifier_tg_baseattack_reduction:OnRefresh(kv)
	self:OnCreated(kv)
end
