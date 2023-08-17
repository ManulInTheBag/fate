FPMVersion = "alpha 0.1"

if FATE_ProjectileManager == nil then
  print ( '[FATE_ProjectileManager] creating FATE Projectile Manager' )
  FATE_ProjectileManager = {}
end

function FATE_ProjectileManager:start()
  FATE_ProjectileManager = self
  self.ActiveProjectiles = {}
  
  local ent = Entities:CreateByClassname("info_target")
  ent:SetThink("Think", self, "FATE_ProjectileManager", FrameTime())
end

function FATE_ProjectileManager:AssignID()
	if not self.uid then self.uid = 0 end
	self.uid = self.uid + 1
	return self.uid
end

function FATE_ProjectileManager:CreateTrackingProjectile(args)
	
end

function FATE_ProjectileManager:Think()

end