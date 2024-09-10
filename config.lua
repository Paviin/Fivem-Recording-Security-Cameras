
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
        controlPoint = vector3(178.7876, 383.3642, 108.9205),
        camCoords = vector3(227.0677, 381.9196, 110.4175), 
        camHeading = 90.0, 
        minFov = 1.0,
        maxFov = 50.0,
        length = 30, 
        obj = "prop_cctv_cam_05a", 
        minCamHeightFov = 10,
        maxCamHeightFov = 2,

        permissions = {
            jobs = {
                {
                    name = ""
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
        camCoords = vector3(193.5627, 334.4494, 109.4351), 
        camHeading = 185.5589, 
        minFov = 1.0,
        maxFov = 50.0,
        length = 30, 
        obj = "prop_cctv_cam_05a", 
        minCamHeightFov = 5,
        maxCamHeightFov = 1,

        permissions = {
            jobs = {
                {
                    name = ""
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
        id = 3,
        title = "Po",
        description = "Police Cam 3",
        controlPoint = vector3(189.6041, 301.7457, 105.477),
        camCoords = vector3(143.6130, 195.5773, 113.1878), 
        camHeading = 287.2511, 
        minFov = 1.0,
        maxFov = 70.0,
        length = 150, 
        obj = "prop_cctv_cam_05a", 
        minCamHeightFov = 20,
        maxCamHeightFov = 10,
        
        permissions = {
            jobs = {
                {
                    name = "unemployed"
                }
            },
            identifiers = {
                {
                    identifier = ""
                }
            }
        }
    },
    {
        id = 4,
        title = "Casino",
        description = "Casino Garage",
        controlPoint = vector3(969.0598, -4.3849, 81.0416),
        camCoords = vector3(928.9232, -2.5198, 83.7641), 
        camHeading = 157.7447, 
        minFov = 1.0,
        maxFov = 70.0,
        length = 150, 
        obj = "prop_cctv_cam_05a", 
        minCamHeightFov = 20,
        maxCamHeightFov = 10,
        
        permissions = {
            jobs = {
                {
                    name = "unemployed"
                }
            },
            identifiers = {
                {
                    identifier = ""
                }
            }
        }
    }
}