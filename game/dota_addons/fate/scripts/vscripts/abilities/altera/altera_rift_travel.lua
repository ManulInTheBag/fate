LinkLuaModifier("modifier_altera_rift_dummy", "abilities/altera/altera_rift_travel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_rift_dummy_unstable", "abilities/altera/altera_rift_travel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_rift_dummy_chains", "abilities/altera/altera_rift_travel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_rift_inside", "abilities/altera/altera_rift_travel", LUA_MODIFIER_MOTION_NONE)

altera_rift_travel = class({})

function altera_rift_travel:OnSpellStart()
	if not self.RiftTable then
		self.RiftTable = {}
	end

	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	--=================================================================================================================
	-- Check if any rifts exist
	--=================================================================================================================
	local continue = false
	for k,v in pairs(self.RiftTable) do
		continue = true
	end

	if not continue then
		return
	end

	--=================================================================================================================
	-- Inside-of-the-rift interactions (TBD)
	--=================================================================================================================
	if caster:HasModifier("modifier_altera_rift_inside") then
		print("inside of the rift, checking closest to cursor")

		local uid = caster:FindModifierByName("modifier_altera_rift_inside").uid

		local closestcheck = nil

		for k,v in pairs(self.RiftTable[uid].ConnectedRifts) do
			if not closestcheck then
				closestcheck = k
			end

			local disttonew = (target - self.RiftTable[k].ori):Length2D()
			local disttocurrent = (target - self.RiftTable[closestcheck].ori):Length2D()

			if disttonew < disttocurrent then
				closestcheck = k
			end
		end

		if not closestcheck then
			print("no other rifts, exiting current one")
			self:ExitRift(uid)
			return
		end

		local disttonew = (target - self.RiftTable[uid].ori):Length2D()
		local disttocurrent = (target - self.RiftTable[closestcheck].ori):Length2D()

		if disttonew < disttocurrent then
			closestcheck = uid
		end

		if closestcheck == uid then
			print("current rift closest, exiting current one")
			self:ExitRift(uid)
		else
			print("transporting to "..closestcheck)
			self:TransportToRift(closestcheck)
		end
		return
	end

	--=================================================================================================================
	-- Rift entering
	--=================================================================================================================
	local standinginside = {}

	for k,v in pairs(self.RiftTable) do
		local check = self:IsStandingOnRift(k, caster)

		if check then
			standinginside[k] = check
		end
		print("enter check for rift "..k)
		print(check)
	end

	local continue2 = false
	for k,v in pairs(standinginside) do
		continue2 = true
	end

	if continue2 then
		print("standing on a rift, checking closest to cursor")

		local closestcheck = nil

		for k,v in pairs(standinginside) do
			if not closestcheck then
				closestcheck = k
			end

			local disttonew = (target - self.RiftTable[k].ori):Length2D()
			local disttocurrent = (target - self.RiftTable[closestcheck].ori):Length2D()

			if disttonew < disttocurrent then
				closestcheck = k
			end
		end

		self:EnterRift(closestcheck, self:GetSpecialValueFor("travel_duration"))
		return
	end
	--=================================================================================================================
	-- Dash to closest rift (TBD)
	--=================================================================================================================
	local closeenough = {}

	for k,v in pairs(self.RiftTable) do
		local check = self:IsCloseEnoughToRift(k)

		if check then
			closeenough[k] = check
		end
		print("proximity check for rift "..k)
		print(check)
	end

	local continue3 = false
	for k,v in pairs(closeenough) do
		continue3 = true
	end

	if continue3 then
		print("standing on a rift, checking closest to cursor")

		local closestcheck = nil

		for k,v in pairs(closeenough) do
			if not closestcheck then
				closestcheck = k
			end

			local disttonew = (target - self.RiftTable[k].ori):Length2D()
			local disttocurrent = (target - self.RiftTable[closestcheck].ori):Length2D()

			if disttonew < disttocurrent then
				closestcheck = k
			end
		end

		caster:SetAbsOrigin(self.RiftTable[closestcheck].ori)
		--self:EnterRift(closestcheck, self:GetSpecialValueFor("travel_duration"))
		return
	end
end

function altera_rift_travel:CreateRift(origin, radius, duration)
	if not self.RiftTable then
		self.RiftTable = {}
	end

	local caster = self:GetCaster()
	local uid = self:GetRiftUID()
	
	local dummy = CreateUnitByName("altera_rift", origin, false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive_fly_pathing"):SetLevel(1)
	dummy:SetDayTimeVisionRange(300)
	dummy:SetNightTimeVisionRange(300)
	dummy:SetForwardVector(caster:GetForwardVector())

	local riftInfo = {}
	riftInfo.uid = uid
	riftInfo.ori = origin
	riftInfo.dummy = dummy
	riftInfo.forward = dummy:GetForwardVector()
	riftInfo.right = dummy:GetRightVector()
	riftInfo.diagonal = radius
	riftInfo.side = radius*math.sqrt(2)
	riftInfo.search_start = riftInfo.ori - riftInfo.forward*riftInfo.side/2
	riftInfo.search_end = riftInfo.ori + riftInfo.forward*riftInfo.side/2
	riftInfo.points = {}
	riftInfo.points[0] = riftInfo.ori + (riftInfo.forward + riftInfo.right)*riftInfo.side/2
	riftInfo.points[1] = riftInfo.ori + (riftInfo.forward + -1*riftInfo.right)*riftInfo.side/2
	riftInfo.points[2] = riftInfo.ori + (-1*riftInfo.forward + riftInfo.right)*riftInfo.side/2
	riftInfo.points[3] = riftInfo.ori + (-1*riftInfo.forward + -1*riftInfo.right)*riftInfo.side/2
	riftInfo.isUnstable = false
	riftInfo.ConnectedRifts = {}

	self.RiftTable[uid] = riftInfo

	dummy:AddNewModifier(caster, self, "modifier_altera_rift_dummy", {life_duration = duration, radius = radius, uid = uid})
	dummy:AddNewModifier(caster, self, "modifier_altera_rift_dummy_chains", {uid = uid})

	self:ConnectNewRift(uid)
end

function altera_rift_travel:DestroyRift(uid)
	if not IsServer() then return end

	if not self.RiftTable[uid] then return end
	
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_altera_rift_inside") then
		local current_uid = caster:FindModifierByName("modifier_altera_rift_inside").uid

		if current_uid == uid then
			local force_transport = self:FindNearestRift(uid)

			if force_transport then
				self:TransportToRift(force_transport)
			else
				self:ExitRift(uid)
			end
		end
	end

	self:DisconnectRift(uid)
	self.RiftTable[uid].dummy:RemoveSelf()
	self.RiftTable[uid] = nil
end

function altera_rift_travel:IsStandingOnRift(uid, target)
	local point = target:GetAbsOrigin()
	local startpoint = self.RiftTable[uid].search_start
	local endpoint = self.RiftTable[uid].search_end
	local width = self.RiftTable[uid].side

	local res = distance_Point_to_Segment_IsInside(point[1], point[2], startpoint[1], startpoint[2], endpoint[1], endpoint[2])
    if res[3] and (res[1]<=width) then
        return true
    end
    return false
end

function altera_rift_travel:IsCloseEnoughToRift(uid)
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin()

	local dash_dist = self:GetSpecialValueFor("dash_max_distance")
	local side = self.RiftTable[uid].side
	local forward = self.RiftTable[uid].forward
	local right = self.RiftTable[uid].right

	local ori = self.RiftTable[uid].ori

	local startpoint = self.RiftTable[uid].search_start - forward*dash_dist
	local endpoint = self.RiftTable[uid].search_end + forward * dash_dist
	local startpoint2 = ori - right*(dash_dist+side/2)
	local endpoint2 = ori + right*(dash_dist + side/2)
	local width = self.RiftTable[uid].side

	local res = distance_Point_to_Segment_IsInside(point[1], point[2], startpoint[1], startpoint[2], endpoint[1], endpoint[2])
    if res[3] and (res[1]<=width/2) then
        return true
    end
    local res = distance_Point_to_Segment_IsInside(point[1], point[2], startpoint2[1], startpoint2[2], endpoint2[1], endpoint2[2])
    if res[3] and (res[1]<=width/2) then
        return true
    end
    for i=0,3 do
    	print("uid"..uid.."point"..i.."is")
    	print(self.RiftTable[uid].points[i])
    	if (self.RiftTable[uid].points[i] - point):Length2D() <= dash_dist then
    		return true
    	end
    end
    return false
end

function altera_rift_travel:EnterRift(uid, duration)
	local caster = self:GetCaster()
	local dummy = self.RiftTable[uid].dummy
	local radius = self.RiftTable[uid].diagonal
	local ori = self.RiftTable[uid].ori

	local modifier = caster:AddNewModifier(caster, self, "modifier_altera_rift_inside", {duration = duration, uid = uid})
	modifier:SetCurrentRift(uid)
	caster:SetAbsOrigin(ori)

	if not self.RiftTable[uid].isUnstable then
		self.RiftTable[uid].isUnstable = true

		dummy:RemoveModifierByName("modifier_altera_rift_dummy")
		dummy:AddNewModifier(caster, self, "modifier_altera_rift_dummy_unstable", {life_duration = self:GetSpecialValueFor("unstable_duration"), radius = radius, uid = uid})
	else
		local force_transport = self:FindNearestRift(uid)

		if force_transport then
			self:TransportToRift(force_transport)
			self:DestroyRift(uid)
		else
			print("ya poluchil pizdi")
			self:ExitRift(uid)
		end
	end
end

function altera_rift_travel:ExitRift(uid)
	local caster = self:GetCaster()

	caster:FindModifierByName("modifier_altera_rift_inside"):SetCurrentRift(uid)
	caster:RemoveModifierByName("modifier_altera_rift_inside")
end

function altera_rift_travel:ExitRift_actual(uid)
	local caster = self:GetCaster()
	local dummy = self.RiftTable[uid].dummy
	local radius = self.RiftTable[uid].diagonal
	local ori = self.RiftTable[uid].ori

	FindClearSpaceForUnit(caster, ori, false)

	if not self.RiftTable[uid].isUnstable then
		self.RiftTable[uid].isUnstable = true

		dummy:RemoveModifierByName("modifier_altera_rift_dummy")
		dummy:AddNewModifier(caster, self, "modifier_altera_rift_dummy_unstable", {life_duration = self:GetSpecialValueFor("unstable_duration"), radius = radius, uid = uid})
	else
		self:DestroyRift(uid)
	end
end

function altera_rift_travel:TransportToRift(uid)
	local caster = self:GetCaster()

	local rift_ori = self.RiftTable[uid].ori

	caster:SetAbsOrigin(rift_ori)

	local modifier = caster:FindModifierByName("modifier_altera_rift_inside")
	modifier:SetCurrentRift(uid)
end

function altera_rift_travel:FindNearestRift(uid)
	local dist = 999999
	local res = false
	for k,v in pairs(self.RiftTable[uid].ConnectedRifts) do
		if v[1] < dist then
			dist = v[1]
			res = k
		end
	end
	return res
end

function altera_rift_travel:ConnectNewRift(uid)
	local this_dummy = self.RiftTable[uid].dummy
	for k,v in pairs(self.RiftTable) do
		if k ~= uid then
			local res = self:ComparePoints(uid, k)

			if res[0] then
				self.RiftTable[uid].ConnectedRifts[k] = {[0] = true, [1] = res[3]}
				self.RiftTable[k].ConnectedRifts[uid] = {[0] = true, [1] = res[3]}

				this_dummy:FindModifierByName("modifier_altera_rift_dummy_chains"):ConnectTo(k, res[1], res[2])
				self.RiftTable[k].dummy:FindModifierByName("modifier_altera_rift_dummy_chains"):ConnectTo(uid, res[2], res[1])
			end
		end
	end
end

function altera_rift_travel:DisconnectRift(uid)
	for k,v in pairs(self.RiftTable) do
		if self.RiftTable[k].ConnectedRifts[uid] then
			ParticleManager:DestroyParticle(self.RiftTable[k].ConnectedRifts[uid][0], false)
			ParticleManager:DestroyParticle(self.RiftTable[uid].ConnectedRifts[k][0], false)
			self.RiftTable[k].ConnectedRifts[uid] = nil
		end
	end
end

function altera_rift_travel:ComparePoints(uid1, uid2)
	local connect_dist = self:GetSpecialValueFor("connect_distance")
	local res = {}

	res[0] = false

	local points_table1 = self.RiftTable[uid1].points
	local points_table2 = self.RiftTable[uid2].points

	local min_dist = 999999

	for i=0,3 do
		for j=0,3 do
			local dist = (points_table1[i] - points_table2[j]):Length2D()
			if dist < min_dist then
				min_dist = dist
				res[1] = i
				res[2] = j
			end
		end
	end

	if min_dist <= connect_dist then
		res[0] = true
		res[3] = min_dist
	end

	return res
end

function altera_rift_travel:GetRiftUID()
	if not self.rift_uid then
		self.rift_uid = 0
	end

	self.rift_uid = self.rift_uid + 1
	return self.rift_uid
end

----modifiers

modifier_altera_rift_dummy = class({})

function modifier_altera_rift_dummy:OnCreated(args)
	if not IsServer() then return end

	self.ability = self:GetAbility()
	self.uid = args.uid

	self.life_duration = args.life_duration
	self.time_elapsed = 0

	self.caster = self:GetCaster()	
	self.parent = self:GetParent()
	self.fx = ParticleManager:CreateParticle("particles/altera/altera_rifts/altera_cube_red.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.fx, 1, Vector(args.radius, 0, 0))

	self:AddParticle(self.fx, false, false, -1, false, false)

	self:StartIntervalThink(FrameTime())
end

function modifier_altera_rift_dummy:OnIntervalThink()
	if not IsServer() then return end
	self.time_elapsed = self.time_elapsed + FrameTime()
	if self.time_elapsed >= self.life_duration then
		self.ability:DestroyRift(self.uid)
	end
end

--

modifier_altera_rift_dummy_unstable = class({})

function modifier_altera_rift_dummy_unstable:OnCreated(args)
	if not IsServer() then return end

	self.ability = self:GetAbility()
	self.uid = args.uid

	self.life_duration = args.life_duration
	self.time_elapsed = 0

	self.caster = self:GetCaster()	
	self.parent = self:GetParent()
	self.fx = ParticleManager:CreateParticle("particles/altera/altera_rifts/altera_unstable_cube_red.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.fx, 1, Vector(args.radius, 0, 0))

	self:AddParticle(self.fx, false, false, -1, false, false)

	self:StartIntervalThink(FrameTime())
end

function modifier_altera_rift_dummy_unstable:OnIntervalThink()
	if not IsServer() then return end
	self.time_elapsed = self.time_elapsed + FrameTime()
	if self.time_elapsed >= self.life_duration then
		self.ability:DestroyRift(self.uid)
	end
end

--

modifier_altera_rift_dummy_chains = class({})

function modifier_altera_rift_dummy_chains:OnCreated(args)
	if not IsServer() then return end

	self.ability = self:GetAbility()
	self.uid = args.uid

	self.parent = self:GetParent()
end

function modifier_altera_rift_dummy_chains:ConnectTo(connect_uid, point1, point2)
	local point1 = self.ability.RiftTable[self.uid].points[point1]
	local point2 = self.ability.RiftTable[connect_uid].points[point2]

	self.fx = ParticleManager:CreateParticle("particles/altera/altera_rifts/altera_rift_chain_red.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.fx, 0, point1)
	ParticleManager:SetParticleControl(self.fx, 1, point2)

	self.ability.RiftTable[self.uid].ConnectedRifts[connect_uid][0] = self.fx

	self:AddParticle(self.fx, false, false, -1, false, false)
end

--

modifier_altera_rift_inside = class({})

function modifier_altera_rift_inside:CheckState()
	return { [MODIFIER_STATE_OUT_OF_GAME] = true,
			 [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
			 [MODIFIER_STATE_ROOTED] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNTARGETABLE_ENEMY] = true,
			 [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true }
end

function modifier_altera_rift_inside:OnCreated(args)
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.uid = args.uid

	self.caster:AddEffects(EF_NODRAW)
end

function modifier_altera_rift_inside:OnDestroy()
	if not IsServer() then return end
	self.caster:RemoveEffects(EF_NODRAW)

	self.ability:ExitRift_actual(self.uid)
end

function modifier_altera_rift_inside:SetCurrentRift(uid)
	self.uid = uid
end

function modifier_altera_rift_inside:IsHidden() return false end