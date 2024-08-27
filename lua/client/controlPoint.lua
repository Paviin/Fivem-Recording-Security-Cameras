
local playerPed = PlayerPedId()
local playerCoords = vector3(0, 0, 0)
local nearestCamDistance, nearestCamCoords
local menuOpen = false
local files

local function updatePlayerCoords()
    playerCoords = GetEntityCoords(playerPed)
end

local function calculateDistance(pointA, pointB)
    return #(pointA - pointB)
end

local function findNearestCam()
    nearestCamDistance = Config.Distance + 1
    nearestCamCoords = nil

    for _, cam in pairs(Config.Cams) do
        local camDistance = calculateDistance(playerCoords, cam.controlPoint)
        if camDistance < nearestCamDistance then
            nearestCamDistance = camDistance
            nearestCamCoords = cam.controlPoint
        end
    end
end

local function handleMarkerDisplay()
    if nearestCamDistance < Config.Distance and not menuOpen then
        DrawMarker(
            Config.Marker.settings.type, nearestCamCoords.x, nearestCamCoords.y, nearestCamCoords.z,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            Config.Marker.settings.scale, Config.Marker.settings.scale, Config.Marker.settings.scale,
            Config.Marker.settings.color.r, Config.Marker.settings.color.g, Config.Marker.settings.color.b, Config.Marker.settings.color.a,
            Config.Marker.settings.bobUpAndDown, Config.Marker.settings.faceCamera, false, false, false, false, false
        )

        if nearestCamDistance < Config.Marker.settings.scale then
            if not menuOpen then
                ShowHelpNotification(Locales.ShowHelpNotification)
            end
            if IsControlJustPressed(0, 38) then
                Citizen.CreateThread(function()
                    TriggerServerEvent('videoRecordingCameras:getVideoCacheFile')
                end)
                SendNUIMessage({action = "open"})
                SetNuiFocus(true, true)
                menuOpen = true
            end
        end
    end
end

Citizen.CreateThread(function()
    while true do
        playerPed = PlayerPedId()
        updatePlayerCoords()

        findNearestCam()
        handleMarkerDisplay()

        Citizen.Wait(nearestCamDistance < Config.Distance and not menuOpen and 0 or 2500)
    end
end)

function ShowHelpNotification(msg)
    AddTextEntry('helpNotify', msg)
    DisplayHelpTextThisFrame('helpNotify', false)
end

RegisterNUICallback('close', function()
    menuOpen = false
    SetNuiFocus(false, false)
end)

RegisterNUICallback('watchCam', function(id)

end)

RegisterNetEvent('videoRecordingCameras:getVideoCacheFile')
AddEventHandler('videoRecordingCameras:getVideoCacheFile', function(files)
  files = files
  Citizen.Wait(500)
  SendNUIMessage({cameras = Config.Cams, videos = files, locales = {Locales.MenuHeader, Locales.MenuDescription}})
end)