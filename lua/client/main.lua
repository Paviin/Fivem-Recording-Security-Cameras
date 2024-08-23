Citizen.CreateThread(function()
    for k, cam in pairs(Config.Cams) do
        CreateCamObj(cam.camCoords, cam.camHeading, cam.obj)
    end
end)
