-- This file contains the locations for vehicle spawns, NPC spawns, dropoff points, and scratch locations

-- Vehicle and NPC spawn locations categorized by vehicle class
BoostLocations = {
    -- D class locations
    {
        Class = "D",
        Vehicle = { x = -1020.12, y = -896.02, z = 5.42, w = 210.0 },
        NPCs = {
            { x = -1018.52, y = -895.12, z = 5.42 },
            { x = -1022.32, y = -894.22, z = 5.42 }
        }
    },
    {
        Class = "D",
        Vehicle = { x = 234.32, y = -789.12, z = 30.18, w = 250.0 },
        NPCs = {
            { x = 232.42, y = -792.52, z = 30.18 },
            { x = 236.12, y = -787.82, z = 30.18 }
        }
    },
    
    -- C class locations
    {
        Class = "C",
        Vehicle = { x = 820.12, y = -1292.32, z = 26.29, w = 80.0 },
        NPCs = {
            { x = 822.52, y = -1294.62, z = 26.29 },
            { x = 818.32, y = -1290.42, z = 26.29 }
        }
    },
    {
        Class = "C",
        Vehicle = { x = 435.82, y = -1026.22, z = 28.59, w = 0.0 },
        NPCs = {
            { x = 433.52, y = -1026.22, z = 28.59 },
            { x = 438.12, y = -1026.22, z = 28.59 }
        }
    },
    
    -- B class locations
    {
        Class = "B",
        Vehicle = { x = -673.12, y = 310.52, z = 82.98, w = 170.0 },
        NPCs = {
            { x = -671.52, y = 312.42, z = 82.98 },
            { x = -675.42, y = 308.92, z = 82.98 }
        }
    },
    {
        Class = "B",
        Vehicle = { x = 1012.32, y = -2528.12, z = 28.31, w = 90.0 },
        NPCs = {
            { x = 1014.52, y = -2530.42, z = 28.31 },
            { x = 1010.12, y = -2526.32, z = 28.31 }
        }
    },
    
    -- A class locations
    {
        Class = "A",
        Vehicle = { x = 2001.32, y = 3786.42, z = 32.18, w = 110.0 },
        NPCs = {
            { x = 2003.52, y = 3784.12, z = 32.18 },
            { x = 1999.12, y = 3788.72, z = 32.18 }
        }
    },
    {
        Class = "A",
        Vehicle = { x = -2162.52, y = -385.12, z = 13.11, w = 250.0 },
        NPCs = {
            { x = -2160.32, y = -387.42, z = 13.11 },
            { x = -2164.72, y = -383.22, z = 13.11 }
        }
    },
    
    -- A+ class locations
    {
        Class = "A+",
        Vehicle = { x = -1551.42, y = -87.12, z = 54.23, w = 0.0 },
        NPCs = {
            { x = -1553.62, y = -87.12, z = 54.23 },
            { x = -1549.22, y = -87.12, z = 54.23 }
        }
    },
    {
        Class = "A+",
        Vehicle = { x = 756.32, y = -1869.12, z = 29.29, w = 85.0 },
        NPCs = {
            { x = 758.52, y = -1871.42, z = 29.29 },
            { x = 754.12, y = -1867.22, z = 29.29 }
        }
    },
    
    -- S class locations
    {
        Class = "S",
        Vehicle = { x = -1795.12, y = -372.52, z = 43.12, w = 320.0 },
        NPCs = {
            { x = -1793.22, y = -370.32, z = 43.12 },
            { x = -1797.42, y = -374.72, z = 43.12 }
        }
    },
    {
        Class = "S",
        Vehicle = { x = 125.32, y = -1078.12, z = 29.19, w = 0.0 },
        NPCs = {
            { x = 123.12, y = -1078.12, z = 29.19 },
            { x = 127.52, y = -1078.12, z = 29.19 }
        }
    },
    
    -- S+ class locations
    {
        Class = "S+",
        Vehicle = { x = -80.12, y = -807.52, z = 43.32, w = 340.0 },
        NPCs = {
            { x = -78.22, y = -805.32, z = 43.32 },
            { x = -82.42, y = -809.72, z = 43.32 }
        }
    },
    {
        Class = "S+",
        Vehicle = { x = 356.32, y = -2043.12, z = 21.59, w = 55.0 },
        NPCs = {
            { x = 358.52, y = -2045.42, z = 21.59 },
            { x = 354.12, y = -2041.22, z = 21.59 }
        }
    }
}

-- Vehicle dropoff locations
DropoffLocations = {
    { x = 619.81, y = 2784.83, z = 41.98 },
    { x = 1243.62, y = -3257.59, z = 5.03 },
    { x = 921.11, y = -1196.58, z = 25.91 },
    { x = 2442.5, y = 4966.83, z = 46.81 },
    { x = -559.1, y = 5328.91, z = 73.43 },
    { x = -2221.84, y = 4229.61, z = 46.61 },
    { x = 706.74, y = -966.22, z = 30.41 },
    { x = -1132.68, y = 2698.25, z = 18.81 },
    { x = 2767.44, y = 3467.69, z = 55.57 },
    { x = 2549.45, y = 342.15, z = 108.46 }
}

-- VIN scratch locations
ScratchLocations = {
    {
        Laptop = {
            Coords = { x = 472.12, y = -1308.32, z = 29.21, w = 270.0 },
            Create = `prop_laptop_lester`
        }
    },
    {
        Laptop = {
            Coords = { x = 2334.72, y = 3128.12, z = 48.21, w = 0.0 },
            Create = `prop_laptop_lester`
        }
    },
    {
        Laptop = {
            Coords = { x = 731.32, y = 4172.52, z = 40.71, w = 90.0 },
            Create = `prop_laptop_lester`
        }
    }
} 