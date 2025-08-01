-- Configuration table is loaded as a global from config.lua
local CONFIG = _G.CONFIG

local function outputMessage(player, mess, tipo)
    return exports['[HS]Notify_System']:notify(player, mess, tipo)
end

function set_gps(player, x, y, z, element, id)
    local blip = createBlipAttachedTo(element, id or 41)
    setElementVisibleTo(blip, root, false)
    setElementVisibleTo(blip, player, true)
    return blip
end

local jobMarkers = {}
for _, start in ipairs(CONFIG.startPositions) do
    local m = createMarker(start.pos[1], start.pos[2], start.pos[3], "cylinder", start.size or 2.0, start.rgb[1], start.rgb[2], start.rgb[3], start.rgb[4] or 150)
    addEventHandler("onMarkerHit", m, function(hitElement)
        if getElementType(hitElement) == "player" then
            outputMessage(hitElement, "Digite /iniciar para escolher uma rota do Carro Forte", "info")
        end
    end)
    table.insert(jobMarkers, m)
end

local routes = CONFIG.routes

local function buildClientRoutes()
    local list = {}
    for _, route in ipairs(routes) do
        local total = 0
        for _, m in ipairs(route.markers) do
            if m.recompensa then
                total = total + (m.recompensa[2] or 0)
            end
        end
        table.insert(list, {name = route.name, reward = total})
    end
    return list
end

addCommandHandler("iniciar", function(player)
    triggerClientEvent(player, "carroforte:openPanel", resourceRoot, buildClientRoutes())
end)

local playerData = {}

local function createDeliveryMarker(player, markerData)
    local data = playerData[player]
    local drop = markerData.dropPos or markerData.pos
    local mark = createMarker(drop[1], drop[2], drop[3], "checkpoint", 2, 255, 255, 0, 150)
    data.deliveryMarker = mark
    exports['[HS]Target']:setTarget(player, {Vector3(drop[1], drop[2], drop[3])}, {title = 'Marcação', hex = '#FFFFFF'})
    local function onDeliver(hit)
        if hit ~= player then return end
        removeEventHandler("onMarkerHit", mark, onDeliver)
        destroyElement(mark)
        setElementFrozen(player, true)
        outputMessage(player, "Entregando malote...", "info")
        setTimer(function()
            if not playerData[player] then return end
            setElementFrozen(player, false)
            local recompensa = markerData.recompensa or {0,0}
            local valor = math.random(recompensa[1] or 0, recompensa[2] or 0)
            givePlayerMoney(player, valor)
            outputMessage(player, "Malote entregue! Você recebeu $"..valor..". Volte ao carro forte.", "success")
            data.step = data.step + 1
            createNextMarker(player)
        end, 5000, 1)
    end
    addEventHandler("onMarkerHit", mark, onDeliver)
end

local function createPickMarker(player, markerData)
    local data = playerData[player]
    local vx, vy, vz = getElementPosition(data.vehicle)
    local _, _, rz = getElementRotation(data.vehicle)
    local bx = vx - math.cos(math.rad(rz)) * 4
    local by = vy - math.sin(math.rad(rz)) * 4
    local pick = createMarker(bx, by, vz, "cylinder", 1.5, 0, 0, 255, 150)
    data.pickMarker = pick
    exports['[HS]Target']:setTarget(player, {Vector3(bx, by, vz)}, {title = 'Marcação', hex = '#FFFFFF'})
    local function onPickHit(hit)
        if hit ~= player then return end
        outputMessage(player, "Pressione E para pegar a maleta", "info")
        local function onKey()
            unbindKey(player, "e", "down", onKey)
            if isElement(pick) then destroyElement(pick) end
            removeEventHandler("onMarkerHit", pick, onPickHit)
            outputMessage(player, "Leve a maleta até o ponto indicado", "info")
            createDeliveryMarker(player, markerData)
        end
        bindKey(player, "e", "down", onKey)
    end
    addEventHandler("onMarkerHit", pick, onPickHit)
end

function createNextMarker(player)
    local data = playerData[player]
    local route = data.route
    local step = data.step
    local markerData = route.markers[step]
    if not markerData then
        outputMessage(player, "Todas as entregas foram concluídas! Vá ao ponto final e digite /finalrota", "info")
        if isElement(data.blip) then destroyElement(data.blip) end
        local finish = CONFIG.finalPosition or CONFIG.startPositions[1].pos
        local mark = createMarker(finish[1], finish[2], finish[3], "checkpoint", 5, 255, 0, 0, 150)
        local blip = set_gps(player, finish[1], finish[2], finish[3], mark, 41)
        data.finishMarker = mark
        data.finalBlip = blip
        data.finished = true
        exports['[HS]Target']:setTarget(player, {Vector3(finish[1], finish[2], finish[3])}, {title = 'Marcação', hex = '#FFFFFF'})
        addEventHandler("onMarkerHit", mark, function(hit)
            if hit == player then
                outputMessage(player, "Digite /finalrota para encerrar a rota", "info")
            end
        end)
        return
    end

    local mark = createMarker(markerData.pos[1], markerData.pos[2], markerData.pos[3], "checkpoint", 5, 255, 0, 0, 150)
    local blip = set_gps(player, markerData.pos[1], markerData.pos[2], markerData.pos[3], mark, 41)
    data.marker = mark
    data.blip = blip
    exports['[HS]Target']:setTarget(player, {Vector3(markerData.pos[1], markerData.pos[2], markerData.pos[3])}, {title = 'Marcação', hex = '#FFFFFF'})

    data.handler = function(hitElement)
        if hitElement == player or hitElement == data.vehicle then
            removeEventHandler("onMarkerHit", mark, data.handler)
            destroyElement(mark)
            if isElement(blip) then destroyElement(blip) end
            outputMessage(player, "Desça do veículo e pegue o malote atrás do carro forte.", "info")
            createPickMarker(player, markerData)
        end
    end
    addEventHandler("onMarkerHit", mark, data.handler)
end

addEvent("carroforte:startRoute", true)
addEventHandler("carroforte:startRoute", root, function(index)
    local player = client
    local route = routes[index]
    if not route then return end

    local veh = getElementData(player, "carroforteVehicle")
    if isElement(veh) then destroyElement(veh) end

    local spawn = route.vehicleSpawn
    veh = createVehicle(427, spawn[1], spawn[2], spawn[3], 0, 0, spawn[4] or 0)
    warpPedIntoVehicle(player, veh)

    setElementData(player, "Emprego", "CarroForte")
    setElementData(player, "carroforteVehicle", veh)

    playerData[player] = {route = route, step = 1, vehicle = veh}
    createNextMarker(player)
end)

addCommandHandler("finalrota", function(player)
    local data = playerData[player]
    if not data or not data.finished then
        outputMessage(player, "Você ainda não concluiu todas as entregas.", "error")
        return
    end
    if not data.finishMarker or not isElementWithinMarker(player, data.finishMarker) then
        outputMessage(player, "Vá até o ponto final para finalizar a rota.", "error")
        return
    end
    if isElement(data.vehicle) then destroyElement(data.vehicle) end
    if isElement(data.finalBlip) then destroyElement(data.finalBlip) end
    if isElement(data.finishMarker) then destroyElement(data.finishMarker) end
    playerData[player] = nil
    setElementData(player, "Emprego", nil)
    outputMessage(player, "Rota finalizada!", "success")
end)
