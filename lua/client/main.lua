local files

Citizen.CreateThread(function()
    for k, cam in pairs(Config.Cams) do
        CreateCamObj(cam.camCoords, cam.camHeading, cam.obj)
    end
end)


RegisterCommand('allvideos', function()
    TriggerServerEvent('videoRecordingCameras:getVideoCacheFile')
end)

RegisterCommand('watchvideo', function(_, args)  
  TriggerServerEvent('videoRecordingCameras:watchVideo', args[1])
end)

RegisterNetEvent('videoRecordingCameras:watchVideo')
AddEventHandler('videoRecordingCameras:watchVideo', function(file)
  print(file)
  watchVideo(file)
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

  CreateCamObj = function(camCoords, camHeading, obj)
    local x, y, z = table.unpack(camCoords)
    cam = CreateObject(GetHashKey(obj), x, y, z, false, false, true)
    SetEntityHeading(cam, camHeading - 180)
  end

  AddEventHandler('onResourceStop', function()
    if cam then
        DeleteObject(cam)
    end
  end)