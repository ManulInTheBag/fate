emiya_overedge_circle  = emiya_overedge_circle or class({})

LinkLuaModifier("modifier_emiya_self_control_circles","abilities/emiya/emiya_overedge_circle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_emiya_dash", "abilities/emiya/emiya_double_slash", LUA_MODIFIER_MOTION_HORIZONTAL)
 
function emiya_overedge_circle:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
    if caster:FindAbilityByName("emiya_caladbolg"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_caladbolg"):SetLevel(self:GetLevel())
    end  
    if caster:FindAbilityByName("emiya_crane_wings"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_crane_wings"):SetLevel(self:GetLevel())
    end
end


function emiya_overedge_circle:OnSpellStart()
	local caster = self:GetCaster()

	
    radius = 400
    local damage = self:GetSpecialValueFor("damage")
    caster:AddNewModifier(caster, self, "modifier_emiya_dash", {duration = 0.33})
    caster:AddNewModifier(caster, self, "modifier_emiya_self_control_circles", {duration = 0.66, radius = radius, damage = damage, interval = 0.033})
	StartAnimation(caster, {duration= 0.33 , activity=ACT_DOTA_RAZE_3, rate= 1})
    caster:StartGesture(ACT_DOTA_ALCHEMIST_CONCOCTION)
	Timers:CreateTimer(0.33, function() 
        StartAnimation(caster, {duration= 0.5 , activity=ACT_DOTA_ALCHEMIST_CONCOCTION_THROW, rate= 1})
	end)

end

 

modifier_emiya_self_control_circles = modifier_emiya_self_control_circles or class({})

function modifier_emiya_self_control_circles:IsHidden() return true end
function modifier_emiya_self_control_circles:IsDebuff() return false end
function modifier_emiya_self_control_circles:IsPurgable() return false end
function modifier_emiya_self_control_circles:RemoveOnDeath() return true end

function modifier_emiya_self_control_circles:CheckState()
    local state =   { 
		[MODIFIER_STATE_SILENCED] = true,
		--[MODIFIER_STATE_ROOTED] = true,
		--[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
                    }
    return state
end
 
function modifier_emiya_self_control_circles:DeclareFunctions()
    local hFunc =   {
    						MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE 
						   
                    }
    return hFunc
end
function modifier_emiya_self_control_circles:GetModifierMoveSpeed_Absolute() return 200 end

function modifier_emiya_self_control_circles:OnCreated(table)
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.counter = 0
    self.radius = table.radius
    self.slash_damage = table.damage
    self:StartIntervalThink(table.interval)
end

function modifier_emiya_self_control_circles:OnIntervalThink()
    self.counter = self.counter + 1
    if(self.counter == 15) then
        self:PerformSlash()
    end
    if(self.counter == 17) then
        self:PerformSlash()
    end

    if(self.counter == 20) then
        self:PerformSlash()
    end
end

function modifier_emiya_self_control_circles:PerformSlash()
local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
                        self.caster:GetAbsOrigin(),
                        nil,
                        self.radius,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
    
     for _,enemy in pairs(enemies) do
        DoDamage(self.caster, enemy, self.slash_damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
         enemy:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
       
     end


end

