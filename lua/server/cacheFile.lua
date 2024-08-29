local function createVideoCacheFile(tbl, id, center, coords, heading, title, description, fov)
	local currentTime = os.time()
	local formattedTime = os.date("%d.%m.%Y_%H.%M.%S", currentTime)
	local fileName = formattedTime..".json"
	local resourceName = GetCurrentResourceName()

	local file = SaveResourceFile(resourceName, "cache/videos/"..fileName, json.encode(tbl), -1)

	if not file then
		print("Error while creating video cache file")
	end

	file = json.decode(LoadResourceFile(resourceName, "cache/videoPaths.json"))

	table.insert(file, {
		fileName = fileName,
		id = id,
		center = center,
		coords = coords,
		title = title,
		description = description,
		fov = fov,
		heading = heading,
		index = #file + 1
	})

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
AddEventHandler('videoRecordingCameras:watchVideo', function(index)
	local resourceName = GetCurrentResourceName()
	local file = getVideoCacheFile()[tonumber(index)].fileName
	local infoFile = json.decode(LoadResourceFile(resourceName, "cache/videoPaths.json"))
	for k,v in pairs(infoFile) do
		if v.index == tonumber(index) then
			infoFile = v
		end
	end
	file = json.decode(LoadResourceFile(resourceName, "cache/videos/"..file))
	TriggerClientEvent('videoRecordingCameras:watchVideo', source, file, infoFile)
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
