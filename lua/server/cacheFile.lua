local data = {}

Citizen.CreateThread(function()
	local file = json.decode(LoadResourceFile(GetCurrentResourceName(), "cache/videoPaths.json"))

	for k, v in pairs(Config.Cams) do
		if not file[k] then
			table.insert(file, {
				videos = {},
				skins = {},
				id = v.id,
				coords = v.camCoords,
				title = v.title,
				description = v.description,
				minFov = v.minFov,
				maxFov = v.maxFov,
				heading = v.camHeading,
				index = #file + 1
			})
		else
			for k_, v_ in pairs(file) do
				if v_.id == v.id then
					v_.coords = v.camCoords
					v_.title = v.title
					v_.description = v.description
					v_.minFov = v.minFov
					v_.maxFov = v.maxFov
					v_.heading = v.camHeading
				end
			end
		end
	end

	SaveResourceFile(GetCurrentResourceName(), "cache/videoPaths.json", json.encode(file), -1)

end)

local function createVideoCacheFile(tbl, id, center, coords, heading, title, description, minFov, maxFov, skins)
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
			table.insert(file[k].skins, {[fileName] = data[id]})
		end
	end

	tprint(file)

	if not fileFound then
		table.insert(file, {
			videos = {},
			skins = {},
			id = id,
			center = center,
			coords = coords,
			title = title,
			description = description,
			minFov = minFov,
			maxFov = maxFov,
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
AddEventHandler('videoRecordingCameras:createCacheFile', function(tbl, id, center, coords, heading, title, description, minFov, maxFov, skins)
	createVideoCacheFile(tbl, id, center, coords, heading, title, description, minFov, maxFov, skins)
end)	

RegisterNetEvent('videoRecordingCameras:watchVideo')
AddEventHandler('videoRecordingCameras:watchVideo', function(camIndex, videoIndex)
	local resourceName = GetCurrentResourceName()
	local file = getVideoCacheFile()
	local video
	local fileName
	for k,v in pairs(file) do
		if v.id == camIndex then
			file = v
			for k_, v_ in pairs(v.videos) do
				if k_ == videoIndex then
					fileName = v_
					video = LoadResourceFile(GetCurrentResourceName(), "cache/videos/"..v_)
				end
			end
		end
	end
	TriggerClientEvent('videoRecordingCameras:watchVideo', source, video, file, fileName) -- @file = infoFile
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


RegisterNetEvent('GetPlayerOutfit')
AddEventHandler('GetPlayerOutfit', function(camId, outfit)
    local source_ = source

    if not data[camId] then
        data[camId] = {}
    end

    data[camId] = {
        skin = outfit,
		id   = source_
    }

end)