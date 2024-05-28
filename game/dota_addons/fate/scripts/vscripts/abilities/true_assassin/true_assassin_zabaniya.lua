true_assassin_zabaniya = class({})

LinkLuaModifier("modifier_zabaniya_curse", "abilities/true_assassin/modifiers/modifier_zabaniya_curse", LUA_MODIFIER_MOTION_NONE)

function true_assassin_zabaniya:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local target_flag = DOTA_UNIT_TARGET_FLAG_NONE

	--if caster:HasModifier("modifier_shadow_strike_upgrade") then		
	--	target_flag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	--end

	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, target_flag, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function true_assassin_zabaniya:GetCustomCastErrorTarget(hTarget)
	return "#Invalid_Target"
end

function true_assassin_zabaniya:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local smokeFx = ParticleManager:CreateParticleForTeam("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_loadout.vpcf", PATTACH_CUSTOMORIGIN, target, caster:GetTeamNumber())
	ParticleManager:SetParticleControl(smokeFx, 0, caster:GetAbsOrigin())

	return true 
end

function true_assassin_zabaniya:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local projectileSpeed = 1050

	caster:EmitSound("Hero_Nightstalker.Trickling_Fear")
	local projectileName = "particles/custom/ta/zabaniya_projectile.vpcf"
	if caster:HasModifier("modifier_hassan_model_swap") then
		projectileName = "particles/zlodemon/gojo_puk/custom/ta/zabaniya_nasral.vpcf"
	end
	local info = {
		Target = target,
		Source = caster, 
		Ability = ability,
		EffectName = projectileName,
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = projectileSpeed
	}

	FATE_ProjectileManager:CreateTrackingProjectile(info) 
	Timers:CreateTimer({
		endTime = 0.033,
		callback = function()
		local smokeFx = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(smokeFx, 0, caster:GetAbsOrigin())
		local smokeFx2 = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(smokeFx2, 0, target:GetAbsOrigin())
		local smokeFx3 = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_loadout.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(smokeFx3, 0, target:GetAbsOrigin())

		-- Destroy particle after delay
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( smokeFx, false )
			ParticleManager:ReleaseParticleIndex( smokeFx )
			ParticleManager:DestroyParticle( smokeFx2, false )
			ParticleManager:ReleaseParticleIndex( smokeFx2 )
			ParticleManager:DestroyParticle( smokeFx3, false )
			ParticleManager:ReleaseParticleIndex( smokeFx3 )
			return nil
		end)

		caster:EmitSound("TA.Darkness")
		caster:EmitSound("Hassan_Zabaniya") 
	end
	})
end

function true_assassin_zabaniya:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if IsSpellBlocked(hTarget) then return end -- Linken effect checker
	local caster = self:GetCaster()
	
	local blood = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)
	ParticleManager:SetParticleControl(blood, 4, hTarget:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(blood, 1, hTarget , 0, "attach_hitloc", hTarget:GetAbsOrigin(), false)

	local shadowFx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)
	ParticleManager:SetParticleControl(shadowFx, 0, hTarget:GetAbsOrigin())
	local smokeFx3 = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_fiendsgrip_hands.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
	ParticleManager:SetParticleControl(smokeFx3, 0, hTarget:GetAbsOrigin())

	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( blood, false )
		ParticleManager:ReleaseParticleIndex( blood )
		ParticleManager:DestroyParticle( shadowFx, false )
		ParticleManager:ReleaseParticleIndex( shadowFx )
		return nil
	end)

	local curseDuration = self:GetSpecialValueFor("curse_duration")
	--local damage_type = DAMAGE_TYPE_MAGICAL
	local damage_type = DAMAGE_TYPE_PURE
	local damage = self:GetSpecialValueFor("damage")

	if caster.IsShadowStrikeAcquired then
		curseDuration = curseDuration + self:GetSpecialValueFor("bonus_curse_duration")
		--damage_type = DAMAGE_TYPE_PURE
		damage = damage + caster:FindModifierByName("modifier_true_assassin_selfmod"):GetStackCount()*5 + 50
	end	
	
	DoDamage(caster, hTarget, damage, damage_type, 0, self, false)

	if not hTarget:IsMagicImmune() and not hTarget:HasModifier("modifier_master_intervention") then
		hTarget:AddNewModifier(caster, self, "modifier_zabaniya_curse", { Duration = curseDuration })
	end
end

function true_assassin_zabaniya:OnUpgrade()
	local MasterUnit2 = self:GetCaster().MasterUnit2

	if MasterUnit2 then 
		MasterUnit2:FindAbilityByName("true_assassin_attribute_shadow_strike"):SetLevel(self:GetLevel())
	end	
end



LinkLuaModifier("modifier_hassan_model_swap", "abilities/true_assassin/true_assassin_zabaniya", LUA_MODIFIER_MOTION_NONE)
--NOTE: Function to handle swapping between models in-game.
if IsServer() then
    if type(hassan_abilities_chat_event) == "number" then
        StopListeningToGameEvent(hassan_abilities_chat_event)
    end
    --===--
    _G.hassan_abilities_chat_event = ListenToGameEvent("player_chat", function(tEventTable)
        local nPlayerID = tEventTable.playerid
        local sText     = tEventTable.text
        local hHero     = PlayerResource:GetSelectedHeroEntity(nPlayerID)
        if not (hHero:GetName() == "npc_dota_hero_bounty_hunter") then
            return
        end
        if IsNotNull(hHero) then
            if sText == "-negr" then
                hHero:RemoveModifierByName("modifier_hassan_model_swap")
            end
            if sText == "-gojo" then
                if GameRules:GetDOTATime(false, false) <= 300 then
                    hHero:AddNewModifier(hHero, nil, "modifier_hassan_model_swap", {})
                end
            end
        end
    end, nil)
end
---------------------------------------------------------------------------------------------------------------------


modifier_hassan_model_swap = modifier_hassan_model_swap or class({})

function modifier_hassan_model_swap:IsHidden()                                                                       return true end
function modifier_hassan_model_swap:IsDebuff()                                                                       return false end
function modifier_hassan_model_swap:IsPurgable()                                                                     return false end
function modifier_hassan_model_swap:IsPurgeException()                                                               return false end
function modifier_hassan_model_swap:RemoveOnDeath()                                                                  return false end
function modifier_hassan_model_swap:IsDimensionException()                                                           return true end
function modifier_hassan_model_swap:AllowIllusionDuplicate()                                                         return true end
function modifier_hassan_model_swap:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_hassan_model_swap:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_hassan_model_swap:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_hassan_model_swap:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.sModelName = "models/zlodemon/gojo.vmdl"
    end
end
function modifier_hassan_model_swap:OnRefresh(hTable)
    self:OnCreated(hTable)
end
--========================================--