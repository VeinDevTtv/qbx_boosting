Queuers = {}

-- Start the queue thread that regularly assigns contracts to players in queue
function StartQueueThread()
    CreateThread(function()
        while true do
            ProcessQueue()
            Wait(60000) -- Process queue every minute
        end
    end)
end

-- Process the queue and assign contracts to eligible players
function ProcessQueue()
    -- If no players in queue, skip processing
    if #Queuers == 0 then return end
    
    -- Process each player in queue
    for i = 1, #Queuers do
        local citizenid = Queuers[i].Cid
        local source = Queuers[i].Source
        
        -- Skip if player is no longer online
        if not QBX.Functions.GetPlayerByCitizenId(citizenid) then
            table.remove(Queuers, i)
            goto continue
        end
        
        -- Get player's boosting data
        local boostData = GetBoostingDataByCid(citizenid)
        
        -- Check if the player already has max contracts
        local contracts = GetContractsByCid(citizenid)
        if #contracts >= Config.MaxContractsAllowed then
            goto continue
        end
        
        -- Check if the player has reached weekly limit
        if boostData.WeeklyContracts >= Config.WeeklyLimit then
            goto continue
        end
        
        -- Get classes player is eligible for
        local currentClass, _ = GetClassesFromExperience(boostData.Experience)
        local eligibleClasses = GetEligibleClasses(currentClass)
        
        -- Random chance to create a contract based on class rarity
        local contractClass = GetRandomContractClass(eligibleClasses)
        if not contractClass then
            goto continue
        end
        
        -- Create a new contract
        local contractorNames = GetContractorNames()
        local contractor = contractorNames[math.random(#contractorNames)]
        
        -- Get a random vehicle for the class
        local vehicle = GetRandomVehicleForClass(contractClass)
        if not vehicle then
            goto continue
        end
        
        -- Calculate expiration time (24 hours)
        local expire = os.time() + (24 * 60 * 60)
        
        -- Insert contract into database
        local insertId = MySQL.insert.await('INSERT INTO laptop_boosting (cid, class, xp, contractor, vehicle, expire) VALUES (?, ?, ?, ?, ?, ?)', {
            citizenid,
            contractClass,
            0,
            contractor,
            vehicle,
            expire
        })
        
        -- Notify player
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'New Boosting Contract',
            description = 'Check your laptop for details',
            type = 'inform'
        })
        
        -- Remove player from queue
        table.remove(Queuers, i)
        
        ::continue::
    end
end

-- Add a player to the boosting queue
function AddCidToQueue(source, citizenid)
    -- Check if player is already in queue
    if IsPlayerQueued(citizenid) then
        return false
    end
    
    -- Add player to queue
    table.insert(Queuers, {
        Source = source,
        Cid = citizenid,
        QueuedAt = os.time()
    })
    
    return true
end

-- Remove a player from the boosting queue
function RemoveCidFromQueue(source, citizenid)
    for i = 1, #Queuers do
        if Queuers[i].Cid == citizenid then
            table.remove(Queuers, i)
            return true
        end
    end
    
    return false
end

-- Check if a player is in the boosting queue
function IsPlayerQueued(citizenid)
    for i = 1, #Queuers do
        if Queuers[i].Cid == citizenid then
            return true
        end
    end
    
    return false
end

-- Get classes a player is eligible for based on current class
function GetEligibleClasses(currentClass)
    local eligibleClasses = {}
    local classes = {"D", "C", "B", "A", "A+", "S", "S+"}
    local currentIndex = 0
    
    -- Find the index of the current class
    for i = 1, #classes do
        if classes[i] == currentClass then
            currentIndex = i
            break
        end
    end
    
    -- Player can get contracts of their class and all lower classes
    for i = 1, currentIndex do
        table.insert(eligibleClasses, classes[i])
    end
    
    return eligibleClasses
end

-- Get a random contract class based on rarity
function GetRandomContractClass(eligibleClasses)
    local rand = math.random()
    
    for i = #eligibleClasses, 1, -1 do
        local class = eligibleClasses[i]
        if rand <= Config.ClassChances[class] then
            return class
        end
    end
    
    -- If no class was selected, return the lowest class
    return eligibleClasses[1]
end

-- Get contractor names
function GetContractorNames()
    return {
        "G",
        "P",
        "Wizard",
        "Ghost",
        "Shadow",
        "Specter",
        "Cipher",
        "Echo",
        "Unknown"
    }
end

-- Get a random vehicle for a specific class
function GetRandomVehicleForClass(class)
    local vehiclesInClass = {}
    
    -- Get all vehicles that match the class
    for model, data in pairs(QBX.Shared.Vehicles) do
        if data.class and data.class:upper() == class then
            table.insert(vehiclesInClass, model)
        end
    end
    
    -- If no vehicles found for the class, return nil
    if #vehiclesInClass == 0 then
        return nil
    end
    
    return vehiclesInClass[math.random(#vehiclesInClass)]
end 