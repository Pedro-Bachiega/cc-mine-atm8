local args = {...}
local computerType = nil

for index, value in ipairs(args) do
    if value == '-t' or value == '--type' then
        computerType = args[index + 1]
    end
end

local function createStartup()
    local content = [[
if not constants then os.loadAPI('constants.lua') end
if not channelAPI then os.loadAPI('channelAPI.lua') end
if not logAPI then os.loadAPI('logAPI.lua') end

channelAPI.importChannelsIfNeeded()

shell.run('postBoot.lua')
shell.run('run.lua')
    ]]

    local file = fs.open('startup.lua', 'w')
    file.write(content)
    file.close()
end

local function chooseComputerType()
    local types = {'farm', 'storage', 'manager', 'log'}
    print('\nSelect the computer type:')

    for index, value in ipairs(types) do
        print(tostring(index) .. ') ' .. value)
    end

    local result = tonumber(read())
    local validResult = result > 0 and result <= #types
    if not validResult then result = #types end

    return types[result]
end

local function chooseSideFor(name, required)
    local sidesTable = {'top', 'right', 'bottom', 'left', 'back', 'none'}

    print('\nSelect the side the ' .. name .. ' is attached to:')

    for index, value in ipairs(sidesTable) do
        print(tostring(index) .. ') ' .. value)
    end

    local result = tonumber(read())
    local validResult = result > 0 and result <= #sidesTable

    if not validResult and required then
        error('Invalid choice')
    elseif not validResult then
        result = #sidesTable
    end

    return sidesTable[result]
end

local function chooseChannel()
    print('\nChannel this computer will use: ')
    return read()
end

local function writeConstants()
    local modemSide = constants.MODEM_SIDE or chooseSideFor('modem', true)
    local monitorSide = constants.MONITOR_SIDE or chooseSideFor('monitor', false)
    local redstoneSide = constants.REDSTONE_SIDE or (computerType == 'farm' and chooseSideFor('redstone', true) or 'none')

    local channel = constants.CHANNEL or (computerType == 'storage' and '420' or chooseChannel())

    local constants = [[
-- Computer
COMPUTER_TYPE = '<computer_type>'

-- Generic
MODEM_SIDE = '<modem_side>'
MONITOR_SIDE = '<monitor_side>'
REDSTONE_SIDE = '<redstone_side>'

-- Channels
CHANNEL = <channel>
CHANNEL_STORAGE = 420
    ]]

    constants = string.gsub(constants, '<computer_type>', computerType)
    constants = string.gsub(constants, '<modem_side>', modemSide)
    constants = string.gsub(constants, '<monitor_side>', monitorSide)
    constants = string.gsub(constants, '<redstone_side>', redstoneSide)
    constants = string.gsub(constants, '<channel>', channel)

    local file = fs.open('constants.lua', 'w')
    file.write(constants)
    file.close()
end

local function deleteFiles(list)
    for index, fileName in ipairs(list) do
        if fs.exists(fileName) then fs.delete(fileName) end
    end
end

local function unpack()
    local contentDir = 'cc-mine-atm8/' .. computerType .. '/'
    local contentFiles = fs.list(contentDir)
    deleteFiles(contentFiles)

    local utilsDir = 'cc-mine-atm8/utils/'
    local utilFiles = fs.list(utilsDir)
    deleteFiles(utilFiles)
    
    for index, fileName in ipairs(contentFiles) do
        fs.copy(contentDir .. fileName, fileName)
    end
    for index, fileName in ipairs(utilFiles) do
        if not fs.exists(fileName) and fileName ~= 'install.lua' then
            fs.copy(utilsDir .. fileName, fileName)
        end
    end

    fs.delete('cc-mine-atm8/')

    writeConstants()
    createStartup()

    if not constants then os.loadAPI('constants.lua') end
    if not channelAPI then os.loadAPI('channelAPI.lua') end
    local channel = channelAPI.channelFromType(computerType, os.getComputerLabel(), constants.CHANNEL)
    channelAPI.registerChannel(channel)

    if not logAPI then os.loadAPI('logAPI.lua') end
    logAPI.log(string.format('Installing %s', computerType))
end

if fs.exists('constants.lua') then
    os.loadAPI('constants.lua')
    computerType = constants.COMPUTER_TYPE or computerType
end

if not computerType then computerType = chooseComputerType() end

if computerType == 'worker' then computerType = 'farm' end

unpack()
shell.run('reboot')
