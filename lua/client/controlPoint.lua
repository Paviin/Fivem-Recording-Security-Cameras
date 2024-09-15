
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
    local camCoords = nil
    local stop = false

    Citizen.CreateThread(function()

        local function isEntityVisibleToCamera(camCoords, entity)
            local entityCoords = GetEntityCoords(entity)
            local success, screenX, screenY = GetScreenCoordFromWorldCoord(entityCoords.x, entityCoords.y, entityCoords.z)
            if not success then
                return false
            end
        
            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, entityCoords.x, entityCoords.y, entityCoords.z, 17, PlayerPedId(), 0)
            local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
        
            return hit and (entityHit == entity or entityHit == 0)
        end

        local rects = {}
        local activeRectsCount = 0 
        
        local function round(num)
            return num + (2^52 + 2^51) - (2^52 + 2^51)
        end

        function DrawRectAroundPed(ped)
            if not rects[ped] and ped then
                rects[ped] = ped
                activeRectsCount = activeRectsCount + 1
        
                Citizen.CreateThread(function()
                    local breakLoop = false
                    while not stop and not breakLoop and rects[ped] do
                        local pedPos = GetEntityCoords(ped)
                
                        local onScreen, x, y = GetScreenCoordFromWorldCoord(pedPos.x, pedPos.y, pedPos.z)
                        
                        if onScreen and isEntityVisibleToCamera(GetEntityCoords(PlayerPedId()), ped) then
                            local rectWidth = 0.025
                            local rectHeight = 0.05
        
                            if IsEntityAVehicle(ped) then
                                DrawRectOutline(x, y, rectWidth, rectHeight, 255, 0, 0, 255) 
                                Draw2DText(x, y, 0.3, 255, 0, 0, 255, round(GetEntitySpeed(ped) * 3.6).."Km/h")
                                Draw2DText(x, y + 0.015, 0.3, 255, 0, 0, 255, GetVehicleNumberPlateText(ped))
                            else
                                if IsPedInAnyVehicle(ped, false) then
                                    rectWidth = rectWidth / 2
                                    rectHeight = rectHeight / 2
        
                                    local headPos = GetPedBoneCoords(ped, 12844, 0.0, 0.0, 0.0) 
                                    onScreen, x, y = GetScreenCoordFromWorldCoord(headPos.x, headPos.y, headPos.z)
                                    DrawRectOutline(x, y, rectWidth, rectHeight, 0, 255, 0, 255) 
                                    Draw2DText(x, y, 0.3, 0, 255, 0, 255, ped)
                                else
                                    DrawRectOutline(x, y, rectWidth / 2, rectHeight, 0, 0, 255, 255) 
                                    Draw2DText(x, y, 0.3, 0, 0, 255, 255, ped)
                                end
                            end
                        else
                            rects[ped] = nil
                            activeRectsCount = activeRectsCount - 1 
                        end
        
                        local sleep = activeRectsCount * 5
                        if sleep > 50 then
                            sleep = 35
                        end
                        Citizen.Wait(sleep) 
                    end
                end)
            end
        end
        

        function DrawRectOutline(x, y, width, height, r, g, b, a)
            local thickness = 0.0015 

            DrawRect(x, y - height / 2, width, thickness, r, g, b, a)
            DrawRect(x, y + height / 2, width, thickness, r, g, b, a)
            DrawRect(x - width / 2, y, thickness, height, r, g, b, a)
            DrawRect(x + width / 2, y, thickness, height, r, g, b, a)
        end

        function Draw2DText(x, y, scale, r, g, b, a, text)
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(scale, scale)
            SetTextColour(r, g, b, a)
            SetTextEntry("STRING")
            AddTextComponentString(text)
            
            DrawText(x, y)
        end

        while true do
            while not camCoords do
                Citizen.Wait(100)
            end
            local peds = GetGamePool('CPed')
            local vehicles = GetGamePool('CVehicle')    

            for k, vehicle in pairs(vehicles) do
                if isEntityVisibleToCamera(camCoords, vehicle) then
                    DrawRectAroundPed(vehicle, false)
                end
            end

            for k, ped in pairs(peds) do
                if isEntityVisibleToCamera(camCoords, ped) then
                    DrawRectAroundPed(ped, true)
                end
            end

            Citizen.Wait(2000)
        end
    end)

    local function setupCamera(camCoords, camHeading, fov)
        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetTimecycleModifier("CAMERA_secuirity_FUZZ")
        SetTimecycleModifierStrength(0.2)
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
            camCoords = v.camCoords
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
                    stop = true
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