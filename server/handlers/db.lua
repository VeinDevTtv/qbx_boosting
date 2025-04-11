-- Get boosting data for a specific citizen ID
function GetBoostingDataByCid(citizenid)
    -- Check if the player exists in the database
    local result = MySQL.query.await('SELECT * FROM laptop_boosting_data WHERE cid = ?', {citizenid})
    
    -- If the player doesn't exist, create a new entry
    if #result == 0 then
        MySQL.insert.await('INSERT INTO laptop_boosting_data (cid) VALUES (?)', {citizenid})
        
        -- Return default values
        return {
            Experience = 0,
            ContractsCompleted = 0,
            ContractsFailed = 0,
            WeeklyContracts = 0,
            WeeklyVins = 0,
            LastVin = 0,
            LastSpecialContract = 0
        }
    end
    
    -- Return the player's data
    return {
        Experience = result[1].experience,
        ContractsCompleted = result[1].contracts_completed,
        ContractsFailed = result[1].contracts_failed,
        WeeklyContracts = result[1].weekly_contracts,
        WeeklyVins = result[1].weekly_vins,
        LastVin = result[1].last_vin,
        LastSpecialContract = result[1].last_special_contract
    }
end

-- Check if a contract is scratchable
function IsContractScratchable(citizenid, vehicle)
    local boostData = GetBoostingDataByCid(citizenid)
    
    -- Check if player has reached weekly vin limit
    if boostData.WeeklyVins >= Config.VinLimit then
        return false
    end
    
    -- Check if player's last vin scratch was within 7 days
    local now = os.time()
    local daysSinceLastVin = (now - boostData.LastVin) / (60 * 60 * 24)
    
    if daysSinceLastVin < 7 then
        return false
    end
    
    return true
end

-- Add experience to a player
function AddExperience(citizenid, experience)
    MySQL.update.await('UPDATE laptop_boosting_data SET experience = experience + ? WHERE cid = ?', {experience, citizenid})
end

-- Record a completed contract
function CompleteContract(citizenid, contractClass)
    MySQL.update.await('UPDATE laptop_boosting_data SET contracts_completed = contracts_completed + 1, weekly_contracts = weekly_contracts + 1 WHERE cid = ?', {citizenid})
    
    -- Add experience based on contract class
    local experienceToAdd = 0
    
    if contractClass == "D" then experienceToAdd = 10
    elseif contractClass == "C" then experienceToAdd = 20
    elseif contractClass == "B" then experienceToAdd = 30
    elseif contractClass == "A" then experienceToAdd = 40
    elseif contractClass == "A+" then experienceToAdd = 50
    elseif contractClass == "S" then experienceToAdd = 60
    elseif contractClass == "S+" then experienceToAdd = 70
    end
    
    AddExperience(citizenid, experienceToAdd)
end

-- Record a failed contract
function FailContract(citizenid)
    MySQL.update.await('UPDATE laptop_boosting_data SET contracts_failed = contracts_failed + 1 WHERE cid = ?', {citizenid})
end

-- Record a VIN scratch
function RecordVinScratch(citizenid)
    MySQL.update.await('UPDATE laptop_boosting_data SET weekly_vins = weekly_vins + 1, last_vin = ? WHERE cid = ?', {os.time(), citizenid})
end

-- Record a special contract
function RecordSpecialContract(citizenid)
    MySQL.update.await('UPDATE laptop_boosting_data SET last_special_contract = ? WHERE cid = ?', {os.time(), citizenid})
end 