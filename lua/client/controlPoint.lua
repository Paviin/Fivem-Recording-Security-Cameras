
local playerPed = PlayerPedId()
local playerCoords = vector3(0, 0, 0)
local nearestCamDistance, nearestCamCoords
menuOpen = false
local files

local function updatePlayerCoords()
    playerCoords = GetEntityCoords(playerPed)
end

local function findNearestCam()
    nearestCamDistance = Config.Distance + 1
    nearestCamCoords = nil

    for _, cam in pairs(Config.Cams) do
        if cam.controlPoint then
            local camDistance = #(playerCoords - cam.controlPoint)
            if camDistance < nearestCamDistance then
                nearestCamDistance = camDistance
                nearestCamCoords = cam.controlPoint
            end
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
    local ped = PlayerPedId()
    local oldCoords = GetEntityCoords(ped)

    local function setupCamera(camCoords, camHeading, fov)
        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetTimecycleModifier("CAMERA_secuirity_FUZZ")
        SetTimecycleModifierStrength(0.8)
        SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z - 0.25)
        SetCamFov(cam, fov)
        SetCamRot(cam, -7.5, 0.0, camHeading, 2)
        RenderScriptCams(true, false, 0, true, true)
        DisplayHud(false)
        DisplayRadar(false)
        return cam
    end

    local function resetCamera(cam)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        SetTimecycleModifierStrength(0.0)
        DisplayHud(true)
        DisplayRadar(true)
    end

    for _, v in pairs(Config.Cams) do
        if v.id == id then
            FreezeEntityPosition(ped, true)
            SetEntityCoords(ped, v.camCoords.x, v.camCoords.y, v.camCoords.z, 0.0, 0.0, 0.0, false)
            SetEntityAlpha(ped, 0.0, -1)

            local cam = setupCamera(v.camCoords, v.camHeading, v.maxFov / 1.7)
            local horizontal, vertical = 0, -7.5
            local fov = v.maxFov / 1.7
            local minFov, maxFov = v.minFov, v.maxFov
            menuOpen = false
            SetNuiFocus(false, false)

            while true do
                if IsControlPressed(0, 34) then -- links
                    horizontal = math.min(35.0, horizontal + fov / 100)
                elseif IsControlPressed(0, 9) then -- rechts
                    horizontal = math.max(-35.0, horizontal - fov / 100)
                end

                if IsControlPressed(0, 32) then -- nach oben
                    vertical = math.min(10.0, vertical + fov / 100)
                elseif IsControlPressed(0, 8) then -- nach unten
                    vertical = math.max(-50.0, vertical - fov / 100)
                end

                if IsControlPressed(0, 17) then
                    fov = math.max(minFov, fov - 5)
                elseif IsControlPressed(0, 16) then
                    fov = math.min(maxFov, fov + 5)
                end

                SetCamRot(cam, vertical, 0.0, v.camHeading + horizontal)
                SetCamFov(cam, fov)
                DisableControlAction(0, 200, true) 

                if IsControlJustPressed(0, 202) then
                    TriggerServerEvent('videoRecordingCameras:requestCamerasPermission')
                    FreezeEntityPosition(ped, false)
                    SetEntityCoords(ped, oldCoords)
                    SetEntityAlpha(ped, 255, false)
                    SetTimecycleModifierStrength(0.0)
                    menuOpen = true
                    SetNuiFocus(true, true)
                    SendNUIMessage({action = "open"})
                    DisableControlAction(0, 200, false) 
                    resetCamera()
                    break
                end

                Citizen.Wait(0)
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
    Citizen.Wait(500)
    SendNUIMessage({cameras = cameras, locales = {Locales.MenuHeader, Locales.MenuDescription}})
end)    