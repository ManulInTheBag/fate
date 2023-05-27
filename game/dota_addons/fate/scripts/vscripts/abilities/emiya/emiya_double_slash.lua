emiya_double_slash  = emiya_double_slash or class({})

LinkLuaModifier("modifier_emiya_self_control","abilities/emiya/emiya_double_slash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_emiya_dash", "abilities/emiya/emiya_double_slash", LUA_MODIFIER_MOTION_HORIZONTAL)
 
function emiya_double_slash:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    if caster:FindAbilityByName("emiya_change"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_change"):SetLevel(self:GetLevel())
    end

end


function emiya_double_slash:OnSpellStart()
	local caster = self:GetCaster()
    local vPoint = self:GetCursorPosition()
	local vCasterPos = caster:GetAbsOrigin()
	local vCastDirection =    (vPoint -vCasterPos):Normalized()
    caster:SetForwardVector(vCastDirection)
	caster:AddNewModifier(caster, self, "modifier_emiya_dash", {duration = 0.33})
    local radius = 300
    if(caster:HasModifier("emiya_overedge_modifier")) then
        radius = 450
    end
    local damage = self:GetSpecialValueFor("damage")
	--StartAnimation(caster, {duration= 0.3 , activity=ACT_DOTA_ALCHEMIST_CONCOCTION, rate= 1})
    caster:StartGesture(ACT_DOTA_ALCHEMIST_CONCOCTION)
	Timers:CreateTimer(0.25, function() 
        if(caster:HasModifier("emiya_overedge_modifier")) then
		    StartAnimation(caster, {duration= 0.75 , activity=ACT_DOTA_AW_MAGNETIC_FIELD, rate= 1})
        else
            StartAnimation(caster, {duration= 0.75 , activity=ACT_DOTA_CAST_ABILITY_3_END, rate= 1})
        end
	    caster:AddNewModifier(caster, self, "modifier_emiya_self_control", {duration = 0.75, damage = damage, radius = radius, interval = 0.03})
		--caster:AddNewModifier(caster, self, "emiya_overedge_modifier", {duration = 8})
        
	end)
 

end

 

modifier_emiya_self_control = modifier_emiya_self_control or class({})

function modifier_emiya_self_control:IsHidden() return true end
function modifier_emiya_self_control:IsDebuff() return false end
function modifier_emiya_self_control:IsPurgable() return false end
function modifier_emiya_self_control:RemoveOnDeath() return true end

function modifier_emiya_self_control:CheckState()
    local state =   { 
		[MODIFIER_STATE_SILENCED] = true,
		--[MODIFIER_STATE_ROOTED] = true,
		--[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
                    }
    return state
end
 
function modifier_emiya_self_control:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
                        MODIFIER_EVENT_ON_ATTACK_LANDED,
						MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE 
						   
                    }
    return hFunc
end
function modifier_emiya_self_control:GetModifierMoveSpeed_Absolute() return 200 end

function modifier_emiya_self_control:OnCreated(table)
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.counter = 0
    self.radius = table.radius
    self.slash_damage = table.damage
    self.interval = table.interval
    if( self.interval == nil ) then
        self.interval = 0.03
    end
    print(self.interval)
    self:StartIntervalThink(self.interval)
end

function modifier_emiya_self_control:OnRefresh()
    return
end

function modifier_emiya_self_control:OnIntervalThink() --- this is insanily stupid but i somehow wrote it not going insane and it works ok for me  
    self.counter = self.counter + 1
    if(self.counter == 10) then
        self:PerformSlash()
    end
    if(self.counter == 11) then
        self:PerformSlash()
    end

    if(self.counter == 20) then
        self:PerformSlash()
        self:PerformSlash()
    end
end

function modifier_emiya_self_control:PerformSlash()
if not IsServer() then return end    
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
       local origin_diff = enemy:GetAbsOrigin() - self.caster:GetAbsOrigin()
       local origin_diff_norm = origin_diff:Normalized()
         if self.caster:GetForwardVector():Dot(origin_diff_norm) > -0.35 then
         DoDamage(self.caster, enemy, self.slash_damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
         enemy:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
       end
     end


end



modifier_emiya_dash = class({})
function modifier_emiya_dash:IsHidden() return true end
function modifier_emiya_dash:IsDebuff() return false end
function modifier_emiya_dash:IsPurgable() return false end
function modifier_emiya_dash:IsPurgeException() return false end
function modifier_emiya_dash:RemoveOnDeath() return true end
function modifier_emiya_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_emiya_dash:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_emiya_dash:CheckState()
    local state =   { 
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
						[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                    }
    return state
end

function modifier_emiya_dash:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    EmitSoundOn("nero_dash", self.parent)

    if IsServer() then
        self.speed          = 1500
        self.distance       = 500
        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = self.parent:GetForwardVector():Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance
        self.parent:SetForwardVector(self.direction)
        self:StartIntervalThink(FrameTime())

    end
end
function modifier_emiya_dash:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_emiya_dash:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_emiya_dash:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.distance >= 0 then
        	--self.direction = self.parent:GetForwardVector()
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()
            local next_pos = parent_pos + self.direction * units_per_dt
            local distance_will = self.distance - units_per_dt
            self.parent:SetOrigin(GetGroundPosition(next_pos, self.parent))
            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_emiya_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_emiya_dash:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end