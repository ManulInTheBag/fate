------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_renvor", "abilities/zlodemon_nasral/modifier_renvor.lua", LUA_MODIFIER_MOTION_NONE)

modifier_renvor = class({})
function modifier_renvor:IsHidden() return true end
function modifier_renvor:IsDebuff() return false end
function modifier_renvor:IsPurgable() return false end
function modifier_renvor:IsPurgeException() return false end
function modifier_renvor:RemoveOnDeath() return false end
function modifier_renvor:OnCreated(table)
	if IsServer() then
 

	local particleName = "particles/zlodemon/modifier_renvor.vpcf"
 
	self.pfx = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    --ParticleManager:SetParticleControl( self.pfx, 0,  self:GetParent():GetAbsOrigin() )
	end
end
function modifier_renvor:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle( self.pfx, false )
			ParticleManager:ReleaseParticleIndex( self.pfx )
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_hvick", "abilities/zlodemon_nasral/modifier_renvor.lua", LUA_MODIFIER_MOTION_NONE)

modifier_hvick = class({})
function modifier_hvick:IsHidden() return true end
function modifier_hvick:IsDebuff() return false end
function modifier_hvick:IsPurgable() return false end
function modifier_hvick:IsPurgeException() return false end
function modifier_hvick:RemoveOnDeath() return false end
function modifier_hvick:OnCreated(table)
	if IsServer() then
 

	local particleName = "particles/zlodemon/modifier_hvick.vpcf"
 
	self.pfx = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    --ParticleManager:SetParticleControl( self.pfx, 0,  self:GetParent():GetAbsOrigin() )
	end
end
function modifier_hvick:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle( self.pfx, false )
			ParticleManager:ReleaseParticleIndex( self.pfx )
		end
	end
end


------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_petuh", "abilities/zlodemon_nasral/modifier_renvor.lua", LUA_MODIFIER_MOTION_NONE)

modifier_petuh = class({})
function modifier_petuh:IsHidden() return true end
function modifier_petuh:IsDebuff() return false end
function modifier_petuh:IsPurgable() return false end
function modifier_petuh:IsPurgeException() return false end
function modifier_petuh:RemoveOnDeath() return false end
function modifier_petuh:OnCreated(table)
	if IsServer() then
 

	local particleName = "particles/zlodemon/chicken.vpcf"
 
	self.pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.pfx, 0,  self:GetParent():GetAbsOrigin() )
		self.damage = 5
	self:StartIntervalThink(1)
	end
end

function modifier_petuh:OnIntervalThink()
	self.damage = self.damage + 1
	DoDamage(self:GetParent(), self:GetParent() , self.damage , DAMAGE_TYPE_PURE, 0, self, false)
	EmitSoundOn("bird_hit_teterew", self:GetParent())
	ParticleManager:SetParticleControl( self.pfx, 0,  self:GetParent():GetAbsOrigin() )
end

function modifier_petuh:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle( self.pfx, false )
			ParticleManager:ReleaseParticleIndex( self.pfx )
		end
	end
end


------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_sosali", "abilities/zlodemon_nasral/modifier_renvor.lua", LUA_MODIFIER_MOTION_NONE)

modifier_sosali = class({})
function modifier_sosali:IsHidden() return true end
function modifier_sosali:IsDebuff() return false end
function modifier_sosali:IsPurgable() return false end
function modifier_sosali:IsPurgeException() return false end
function modifier_sosali:RemoveOnDeath() return false end
function modifier_sosali:OnCreated(table)
	if IsServer() then
 

	local particleName = "particles/zlodemon/sosali.vpcf"
 
	self.pfx = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    --ParticleManager:SetParticleControl( self.pfx, 0,  self:GetParent():GetAbsOrigin() )
	end
end
function modifier_sosali:OnDestroy()
	if IsServer() then
		if self.pfx then
			ParticleManager:DestroyParticle( self.pfx, true )
			ParticleManager:ReleaseParticleIndex( self.pfx )
		end
	end
end
