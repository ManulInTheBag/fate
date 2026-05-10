ozy_move_boat = class({})

function ozy_move_boat:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function ozy_move_boat:GetCustomCastErrorLocation(vLocation)
	 return "#Wrong_Target_Location"
end

function ozy_move_boat:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local ozymandias = hCaster.ozy
	local boatOrigin = hCaster:GetAbsOrigin()
	local ozyOrigin = ozymandias:GetAbsOrigin()
	local distance  = (vTargetPoint - ozyOrigin):Length2D()
	local MaxDistance = self:GetSpecialValueFor("max_distance")
	local speed = self:GetSpecialValueFor("speed")
	local moveTime = 0
	local vector = (vTargetPoint - boatOrigin):Normalized()
	vector.z = 0
	local tickTime = FrameTime()
	if distance > MaxDistance then
		vector = (vTargetPoint - ozyOrigin):Normalized()
		vTargetPoint = ozyOrigin + vector * MaxDistance
		vector = (vTargetPoint - boatOrigin):Normalized()
		if not IsInSameRealm(vTargetPoint, hCaster:GetAbsOrigin()) then
			vTargetPoint = hCaster:GetAbsOrigin()
		end
	end
	
	Timers:CreateTimer("ozymandias_move_boat", {
			endTime = 0,
			callback = function()
			if hCaster:IsAlive() == false then return end
			boatOrigin = hCaster:GetAbsOrigin()
			hCaster:SetAbsOrigin(boatOrigin + vector * speed*tickTime)
			hCaster:FaceTowards(vTargetPoint)
			if (hCaster:GetAbsOrigin() -  vTargetPoint):Length2D() < 30 then
				return 
			end
			return tickTime
		end})
	
	


end


