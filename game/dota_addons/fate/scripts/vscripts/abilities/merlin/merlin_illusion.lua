
LinkLuaModifier("modifier_merlin_illusion","abilities/merlin/merlin_illusion", LUA_MODIFIER_MOTION_NONE)
 
LinkLuaModifier("modifier_merlin_illusion_overslept","abilities/merlin/merlin_illusion", LUA_MODIFIER_MOTION_NONE)
merlin_illusion = class({})
function merlin_illusion:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function merlin_illusion:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local radius = self:GetAOERadius()
    local target = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("basic_duration")
    local duration_reduction = self:GetSpecialValueFor("duration_red_per_unit")
    local seva_spasibo = 0
    local min_duration = self:GetSpecialValueFor("min_duration")

    local damage = self:GetSpecialValueFor("damage")

    caster:FindAbilityByName("merlin_charisma"):AttStack() 
    if(caster.RapidChantingAcquired) then
		local cd1 = caster:GetAbilityByIndex(0):GetCooldownTimeRemaining()
		
		local cd3 = caster:GetAbilityByIndex(5):GetCooldownTimeRemaining()
		caster:GetAbilityByIndex(0):EndCooldown()
	
		caster:GetAbilityByIndex(5):EndCooldown()
        if(cd1 > 0 ) then
		    caster:GetAbilityByIndex(0):StartCooldown(cd1 -1)
        end
	 
			local cd2 = caster:GetAbilityByIndex(1):GetCooldownTimeRemaining()
			caster:GetAbilityByIndex(1):EndCooldown()
            if(cd2 > 0 ) then
		    	caster:GetAbilityByIndex(1):StartCooldown(cd2 -1)
            end
            if(cd3 > 0 ) then
	        	caster:GetAbilityByIndex(5):StartCooldown(cd3 -1)
            end
	end
    self.illusion_fx = ParticleManager:CreateParticle("particles/merlin/merlin_illusion_cast_1.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(self.illusion_fx, 0, target     ) 
    ParticleManager:SetParticleControl(self.illusion_fx, 1, Vector(radius,0,0)     ) 
    Timers:CreateTimer(0.85, function() 
        caster:EmitSound("merlin_illusion")
        local targets = FindUnitsInRadius(caster:GetTeam(), target, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
     
        duration = duration - (#targets-1)*duration_reduction
        if(duration < 0) then duration = 0 end
        if(duration < min_duration) then 
            duration = min_duration
        end
        self.explosionFx = ParticleManager:CreateParticle("particles/merlin/merlin_illusion_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(self.explosionFx, 0, target     ) 
        for k,v in pairs(targets) do
            if(v:HasModifier( "modifier_merlin_illusion_overslept")) then
               v:AddNewModifier(caster, self, "modifier_merlin_illusion", { Duration =  min_duration, damage = damage})
            else
               v:AddNewModifier(caster, self, "modifier_merlin_illusion", { Duration =  duration, damage = damage})
            end
            v:AddNewModifier(caster, self, "modifier_merlin_illusion_overslept", { Duration =  5})
            
         end



    end)


 
end


modifier_merlin_illusion = class({})

function modifier_merlin_illusion:CheckState()
    local state =   { 
            [MODIFIER_STATE_SILENCED] = true,
            [MODIFIER_STATE_ROOTED] = true,
            [MODIFIER_STATE_MUTED] = true,
            [MODIFIER_STATE_DISARMED] = true,
                    }
    return state
end

function modifier_merlin_illusion:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING  }

	return funcs
end

function modifier_merlin_illusion:GetModifierDisableTurning() 
	return 1
end
 

function modifier_merlin_illusion:OnCreated(args)
    self.damage_total = 0
    self.sleepfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_sleep.vpcf", PATTACH_OVERHEAD_FOLLOW , self:GetParent()) 
    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.abililty = self:GetAbility()
    self.damage = args.damage
    self:StartIntervalThink(0.25)
 
end

function modifier_merlin_illusion:OnIntervalThink()
    DoDamage(self.caster, self.parent, self.damage , DAMAGE_TYPE_PURE, 0,  self.abililty, false)

 
end
 
        
function modifier_merlin_illusion:OnRefresh()
    ParticleManager:DestroyParticle(self.sleepfx, false)
	ParticleManager:ReleaseParticleIndex(self.sleepfx) 
    self.damage_total = 0
    self.sleepfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_sleep.vpcf", PATTACH_OVERHEAD_FOLLOW , self:GetParent()) 
end

function modifier_merlin_illusion:OnDestroy()
    ParticleManager:DestroyParticle(self.sleepfx, false)
	ParticleManager:ReleaseParticleIndex(self.sleepfx) 
end




function modifier_merlin_illusion:OnTakeDamage(args)
    local ability = self:GetAbility()
    local damage = args.damage
    if args.inflictor ~= ability then
        self.damage_total = self.damage_total + damage
    end
    
    if(self.damage_total >= self:GetAbility():GetSpecialValueFor("damage_to_awake")) then
        self:Destroy()
    end
    
end
 
function modifier_merlin_illusion:IsHidden() return false end
function modifier_merlin_illusion:RemoveOnDeath() return true end

 
modifier_merlin_illusion_overslept = class({})

function modifier_merlin_illusion:IsHidden() return false end
function modifier_merlin_illusion:RemoveOnDeath() return true end