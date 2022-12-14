
local lockpos = false
local insidePrompt = false
local guiEnabled = false
function openGui(sentLength,taskID,namesent,keepWeapon)
    if not keepWeapon then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    guiEnabled = true
    SendNUIMessage({runProgress = true, Length = sentLength, Task = taskID, name = namesent})
end
function updateGui(sentLength,taskID,namesent)
    SendNUIMessage({runUpdate = true, Length = sentLength, Task = taskID, name = namesent})
end
local activeTasks = {}
function closeGuiFail()
    guiEnabled = false
    SendNUIMessage({closeFail = true})
end
function closeGui()
    guiEnabled = false
    SendNUIMessage({closeProgress = true})
end


function closeNormalGui()
    guiEnabled = false
end

RegisterNUICallback('taskCancel', function(data, cb)
  closeGui()
  local taskIdentifier = data.tasknum
  activeTasks[taskIdentifier] = 2
end)

RegisterNUICallback('taskEnd', function(data, cb)
  closeNormalGui()
  
  local taskIdentifier = data.tasknum
  activeTasks[taskIdentifier] = 3
end)

local taskInProcess = false
function taskBar(length,name,runCheck,keepWeapon,vehicle,vehCheck)
    local playerPed = PlayerPedId()
    if taskInProcess then
        return 0
    end
 
    taskInProcess = true
    local taskIdentifier = "taskid" .. math.random(1000000)
    openGui(length,taskIdentifier,name,keepWeapon)
    activeTasks[taskIdentifier] = 1
    local maxcount = GetGameTimer() + length
    local curTime
    while activeTasks[taskIdentifier] == 1 do
        Citizen.Wait(1)
        curTime = GetGameTimer()
        if curTime > maxcount or not guiEnabled then
            activeTasks[taskIdentifier] = 2
        end
        DisableControlAction(0, 289, true)
        local fuck = 100 - (((maxcount - curTime) / length) * 100)
        fuck = math.min(100, fuck)
        updateGui(fuck,taskIdentifier,name)

        if IsControlJustPressed(0, 200) then
            closeGuiFail() 
        end

        if runCheck then
            if IsPedClimbing(PlayerPedId()) or IsPedJumping(PlayerPedId()) then
                SetPlayerControl(PlayerId(), 0, 0)
                local totaldone = math.ceil(100 - (((maxcount - curTime) / length) * 100))
                totaldone = math.min(100, totaldone)
                taskInProcess = false
                closeGuiFail()
                Citizen.Wait(1000)
                SetPlayerControl(PlayerId(), 1, 1)
                Citizen.Wait(1000)
                return totaldone
            end
        end

        if vehicle ~= nil and vehicle ~= 0 then
            local driverPed = GetPedInVehicleSeat(vehicle, -1)
            if driverPed ~= playerPed and vehCheck then
                SetPlayerControl(PlayerId(), 0, 0)
                local totaldone = math.ceil(100 - (((maxcount - curTime) / length) * 100))
                totaldone = math.min(100, totaldone)
                taskInProcess = false
                closeGuiFail()
                Citizen.Wait(1000)
                SetPlayerControl(PlayerId(), 1, 1)
                Citizen.Wait(1000)
                return totaldone
            end

            local model = GetEntityModel(playerVeh)
            if IsThisModelACar(model) or IsThisModelABike(model) or IsThisModelAQuadbike(model) then
                if IsEntityInAir(vehicle) then
                    Wait(1000)
                    if IsEntityInAir(vehicle) then
                        local totaldone = math.ceil(100 - (((maxcount - curTime) / length) * 100))
                        totaldone = math.min(100, totaldone)
                        taskInProcess = false
                        closeGuiFail()
                        Citizen.Wait(1000)
                        return totaldone
                    end
                end
            end
        end
    end

    local resultTask = activeTasks[taskIdentifier]
    if resultTask == 2 then
        local totaldone = math.ceil(100 - (((maxcount - curTime) / length) * 100))
        totaldone = math.min(100, totaldone)
        taskInProcess = false
        closeGuiFail()
        return totaldone
    else
        closeGui()
        taskInProcess = false
        EnableControlAction(0, 289, true)
        return 100
    end 
   
end

function CheckCancels()
    if IsPedRagdoll(PlayerPedId()) then
        return true
    end
    return false
end
RegisterNetEvent('hud:taskBar')
AddEventHandler('hud:taskBar', function(length,name)
    taskBar(length,name)
end)

RegisterNetEvent('hud:insidePrompt')
AddEventHandler('hud:insidePrompt', function(bool)
    insidePrompt = bool
end)

RegisterNetEvent('event:control:taskBar')
AddEventHandler('event:control:taskBar', function(useID)
    if useID == 1 and not insidePrompt then
        TriggerEvent("radioGui")
    elseif useID == 2 and not insidePrompt then
        TriggerEvent("stereoGui") 
    elseif useID == 3 and not insidePrompt then
        TriggerEvent("phoneGui") 
    elseif useID == 4 and guiEnabled then 
        closeGuiFail() 
    end
end)
