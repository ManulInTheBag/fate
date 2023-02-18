LinkLuaModifier("modifier_merlin_hero_creation", "abilities/merlin/merlin_hero_creation", LUA_MODIFIER_MOTION_NONE)
 
merlin_hero_creation = class({})

function merlin_hero_creation:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
    self.lasttargetprimarystat = target:GetPrimaryAttribute() 
  
    target:AddNewModifier(target, self, "modifier_merlin_hero_creation", {duration = self:GetSpecialValueFor("duration")})

    caster:FindAbilityByName("merlin_charisma"):AttStack() 
    
    caster:EmitSound("hero_creation")
end

modifier_merlin_hero_creation = class({})

function modifier_merlin_hero_creation:OnCreated()

    self.parent = self:GetParent()
    self.particle = ParticleManager:CreateParticle("particles/merlin/flowers_petals_hero.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(    self.particle , 0,  self.parent:GetAbsOrigin() )  
    self.strbonus = 0 
    self.agibonus = 0
    self.intbonus = 0
    self.msbonus = 0
    self.msbonusbase =  self:GetAbility():GetSpecialValueFor("ms_base")
    self.primaryatr = self:GetAbility().lasttargetprimarystat 
 
    self.base_stat_bonus = self:GetAbility():GetSpecialValueFor("base_stat_bonus")
 

  
     self.radius = self:GetAbility():GetSpecialValueFor("radius")
    
     self.increase_per_teammate = self:GetAbility():GetSpecialValueFor("stat_increase_per_teammate")
 
	 self:StartIntervalThink(FrameTime())
 
    
end
 

function modifier_merlin_hero_creation:OnIntervalThink()
    if IsServer() then
        local seva_spasibo = 0
        local targets = FindUnitsInRadius( self.parent:GetTeam(),  self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY , DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
        for k,v in pairs(targets) do
            seva_spasibo   = seva_spasibo + 1
        end
        if(  self.primaryatr == 0 ) then
            self.strbonus = self.base_stat_bonus +  self.increase_per_teammate * (seva_spasibo-1)
        elseif(  self.primaryatr == 1 ) then
            self.agibonus =  self.base_stat_bonus+   self.increase_per_teammate * (seva_spasibo-1)
        else
            self.intbonus = self.base_stat_bonus +  self.increase_per_teammate * (seva_spasibo-1)
        end
        self.msbonus =  self.msbonusbase +  self.increase_per_teammate * (seva_spasibo-1)
    end
end


function modifier_merlin_hero_creation:OnDestroy( )
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
end


function modifier_merlin_hero_creation:IsHidden() return false end
function modifier_merlin_hero_creation:IsDebuff() return false end
function modifier_merlin_hero_creation:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, 
	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,      }
end


function modifier_merlin_hero_creation:GetModifierBonusStats_Strength()
	return  self.strbonus
end
 
function modifier_merlin_hero_creation:GetModifierBonusStats_Intellect()
	return  self.intbonus
end
function modifier_merlin_hero_creation:GetModifierBonusStats_Agility()
	return  self.agibonus 
end

function modifier_merlin_hero_creation:GetModifierMoveSpeedBonus_Percentage()
	return self.msbonus
end

function modifier_merlin_hero_creation:OnTakeDamage(args)
	if args.attacker ~= self:GetParent() then return end
	if(  args.unit:GetTeam() == self:GetParent():GetTeam()) then return end
	if args.damage_type == 2 then
		self:GetParent():Heal(args.damage*0.1, self:GetParent())
	end
end
 

function modifier_merlin_hero_creation:GetTexture()
    return "custom/merlin/merlin_hero_creation"
end
