ButcherCorpsesB42Util = ButcherCorpsesB42Util or {};

ButcherCorpsesB42Util.onCreate_getFreshResult = function (items, result, player)
    result:setAge(0);
end

ButcherCorpsesB42Util.OnEat_CorpseFlesh = function (food, player, percent)
    local effectOnEat = SandboxVars.ButcherCorpsesB42.EffectOnEat or 3
    ButcherCorpsesB42Util.OnEat_CorpseFlesh_Effect(effectOnEat, percent * food:getActualWeight(), player)
end
 
ButcherCorpsesB42Util.OnEat_CookedCorpseFlesh = function (food, player, percent)
    local effectOnEatCooked = SandboxVars.ButcherCorpsesB42.EffectOnEatCooked or 1
    ButcherCorpsesB42Util.OnEat_CorpseFlesh_Effect(effectOnEatCooked, percent * food:getActualWeight(), player)
end

-- setting 1 = no effect | 2 = food sick | 3 = infection | 4 = both
ButcherCorpsesB42Util.OnEat_CorpseFlesh_Effect = function (setting, amount, player)
    local bodyDamage = player:getBodyDamage();

    if setting == 2 or setting == 4 then
        -- add sickness level based on amount eaten. Eating one full flesh will result in +100% sickness.
        local sickness = bodyDamage:getFoodSicknessLevel() + amount * 100
        bodyDamage:setFoodSicknessLevel(sickness);
    end

    if setting == 3 or setting == 4 then
        bodyDamage:setInfected(true);
    end
end


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

local function itemMatchesRecipeTool(item, recipeTool)
    if not item or not recipeTool then
        return false
    end
    if recipeTool == item:getFullType() or recipeTool == item:getType() then
        return true
    end
    if recipeTool == "SharpKnife" or recipeTool == "[Recipe.GetItemTypes.SharpKnife]" then
        return itemHasTag(item, "SharpKnife")
    end
    if recipeTool == "Saw" or recipeTool == "[Recipe.GetItemTypes.Saw]" then
        return itemHasTag(item, "Saw")
    end
    return false
end

local function isButcherToolForRecipe(item, recipe)
    if not item or item:isBroken() or not recipe then
        return false
    end
    for i=0, recipe:getSource():size()-1 do
        local source = recipe:getSource():get(i)
        if source:isKeep() then
            local recipeTools = source:getItems()
            for j=0, recipeTools:size()-1 do
                if itemMatchesRecipeTool(item, recipeTools:get(j)) then
                    return true
                end
            end
        end
    end
    return false
end

local function hasButcherTool(player, recipe)
    if not player or not recipe then
        return false
    end
    return player:getInventory():getFirstEvalRecurse(function(item)
        return isButcherToolForRecipe(item, recipe)
    end) ~= nil
end

local function getButcherRecipe()
    return getScriptManager():getRecipe("ButcherCorpsesB42.ButcherCorpsesB42 Butcher Corpse")
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
    local recipe = getButcherRecipe()
    local square = getButcherSquare(args)
    local corpse = getCorpseFromSquare(square, args and args.corpseIndex or nil)
    if not recipe or not square or not corpse or not isPlayerCloseEnough(player, square) or not hasButcherTool(player, recipe) then
        return
    end

    local result = recipe:getResult()
    if not result then
        return
    end

    local dropOnGround = SandboxVars.ButcherCorpsesB42.DropMeatOnGround
    for i=1, result:getCount() do
        addResultItem(player, square, result:getFullType(), dropOnGround)
    end

    square:removeCorpse(corpse, false)
end

local function onClientCommand(module, command, player, args)
    if module == "ButcherCorpsesB42" and command == "ButcherCorpse" then
        ButcherCorpsesB42Util.butcherCorpse(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
