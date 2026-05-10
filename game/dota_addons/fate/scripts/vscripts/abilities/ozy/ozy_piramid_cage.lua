ozy_piramid_cage  = ozy_piramid_cage or class({})

LinkLuaModifier("modifier_ozy_cage", "abilities/ozy/ozy_piramid_cage", LUA_MODIFIER_MOTION_NONE)

function ozy_piramid_cage:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end



function ozy_piramid_cage:OnSpellStart()
	local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    if (point-caster:GetAbsOrigin()):Length2D() > 1500 then
		point = caster:GetAbsOrigin() + (point-caster:GetAbsOrigin()):Normalized() * 1500
	end
    CreateModifierThinker(caster, self, "modifier_ozy_cage", {duration = self:GetSpecialValueFor("duration") }, point, caster:GetTeamNumber(), false)
	

	 
end



modifier_ozy_cage = modifier_ozy_cage or class({})

function modifier_ozy_cage:IsHidden() return false end
function modifier_ozy_cage:IsDebuff() return false end
function modifier_ozy_cage:IsPurgable() return false end
function modifier_ozy_cage:IsPurgeException() return false end
function modifier_ozy_cage:RemoveOnDeath() return true end
function modifier_ozy_cage:CheckState()
    local state = { [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_PROVIDES_VISION] = true, }
    return state
end
function modifier_ozy_cage:OnCreated(hTable)
    self.hParent = self:GetParent()
    self.hCaster = self:GetCaster().Ozy
    self.hAbility = self:GetAbility()
    self.nRadius = self.hAbility:GetSpecialValueFor("radius")
    self.nSSDuration = self.hAbility:GetSpecialValueFor("root_duration")
    self.cageParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_kineticfield.vpcf", PATTACH_CUSTOMORIGIN, self.hParent)
    ParticleManager:SetParticleControl(self.cageParticle, 0, self.hParent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.cageParticle, 1, Vector(self.nRadius, 0, 0))
    ParticleManager:SetParticleControl(self.cageParticle, 2, Vector(self.nRadius, 0, 0))
    self:AddParticle(self.cageParticle, true, false, -1, false, false)
    self:StartIntervalThink(0.1)
    EmitSoundOn("ozy_cage_cast", self.hParent)
     
end
function modifier_ozy_cage:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_ozy_cage:OnDestroy()
   StopSoundOn("ozy_cage_cast", self.hParent)
end

if IsServer() then
    function modifier_ozy_cage:OnIntervalThink()
        
        local tEnemies = FindUnitsInRadius(self.hCaster:GetTeam(), self.hParent:GetAbsOrigin(), nil, self.nRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
        for k,v in pairs(tEnemies) do
            giveUnitDataDrivenModifier(self.hCaster, v, "locked", 0.15)
        end
    end
end

function modifier_ozy_cage:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_EVENT_ON_ABILITY_START
                    }
    return tFunc
end

function modifier_ozy_cage:OnAbilityStart(keys)
    if IsServer()
        and IsNotNull(keys.unit)
        and IsNotNull(keys.ability)
        and not keys.ability:IsItem()
        and GetDistance(keys.unit, self.hParent) <= self.nRadius
        and UnitFilter( --This checks filter units for example you can put here settings AKA check non-invis and etc.
                        keys.unit,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_HERO,
                        DOTA_UNIT_TARGET_FLAG_NONE, --DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                        self.hCaster:GetTeamNumber()
                        ) == UF_SUCCESS then


        
        keys.unit:AddNewModifier(self.hCaster, self.hAbility, "modifier_rooted", {duration = self.nSSDuration})
    end
end