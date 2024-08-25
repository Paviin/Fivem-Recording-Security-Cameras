local camCoords = vector3(-290.2076, -1504.9645, 29.4804)
local camHorizontalHeading = 260.0
local fov = 40.0
local length = 200.0
local camHeightFov = 50.0
local fileName
local playbackRecording = false
local recordedData = {}
local entitiesInZone = {}

local halfFov = fov / 2.0
local radHorizontalHeading = math.rad(camHorizontalHeading)

local frontLeft = camCoords + vector3(
    math.cos(radHorizontalHeading - math.rad(halfFov)) * length,
    math.sin(radHorizontalHeading - math.rad(halfFov)) * length,
    0.0
)

local frontRight = camCoords + vector3(
    math.cos(radHorizontalHeading + math.rad(halfFov)) * length,
    math.sin(radHorizontalHeading + math.rad(halfFov)) * length,
    0.0
)

local backLeft = camCoords + vector3(
    math.cos(radHorizontalHeading) - 1.5,
    math.sin(radHorizontalHeading),
    0.0
)

local backRight = camCoords + vector3(
    math.cos(radHorizontalHeading) - 1.5,
    math.sin(radHorizontalHeading),
    0.0
)

local camZone = PolyZone:Create({
    vector2(backLeft.x, backLeft.y),
    vector2(frontLeft.x, frontLeft.y),
    vector2(frontRight.x, frontRight.y),
    vector2(backRight.x, backRight.y)
}, {
    name = "camera_zone",
    minZ = camCoords.z - camHeightFov,
    maxZ = camCoords.z + camHeightFov,
    debugPoly = false
})

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

local function collectPedData(ped)
    local pedCoords = GetEntityCoords(ped)
    local weapon = GetSelectedPedWeapon(ped)

    return {
        type = 'ped',
        pedId = PedToNet(ped),
        coords = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z },
        heading = GetEntityHeading(ped),
        weapon = weapon,
        isInVehicle = IsPedInAnyVehicle(ped, false),
        currentAnimation = GetEntityAnimCurrentTime(ped),
        isAiming = IsPedAimingFromCover(ped) or IsPedShooting(ped),
        isRunning = IsPedRunning(ped),
        isWalking = IsPedWalking(ped),
        isInCover = IsPedInCover(ped, false),
        isInMeleeCombat = IsPedInMeleeCombat(ped),
        isDucking = IsPedDucking(ped),
        isReloading = IsPedReloading(ped),
        isRagdoll = IsPedRagdoll(ped)
    }
end

local function collectVehicleData(vehicle)
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)

    return {
        type = 'vehicle',
        coords = { x = vehicleCoords.x, y = vehicleCoords.y, z = vehicleCoords.z },
        heading = GetEntityHeading(vehicle),
        model = GetEntityModel(vehicle),
        colorPrimary = colorPrimary,
        colorSecondary = colorSecondary,
        plate = GetVehicleNumberPlateText(vehicle),
        isEngineRunning = GetIsVehicleEngineRunning(vehicle),
        pedInsideVeh = GetPedInVehicleSeat(vehicle, -1),
        speed = GetEntitySpeed(vehicle),
        doorsOpen = {
            frontLeft = IsVehicleDoorDamaged(vehicle, 0),
            frontRight = IsVehicleDoorDamaged(vehicle, 1),
            backLeft = IsVehicleDoorDamaged(vehicle, 2),
            backRight = IsVehicleDoorDamaged(vehicle, 3),
            hood = IsVehicleDoorDamaged(vehicle, 4),
            trunk = IsVehicleDoorDamaged(vehicle, 5)
        },
        occupants = GetVehicleNumberOfPassengers(vehicle),
    }
end

local function collectDataInZone()
    local peds = GetGamePool('CPed')
    local vehicles = GetGamePool('CVehicle')

    for entity, _ in pairs(entitiesInZone) do
        if DoesEntityExist(entity) and not camZone:isPointInside(GetEntityCoords(entity)) then
            if IsEntityAPed(entity) then
                table.insert(recordedData, collectPedData(entity))
            elseif IsEntityAVehicle(entity) then
                table.insert(recordedData, collectVehicleData(entity))
            end
        end
    end

    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) and camZone:isPointInside(GetEntityCoords(ped)) and isEntityVisibleToCamera(camCoords, ped) then
            entitiesInZone[ped] = true
            table.insert(recordedData, collectPedData(ped))
        end
    end

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) and camZone:isPointInside(GetEntityCoords(vehicle)) and isEntityVisibleToCamera(camCoords, vehicle) then
            entitiesInZone[vehicle] = true
            table.insert(recordedData, collectVehicleData(vehicle))
        end
    end
end

local isPlayerInZone = false
local spawnedPeds = {}
local spawnedVehicles = {}

camZone:onPlayerInOut(function(isPointInside, point, entity)
    isPlayerInZone = isPointInside

    if isPlayerInZone then
        print("Spieler oder Ped erkannt")
        TriggerServerEvent('createFile')
        Citizen.CreateThread(function()
            while isPlayerInZone do
                collectDataInZone()
                Citizen.Wait(875)
            end
        end)
    else
        TriggerServerEvent('videoRecordingCameras:createCacheFile', recordedData)
        print("Spieler oder Ped hat Sichtweite verlassen und Daten wurden gespeichert")
    end
end)

local function requestModels(models)
    for _, model in ipairs(models) do
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
    end
end

RegisterCommand('aufnahme', function()
    watchVideo(recordedData)
end)

function watchVideo(file)
    playbackRecording = true
    if #file == 0 then
        print("No recorded data available.")
        return
    end

    -- Request all models used for playback
    local modelsToRequest = { "a_m_y_stbla_01", "a_m_y_beach_02" }
    requestModels(modelsToRequest)

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, backRight.x, backRight.y, camCoords.z)

    SetCamFov(cam, fov - 20)
    RenderScriptCams(true, false, 0, true, true)
    SetCamRot(cam, 0.0, 0.0, camHorizontalHeading - 90, 2) 
    DisplayHud(false)
    DisplayRadar(false)

    Citizen.CreateThread(function()
        local index = 1

        while playbackRecording do
            if index <= #file then
                local data = file[index]
                if data.type == 'ped' then
                    local ped
                    if data.pedId and spawnedPeds[data.pedId] then
                        ped = spawnedPeds[data.pedId]
                        SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z)
                        SetEntityHeading(ped, data.heading)
                    else
                        --ped = CreatePed(4, GetHashKey("a_m_y_stbla_01"), data.coords.x, data.coords.y, data.coords.z, data.heading, false, false)
                        SetEntityHeading(ped, data.heading)
                        if data.isInVehicle then
                            local vehicle
                            if data.plate and spawnedVehicles[data.plate] then
                                vehicle = spawnedVehicles[data.plate]
                                TaskWarpPedIntoVehicle(ped, vehicle, -1)
                            else
                                vehicle = CreateVehicle(data.model, data.coords.x, data.coords.y, data.coords.z, data.heading, false, false)
                                SetVehicleOnGroundProperly(vehicle)
                                SetVehicleColours(vehicle, data.colorPrimary, data.colorSecondary)
                                SetVehicleNumberPlateText(vehicle, data.plate)
                                SetVehicleEngineOn(vehicle, data.isEngineRunning, true, false)
                                SetVehicleCurrentRpm(vehicle, data.rpm)
                                SetVehicleFuelLevel(vehicle, data.fuelLevel)
                                if data.plate then
                                    spawnedVehicles[data.plate] = vehicle
                                end
                                TaskWarpPedIntoVehicle(ped, vehicle, -1)
                            end
                        end
                        if data.pedId then
                            spawnedPeds[data.pedId] = ped
                        end
                    end
                    if data.isRunning then
                        TaskGoStraightToCoord(ped, data.coords.x, data.coords.y, data.coords.z, 10, -1, 100.0)
                    elseif data.isWalking then
                        TaskPlayAnim(ped, "move_m@walk", "walk", 8.0, -8.0, -1, 1, 0, false, false, false)
                    elseif data.isAiming then
                        TaskAimGunScripted(ped, GetHashKey("SCRIPTED_GUN_TASK"), true, true)
                    end
                elseif data.type == 'vehicle' then
                    local vehicle
                    local ped
                    if data.plate and spawnedVehicles[data.plate] then
                        vehicle = spawnedVehicles[data.plate]
                        -- Update the position of the vehicle
                        SetEntityHeading(vehicle, data.heading)

                        local modelHash = "a_m_y_beach_02"
                        RequestModel(modelHash)
                        while not HasModelLoaded(modelHash) do
                            Wait(0)
                        end
                        SetVehicleOnGroundProperly(vehicle)
                        print(GetPedInVehicleSeat(vehicle, -1), vehicle, data.coords.x, data.coords.y, data.coords.z, 100.0, 0.0, data.model, 52, 1.0, true)
                        --TaskVehicleDriveToCoord(GetPedInVehicleSeat(vehicle, -1), vehicle, data.coords.x, data.coords.y, data.coords.z, data.speed, 0.0, data.model, 0, 1.0, true)
                        SetEntityCoords(vehicle, data.coords.x, data.coords.y, data.coords.z, 0.0, 0.0, 0.0, false)
                        SetPedIntoVehicle(GetPedInVehicleSeat(vehicle, -1), vehicle, -1)
                        SetVehicleOnGroundProperly(vehicle)

                    else
                        vehicle = CreateVehicle(data.model, data.coords.x, data.coords.y, data.coords.z, data.heading, false, false)
                        local modelHash = "a_m_y_beach_02"
                        RequestModel(modelHash)
                        while not HasModelLoaded(modelHash) do
                            Wait(0)
                        end
                        ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey(modelHash), -1, false, false)
                        print(ped)
                        SetVehicleOnGroundProperly(vehicle)
                        SetVehicleColours(vehicle, data.colorPrimary, data.colorSecondary)
                        SetVehicleNumberPlateText(vehicle, data.plate)
                        SetVehicleEngineOn(vehicle, data.isEngineRunning, true, false)
                        SetVehicleCurrentRpm(vehicle, data.rpm)
                        SetVehicleFuelLevel(vehicle, data.fuelLevel)
                        if data.plate then
                            spawnedVehicles[data.plate] = vehicle
                        end
                    end
                end
                index = index + 1
            end
            local adjustedWaitTime = 1000 / (#file / 10) -- 10 ist eine willkürliche Skalierungszahl, die angepasst werden kann
            Citizen.Wait(math.max(adjustedWaitTime, 100)) -- Mindest-Wartezeit von 100ms, um ein Einfrieren zu vermeiden
        end
        RenderScriptCams(false, false, 0, true, true)
        DisplayHud(true)
        DisplayRadar(true)
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(#file * 875 + 1000)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        DisplayHud(true)
        DisplayRadar(true)
        print("Playback finished and camera reset.")
        playbackRecording = false
    end)

    local function removeNonRecordedEntities()
        local allPeds = GetGamePool('CPed')
        local allVehicles = GetGamePool('CVehicle')
    
        for _, ped in ipairs(allPeds) do
            if DoesEntityExist(ped) and not camZone:isPointInside(GetEntityCoords(ped)) then
                DeletePed(ped)
            end
        end
    
        for _, vehicle in ipairs(allVehicles) do
            if DoesEntityExist(vehicle) and not camZone:isPointInside(GetEntityCoords(vehicle)) then
                SetEntityAsMissionEntity(vehicle, true, true)
                DeleteVehicle(vehicle)
                SetVehicleAsNoLongerNeeded(vehicle)
            end
        end
    end
    
    Citizen.CreateThread(function()
        local _ = false
        while true do
            if playbackRecording then
                if not _ then
                    local allPeds = GetGamePool('CPed')
                    local allVehicles = GetGamePool('CVehicle')
    
                    for _, ped in ipairs(allPeds) do
                        if DoesEntityExist(ped) and camZone:isPointInside(GetEntityCoords(ped)) then
                            DeletePed(ped)
                        end
                    end
    
                    for _, vehicle in ipairs(allVehicles) do
                        if DoesEntityExist(vehicle) and camZone:isPointInside(GetEntityCoords(vehicle)) then
                            SetEntityAsMissionEntity(vehicle, true, true)
                            DeleteVehicle(vehicle)
                            SetVehicleAsNoLongerNeeded(vehicle)
                        end
                    end
                    _ = true
                end
                removeNonRecordedEntities()
            end
            Citizen.Wait()
        end
    end)
    
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

RegisterCommand('stop', function()
    playbackRecording = false

    for _, ped in pairs(spawnedPeds) do
        DeleteEntity(ped)
    end
    spawnedPeds = {}

    for _, vehicle in pairs(spawnedVehicles) do
        DeleteEntity(vehicle)
    end
    spawnedVehicles = {}
end)