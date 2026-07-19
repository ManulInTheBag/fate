modifier_kim_eye = modifier_kim_eye or class({})

function modifier_kim_eye:IsHidden()                 return true end
function modifier_kim_eye:IsDebuff()                 return false end
function modifier_kim_eye:IsPurgable()               return false end
function modifier_kim_eye:IsPurgeException()         return false end
function modifier_kim_eye:RemoveOnDeath()            return false end
function modifier_kim_eye:IsDimensionException()     return true end
function modifier_kim_eye:AllowIllusionDuplicate()   return true end

function modifier_kim_eye:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_kim_eye:OnCreated()
	if not IsServer() then return end
	if self:GetParent():IsAlive() then
		self:StartEye()
	end
end

function modifier_kim_eye:OnRefresh()
	--nothing to re-read; the particle is already up
end

function modifier_kim_eye:OnDestroy()
	if not IsServer() then return end
	self:StopEye()
end

function modifier_kim_eye:StartEye()
	if self.EyeFx then return end
	local parent = self:GetParent()
	self.EyeFx = ParticleManager:CreateParticle("particles/zlodemon/kim/kim_eye_glow.vpcf", PATTACH_POINT_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.EyeFx, 0, parent, PATTACH_POINT_FOLLOW, "attach_eye", parent:GetAbsOrigin(), true)
end

function modifier_kim_eye:StopEye()
	if not self.EyeFx then return end
	ParticleManager:DestroyParticle(self.EyeFx, true)
	ParticleManager:ReleaseParticleIndex(self.EyeFx)
	self.EyeFx = nil
end

--the modifier outlives death (RemoveOnDeath false), and sasaki has DrawParticlesWhileHidden,
--so the glow has to be taken down by hand or it hangs over the corpse
function modifier_kim_eye:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	self:StopEye()
end

function modifier_kim_eye:OnRespawn(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	self:StartEye()
end
