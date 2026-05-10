LinkLuaModifier("ozy_teleport_boat_delay", "abilities/ozy/ozy_teleport_boat", LUA_MODIFIER_MOTION_NONE)
ozy_teleport_boat = class({})

function ozy_teleport_boat:OnChannelFinish(interrupted)
	if interrupted then
		if self:GetCaster().ozy:HasModifier("ozy_teleport_boat_delay") then
			self:GetCaster().ozy:RemoveModifierByName("ozy_teleport_boat_delay")
		end
	end



end
function ozy_teleport_boat:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local ozymandias = hCaster.ozy
	local boatOrigin = hCaster:GetAbsOrigin()
	local ozyOrigin = ozymandias:GetAbsOrigin()
	local distance  = (vTargetPoint - ozyOrigin):Length2D()
	local MaxDistance = self:GetSpecialValueFor("max_distance")
	local delay = self:GetSpecialValueFor("delay")
	EmitSoundOn("ozy_boat_recall", hCaster)
	EmitSoundOn("ozy_boat_recall", ozymandias)
	if distance > MaxDistance then
		vector = (vTargetPoint - ozyOrigin):Normalized()
		vTargetPoint = ozyOrigin + vector * MaxDistance
	end
	self.point = vTargetPoint
	Timers:RemoveTimer("ozymandias_move_boat")
	ozymandias:AddNewModifier(hCaster, self, "ozy_teleport_boat_delay", {duration = 3, vPoint = vTargetPoint})


end



ozy_teleport_boat_delay = class({})
function ozy_teleport_boat_delay:IsHidden() return false end
function ozy_teleport_boat_delay:IsDebuff() return false end
function ozy_teleport_boat_delay:IsPurgable() return false end
function ozy_teleport_boat_delay:IsPurgeException() return false end
function ozy_teleport_boat_delay:RemoveOnDeath() return true end
function ozy_teleport_boat_delay:GetPriority() return MODIFIER_PRIORITY_HIGH end
function ozy_teleport_boat_delay:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function ozy_teleport_boat_delay:DestroyOnExpire() return false end
function ozy_teleport_boat_delay:OnCreated(args) 
	self.vPoint = self:GetAbility().point
	print(self.vPoint)
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("delay"))
	
end

function ozy_teleport_boat_delay:OnIntervalThink() 
	self:GetCaster():SetAbsOrigin(self.vPoint)
	self:Destroy()

end

function ozy_teleport_boat_delay:OnDestroy() 
	StopSoundOn("ozy_boat_recall", self:GetCaster())
	StopSoundOn("ozy_boat_recall", self:GetCaster().ozy)
end
function ozy_teleport_boat_delay:OnTakeDamage(args)
    local caster = self:GetParent()
    local ability = self:GetAbility()

    ----damage 
    if(  args.attacker ~= caster )then
		if args.damage > ability:GetSpecialValueFor("minimum_damage") then
			self:Destroy()
		end
    
    end

    

end

function ozy_teleport_boat_delay:GetEffectName()
	return  "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_recall.vpcf" 
end

function ozy_teleport_boat_delay:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
