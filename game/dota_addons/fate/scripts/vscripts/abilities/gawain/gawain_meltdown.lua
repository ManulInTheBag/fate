gawain_meltdown = class({})

LinkLuaModifier("modifier_meltdown", "abilities/gawain/gawain_meltdown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meltdown_mark", "abilities/gawain/gawain_meltdown", LUA_MODIFIER_MOTION_NONE)
 

function gawain_meltdown:OnSpellStart()
    local caster = self:GetCaster()
	local ability = self
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		if v:GetUnitName() == "gawain_artificial_sun" then
 
            v:AddNewModifier(caster,ability,"modifier_meltdown", {duration = 5})
            v:FindModifierByNameAndCaster("modifier_gawain_sun_passive", v):Meltdown()
            v:RemoveModifierByName("modifier_artificial_sun_aura")
			v:EmitSound("Hero_DoomBringer.ScorchedEarthAura")
			v:EmitSound("Hero_Warlock.RainOfChaos_buildup" )
			v.metldownFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_meltdown.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
			ParticleManager:SetParticleControl( v.metldownFx, 0, v:GetAbsOrigin())
			Timers:CreateTimer(5.0, function()
				if IsValidEntity(v) and v:IsAlive() then
					ParticleManager:DestroyParticle( v.metldownFx, true )
					ParticleManager:ReleaseParticleIndex( v.metldownFx )
				end
				StopSoundOn("Hero_DoomBringer.ScorchedEarthAura", v)
			end)
		end
	end
end


modifier_meltdown = class({})

function modifier_meltdown:IsHidden() return true end
function modifier_meltdown:IsDebuff() return false end
function modifier_meltdown:RemoveOnDeath() return true end
function modifier_meltdown:DeclareFunctions()
	return { 
   
           }
end


function modifier_meltdown:OnCreated()
    self:StartIntervalThink(0.25)
    self.caster = self:GetCaster()
    self.sun = self:GetParent()
    self.counter = 20
    self.ability = self:GetAbility()
    self.team = self.caster:GetTeamNumber()
end 

function modifier_meltdown:OnDestroy()
    self.sun:RemoveSelf()
end 


function modifier_meltdown:OnIntervalThink()
	if not IsServer() then return end
    self.counter = self.counter - 1
	local targets = FindUnitsInRadius(  self.team, self.sun:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
        if( not v:HasModifier("modifier_meltdown_mark")) then
		    DoDamage(self.caster, v, v:GetHealth()  * ( 0.03+ self.counter/660), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            v:AddNewModifier(self.caster, self.ability,"modifier_meltdown_mark", {duration = 0.2})
        end
	end

end 
 
modifier_meltdown_mark = class({})

function modifier_meltdown_mark:IsHidden() return false end
function modifier_meltdown_mark:IsDebuff() return true end
function modifier_meltdown_mark:RemoveOnDeath() return true end
function modifier_meltdown_mark:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_meltdown_mark:GetModifierMoveSpeedBonus_Percentage(keys)
    return -30
end
