modifier_courier_position = class({})
function modifier_courier_position:OnCreated(args)
	self.vector_x = args.vector_x
	self.vector_y = args.vector_y
	self.vector_z = args.vector_z
	--[[if IsServer() then
		self:GetParent():SetAbsOrigin(Vector(self.vector_x, self.vector_y, self.vector_z))
	end]]
	self:StartIntervalThink(1)
end
function modifier_courier_position:OnIntervalThink()
	if IsServer() then
		self:GetParent():SetAbsOrigin(Vector(self.vector_x, self.vector_y, self.vector_z))
	end
end

modifier_tp_cooldown = class({})
function modifier_tp_cooldown:IsHidden() return true end
function modifier_tp_cooldown:IsDebuff() return false end
function modifier_tp_cooldown:IsPurgable() return false end
function modifier_tp_cooldown:IsPurgeException() return false end
function modifier_tp_cooldown:RemoveOnDeath() return false end
function modifier_tp_cooldown:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_tp_cooldown:OnCreated(args)
	self:StartIntervalThink(1)
end
function modifier_tp_cooldown:OnIntervalThink()
	if IsServer() then
		self:GetParent():GetItemInSlot(15):StartCooldown(99999)
	end
end

modifier_airborne_marker = class({})
function modifier_airborne_marker:IsHidden() return true end
function modifier_airborne_marker:IsDebuff() return false end
function modifier_airborne_marker:IsPurgable() return false end
function modifier_airborne_marker:IsPurgeException() return false end
function modifier_airborne_marker:RemoveOnDeath() return true end
function modifier_airborne_marker:OnCreated()
    self.elapsed = 0
    self:StartIntervalThink(FrameTime())
end
function modifier_airborne_marker:OnIntervalThink()
    self.elapsed = self.elapsed + FrameTime()
    --print(self.elapsed)
end
function modifier_airborne_marker:OnRefresh()
    self:OnCreated()
end