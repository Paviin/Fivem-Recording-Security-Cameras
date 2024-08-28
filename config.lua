
Config = {}

Config.Debug = false

Config.Distance = 20.0

Config.JobsTableQuery = 'SELECT identifier FROM users WHERE job = @job'

Config.Marker = {
    enabled = true,
    settings = {
        type = 22,
        scale = 1.0,
        bobUpAndDown = true,
        faceCamera = true,
        color = {
            r = 0,
            g = 255,
            b = 100,
            a = 100
        }
    }
}

Config.Cams = {
    {
        id  = 1,
        title = "Police Cam",
        description = "Police Cam 1",
        controlPoint = vector3(-393.0705, -2764.1851, 6.0004),
        camCoords = vector3(226.0677, 381.9196, 110.4175), 
        camHeading = 90.0, 
        camVerticalHeading = 40, 
        fov = 50, 
        length = 30, 
        obj = "prop_cctv_cam_05a", 
        camHeightFov = 20,

        permissions = {
            jobs = {
                {
                    name = "asd"
                }
            },
            identifiers = {
                {
                    identifier = "license:d6a4657db0b45d37b70d43840f04b204711be1c6"
                }
            }
        }
    },
    {
        id = 2,
        title = "Police Cam",
        description = "Police Cam 2",
        controlPoint = vector3(-393.0705, -2764.1851, 6.0004),
        camCoords = vector3(226.0677, 381.9196, 110.4175), 
        camHeading = 90.0, 
        camVerticalHeading = 40, 
        fov = 50, 
        length = 30, 
        obj = "prop_cctv_cam_05a", 
        camHeightFov = 20,

        permissions = {
            jobs = {
                {
                    name = "unemployed"
                }
            },
            identifiers = {
                {
                    identifier = "steam:123456789abcdef"
                }
            }
        }
    },
}