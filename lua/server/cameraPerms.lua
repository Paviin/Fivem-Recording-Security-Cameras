RegisterNetEvent('videoRecordingCameras:requestCamerasPermission')
AddEventHandler('videoRecordingCameras:requestCamerasPermission', function()
    local identifiers = {}
    local cameras     = {}
    local source_ = source

    local function isCameraAlreadyAdded(cam)
        for _, v in pairs(cameras) do
            if v == cam then
                return true
            end
        end
        return false
    end

    for k,v in pairs(GetPlayerIdentifiers(source_)) do
        local match_
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            match_ = string.match(v, ":(%w+)")
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
            match_ = string.match(v, ":(%w+)")
        end

        for k_,v_ in pairs(Config.Cams) do
            for k__,v__ in pairs(v_.permissions.identifiers) do
                local match = string.match(v__.identifier, ":(%w+)")
                if match == match_ then
                    if not isCameraAlreadyAdded(v) then
                        table.insert(cameras, {cameras = v_})
                        for _, file in pairs(files) do
                            if file.id == v_.id then
                                cameras[k_].videos = file
                            end
                        end
                    end
                end
            end
        end
    end

    local jobs_count = 0
    local jobs_total = 0

    for k,v in pairs(Config.Cams) do
        jobs_total = jobs_total + #v.permissions.jobs
    end

    for k,v in pairs(Config.Cams) do
        for k_,v_ in pairs(v.permissions.jobs) do
            MySQL.Async.fetchAll(Config.JobsTableQuery, { ["@job"] = v_.name }, function(result)
                for k__,v__ in pairs(result) do
                    local match = string.match(v__.identifier, ":(%w+)")

                    for k___,v___ in pairs(GetPlayerIdentifiers(source_)) do
                        local match_
                        if string.sub(v___, 1, string.len("steam:")) == "steam:" then
                            match_ = string.match(v___, ":(%w+)")
                        elseif string.sub(v___, 1, string.len("license:")) == "license:" then
                            match_ = string.match(v___, ":(%w+)")
                        elseif string.sub(v___, 1, string.len("xbl:")) == "xbl:" then
                            match_ = string.match(v___, ":(%w+)")
                        elseif string.sub(v___, 1, string.len("ip:")) == "ip:" then
                            match_ = string.match(v___, ":(%w+)")
                        elseif string.sub(v___, 1, string.len("discord:")) == "discord:" then
                            match_ = string.match(v___, ":(%w+)")
                        elseif string.sub(v___, 1, string.len("live:")) == "live:" then
                            match_ = string.match(v___, ":(%w+)")
                        end

                        if match == match_ then
                            if not isCameraAlreadyAdded(v) then
                                table.insert(cameras, {cameras = v})
                                local files = getVideoCacheFile()

                                for _, file in pairs(files) do
                                    if file.id == v.id then
                                        cameras[k].videos = file
                                    end
                                end
                            end
                        end
                    end
                end

                jobs_count = jobs_count + 1
                if jobs_count == jobs_total then
                    TriggerClientEvent('videoRecordingCameras:requestCamerasPermission', source_, cameras)
                end
            end)
        end
    end
end)

function tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent + 1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end


function tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent + 1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end
