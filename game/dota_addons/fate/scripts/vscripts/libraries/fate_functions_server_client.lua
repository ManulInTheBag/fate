if _G and not _G["bFATE_FIX_FOR_CRASHES_BY_NONE_ISNULL"] then
	_G["bFATE_FIX_FOR_CRASHES_BY_NONE_ISNULL"] = true

	for hKey0, hValue0 in pairs(_G) do
        if type(hValue0) == "table"
            and type(hValue0.IsNull) == "function" then
            for hKey1, hValue1 in pairs(hValue0) do
                if hKey1 ~= "IsNull"
                    and type(hValue1) == "function" then
                    local hOldFunction1 = _G[hKey0][hKey1]
                    _G[hKey0][hKey1] = function(self, ...)
                        if type(self) ~= "nil"
                            and type(self.IsNull) == "function"
                            and not self:IsNull() then
                            return hOldFunction1(self, ...)
                        end
                        return error("Error in: "..hKey0.." AND "..hKey1)
                    end
                end
            end
        end
    end
end

TableLength = function(hTable)
    local i = 0
    if type(hTable) == "table" then
        for _, hV in pairs(hTable) do
            i = i + 1
        end
    end
    return i
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
TableCopy = function(hTable, siIndex, bIntIndex)
    local hTable2 = {}
    if type(hTable) == "table" then
        local i = 1
        for siKey, hValue in pairs(hTable) do
            siKey = bIntIndex 
                    and i
                    or ( ( type(siIndex) ~= "nil" and type(hValue) == "table" )
                         and hValue[siIndex]
                         or siKey )
            hTable2[siKey] = hValue
            i = i + 1
        end
    else
        hTable2 = hTable
    end
    return hTable2
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
TablePick = function(hTableReference, hTable, bRemove)
    if type(hTableReference) == "table" 
        and type(hTable) == "table" then
        if TableLength(hTable) <= 0 then
            for k, v in pairs(hTableReference) do
                hTable[k] = v
            end
        end
        local iRandIndex = RandomInt( 1, TableLength(hTable) )
        local hReturn    = hTable[iRandIndex]
        if bRemove then
            table.remove( hTable, iRandIndex )
        end
        return hReturn
    end
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
TableShuffle = function(hTable, bCopy)
    if type(hTable) == "table" then
        local hTableReturn = bCopy and {} or hTable
        local hTableInt = TableCopy(hTable, nil, true)
        for k, v in pairs(hTable) do
            hTableReturn[k] = TablePick(hTableInt, hTableInt, true)
        end
        return hTableReturn
    end
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
TableEqual = function(hTable1, hTable2, bIgnoreMetatable)
    if hTable1 == hTable2 then
        return true
    end

    local sType1 = type(hTable1)
    local sType2 = type(hTable2)

    if sType1 ~= "table"
        or sType1 ~= sType2 then
        return false
    end

    if not bIgnoreMetatable then
        local hMeta1 = getmetatable(hTable1)
        if hMeta1 and hMeta1.__eq then --compare using built in method
            return hTable1 == hTable2
        end
    end

    local hKeysSet = {}
    
    for iKey1, hValue1 in pairs(hTable1) do
        local hValue2 = hTable2[iKey1]
        if hValue2 == nil 
            or not TableEqual(hValue1, hValue2, bIgnoreMetatable) then
            return false
        end
        hKeysSet[iKey1] = true
    end

    for iKey2, hValue2 in pairs(hTable2) do
        if not hKeysSet[iKey2] then
            return false
        end
    end

    return true
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetDistance = function(hEnt1, hEnt2, b3D)
    hEnt1 = hEnt1.GetAbsOrigin and hEnt1:GetAbsOrigin() or hEnt1
    hEnt2 = hEnt2.GetAbsOrigin and hEnt2:GetAbsOrigin() or hEnt2
    return b3D and (hEnt1 - hEnt2):Length() or (hEnt1 - hEnt2):Length2D()
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetDirection = function(hEnt1, hEnt2, b3D)
    hEnt1 = hEnt1.GetAbsOrigin and hEnt1:GetAbsOrigin() or hEnt1
    hEnt2 = hEnt2.GetAbsOrigin and hEnt2:GetAbsOrigin() or hEnt2

    local iEnt1 = hEnt1.z
    local iEnt2 = hEnt2.z
    
    hEnt1.z = b3D and iEnt1 or 0
    hEnt2.z = b3D and iEnt2 or 0

    local vReturn = (hEnt1 - hEnt2):Normalized()

    hEnt1.z = iEnt1
    hEnt2.z = iEnt2

    return vReturn
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
GetLerped = function(hValue1, hValue2, fTime)
    return hValue1 + ( hValue2 - hValue1 ) * fTime
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
--!!IMPORTANT: NEED FOR HANDLE SOME FUNCTION ON CLIENT SIDE!!!------------------------------------------------------------------------------------------------
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
_G.RegistredGameEventsListeners = RegistredGameEventsListeners or {}
for _, lID in pairs(RegistredGameEventsListeners) do
    StopListeningToGameEvent(lID)
    RegistredGameEventsListeners[_] = nil
end

CDOTABaseAbility = IsServer() and CDOTABaseAbility or C_DOTABaseAbility
--[:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::]
CDOTA_Ability_Lua = IsServer() and CDOTA_Ability_Lua or C_DOTA_Ability_Lua
--[:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::]
CDOTA_Item_Lua = IsServer() and CDOTA_Item_Lua or C_DOTA_Item_Lua

CDOTABaseAbility.GetCastRangeBonus = function(self, ...) --Crashes normal addons, because gaben released new patch with error in 24.02.2022 pizdec, only for LUA ABILITY, For items i think all fne.... cringe
    return self:GetCaster():GetCastRangeBonus()
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
local VALVE_CDOTA_Ability_Lua_GetCastRangeBonus = CDOTA_Ability_Lua.GetCastRangeBonus
CDOTA_Ability_Lua.GetCastRangeBonus = function(self, ...) --I DID IT FOR ALL BECASUE NOT WANNA RECIEVE ERRORS IN FUTURE
    return VALVE_CDOTA_Ability_Lua_GetCastRangeBonus(self, ...)
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
CDOTA_Item_Lua.GetCastRangeBonus = function(self, ...) --Predict Crash???
    return self:GetCaster():GetCastRangeBonus()
end

local VALVE_CDOTABaseAbility_GetBehavior = CDOTABaseAbility.GetBehavior
CDOTABaseAbility.GetBehavior = function(self) --Predict uint64?
    return tonumber(tostring(VALVE_CDOTABaseAbility_GetBehavior(self)))
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
local VALVE_CDOTA_Ability_Lua_GetBehavior = CDOTA_Ability_Lua.GetBehavior
CDOTA_Ability_Lua.GetBehavior = function(self) --Predict uint64?
    return tonumber(tostring(VALVE_CDOTA_Ability_Lua_GetBehavior(self)))
end
--!!----------------------------------------------------------------------------------------------------------------------------------------------------------
local VALVE_CDOTA_Item_Lua_GetBehavior = CDOTA_Item_Lua.GetBehavior
CDOTA_Item_Lua.GetBehavior = function(self) --Predict uint64?
    return tonumber(tostring(VALVE_CDOTA_Item_Lua_GetBehavior(self)))
end

--[[CScriptParticleManager = IsServer() and CScriptParticleManager or C_ScriptParticleManager

local VALVE_CreateParticle = CScriptParticleManager.CreateParticle
CScriptParticleManager.CreateParticle = function(self, partname, attach, entity)
    if entity:IsNull() or not entity:IsValidEntity() then
        return error("CreateParticle pepega entity")
    end
    return VALVE_CreateParticle(self, partname, attach, entity)
end

local VALVE_DestroyParticle = CScriptParticleManager.DestroyParticle
CScriptParticleManager.DestroyParticle = function(self, index, immediate)
    if (not type(index) == "number") or index == nil then
        return error("DestroyParticle shit index")
    end
    return VALVE_DestroyParticle(self, index, immediate)
end

local VALVE_ReleaseParticleIndex = CScriptParticleManager.ReleaseParticleIndex
CScriptParticleManager.ReleaseParticleIndex = function(self, index)
    if (not type(index) == number) or index == nil then
        return error("ReleaseParticleIndex shit index")
    end
    return VALVE_ReleaseParticleIndex(self, index)
end

CDOTA_BaseNPC = IsServer() and CDOTA_BaseNPC or C_DOTA_BaseNPC

local VALVE_ForceKill = CDOTA_BaseNPC.ForceKill
CDOTA_BaseNPC.ForceKill = function(self, bReincarnate)
    if not IsValidEntity(self) then
        return error("ForceKill not valid entity")
    end
    return VALVE_ForceKill(self, bReincarnate)
end

local VALVE_AddNewModifier = CDOTA_BaseNPC.AddNewModifier
CDOTA_BaseNPC.AddNewModifier = function(self, caster, ability, scriptname, modifiertable)
    if not IsValidEntity(self) then
        return error("AddNewModifier not valid target")
    end
    return VALVE_AddNewModifier(self, caster, ability, scriptname, modifiertable)
end

local VALVE_RemoveModifierByName = CDOTA_BaseNPC.RemoveModifierByName
CDOTA_BaseNPC.RemoveModifierByName = function(self, modifiername)
    if not IsValidEntity(self) then
        return error("RemoveModifierByName not valid entity")
    end
    return VALVE_RemoveModifierByName(self, modifiername)
end

local VALVE_FindModifierByName = CDOTA_BaseNPC.FindModifierByName
CDOTA_BaseNPC.FindModifierByName = function(self, scriptname)
    if not IsValidEntity(self) then
        return error("FindModifierByName not valid entity")
    end
    return VALVE_FindModifierByName(self, scriptname)
end

local VALVE_HasModifier = CDOTA_BaseNPC.HasModifier
CDOTA_BaseNPC.HasModifier = function(self, scriptname)
    if not IsValidEntity(self) then
        return error("HasModifier not valid entity")
    end
    return VALVE_HasModifier(self, scriptname)
end

local VALVE_IsAlive = CDOTA_BaseNPC.IsAlive
CDOTA_BaseNPC.IsAlive = function(self)
    if not IsValidEntity(self) then
        return error("IsAlive not valid entity")
    end
    return VALVE_IsAlive(self)
end

local VALVE_GetUnitName = CDOTA_BaseNPC.GetUnitName
CDOTA_BaseNPC.GetUnitName = function(self)
    if not IsValidEntity(self) then
        return error("GetUnitName not valid entity")
    end
    return VALVE_GetUnitName(self)
end

local VALVE_FindAbilityByName = CDOTA_BaseNPC.FindAbilityByName
CDOTA_BaseNPC.FindAbilityByName = function(self, abilityname)
    if not IsValidEntity(self) then
        return error("FindAbilityByName not valid entity")
    end
    return VALVE_FindAbilityByName(self, abilityname)
end

local VALVE_GetAbilityByIndex = CDOTA_BaseNPC.GetAbilityByIndex
CDOTA_BaseNPC.GetAbilityByIndex = function(self, index)
    if not IsValidEntity(self) then
        return error("GetAbilityByIndex not valid entity")
    end
    return VALVE_GetAbilityByIndex(self, index)
end]]

local VALVE_Say = Say
Say = function(entity, msg, teamOnly)
	if not IsValidEntity(entity) then
		return error("Say not valid entity")
	end
    return VALVE_Say(entity, msg, teamOnly)
    --[[local table =
    {
        text = msg
    }
    CustomGameEventManager:Send_ServerToAllClients( "player_chat_lua", table )
    return]]
end

--[[CBaseEntity = IsServer() and CBaseEntity or C_BaseEntity
local VALVE_GetAbsOrigin = CBaseEntity.GetAbsOrigin
CBaseEntity.GetAbsOrigin = function(self)
    if not IsValidEntity(self) then
        return error("GetAbsOrigin not valid entity")
    end
    return VALVE_GetAbsOrigin(self)
end

local VALVE_SetAbsOrigin = CBaseEntity.SetAbsOrigin
CBaseEntity.SetAbsOrigin = function(self, origin)
    if not IsValidEntity(self) then
        return error("SetAbsOrigin not valid entity")
    end
    return VALVE_SetAbsOrigin(self, origin)
end]]

--thx eyeoflie
if IsServer() then

	local RegistredCustomEventsListeners = RegistredCustomEventsListeners or {}
    for _, lID in pairs(RegistredCustomEventsListeners) do
        CustomGameEventManager:UnregisterListener(lID)
        RegistredCustomEventsListeners[_] = nil
    end
    --!!----------------------------------------------------------------------------------------------------------------------------------------------------------
    RegisterCustomEventListener = function(sEventName, fCallBack)
        table.insert(RegistredCustomEventsListeners, CustomGameEventManager:RegisterListener(sEventName, function(_, args) fCallBack(args) end))
    end

    CDOTABaseGameMode.SetControlFateMechanic = function(self, bValue)
        if type(bValue) == "boolean" then
            if bValue then
                self.___SetControlFateMechanic = CreateModifierThinker(self, nil, "modifier_fate_mechanic_parent_new", {}, Vector(0, 0, 0), DOTA_TEAM_NOTEAM, false)
            elseif not bValue and IsNotNull(self.___SetControlFateMechanic) then
                self.___SetControlFateMechanic:Destroy()
            end
            return nil
        end
        error("SetControlFateMechanic not a boolean")
    end

    CDOTA_BaseNPC.TakeDamageCentralized = function(self, hKeys)
        if IsNotNull(self) then
            local hModifiers = self:FindAllModifiers()
            for _, hModifier in pairs(hModifiers) do
                if IsNotNull(hModifier) and type(hModifier.OnTakeDamage) == "function" and not hModifier:HasFunction(MODIFIER_EVENT_ON_TAKEDAMAGE) then
                    hModifier:OnTakeDamage(hKeys)
                end
            end
        end
    end

    CDOTA_BaseNPC.AttackLandedCentralized = function(self, hKeys)
        if IsNotNull(self) then
            local hModifiers = self:FindAllModifiers()
            for _, hModifier in pairs(hModifiers) do
                if IsNotNull(hModifier) and type(hModifier.OnAttackLanded) == "function" and not hModifier:HasFunction(MODIFIER_EVENT_ON_ATTACK_LANDED) then
                    hModifier:OnAttackLanded(hKeys)
                end
            end
        end
    end

    CDOTA_BaseNPC.AttackStartedCentralized = function(self, hKeys)
        if IsNotNull(self) then
            local hModifiers = self:FindAllModifiers()
            for _, hModifier in pairs(hModifiers) do
                if IsNotNull(hModifier) and type(hModifier.OnAttackStart) == "function" and not hModifier:HasFunction(MODIFIER_EVENT_ON_ATTACK_START) then
                    hModifier:OnAttackStart(hKeys)
                end
            end
        end
    end

    CDOTA_BaseNPC.AbilityExecutedCentralized = function(self, hKeys)
        if IsNotNull(self) then
            local hModifiers = self:FindAllModifiers()
            for _, hModifier in pairs(hModifiers) do
                if IsNotNull(hModifier) and type(hModifier.OnAbilityExecuted) == "function" and not hModifier:HasFunction(MODIFIER_EVENT_ON_ABILITY_EXECUTED) then
                    hModifier:OnAbilityExecuted(hKeys)
                end
            end
        end
    end

end

LinkLuaModifier("modifier_fate_mechanic_parent_new", "libraries/fate_functions_server_client", LUA_MODIFIER_MOTION_NONE)

modifier_fate_mechanic_parent_new = modifier_fate_mechanic_parent_new or class({})

function modifier_fate_mechanic_parent_new:IsHidden()                                                                          return true end
function modifier_fate_mechanic_parent_new:IsDebuff()                                                                          return false end
function modifier_fate_mechanic_parent_new:IsPurgable()                                                                        return false end
function modifier_fate_mechanic_parent_new:IsPurgeException()                                                                  return false end
function modifier_fate_mechanic_parent_new:RemoveOnDeath()                                                                     return false end
function modifier_fate_mechanic_parent_new:GetAttributes()                                                                     return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_fate_mechanic_parent_new:GetPriority()                                                                       return MODIFIER_PRIORITY_ULTRA end
function modifier_fate_mechanic_parent_new:IsMarbleException()                                                                 return true end
function modifier_fate_mechanic_parent_new:CheckState()
    local hState =  {
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
                    }
    return hState
end
function modifier_fate_mechanic_parent_new:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_EVENT_ON_ATTACK_START,
                        --MODIFIER_EVENT_ON_ATTACK_RECORD,
                        MODIFIER_EVENT_ON_ABILITY_EXECUTED,

                        MODIFIER_EVENT_ON_DAMAGE_CALCULATED, --FOR LIFESTEAL
                        MODIFIER_EVENT_ON_TAKEDAMAGE, --FOR ALL
                        MODIFIER_EVENT_ON_ATTACK_LANDED
                    }
    return hFunc
end
function modifier_fate_mechanic_parent_new:OnAbilityExecuted(keys)
    if IsServer() then
        local hCaster = keys.ability:GetCaster()
        if IsNotNull(hCaster) then

            hCaster:AbilityExecutedCentralized(keys)
            --[[local iIndex    = tostring(hAttacker:entindex()..hTarget:entindex())
            local fAccuracy = hAttacker:GetAccuracy(keys)
            if fAccuracy > 0 
                and RollPseudoRandom(fAccuracy, hAttacker) then
                self.ACCURACY_RECORDS[iIndex] = hAttacker:AddNewModifier(hAttacker, self.ability, "modifier_anime_mechanic_accuracy", {})
            end]]
        end
    end
end
function modifier_fate_mechanic_parent_new:OnAttackStart(keys)
    if IsServer() then
        local hAttacker = keys.attacker
        local hTarget   = keys.target
        if IsNotNull(hAttacker) 
            and IsNotNull(hTarget) then

            hAttacker:AttackStartedCentralized(keys)
            hTarget:AttackStartedCentralized(keys)
            --[[local iIndex    = tostring(hAttacker:entindex()..hTarget:entindex())
            local fAccuracy = hAttacker:GetAccuracy(keys)
            if fAccuracy > 0 
                and RollPseudoRandom(fAccuracy, hAttacker) then
                self.ACCURACY_RECORDS[iIndex] = hAttacker:AddNewModifier(hAttacker, self.ability, "modifier_anime_mechanic_accuracy", {})
            end]]
        end
    end
end
--[[function modifier_fate_mechanic_parent_new:OnAttackRecord(keys)
    if IsServer() then
        local hAttacker = keys.attacker
        local hTarget   = keys.target
        if IsNotNull(hAttacker) 
            and IsNotNull(hTarget) then
            local iIndex = tostring(hAttacker:entindex()..hTarget:entindex())
            local hModifier = self.ACCURACY_RECORDS[iIndex]
            if IsNotNull(hModifier) then
                hModifier:Destroy()
                self.ACCURACY_RECORDS[iIndex] = nil
            end
        end
    end
end]]
function modifier_fate_mechanic_parent_new:OnAttackLanded(keys)
    --PrintTable(keys)
    --print("FateMechanic OnAttackLanded 1")
    if IsServer() then
        local hAttacker        = keys.attacker
        local hTarget          = keys.target

        if IsNotNull(hAttacker) 
            and IsNotNull(hTarget) then

            hAttacker:AttackLandedCentralized(keys)
            hTarget:AttackLandedCentralized(keys)
        end
    end
end
function modifier_fate_mechanic_parent_new:OnTakeDamage(keys)
    --print("FateMechanic OnTakeDamage 1")
    if IsServer() then
        local hAttacker        = keys.attacker
        local hTarget          = keys.unit
        local hAbility         = keys.inflictor
        local fOriginalDamage  = keys.original_damage
        local fDamage          = keys.damage
        local iDamageType      = keys.damage_type
        local iDamageCategory  = keys.damage_category
        local iDamageFlags     = keys.damage_flags
        local attackerHero = nil
        --print(fDamage)
        --print(fOriginalDamage)

        if IsNotNull(hAttacker) 
            and IsNotNull(hTarget)
            and fDamage > 0 then

            hAttacker:TakeDamageCentralized(keys)
            hTarget:TakeDamageCentralized(keys)
            if hTarget:IsHero() then
                if not hAttacker:IsHero() then --Account neutral attackers
                    attackerHero = PlayerResource:GetSelectedHeroEntity(hAttacker:GetMainControllingPlayer())
                else
                    attackerHero = hAttacker
                end
                local hServerStat = hTarget.ServStat
                if type(hServerStat) == "table" then
                    hServerStat:takeActualDamage(fDamage)
                    hServerStat:takeDamageBeforeReduction(fOriginalDamage)
                    if IsNotNull(attackerHero) then
                        local hAttackerStat = attackerHero.ServStat
                        if type(hAttackerStat) == "table" then
                            hAttackerStat:doActualDamage(fDamage)
                            hAttackerStat:doDamageBeforeReduction(fOriginalDamage)
                        end
                    end
                end
            end
        end
    end
end
function modifier_fate_mechanic_parent_new:OnCreated(hTable)
    self.__hCaster  = self:GetCaster()
    self.__hParent  = self:GetParent()
    self.__hAbility = self:GetAbility()

    self.__fFIND_RADIUS = FIND_UNITS_EVERYWHERE

    self.__iCASTER_TEAM          = self.__hParent:GetTeamNumber()
    self.__vCASTER_LOC           = self.__hParent:GetAbsOrigin()

    self.__iABILITY_TARGET_TEAM  =  DOTA_UNIT_TARGET_TEAM_BOTH
    self.__iABILITY_TARGET_TYPE  =  DOTA_UNIT_TARGET_ALL
    self.__iABILITY_TARGET_FLAGS =  DOTA_UNIT_TARGET_FLAG_DEAD +
                                    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + 
                                    DOTA_UNIT_TARGET_FLAG_INVULNERABLE + 
                                    DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + 
                                    DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
    --[[if IsServer() then
        --self.ACCURACY_RECORDS = self.ACCURACY_RECORDS or {}

        self:OnIntervalThink()
        self:StartIntervalThink(0.5)
    end]]
end
function modifier_fate_mechanic_parent_new:OnRefresh(hTable)
    self:OnCreated(hTable)
end
--mb will be useful later, poka nahui
--[[function modifier_fate_mechanic_parent_new:OnIntervalThink()
    if IsServer() then
        local hEntities = FindUnitsInRadius( 
                                                self.__iCASTER_TEAM,
                                                self.__vCASTER_LOC,
                                                nil,
                                                self.__fFIND_RADIUS,
                                                self.__iABILITY_TARGET_TEAM,
                                                self.__iABILITY_TARGET_TYPE,
                                                self.__iABILITY_TARGET_FLAGS,
                                                FIND_ANY_ORDER,
                                                false
                                            )

        for _, hEntity in pairs(hEntities) do
            if IsNotNull(hEntity)
                and not hEntity:HasModifier("modifier_anime_mechanic_backtrack") then
                --print(hEntity:IsIllusion(), "WTF", hEntity:GetUnitName())
                hEntity:AddNewModifier(hEntity, self.__hAbility, "modifier_anime_mechanic_backtrack", {})
            end
        end
    end
end]]