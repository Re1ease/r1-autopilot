local QBCore = exports['qb-core']:GetCoreObject()

local speedNormal = false
local speedSlow = false
local speedFast = false
local slowdown = false
local autopilot = false
local savedBodyHealth
local x, y, z

local function stopSequence()
	slowdown = false
	QBCore.Functions.Notify("Autopilot Disabled", "success", 2000)
	TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2.0, 'autopilot_destinationreached', 0.1)
	autopilot = false	
end

local function checkModel(vehModelName)
	for _, v in pairs(PL.Models) do
		if vehModelName == v then
			return true
		end
	end
end

CreateThread(function()
	while true do
		Wait(500)

		if autopilot then
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			local veh = GetVehiclePedIsIn(ped, false)
			local vehSpeed = GetEntitySpeed(veh)
			local distance = #(pedCoords - vector3(x,y,z))
			local bodyHealth = GetVehicleBodyHealth(veh)

			if PL.EnableVehicleDamage then
				if bodyHealth < savedBodyHealth then
					ClearPedTasks(ped)
					slowdown = true

					if vehSpeed < 2 then
						stopSequence()
					end
				end
			end

			if speedNormal or speedSlow then
				if distance < 20 then
					ClearPedTasks(ped)
					slowdown = true

					if vehSpeed < 2 then
						stopSequence()
					end
				end

			elseif speedFast then
				if distance < 40 then
					ClearPedTasks(ped)
					slowdown = true

					if vehSpeed < 2 then
						stopSequence()
					end
				end
			end
		else
			Wait(1000)
		end
	end
end)

CreateThread(function()
	while true do
		Wait(100)

		if slowdown then
			local ped = PlayerPedId()
			local veh = GetVehiclePedIsIn(ped, false)
			local vehSpeed = GetEntitySpeed(veh)

			for i = 1, vehSpeed do
				if vehSpeed > 2 then
					speed = (vehSpeed-1)
				end
			end

			SetVehicleForwardSpeed(veh, speed)

		else
			Wait(1000)
		end
	end
end)

RegisterCommand("+autopilot", function()
	local ped = PlayerPedId()

	if IsPedInAnyVehicle(ped, false) then
		local veh = GetVehiclePedIsIn(ped, false)
		local vehModel = GetEntityModel(veh)
		local vehModelName = GetDisplayNameFromVehicleModel(vehModel)
		local vehCheck = checkModel(vehModelName)

		if vehCheck then
			if autopilot then
				ClearPedTasks(ped)
				slowdown = false
				QBCore.Functions.Notify("Autopilot Disabled", "success", 2000)
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2.0, 'autopilot_disabled', 0.1)
				autopilot = false	
				return
			end

			local waypoint = GetFirstBlipInfoId(8)

			if DoesBlipExist(waypoint) then
				autopilot = true
				speedNormal = true

				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2.0, 'autopilot_engaged', 0.1)
				QBCore.Functions.Notify("Autopilot Enabled", "success", 2000)

				local waypointCoords = GetBlipInfoIdCoord(waypoint)
				x, y, z = waypointCoords.x, waypointCoords.y, waypointCoords.z
				savedBodyHealth = (GetVehicleBodyHealth(veh)*PL.VehicleDamageMultiplier)

				TaskVehicleDriveToCoord(ped, veh, x, y, z, 20.0, 0, vehModel, 786603, 0, true)
				SetDriveTaskDrivingStyle(ped, 8388614)
				
			else
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2.0, 'autopilot_nowaypoint', 0.1)
				QBCore.Functions.Notify("Set a waypoint on your GPS", "error", 3000)
			end
		end
	end
end)

RegisterCommand("+autopilotspeed", function()
	if autopilot then
		local ped = PlayerPedId()
		local veh = GetVehiclePedIsIn(ped, false)
		local vehModel = GetEntityModel(veh)

		if speedNormal then
			speedNormal = false
			speedSlow = true

			TaskVehicleDriveToCoord(ped, veh, x, y, z, (PL.SlowSpeed/2.24), 0, vehModel, 786603, 0, true)
			QBCore.Functions.Notify("Autopilot: Speed Decreased", "success", 2000)
		elseif speedSlow then
			speedSlow = false
			speedFast = true

			TaskVehicleDriveToCoord(ped, veh, x, y, z, (PL.FastSpeed/2.24), 0, vehModel, 786603, 0, true)
			QBCore.Functions.Notify("Autopilot: Speed Increased", "success", 2000)
		elseif speedFast then
			speedFast = false
			speedNormal = true

			TaskVehicleDriveToCoord(ped, veh, x, y, z, (PL.NormalSpeed/2.24), 0, vehModel, 786603, 0, true)
			QBCore.Functions.Notify("Autopilot: Speed Normal", "success", 2000)
		end
	end
end)

RegisterKeyMapping('+autopilot', 'Toggle Autopilot', 'keyboard', 'n')
RegisterKeyMapping('+autopilotspeed', 'Autopilot Increase Speed', 'keyboard', 'up')