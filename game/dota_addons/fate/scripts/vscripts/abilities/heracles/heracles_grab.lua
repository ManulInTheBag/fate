heracles_grab = class({})

LinkLuaModifier("modifier_herc_grab", "abilities/heracles/heracles_grab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_herc_grab_enemy", "abilities/heracles/heracles_grab", LUA_MODIFIER_MOTION_NONE)
--phase start 0.2
function heracles_grab:OnAbilityPhaseStart()
	local caster = self:GetCaster()
    if caster:HasModifier("modifier_heracles_berserk") then
        StartAnimation(caster, {duration=1.5, activity=ACT_DOTA_CAST_ABILITY_2, rate=1})
    else
        StartAnimation(caster, {duration=1.5, activity=ACT_DOTA_CAST_SUN_STRIKE, rate=1})
    end
	
end

function heracles_grab :OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end



function heracles_grab:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local damage = self:GetSpecialValueFor("grab_damage")

	--caster:EmitSound("aoko_intimidation_grab_1")
    

	targetindex = target:entindex()

	caster:AddNewModifier(caster, self, "modifier_herc_grab", {targetindex = targetindex, duration = 1.3})

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)



end



modifier_herc_grab = class({})

function modifier_herc_grab:OnCreated(args)
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.enemy = EntIndexToHScript(args.targetindex)
        self.pos_enemy = self.parent:GetAbsOrigin() + self.parent:GetForwardVector() * 150 + Vector(0,0,50) --self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_hand"))


        self.enemy:AddNewModifier(self.parent, self.ability, "modifier_stunned", {duration = 1.3}) 
         self.enemy:AddNewModifier(self.parent, self.ability, "modifier_herc_grab_enemy", {duration = 1.3}) 

		self:StartIntervalThink(FrameTime())
		self.ticks = 0
		self.pepeg = false
          self.enemy:SetAbsOrigin(self.pos_enemy )
	end
end

function modifier_herc_grab:IsHidden() return false end
function modifier_herc_grab:IsDebuff() return false end
function modifier_herc_grab:RemoveOnDeath() return true end
function modifier_herc_grab:GetPriority() return MODIFIER_PRIORITY_HIGH end

function modifier_herc_grab:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY ] = true, }
    
    return state
end
function modifier_herc_grab:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)

        FindClearSpaceForUnit(self.parent, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent), true)
        FindClearSpaceForUnit(self.enemy, GetGroundPosition(self.enemy:GetAbsOrigin() + self.parent:GetForwardVector()*100, self.enemy), true)

    end
end
function modifier_herc_grab:OnIntervalThink()
	self:UpdateHorizontalMotion(self.parent, FrameTime())

	--[[ParticleManager:SetParticleControl(self.hand_fx_1, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack1")))
	ParticleManager:SetParticleControl(self.hand_fx_2, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack2")))]]
end
function modifier_herc_grab:UpdateHorizontalMotion(me, dt)
	
    self:Rush(me, dt)
    self:EnemyRush()
end
function modifier_herc_grab:Rush(me, dt)

    self.ticks = self.ticks + 1
end
function modifier_herc_grab:EnemyRush()
    --[[if self.parent:IsStunned() then
        return nil
    end]]

   -- print()
    self.pos_enemy = self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_hand"))

    self.enemy:SetAbsOrigin(self.pos_enemy )
    --FindClearSpaceForUnit(self.enemy, self.pos_enemy, false)
end

modifier_herc_grab_enemy = class({})

function modifier_herc_grab_enemy:IsHidden() return false end
function modifier_herc_grab_enemy:IsDebuff() return false end
function modifier_herc_grab_enemy:RemoveOnDeath() return true end
function modifier_herc_grab_enemy:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY ] = true, }
    
    return state
end