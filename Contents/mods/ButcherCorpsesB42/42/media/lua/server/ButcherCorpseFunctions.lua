ButcherCorpsesB42Util = ButcherCorpsesB42Util or {}

local TOOL_TYPES = {
    MeatCleaver = true,
    HandAxe = true,
    Axe = true,
    WoodAxe = true,
}

local TOOL_TAGS = {
    SharpKnife = true,
    Saw = true,
}

local RESULT_FULL_TYPE = "ButcherCorpsesB42.Fleshofcorpse"
local RESULT_COUNT = 10

local function itemHasTag(item, tag)
    if not item or not tag then
        return false
    end
    if item.hasTag and item:hasTag(tag) then
        return true
    end
    local tags = item.getTags and item:getTags() or nil
    return tags and tags:contains(tag) or false
end

local function isButcherTool(item)
    if not item or item:isBroken() then
        return false
    end
    if TOOL_TYPES[item:getType()] or TOOL_TYPES[item:getFullType()] then
        return true
    end
    for tag in pairs(TOOL_TAGS) do
        if itemHasTag(item, tag) then
            return true
        end
    end
    return false
end

local function hasButcherTool(player)
    if not player then
        return false
    end
    return player:getInventory():getFirstEvalRecurse(isButcherTool) ~= nil
end

local function getCorpseFromSquare(square, corpseIndex)
    if not square then
        return nil
    end
    local staticMovingObjects = square:getStaticMovingObjects()
    if not staticMovingObjects then
        return nil
    end
    for i=0, staticMovingObjects:size()-1 do
        local staticMovingObject = staticMovingObjects:get(i)
        if instanceof(staticMovingObject, "IsoDeadBody") then
            if corpseIndex == nil or corpseIndex < 0 or staticMovingObject:getStaticMovingObjectIndex() == corpseIndex then
                return staticMovingObject
            end
        end
    end
    return nil
end

local function getButcherSquare(args)
    if not args or not args.x or not args.y or args.z == nil then
        return nil
    end
    return getCell():getGridSquare(args.x, args.y, args.z)
end

local function isPlayerCloseEnough(player, square)
    if not player or not square then
        return false
    end
    local dx = math.abs(player:getX() - square:getX())
    local dy = math.abs(player:getY() - square:getY())
    local dz = math.abs(player:getZ() - square:getZ())
    return dx <= 2 and dy <= 2 and dz < 1
end

local function freshenItem(item)
    if item and item.setAge then
        item:setAge(0)
    end
end

local function addResultItem(player, square, fullType, dropOnGround)
    local item = nil
    if dropOnGround then
        item = square:AddWorldInventoryItem(fullType, 0, 0, 0)
        freshenItem(item)
    else
        item = player:getInventory():AddItem(fullType)
        freshenItem(item)
        if item and sendAddItemToContainer then
            sendAddItemToContainer(player:getInventory(), item)
        end
    end
end

ButcherCorpsesB42Util.butcherCorpse = function(player, args)
    local square = getButcherSquare(args)
    local corpse = getCorpseFromSquare(square, args and args.corpseIndex or nil)
    if not square or not corpse or not isPlayerCloseEnough(player, square) or not hasButcherTool(player) then
        return
    end

    local dropOnGround = not SandboxVars.ButcherCorpsesB42 or SandboxVars.ButcherCorpsesB42.DropMeatOnGround
    for i=1, RESULT_COUNT do
        addResultItem(player, square, RESULT_FULL_TYPE, dropOnGround)
    end

    square:removeCorpse(corpse, false)
end

local function onClientCommand(module, command, player, args)
    if module == "ButcherCorpsesB42" and command == "ButcherCorpse" then
        ButcherCorpsesB42Util.butcherCorpse(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
