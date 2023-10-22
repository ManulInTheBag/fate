FPMVersion = "alpha 0.1"

FPMThink = FrameTime()

FATE_PROJECTILE_TYPE_TRACKING = 1
FATE_PROJECTILE_TYPE_LINEAR = 2

FATE_PROJECTILE_TARGET_TEAM_NONE = 0
FATE_PROJECTILE_TARGET_TEAM_FRIENDLY = 1
FATE_PROJECTILE_TARGET_TEAM_ENEMY = 2
FATE_PROJECTILE_TARGET_TEAM_BOTH = 3

FATE_AREA_TYPE_SLOWING = 1

------- Init

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
  self.ActiveAreas = {}
  
  local ent = Entities:CreateByClassname("info_target")
  ent:SetThink("Think", self, "FATE_ProjectileManager", FPMThink)
end

--------- UID

function FATE_ProjectileManager:AssignID()
	if not self.uid then self.uid = 0 end
	self.uid = self.uid + 1
	return self.uid
end

--------- Projectiles

---------------- Tracking projectiles

function FATE_ProjectileManager:CreateTrackingProjectile(args)
	if not args.Target or args.Target:IsNull() then
		print("FPM target not defined")
	end

	--defining target
	local target = args.Target

	--defining ability
	local ability = nil
	if args.Ability then
		ability = args.Ability
	end
	
	--defining callback caller and projectile source location
	local caster = args.Source
	local source = args.Source

	if args.Caster then
		caster = args.Caster
	end

	if (not source) and ability then
		source = ability:GetCaster()
	end

	if (not caster) and ability then
		caster = ability:GetCaster()
	end

	local sourceLoc = Vector(0, 0, 0)

	if source and not source:IsNull() then
		sourceLoc = source:GetAbsOrigin()
	end

	if args.vSourceLoc then
		sourceLoc = args.vSourceLoc
	end

	local attachment = args.iSourceAttachment

	if attachment then
		if attachment == DOTA_PROJECTILE_ATTACHMENT_ATTACK_1 then
			attachment = "attach_attack1"
		elseif attachment == DOTA_PROJECTILE_ATTACHMENT_ATTACK_2 then
			attachment = "attach_attack2"
		elseif attachment == DOTA_PROJECTILE_ATTACHMENT_HITLOCATION then
			attachment = "attach_hitloc"
		end
		sourceLoc = source:GetAttachmentOrigin(source:ScriptLookupAttachment(attachment)) --check for bugs here bcs of missing attachments
	end

	--defining callback
	local callback = nil
	local thinkCallback = nil
	if ability then
		if type(ability.OnProjectileHit) == "function" then
			callback = ability.OnProjectileHit
		end
		if type(ability.OnProjectileHit_ExtraData) == "function" then
			callback = ability.OnProjectileHit_ExtraData
		end
		if type(ability.OnProjectileThink) == "function" then
			thinkCallback = ability.OnProjectileThink
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
	if args.bDodgeable == false then
		dodgeable = args.bDodgeable
	end

	--Projectile levels: 0 is technical, default level is 3
	local level = 3
	if args.level then
		level = args.level
	end

	--Expiration time
	local expires = false
	local expireTime = 1
	if args.flExpireTime then
		expires = true
		expireTime = args.flExpireTime
	end

	local UID = self:AssignID()

	local ProjectileTable = {}
	ProjectileTable.ID = UID
	ProjectileTable.type = FATE_PROJECTILE_TYPE_TRACKING
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
	ProjectileTable.expires = expires
	ProjectileTable.expireTime = expireTime
	ProjectileTable.level = level
	ProjectileTable.timeElapsed = 0

	self.ActiveProjectiles[UID] = ProjectileTable

	return UID
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

function FATE_ProjectileManager:DestroyTrackingProjectile(uid)
	local v = self.ActiveProjectiles[uid]

	if not v then return end

	if v.projFX then
		ParticleManager:DestroyParticle(v.projFX, false)
		ParticleManager:ReleaseParticleIndex(v.projFX)
	end

	self.ActiveProjectiles[uid] = nil
end


---------- Linear Projectiles

function FATE_ProjectileManager:CreateLinearProjectile(args)
	--defining ability
	local ability = nil
	if args.ability then
		ability = args.ability
	end
	
	--defining callback caller and projectile source location
	local caster = args.caster
	if not args.caster then
		print("FPM error: caster not defined")
		return
	end

	local source = args.source
	if not args.source then
		print("FPM error: source not defined")
		return
	end

	local sourceLoc = Vector(0, 0, 0)

	if source and not source:IsNull() then
		sourceLoc = source:GetAbsOrigin()
	end

	if args.sourceLoc then
		sourceLoc = args.sourceLoc
	end

	local attachment = args.sourceAttachment

	if attachment then
		if attachment == DOTA_PROJECTILE_ATTACHMENT_ATTACK_1 then
			attachment = "attach_attack1"
		elseif attachment == DOTA_PROJECTILE_ATTACHMENT_ATTACK_2 then
			attachment = "attach_attack2"
		elseif attachment == DOTA_PROJECTILE_ATTACHMENT_HITLOCATION then
			attachment = "attach_hitloc"
		end
		sourceLoc = source:GetAttachmentOrigin(source:ScriptLookupAttachment(attachment)) --check for bugs here bcs of missing attachments
	end

	--defining callback
	local callback = nil
	local thinkCallback = nil
	if ability then
		if type(ability.OnProjectileHit) == "function" then
			callback = ability.OnProjectileHit
		end
		if type(ability.OnProjectileHit_ExtraData) == "function" then
			callback = ability.OnProjectileHit_ExtraData
		end
		if type(ability.OnProjectileThink) == "function" then
			thinkCallback = ability.OnProjectileThink
		end
		if type(ability.OnProjectileThink_ExtraData) == "function" then
			thinkCallback = ability.OnProjectileThink_ExtraData
		end
	end

	if args.CustomCallback then
		callback = args.CustomCallback
	end

	--movement definition
	local direction = args.direction
	if not direction then
		print("FPM error: direction not defined")
		return
	end

	local speed = 0
	if args.speed then
		speed = args.speed
	end

	local max_distance = 0
	if args.distance then
		max_distance = args.distance
	end

	--DeleteOnHit

	local DeleteOnHit = false
	if args.DeleteOnHit then
		DeleteOnHit = args.DeleteOnHit
	end

	--Search parameters

	local iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iUnitTargetType = DOTA_UNIT_TARGET_ALL

	if args.iUnitTargetTeam then
		iUnitTargetTeam = args.iUnitTargetTeam
	end

	if args.iUnitTargetType then
		iUnitTargetType = args.iUnitTargetType
	end

	if args.iUnitTargetFlags then
		iUnitTargetFlags = args.iUnitTargetFlags
	end

	local start_radius = 1
	local end_radius = 1
	if args.startRadius then
		start_radius = args.startRadius
	end
	if args.endRadius then
		end_radius = args.endRadius
	end

	--VFX
	local projFX = nil
	if args.EffectName then
		projFX = ParticleManager:CreateParticle(args.EffectName, PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(projFX, 0, sourceLoc)
		ParticleManager:SetParticleControl(projFX, 1, speed*direction)
	end

	--ExtraData
	local ExtraData = nil
	if args.ExtraData then
		ExtraData = args.ExtraData
	end

	--Projectile levels: 0 is technical, default level is 3
	local level = 3
	if args.level then
		level = args.level
	end

	--Expiration time
	local expires = false
	local expireTime = 1
	if args.expireTime then
		expires = true
		expireTime = args.expireTime
	end

	local UID = self:AssignID()

	local ProjectileTable = {}
	ProjectileTable.ID = UID
	ProjectileTable.type = FATE_PROJECTILE_TYPE_LINEAR
	ProjectileTable.caster = caster
	ProjectileTable.source = source
	ProjectileTable.currentLoc = sourceLoc
	ProjectileTable.ability = ability
	ProjectileTable.callback = callback
	ProjectileTable.iUnitTargetTeam = iUnitTargetTeam
	ProjectileTable.iUnitTargetFlags = iUnitTargetFlags
	ProjectileTable.iUnitTargetType = iUnitTargetType
	ProjectileTable.thinkCallback = thinkCallback
	ProjectileTable.direction = direction
	ProjectileTable.speed = speed
	ProjectileTable.max_distance = max_distance
	ProjectileTable.curr_distance = 0
	ProjectileTable.start_radius = start_radius
	ProjectileTable.end_radius = end_radius
	ProjectileTable.DeleteOnHit = DeleteOnHit
	ProjectileTable.projFX = projFX
	ProjectileTable.ExtraData = ExtraData
	ProjectileTable.expires = expires
	ProjectileTable.expireTime = expireTime
	ProjectileTable.level = level
	ProjectileTable.timeElapsed = 0

	self.ActiveProjectiles[UID] = ProjectileTable

	return UID
end


---------------- Areas

function FATE_ProjectileManager:CreateSlowingArea_Circle(args)
	--defining callback caller and location
	local caster = args.caster

	local location = args.location

	local radius = args.radius
	if not radius then radius = 1 end

	local target_team = FATE_PROJECTILE_TARGET_TEAM_NONE
	if args.target_team then
		target_team = args.target_team
	end

	--defining callback ability and callback itself if we want it linked here for some weird reason
	--[[local ability = nil
	if args.Ability then
		ability = args.Ability
	end

	local callback = nil
	local thinkCallback = nil

	if args.callback then
		callback = args.callback
	end]]

	--ms change, % removed or added, stacks diminishingly
	local speed = 0
	if args.speed then
		speed = args.speed
	end

	--Affected projectile levels: 0 is technical, default level is 3, affects by rule what is >= level
	local level = 3
	if args.level then
		level = args.level
	end

	local expires = false
	local expireTime = 1
	if args.flExpireTime then
		expires = true
		expireTime = args.flExpireTime
	end

	local UID = self:AssignID()

	local AreaTable = {}
	AreaTable.ID = UID
	AreaTable.type = FATE_AREA_TYPE_SLOWING
	AreaTable.target_team = target_team
	AreaTable.caster = caster
	AreaTable.location = location
	AreaTable.radius = radius
	AreaTable.caster = caster
	AreaTable.speed = speed
	AreaTable.level = level
	AreaTable.expires = expires
	AreaTable.expireTime = expireTime

	AreaTable.timeElapsed = 0

	self.ActiveAreas[UID] = AreaTable

	return UID
end

function FATE_ProjectileManager:DestroyArea(uid)
	local v = self.ActiveAreas[uid]

	if not v then return end

	self.ActiveAreas[uid] = nil
end

---------- Thinker

--TODO: make table-function switch to reduce from O(n) to O(1)

function FATE_ProjectileManager:Think()
	--targetted
	for k, v in pairs(self.ActiveProjectiles) do
		--targetted block
		if v.type == FATE_PROJECTILE_TYPE_TRACKING then
			local ran, errorMsg = pcall(function() return self:Think_TRACKING(k,v) end)
			if not ran then
				print(errorMsg)
			end
		end
		if v.type == FATE_PROJECTILE_TYPE_LINEAR then
			local ran, errorMsg = pcall(function() return self:Think_LINEAR(k,v) end)
			if not ran then
				print(errorMsg)
			end
		end
		--linear block
	end
	return FPMThink
end

function FATE_ProjectileManager:Think_TRACKING(k, v)
	local hit = false
	local speed = v.speed
	local target = v.target
	for kz, vz in pairs(self.ActiveAreas) do
		if v.level >= vz.level then
			local teamfilter = false
			if (vz.target_team == FATE_PROJECTILE_TARGET_TEAM_FRIENDLY) and (vz.caster:GetTeamNumber() == v.caster:GetTeamNumber()) then
				teamfilter = true
			end
			if (vz.target_team == FATE_PROJECTILE_TARGET_TEAM_ENEMY) and (vz.caster:GetTeamNumber() ~= v.caster:GetTeamNumber()) then
				teamfilter = true
			end
			if (vz.target_team == FATE_PROJECTILE_TARGET_TEAM_BOTH) then
				teamfilter = true
			end
			if teamfilter then
				if ((vz.location - v.currentLoc):Length2D() <= vz.radius) then
					if vz.type == FATE_AREA_TYPE_SLOWING then
						speed = math.max(1, speed * ((100 - vz.speed)/100))
					end
				end
			end
		end
	end
	if target and not target:IsNull() then
		if target:IsAlive() then
			v.targetLoc = target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc"))
			if v.projFX then
				if speed > 1 then
					ParticleManager:SetParticleControl(v.projFX, 1, v.targetLoc)
				end
			end
		else
			v.target = nil
		end
	end
	if v.projFX then
		ParticleManager:SetParticleControl(v.projFX, 2, Vector(speed, 0, 0))
	end
	local direction = (v.targetLoc - v.currentLoc):Normalized()
	local distance = FPMThink*speed
	local remainingdist = (v.currentLoc - v.targetLoc):Length()
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
		--[[if not thinkStatus then
			print(thinkNextCall)
		end]]
	end

	if hit then
		--print("FPMSUCCESS"..k)
		self.ActiveProjectiles[k] = nil
		if v.callback then
			local status, nextCall = xpcall(function() return v.callback(v.ability, v.target, v.currentLoc, v.ExtraData) end, function (msg)
                                    return msg..'\n'..debug.traceback()..'\n'
                                  end)
		end
		if v.projFX then
			ParticleManager:DestroyParticle(v.projFX, false)
			ParticleManager:ReleaseParticleIndex(v.projFX)
		end
	end
	
	if v.expires and GameRules:GetGameTime() >= v.expireTime then
		self.ActiveProjectiles[k] = nil
		
		if v.projFX then
			ParticleManager:DestroyParticle(v.projFX, false)
			ParticleManager:ReleaseParticleIndex(v.projFX)
		end
	end
end

function FATE_ProjectileManager:Think_LINEAR(k, v)
	local hit = false
	local lastframe = false
	local speed = v.speed
	local direction = v.direction
	for kz, vz in pairs(self.ActiveAreas) do
		if v.level >= vz.level then
			local teamfilter = false
			if (vz.target_team == FATE_PROJECTILE_TARGET_TEAM_FRIENDLY) and (vz.caster:GetTeamNumber() == v.caster:GetTeamNumber()) then
				teamfilter = true
			end
			if (vz.target_team == FATE_PROJECTILE_TARGET_TEAM_ENEMY) and (vz.caster:GetTeamNumber() ~= v.caster:GetTeamNumber()) then
				teamfilter = true
			end
			if (vz.target_team == FATE_PROJECTILE_TARGET_TEAM_BOTH) then
				teamfilter = true
			end
			if teamfilter then
				if ((vz.location - v.currentLoc):Length2D() <= vz.radius) then
					if vz.type == FATE_AREA_TYPE_SLOWING then
						speed = math.max(1, speed * ((100 - vz.speed)/100))
					end
				end
			end
		end
	end
	if v.projFX then
		ParticleManager:SetParticleControl(v.projFX, 1, speed*direction)
	end
	local distance = FPMThink*speed
	local remainingdist = (v.max_distance - v.curr_distance)
	if remainingdist <= distance then
		distance = remainingdist
		lastframe = true
	end
	local oldloc = v.currentLoc
	local newloc = v.currentLoc + distance*direction
	v.currentLoc = newloc
	v.curr_distance = v.curr_distance + distance

	if v.thinkCallback then
		local thinkStatus, thinkNextCall = xpcall(function() return v.thinkCallback(v.ability, v.currentLoc, v.ExtraData) end, function (msg)
			                                    return msg..'\n'..debug.traceback()..'\n'
	                                  end)
	end

	local targets = {}

	local units = FATE_FindUnitsInLine(v.caster:GetTeamNumber(), oldloc, newloc, v.start_radius, v.iUnitTargetTeam, v.iUnitTargetType, v.iUnitTargetFlags, FIND_CLOSEST)
	for ku, vu in pairs(units) do
		targets[vu:entindex()] = true
		if v.DeleteOnHit and not hit then
			hit = true
			break
		end
	end
	--[[local units = FindUnitsInRadius(v.caster:GetTeamNumber(), newloc, nil, v.start_radius, v.iUnitTargetTeam, v.iUnitTargetType, v.iUnitTargetFlags, FIND_CLOSEST, false)
	for ku, vu in pairs(units) do
		targets[vu:entindex()] = true
		if v.DeleteOnHit and not hit then
			hit = true
			break
		end
	end]]

	if hit or lastframe or (v.expires and GameRules:GetGameTime() >= v.expireTime) then
		--print("FPMSUCCESS"..k)
		self.ActiveProjectiles[k] = nil
		if v.callback then
			for kt, vt in pairs(targets) do
				local status, nextCall = xpcall(function() return v.callback(v.ability, EntIndexToHScript(kt), v.currentLoc, v.ExtraData) end, function (msg)
	                                    return msg..'\n'..debug.traceback()..'\n'
	                                  end)
			end
		end
		if v.projFX then
			ParticleManager:DestroyParticle(v.projFX, false)
			ParticleManager:ReleaseParticleIndex(v.projFX)
		end
	end
	
	--[[if v.expires and GameRules:GetGameTime() >= v.expireTime then
		self.ActiveProjectiles[k] = nil
		
		if v.projFX then
			ParticleManager:DestroyParticle(v.projFX, false)
			ParticleManager:ReleaseParticleIndex(v.projFX)
		end
	end]]
end

if not FATE_ProjectileManager.ActiveProjectiles then FATE_ProjectileManager:start() end