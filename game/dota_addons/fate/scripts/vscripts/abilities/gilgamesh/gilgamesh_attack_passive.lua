gilgamesh_attack_passive = class({})

LinkLuaModifier("modifier_gilgamesh_attack_passive", "abilities/gilgamesh/gilgamesh_attack_passive", LUA_MODIFIER_MOTION_NONE)

function gilgamesh_attack_passive:GetIntrinsicModifierName()
	return "modifier_gilgamesh_attack_passive"
end
function gilgamesh_attack_passive:CreateGOB(position, target)

	local caster = self:GetCaster()
	local vCasterOrigin = caster:GetAbsOrigin()
	 
	self.gramDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	self.gramDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.gramDummy:SetAbsOrigin(position)
	local gramDummy = self.gramDummy
	Timers:CreateTimer(1.0, function()
		gramDummy:RemoveSelf()
	end)
	self.gramDummy:SetForwardVector((vCasterOrigin-target:GetAbsOrigin()):Normalized())
 
	local portalFxIndex = ParticleManager:CreateParticle( "particles/gilgamesh/gob.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.gramDummy )
	ParticleManager:SetParticleControl(portalFxIndex, 3, position ) 
	ParticleManager:SetParticleControl(portalFxIndex, 10, Vector(1,0,0)) 
	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(portalFxIndex, false)
		ParticleManager:ReleaseParticleIndex(portalFxIndex)
	end)
end

function gilgamesh_attack_passive:ShootSword(target)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local vCasterOrigin = caster:GetAbsOrigin()
	local vForwardVector =  caster:GetForwardVector()
	vOrigin = vCasterOrigin + vForwardVector*-50  + Vector(0,0,350)   
	local leftvec = Vector(-vForwardVector.y, vForwardVector.x, 0)
	local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		if random2 == 0 then 
			vOrigin = vOrigin + leftvec * RandomInt(100,300)
		else 
			vOrigin = vOrigin -leftvec * RandomInt(100,300)
		end

	self:CreateGOB(vOrigin, target)
   self.info = {
	  Target = target,
	  Source = self.caster,
	  vSourceLoc = vOrigin + vForwardVector * -60, 
	  Ability = self,
	  bHasFrontalCone = false,
	  bReplaceExisting = false,
	  bIsAttack = false,
	  iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	  iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	  iUnitTargetType = DOTA_UNIT_TARGET_OTHER + DOTA_UNIT_TARGET_ALL,
	  EffectName = "particles/gilgamesh/gil_target_gob_projectile.vpcf",
	  iMoveSpeed = 2000,
	  fExpireTime = GameRules:GetGameTime() + 0.5,
	  bDeleteOnHit = true,
	  ExtraData = {
		targetIndex = target:entindex(),

		}
	}   
 
  	

end

function gilgamesh_attack_passive:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
	local target = EntIndexToHScript(tExtraData.targetIndex)
	if target == nil then return end
	local hCaster = self:GetCaster()
	if target:GetClassname() == "dota_item_drop" then UTIL_RemoveImmediate(target) return end
	hCaster:PerformAttack(target, true, true, true, false, false, false, false)


	
	local particle = ParticleManager:CreateParticle("particles/gilgamesh/gob_hit.vpcf", PATTACH_ABSORIGIN, hTarget)
	ParticleManager:SetParticleControlEnt(particle,0,hTarget,PATTACH_POINT,"attach_hitloc", Vector(0,0,0),true)

	Timers:CreateTimer(0.3,function()

		ParticleManager:DestroyParticle(particle, true)
		ParticleManager:ReleaseParticleIndex(particle)
	
	end)
	
end

modifier_gilgamesh_attack_passive = class({})

 

function modifier_gilgamesh_attack_passive:IsHidden() return true end
function modifier_gilgamesh_attack_passive:IsPermanent() return true end
function modifier_gilgamesh_attack_passive:RemoveOnDeath() return false end
function modifier_gilgamesh_attack_passive:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_gilgamesh_attack_passive:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_FINISHED, MODIFIER_EVENT_ON_ATTACK_START } end

function modifier_gilgamesh_attack_passive:OnAttackStart(args)
	if not IsServer() then return end
    if args.attacker ~= self:GetParent() then return end
         if(args.target ~= nil) then
            self:GetAbility():ShootSword(args.target)
 
		end
end
function modifier_gilgamesh_attack_passive:OnAttackFinished(args)
	if not IsServer() then return end
    if args.attacker ~= self:GetParent() then return end
	ProjectileManager:CreateTrackingProjectile(self:GetAbility().info) 
end
 


LinkLuaModifier("modifier_gil_model_swap", "abilities/gilgamesh/gilgamesh_attack_passive", LUA_MODIFIER_MOTION_NONE)
--NOTE: Function to handle swapping between models in-game.
if IsServer() then
    if type(gil_abilities_chat_event) == "number" then
        StopListeningToGameEvent(gil_abilities_chat_event)
    end
    --===--
    _G.gil_abilities_chat_event = ListenToGameEvent("player_chat", function(tEventTable)
        local nPlayerID = tEventTable.playerid
        local sText     = tEventTable.text
        local hHero     = PlayerResource:GetSelectedHeroEntity(nPlayerID)
        if not (hHero:GetName() == "npc_dota_hero_skywrath_mage") then
            return
        end
        if IsNotNull(hHero) then
            if sText == "-gil1" then
                hHero:RemoveModifierByName("modifier_gil_model_swap")
            end
            if sText == "-gil2" then
                if GameRules:GetGameTime() <= 240 then
                    hHero:AddNewModifier(hHero, nil, "modifier_gil_model_swap", {})
                end
            end
        end
    end, nil)
end
---------------------------------------------------------------------------------------------------------------------


modifier_gil_model_swap = modifier_gil_model_swap or class({})

function modifier_gil_model_swap:IsHidden()                                                                       return true end
function modifier_gil_model_swap:IsDebuff()                                                                       return false end
function modifier_gil_model_swap:IsPurgable()                                                                     return false end
function modifier_gil_model_swap:IsPurgeException()                                                               return false end
function modifier_gil_model_swap:RemoveOnDeath()                                                                  return false end
function modifier_gil_model_swap:IsDimensionException()                                                           return true end
function modifier_gil_model_swap:AllowIllusionDuplicate()                                                         return true end
function modifier_gil_model_swap:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_gil_model_swap:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_gil_model_swap:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_gil_model_swap:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.sModelName = "models/gilgamesh/gilgamesh_police.vmdl"
    end
end
function modifier_gil_model_swap:OnRefresh(hTable)
    self:OnCreated(hTable)
end
--========================================--