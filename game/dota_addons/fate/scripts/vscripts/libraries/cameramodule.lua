--[[Camera Module v 0.1 by ManulInTheBag
About custom parameters:
SetCameraPosition:
- isCinematic enables "cinematic" mode (hides ability bar, inventory, shop and minimap HUD, adds two black bars)
- remember makes camera "remember" the height of the point you are staring at and reduce height offset by that value for correct height things
(because of valve autocorrection or smth like that idk exactly).
PositionSlip:
path - "min" or "max" - chooses the way camera will fly in yaw, min or max
whatfunc - "linear", "decrease", "increase", "edge_dec", "edge_inc" - chooses the velocity function, "edge_dec" min start max center min end, "edge_inc" max start min center max end
do not use it again before resetting it with InitializeCamera or some other way (if you're here you probably can guess, how to do it),
because it will "down" the camera position each time it is used.
i'll test it but i suppose if you'll use initcamera with the other camera thing at the same tick it will reset but initcamera won't be seen by the player so it's kinda easy
TODO: 
- Add transition from one PositionSlip to other PositionSlip to remember the yaw change direction (maybe? idk if needed)

P.S. this module also turns on the top hud with heroes, rounds and game time after picks end (with initcamera lul) so i don't really think you want to turn it off unless you are masochist]]

AllPlayersInterval = {0,1,2,3,4,5,6,7,8,9,10,11,12,13}

if not CameraModule then
	CameraModule = class({})
	CameraModule.BaseZ = 256 --base Z level of the map
	CameraModule.EmptyStateData = {
		yaw = 0,
		pitch = 60,
		heightOffset = 100,
		distance = 1600,
		cinematic = false,
		remember = true,
		reset = false
	}
end

function CameraModule:CollectPD()
	PlayerTables:CreateTable("hero_camera", {}, AllPlayersInterval)
end

function CameraModule:InitializeCamera(playerId) --setting camera to base position, also used to initialize the table for each player
	local storageData = {
		yaw = 0,
		pitch = 60,
		heightOffset = 100,
		distance = 1601,
		cinematic = false,
		remember = true,
		reset = true
	}
	PlayerTables:SetTableValue("hero_camera", playerId, storageData)

	local storageData2 = {
		yaw = 0,
		pitch = 60,
		heightOffset = 100,
		distance = 1600,
		cinematic = false,
		remember = true,
		reset = true
	}
	PlayerTables:SetTableValue("hero_camera", playerId, storageData2)
end

function CameraModule:SetCameraPosition(playerId, yaw, pitch, heightOffset, distance, isCinematic, remember) --core function
	local fin_yaw = yaw
	local fin_pitch = pitch  ----because yaw and pitch can't be < 0 and I'm not sure if they can be >=360 so it automatically corrects this

	while fin_yaw < 0 do
		fin_yaw = 360 + fin_yaw
	end
	while fin_yaw >= 360 do
		fin_yaw = fin_yaw - 360
	end
	while fin_pitch < 0 do
		fin_pitch = 360 + fin_pitch
	end
	while fin_pitch >= 360 do
		fin_pitch = fin_pitch - 360
	end

	local storageData = {
		yaw = fin_yaw,
		pitch = fin_pitch,
		heightOffset = heightOffset,
		distance = distance,
		cinematic = isCinematic,
		remember = remember,
		reset = false
	}

	PlayerTables:SetTableValue("hero_camera", playerId, storageData)
	--PrintTable(PlayerTables:GetAllTableValuesForReadOnly("hero_camera"))
end

function CameraModule:GetYawAngle(hero) --add to yaw to follow the yaw vector of the character
	local caster_vector = hero:GetForwardVector()
	local return_angle = 0

	if caster_vector.y >= 0 then
		return_angle = math.acos(caster_vector.x)/3.1415*180 - 90
	else
		return_angle = 270 - math.acos(caster_vector.x)/3.1415*180
	end

	if return_angle < 0 then
		return_angle = 360 + return_angle
	end

	return return_angle
end

function CameraModule:GetHeightDiff(hero) --add to height offset to make it follow the z-coord of character
	local caster_pos = hero:GetAbsOrigin()
	local height_diff = caster_pos.z - CameraModule.BaseZ

	return height_diff
end

function CameraModule:GetDiff(time_elapsed, time_full, step, whatfunc) --if whatfunc is empty returns linear
	local return_value = step/time_full
	if whatfunc == "linear" then
		return_value = step/time_full
	elseif whatfunc == "decrease" then
		return_value = step/time_full*2*(1 - time_elapsed/time_full)
	elseif whatfunc == "increase" then
		return_value = step/time_full*2*(time_elapsed/time_full)
	elseif whatfunc == "edge_inc" then
		return_value = step/time_full*4*(math.abs(1/2 - time_elapsed/time_full))
	elseif whatfunc == "edge_dec" then
		return_value = step/time_full*4*(math.abs(1/2 - math.abs(1/2 - time_elapsed/time_full)))
	end
	return return_value
end

function CameraModule:PositionSlip(playerId, yaw, pitch, heightOffset, distance, isCinematic, remember, time, path, whatfunc) 
	local camera_data = PlayerTables:GetTableValue("hero_camera", playerId)
	local init_yaw = camera_data.yaw
	local init_pitch = camera_data.pitch
	local init_heightOffset = camera_data.heightOffset
	local init_distance = camera_data.distance

	local yaw_diff = yaw - init_yaw
	local pitch_diff = pitch - init_pitch
	local heightOffset_diff = heightOffset - init_heightOffset
	local distance_diff = distance - init_distance

	if path == "min" then
		while yaw_diff > 180 do
			yaw_diff = yaw_diff - 360
		end

		while yaw_diff < -180 do
			yaw_diff = yaw_diff + 360
		end

		while pitch_diff > 180 do
			pitch_diff = pitch_diff - 360
		end

		while pitch_diff < -180 do
			pitch_diff = pitch_diff + 360
		end
	elseif path == "max" then
		while yaw_diff < 180 and yaw_diff > 0 do
			yaw_diff = yaw_diff - 360
		end

		while yaw_diff > -180 and yaw_diff < 0 do
			yaw_diff = yaw_diff + 360
		end

		while pitch_diff > 180 do
			pitch_diff = pitch_diff - 360
		end

		while pitch_diff < -180 do
			pitch_diff = pitch_diff + 360
		end
	end

	local time_counter = 0
	local remember_pepe = remember
	local diff = 0
	Timers:CreateTimer(FrameTime()*2, function()
		time_counter = time_counter + FrameTime()
		if time_counter <= time then
			diff = diff + CameraModule:GetDiff(time_counter, time, FrameTime(), whatfunc)
			CameraModule:SetCameraPosition(playerId, init_yaw + yaw_diff*diff, init_pitch + pitch_diff*diff, init_heightOffset + heightOffset_diff*diff, init_distance + distance_diff*diff, isCinematic, remember_pepe)
			remember_pepe = false
			return FrameTime()
		else
			--CameraModule:SetCameraPosition(playerId, yaw, pitch, heightOffset, distance, isCinematic, remember_pepe)
		end
	end)
end

function CameraModule:InverseSlip(playerId) --slip to base position
	local camera_data = PlayerTables:GetTableValue("hero_camera", playerId)
	local init_yaw = camera_data.yaw
	local init_pitch = camera_data.pitch
	local init_heightOffset = camera_data.heightOffset
	local init_distance = camera_data.distance

	local yaw_diff = 0 - init_yaw
	local pitch_diff = 60 - init_pitch
	local heightOffset_diff = 100 - init_heightOffset
	local distance_diff = 1600 - init_distance

	local time_counter = 0
	Timers:CreateTimer(FrameTime(), function()
		time_counter = time_counter + FrameTime()
		if time_counter <= time then
			diff = time_counter/time
			CameraModule:SetCameraPosition(playerId, init_yaw + yaw_diff*diff, init_pitch + pitch_diff*diff, init_heightOffset + heightOffset_diff*diff, init_distance + distance_diff*diff, true)
			return FrameTime()
		else
			CameraModule:InitializeCamera(playerId)
		end
	end)
end