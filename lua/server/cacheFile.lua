Citizen.CreateThread(function()
	local file = json.decode(LoadResourceFile(GetCurrentResourceName(), "cache/videoPaths.json"))

	for k, v in pairs(Config.Cams) do
		if not file[k] then
			table.insert(file, {
				videos = {},
				id = v.id,
				coords = v.camCoords,
				title = v.title,
				description = v.description,
				fov = v.fov,
				heading = v.camHeading,
				index = #file + 1
			})
		end
	end

	SaveResourceFile(GetCurrentResourceName(), "cache/videoPaths.json", json.encode(file), -1)

end)

local function createVideoCacheFile(tbl, id, center, coords, heading, title, description, fov)
	local currentTime = os.time()
	local formattedTime = os.date("%d.%m.%Y_%H.%M.%S", currentTime)
	local fileName = formattedTime..".json"
	local resourceName = GetCurrentResourceName()
	local fileFound = false
	local file = SaveResourceFile(resourceName, "cache/videos/"..fileName, tbl, -1)

	if not file then
		print("Error while creating video cache file")
	end

	file = json.decode(LoadResourceFile(resourceName, "cache/videoPaths.json"))

	for k, v in pairs(file) do
		if v.id == id then
			fileFound = true
			table.insert(file[k].videos, fileName)
		end
	end

	if not fileFound then
		table.insert(file, {
			videos = {},
			id = id,
			center = center,
			coords = coords,
			title = title,
			description = description,
			fov = fov,
			heading = heading,
			index = #file + 1
		})
		table.insert(file[#file + 1].videos, fileName)
	end

	file = json.encode(file)

	file = SaveResourceFile(resourceName, "cache/videoPaths.json", file, -1)

	if not file then
		print("Error while adding path to videoPaths.json")
	end
end

function getVideoCacheFile()
	local resourceName = GetCurrentResourceName()
	local file = LoadResourceFile(resourceName, "cache/videoPaths.json")
	file = json.decode(file)

	return file
end

RegisterNetEvent('videoRecordingCameras:getVideoCacheFile')
AddEventHandler('videoRecordingCameras:getVideoCacheFile', function()
	TriggerClientEvent('videoRecordingCameras:getVideoCacheFile', source, getVideoCacheFile())
end)	

RegisterNetEvent('videoRecordingCameras:createCacheFile')
AddEventHandler('videoRecordingCameras:createCacheFile', function(tbl, id, center, coords, heading, title, description, fov)
	createVideoCacheFile(tbl, id, center, coords, heading, title, description, fov)
end)	

RegisterNetEvent('videoRecordingCameras:watchVideo')
AddEventHandler('videoRecordingCameras:watchVideo', function(camIndex, videoIndex)
	local resourceName = GetCurrentResourceName()
	local file = getVideoCacheFile()
	local video
	for k,v in pairs(file) do
		if v.id == camIndex then
			file = v
			for k_, v_ in pairs(v.videos) do
				if k_ == videoIndex then
					video = LoadResourceFile(GetCurrentResourceName(), "cache/videos/"..v_)
				end
			end
		end
	end
	TriggerClientEvent('videoRecordingCameras:watchVideo', source, video, file) -- @file = infoFile
end)

function tprint (tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
	  formatting = string.rep("  ", indent) .. k .. ": "
	  if type(v) == "table" then
		print(formatting)
		tprint(v, indent+1)
	  elseif type(v) == 'boolean' then
		print(formatting .. tostring(v))      
	  else
		print(formatting .. v)
	  end
	end
  end


RegisterNetEvent('deleteVehicleForPlayer')
AddEventHandler('deleteVehicleForPlayer', function(vehicleNetId)
    local sourcePlayer = source
    TriggerClientEvent('clientDeleteVehicle', sourcePlayer, vehicleNetId)
end)