
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
                    TriggerServerEvent('videoRecordingCameras:requestCamerasPermission')
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

RegisterNUICallback('watchRecording', function(cam)
    local cam, video = table.unpack(cam)
    TriggerServerEvent('videoRecordingCameras:watchVideo', cam, video)
end)

RegisterNUICallback('watchCam', function(id)
    for k, v in pairs(Config.Cams) do
        if v.id == id then
            local camCoords = vector3(v.camCoords.x, v.camCoords.y, v.camCoords.z)
            local camHorizontalHeading = v.camHeading
            local fov = v.fov
            local minFov = 1.0
            local maxFov = 80.0
            menuOpen = false
            SetNuiFocus(false, false)
            local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            SetTimecycleModifier("Broken_camera_fuzz")
            SetTimecycleModifierStrength(0.05)
            SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z -0.5)
            SetCamFov(cam, fov - 20)
            RenderScriptCams(true, false, 0, true, true)
            SetCamRot(cam, 0.0, 0.0, camHorizontalHeading, 2) 
            DisplayHud(false)
            DisplayRadar(false)

            local horizontal = 0
            local vertikal = 0
            while true do
                if IsControlPressed(0, 34) then -- links
                    horizontal = horizontal +fov / 100

                    if horizontal > 35 then horizontal = 35.0 end
                    if horizontal < -35 then horizontal = -35.0 end
                    SetCamRot(cam, vertikal, 0.0, camHorizontalHeading + horizontal)
                end
                if IsControlPressed(0, 9) then -- rechts
                    horizontal = horizontal - fov / 100
                    if horizontal > 35 then horizontal = 35.0 end
                    if horizontal < -35 then horizontal = -35.0 end
                    SetCamRot(cam, vertikal, 0.0, camHorizontalHeading + horizontal)
                end
                if IsControlPressed(0, 8) then -- nach unten
                    vertikal = vertikal - fov / 100
                    if vertikal > 10.0 then vertikal = 10.0 end
                    if vertikal < -50.0 then vertikal = -50.0 end
                    SetCamRot(cam, vertikal, 0, camHorizontalHeading + horizontal)
                end
                if IsControlPressed(0, 32) then -- nach oben
                    vertikal = vertikal + fov / 100

                    if vertikal > 10.0 then vertikal = 10.0 end
                    if vertikal < -50.0 then vertikal = -50.0 end
                    SetCamRot(cam, vertikal, 0.0, camHorizontalHeading + horizontal)
                end
                if IsControlPressed(0, 17) then
                    fov = fov - 5
                    if fov < minFov then fov = minFov end
                    if fov > maxFov then fov = maxFov end
                    SetCamFov(cam, fov)
                end
                if IsControlPressed(0, 16) then
                    fov = fov + 5
                    if fov > maxFov then fov = maxFov end
                    if fov < minFov then fov = minFov end
                    SetCamFov(cam, fov)
                end
                Citizen.Wait()
            end
        end
    end
end)

RegisterNetEvent('videoRecordingCameras:getVideoCacheFile')
AddEventHandler('videoRecordingCameras:getVideoCacheFile', function(files)
  files = files
  Citizen.Wait(500)
  SendNUIMessage({cameras = Config.Cams, videos = files, locales = {Locales.MenuHeader, Locales.MenuDescription}})
end)

RegisterNetEvent('videoRecordingCameras:requestCamerasPermission')
AddEventHandler('videoRecordingCameras:requestCamerasPermission', function(cameras)
    for k,v in pairs(cameras) do
        cameras[k].cameras.location = GetStreetNameFromHashKey(GetStreetNameAtCoord(cameras[k].cameras.coords.x, cameras[k].cameras.coords.y, cameras[k].cameras.coords.z))
    end
    SendNUIMessage({cameras = cameras, locales = {Locales.MenuHeader, Locales.MenuDescription}})
end)    