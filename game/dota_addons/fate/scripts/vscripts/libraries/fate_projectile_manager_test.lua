FPMVersion = "alpha 0.1"

FPMThink = FrameTime()

if FATE_ProjectileManager == nil then
  print ( '[FATE_ProjectileManager] creating FATE Projectile Manager' )
  FATE_ProjectileManager = {}
  FATE_ProjectileManager.__index = FATE_ProjectileManager
end

function FATE_ProjectileManager:new( o )
  o = o or {}
  setmetatable( o, FATE_ProjectileManager )
  return o
end

function FATE_ProjectileManager:start()
	print("FPM START")
  FATE_ProjectileManager = self
  self.ActiveProjectiles = {}
  
  local ent = Entities:CreateByClassname("info_target")
  ent:SetThink("Think", self, "FATE_ProjectileManager", FPMThink)
end

function FATE_ProjectileManager:AssignID()
	if not self.uid then self.uid = 0 end
	self.uid = self.uid + 1
	return self.uid
end

local VALVE_ProjectileManager_ProjectileDodge = ProjectileManager.ProjectileDodge
ProjectileManager.ProjectileDodge = function(self, unit)
	FATE_ProjectileManager:ProjectileDodge(unit)
    return VALVE_ProjectileManager_ProjectileDodge(self, unit)
end

function FATE_ProjectileManager:ProjectileDodge(unit)
	for k, v in pairs(self.ActiveProjectiles) do
		if (v.target == unit) and (v.dodgeable == true) then
			v.target = nil
		end
	end
end

function FATE_ProjectileManager:CreateTrackingProjectile(args)
	print("projectile activation")
	if not args.Target or args.Target:IsNull() then
		print("FPM target not defined")
	end

	--defining target
	local target = args.Target
	
	--defining callback caller and projectile source location
	local caster = args.Source
	local source = args.Source

	if args.Caster then
		caster = args.Caster
	end

	local sourceLoc = source:GetAbsOrigin()

	local sourceLoc = args.vSourceLoc

	local attachment = args.iSourceAttachment

	if attachment then
		if attachment == DOTA_PROJECTILE_ATTACHMENT_ATTACK_1 then
			attachment = "attach_attack1"
		elseif attachment == DOTA_PROJECTILE_ATTACHMENT_ATTACK_2 then
			attachment = "attach_attack2"
		end
		sourceLoc = source:GetAttachmentOrigin(source:ScriptLookupAttachment(attachment)) --check for bugs here bcs of missing attachments
	end

	--defining callback ability and callback itself
	local ability = nil
	if args.Ability then
		ability = args.Ability
	end

	local callback = nil
	local thinkCallback = nil
	if ability then
		if type(ability.OnProjectileHit) == "function" then
			callback = ability.OnProjectileHit
		end
		if type(ability.OnProjectileHit_ExtraData) == "function" then
			callback = ability.OnProjectileHit_ExtraData
		end
		if type(ability.OnProjectileThink_ExtraData) == "function" then
			thinkCallback = ability.OnProjectileThink_ExtraData
		end
	end

	if args.CustomCallback then
		callback = args.CustomCallback
	end

	--movement definition
	local speed = 0
	if args.iMoveSpeed then
		speed = args.iMoveSpeed
	end

	--VFX
	local projFX = nil
	if args.EffectName then
		projFX = ParticleManager:CreateParticle(args.EffectName, PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(projFX, 0, sourceLoc)
		ParticleManager:SetParticleControl(projFX, 1, target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))
		ParticleManager:SetParticleControl(projFX, 2, Vector(speed, 0, 0))
	end

	--ExtraData
	local ExtraData = nil
	if args.ExtraData then
		ExtraData = args.ExtraData
	end

	--IsDodgeable
	local dodgeable = true
	if args.Dodgeable then
		dodgeable = args.Dodgeable
	end

	local UID = self:AssignID()

	local ProjectileTable = {}
	ProjectileTable.ID = UID
	ProjectileTable.target = target
	ProjectileTable.targetLoc = target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc"))
	ProjectileTable.targetAlive = target:IsAlive()
	ProjectileTable.caster = caster
	ProjectileTable.source = source
	ProjectileTable.dodgeable = dodgeable
	ProjectileTable.currentLoc = sourceLoc
	ProjectileTable.ability = ability
	ProjectileTable.callback = callback
	ProjectileTable.thinkCallback = thinkCallback
	ProjectileTable.speed = speed
	ProjectileTable.projFX = projFX
	ProjectileTable.ExtraData = ExtraData

	self.ActiveProjectiles[UID] = ProjectileTable

	return UID
end

function FATE_ProjectileManager:Think() --TODO: use pcall or xpcall
	--targetted
	for k, v in pairs(self.ActiveProjectiles) do
		--print(k)
		local hit = false
		local speed = v.speed
		local target = v.target
		if target and not target:IsNull() then
			if target:IsAlive() then
				v.targetLoc = target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc"))
				ParticleManager:SetParticleControl(v.projFX, 1, v.targetLoc)
			else
				v.target = nil
			end
		end
		local direction = (v.targetLoc - v.currentLoc):Normalized()
		local distance = FPMThink*speed
		local remainingdist = (v.currentLoc - v.targetLoc):Length2D()
		--print(remainingdist)
		if remainingdist <= distance then
			distance = remainingdist
			hit = true
		end
		v.currentLoc = v.currentLoc + distance*direction

		if v.thinkCallback then
			local thinkStatus, thinkNextCall = xpcall(function() return v.thinkCallback(v.ability, v.currentLoc, v.ExtraData) end, function (msg)
	                                    return msg..'\n'..debug.traceback()..'\n'
	                                  end)
		end

		if hit then
			--print("FPMSUCCESS"..k)

			self.ActiveProjectiles[k] = nil

			if v.callback then
				local status, nextCall = xpcall(function() return v.callback(v.ability, v.target, v.currentLoc, v.ExtraData) end, function (msg)
	                                    return msg..'\n'..debug.traceback()..'\n'
	                                  end)
			end

			ParticleManager:DestroyParticle(v.projFX, false)
			ParticleManager:ReleaseParticleIndex(v.projFX)
		end
	end
	return FPMThink
end

if not FATE_ProjectileManager.ActiveProjectiles then FATE_ProjectileManager:start() end