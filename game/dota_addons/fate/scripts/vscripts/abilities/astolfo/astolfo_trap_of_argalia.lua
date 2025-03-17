astolfo_trap_of_argalia = class({})

function astolfo_trap_of_argalia:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local vector = (self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
	vector.z = 0
	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
	-- Attachments:AttachProp(caster, "attach_sword", "models/astolfo/astolfo_sword.vmdl")
	local qdProjectile = 
	{
		Ability = ability,
        EffectName = "particles/custom/false_assassin/fa_quickdraw.vpcf",
        iMoveSpeed = 1850,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = 925,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = vector * 1850
	}

	caster:EmitSound("Astolfo_Slide_" .. math.random(1,5))
	caster:SetForwardVector(vector)
	local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5)
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk") 
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector() * 1850)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer("trap_dash", {
		endTime = 0.5,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		-- local prop = Attachments:GetCurrentAttachment(caster, "attach_sword")
		-- if not prop:IsNull() then prop:RemoveSelf() end
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("trap_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		ProjectileManager:DestroyLinearProjectile(projectile)
		caster:RemoveModifierByName("pause_sealenabled")
		-- local prop = Attachments:GetCurrentAttachment(caster, "attach_sword")
		-- if not prop:IsNull() then prop:RemoveSelf() end
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end

function astolfo_trap_of_argalia:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")

	--giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration)
	giveUnitDataDrivenModifier(caster, hTarget, "locked", duration)

	hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

	if caster.bIsSanityAcquired then
		caster:PerformAttack( hTarget, true, true, true, true, false, false, false )
	end
end




LinkLuaModifier("modifier_astolfo_model_swap", "abilities/astolfo/astolfo_trap_of_argalia", LUA_MODIFIER_MOTION_NONE)
--NOTE: Function to handle swapping between models in-game.
if IsServer() then
    if type(astolfo_abilities_chat_event) == "number" then
        StopListeningToGameEvent(astolfo_abilities_chat_event)
    end
    --===--
    _G.astolfo_abilities_chat_event = ListenToGameEvent("player_chat", function(tEventTable)
        local nPlayerID = tEventTable.playerid
        local sText     = tEventTable.text
        local hHero     = PlayerResource:GetSelectedHeroEntity(nPlayerID)
        if not (hHero:GetName() == "npc_dota_hero_queenofpain") then
            return
        end
        if IsNotNull(hHero) then
            if sText == "-astolfo1" then
                hHero:RemoveModifierByName("modifier_astolfo_model_swap")
            end
            if sText == "-astolfo2" then
                if GameRules:GetDOTATime(false, false) <= 300 then --300
                    hHero:AddNewModifier(hHero, nil, "modifier_astolfo_model_swap", {status = 1})
                end
            end
            if sText == "-astolfo3" then
                if GameRules:GetDOTATime(false, false) <= 300 then --300
                    hHero:AddNewModifier(hHero, nil, "modifier_astolfo_model_swap", {status  = 2})
                end
            end
        end
    end, nil)
end


modifier_astolfo_model_swap = modifier_astolfo_model_swap or class({})

function modifier_astolfo_model_swap:IsHidden()                                                                       return true end
function modifier_astolfo_model_swap:IsDebuff()                                                                       return false end
function modifier_astolfo_model_swap:IsPurgable()                                                                     return false end
function modifier_astolfo_model_swap:IsPurgeException()                                                               return false end
function modifier_astolfo_model_swap:RemoveOnDeath()                                                                  return false end
function modifier_astolfo_model_swap:IsDimensionException()                                                           return true end
function modifier_astolfo_model_swap:AllowIllusionDuplicate()                                                         return true end
function modifier_astolfo_model_swap:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_astolfo_model_swap:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_astolfo_model_swap:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_astolfo_model_swap:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if IsServer() then
        if hTable.status == 1 then
            self.sModelName = "models/astolfo/astolfo_trifas.vmdl"
        else
            self.sModelName = "models/astolfo/extella/astolfo_swimsuit.vmdl"
        end
    end
end
function modifier_astolfo_model_swap:OnRefresh(hTable)
    self:OnCreated(hTable)
end

--========================================--
