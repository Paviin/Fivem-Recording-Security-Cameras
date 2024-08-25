local function createVideoCacheFile(tbl)
	local currentTime = os.time()
	local formattedTime = os.date("%d.%m.%Y_%H.%M.%S", currentTime)
	local fileName = formattedTime..".json"
	local resourceName = GetCurrentResourceName()
	
	local file = SaveResourceFile(resourceName, "cache/"..fileName, json.encode(tbl), -1)

	if not file then
		print("Error while creating video cache file")
	end

	file = json.decode(LoadResourceFile(resourceName, "cache/videoPaths.json"))

	table.insert(file, {
		fileName = fileName,
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
AddEventHandler('videoRecordingCameras:createCacheFile', function(tbl)
	createVideoCacheFile(tbl)
end)	

RegisterNetEvent('videoRecordingCameras:watchVideo')
AddEventHandler('videoRecordingCameras:watchVideo', function(index)
	local resourceName = GetCurrentResourceName()
	local file = getVideoCacheFile()[tonumber(index)].fileName
	file = json.decode(LoadResourceFile(resourceName, "cache/"..file))
	TriggerClientEvent('videoRecordingCameras:watchVideo', source, file)
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