local CollectPrompt
local active = false
local oldBush = {}
local bush
local itemSet
local is_prompt_active = false
local pickup_anim_name = "mech_pickup@plant@berries"
local collect_prompt_is_enabled = false

local Bushgroup = GetRandomIntInRange(0, 0xffffff)

function createPromptGroup()
    Citizen.CreateThread(function()
        local str = Config.Language.prompt
        CollectPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(CollectPrompt, Config.SearchKey)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(CollectPrompt, str)
        PromptSetEnabled(CollectPrompt, true)
        PromptSetVisible(CollectPrompt, true)
        PromptSetStandardizedHoldMode(CollectPrompt, GetHashKey("MEDIUM_TIMED_EVENT"))
        PromptSetGroup(CollectPrompt, Bushgroup)
        PromptRegisterEnd(CollectPrompt)
    end)
end

function initializeItemSet()
    itemSet = CreateItemset(true)
end

---@param player_ped_id number @Optional
---@return boolean
isPlayerValid = function(player_ped_id)

    player_ped_id = player_ped_id or PlayerPedId()

    if IsPedOnMount(player_ped_id) then
        return false
    end

    if IsPedInAnyVehicle(player_ped_id) then
        return false
    end

    if IsPedDeadOrDying(player_ped_id) then
        return false
    end

    return true
end

---@param _bush table<number>
---@return boolean
function isBushChopped(_bush)
    return oldBush[tostring(_bush)] == true
end

---@param _bush table<number>
function setBushChopped(_bush)
    oldBush[tostring(_bush)] = true
end

Citizen.CreateThread(function()

    createPromptGroup()

    initializeItemSet()

    while true do

        local player_ped_id = PlayerPedId()

        if isPlayerValid(player_ped_id) then
            bush = GetClosestBush()

            if isBushChopped(_bush) then
                bush = nil
            end
        else
            bush = nil
        end

        if bush ~= nil then
            startPrompts()
        else
            stopPrompts()
        end

        Citizen.Wait(500)
    end
end)

function stopPrompts()
    is_prompt_active = false
end

function startPrompts()

    if is_prompt_active then
        return
    end

    is_prompt_active = true

    local player_ped_id = PlayerPedId()

    Citizen.CreateThread(function()

        while bush ~= nil and is_prompt_active do

            checkPrompts(player_ped_id)

            Citizen.Wait(0)
        end
    end)
end

function enableCollectPrompt()

    if collect_prompt_is_enabled then
        return
    end

    collect_prompt_is_enabled = true

    PromptSetEnabled(CollectPrompt, true)
end

function disableCollectPrompt()

    if not collect_prompt_is_enabled then
        return
    end

    collect_prompt_is_enabled = false

    PromptSetEnabled(CollectPrompt, false)
end

---@param player_ped_id number @Optional
function checkPrompts(player_ped_id)

    player_ped_id = player_ped_id or PlayerPedId()

    if active == false then
        local BushgroupName = CreateVarString(10, 'LITERAL_STRING', Config.Language.promptsub)
        PromptSetActiveGroupThisFrame(Bushgroup, BushgroupName)
    end

    if IsPedStopped(player_ped_id) then

        enableCollectPrompt()

        if PromptHasHoldModeCompleted(CollectPrompt) then
            stopPrompts()
            SetCurrentPedWeapon(player_ped_id, GetHashKey('WEAPON_UNARMED'), true)
            Wait(50)
            active = true
            setBushChopped(bush)
            goCollect()
        end
    else
        disableCollectPrompt()
    end
end

---@param _anim_name string
function loadAnimation(_anim_name)
    RequestAnimDict(_anim_name)
    while not HasAnimDictLoaded(_anim_name) do
        Wait(50)
    end
end

---@param player_ped_id number @Optional
function lockPlayer(player_ped_id)
    player_ped_id = player_ped_id or PlayerPedId()
    FreezeEntityPosition(player_ped_id, true)
end

---@param player_ped_id number @Optional
function playPickAnimation(player_ped_id)

    player_ped_id = player_ped_id or PlayerPedId()

    loadAnimation(pickup_anim_name)

    TaskPlayAnim(player_ped_id, pickup_anim_name, "enter_lf", 8.0, -0.5, -1, 0, 0, true, 0, false, 0, false)
    Wait(800)

    TaskPlayAnim(player_ped_id, pickup_anim_name, "base", 8.0, -0.5, -1, 0, 0, true, 0, false, 0, false)
    Wait(2000)

    TaskPlayAnim(player_ped_id, pickup_anim_name, "exit_stow", 8.0, -0.5, -1, 0, 0, true, 0, false, 0, false)
    Wait(1000)
end

---@param player_ped_id number @Optional
---@param wait_in_ms number @Optional
function releasePlayer(player_ped_id, wait_in_ms)

    player_ped_id = player_ped_id or PlayerPedId()

    ClearPedTasks(player_ped_id)

    if wait_in_ms then
        Wait(wait_in_ms)
    end

    FreezeEntityPosition(player_ped_id, false)
end

function goCollect()
    local player_ped_id = PlayerPedId()
    if not isPlayerValid(player_ped_id) then
        return
    end
    Wait(50)
    lockPlayer(player_ped_id)
    playPickAnimation(player_ped_id)
    if (math.random(1, 100) < 50) then
        TriggerServerEvent('vorp_picking:addItem')
        active = false
        releasePlayer(player_ped_id, 200)
    else
        TriggerEvent('vorp:NotifyLeft', Config.Language.notifytitel, Config.Language.notfound, "BLIPS", "blip_destroy", 2000, "COLOR_RED")
        active = false
        releasePlayer(player_ped_id, 200)
    end
end

function GetClosestBush()

    _clearItemSet(itemSet)

    local playerped = PlayerPedId()
    local size = Citizen.InvokeNative(0x59B57C4B06531E1E, GetEntityCoords(playerped), 1.5, itemSet, 3, Citizen.ResultAsInteger())

    if not IsItemsetValid(itemSet) then
        return nil
    end

    local found_entity

    if size > 0 then
        for index = 0, size - 1 do
            local entity = GetIndexedItemInItemset(index, itemSet)
            local model_hash = GetEntityModel(entity)
            if (model_hash == 477619010 or model_hash == 85102137 or model_hash == -1707502213) and not oldBush[tostring(entity)] then
                found_entity = entity
                break
            end
        end
    end

    _clearItemSet(itemSet)

    return found_entity
end

---@param _item_set table
function _clearItemSet(_item_set)
    Citizen.InvokeNative(0x20A4BF0E09BEE146, _item_set)
end

AddEventHandler('onResourceStop', function(resourceName)

    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if IsItemsetValid(itemSet) then
        DestroyItemset(itemSet)
    end

    stopPrompts()
    releasePlayer()
end)