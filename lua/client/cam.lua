local camCoords = vector3(226.0677, 381.9196, 110.4175)
local camHorizontalHeading = 180
local fov = 90.0
local length = 90.0
local camHeightFov = 5.0

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
    maxZ = camCoords.z + camHeightFov / 6,
    debugPoly = true
})

local function isPlayerVisibleToCamera(camCoords, camHorizontalHeading, playerPed)
    local playerCoords = GetEntityCoords(playerPed)

    local success, screenX, screenY = GetScreenCoordFromWorldCoord(playerCoords.x, playerCoords.y, playerCoords.z)

    if not success then
        return false
    end

    local rayHandle = CastRayPointToPoint(camCoords.x, camCoords.y, camCoords.z, playerCoords.x, playerCoords.y, playerCoords.z, 17, PlayerPedId(), 0)
    local _, _, _, _, entityHit = GetRaycastResult(rayHandle)

    if entityHit == playerPed or entityHit == 0 then
        return true
    else
        return false
    end
end

local function checkPlayerVisibility()
    local playerPed = GetPlayerPed(-1) 
    if isPlayerVisibleToCamera(camCoords, camHorizontalHeading, playerPed) then
        print("Person ist weiterhin sichtbar")
    else
        print("Spieler hinter objekt.")
    end
end

local isPlayerInZone = false

camZone:onPlayerInOut(function(isPointInside, point, entity)
    isPlayerInZone = isPointInside

    if isPlayerInZone then
        print("Spieler erkannt")
        
        Citizen.CreateThread(function()
            while isPlayerInZone do
                checkPlayerVisibility()
                Citizen.Wait(500)
            end
        end)
    else
        print("Spieler hat Sichtweite verlassen")
    end
end)

CreateCamObj = function(camCoords, camHeading, obj)
    local x, y, z = table.unpack(camCoords)
    cam = CreateObject(GetHashKey(obj), x, y, z, false, false, true)
    SetEntityHeading(cam, camHeading - 180)
end

AddEventHandler('onResourceStop', function()
    DeleteObject(cam)
end)
