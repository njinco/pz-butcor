require "TimedActions/ISBaseTimedAction"

ButcherCorpseB42Action = ISBaseTimedAction:derive("ButcherCorpseB42Action");
ButcherCorpseB42Action.soundDelay = 1

function ButcherCorpseB42Action:isValid()
    if self.corpseBody:getStaticMovingObjectIndex() < 0 then
        return false
    end
    return true
end

function ButcherCorpseB42Action:waitToStart()
    self.character:faceThisObject(self.corpseBody)
    return self.character:shouldBeTurning();
end

function ButcherCorpseB42Action:update()
    if self.soundTime + ButcherCorpseB42Action.soundDelay < getTimestamp() then
        self.soundTime = getTimestamp();

        -- play sound
        self.sound = self.character:getEmitter():playSound("SliceMeat");
        addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 10);

        -- create blood on environment
        addBloodSplat(self.corpseBody:getSquare(), ZombRand(15, 25));
        self.character:splatBlood(2.0, 1.0);

        -- add random blood to character, with scratch blood, no bites, only outer layer
        self.character:addBlood(nil, true, false, false);

        -- increase item blood level if using a weapon
        if self.usesWeapon then
            local itemBlood = self.butcherItem:getBloodLevel();
            if itemBlood <= 0.95 then
                self.butcherItem:setBloodLevel(itemBlood + 0.05);
                self.character:resetModel();
            elseif itemBlood <= 1 then
                self.butcherItem:setBloodLevel(1);
                self.character:resetModel();
            end
        end
    end

    self.corpse:setJobDelta(self:getJobDelta());
    self.character:faceThisObject(self.corpseBody);

    self.character:setMetabolicTarget(Metabolics.HeavyWork);
end

function ButcherCorpseB42Action:start()
    self.corpse:setJobType(getText("ContextMenu_ButcherCorpsesB42_Butcher_Corpse"));
    self.corpse:setJobDelta(0.0);
    self.character:SetVariable("LootPosition", "Low");
    self:setActionAnim("Loot");

    self.character:reportEvent("EventLootItem");
end

function ButcherCorpseB42Action:stop()
    if self.sound and self.sound ~= 0 and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound);
    end

    ISBaseTimedAction.stop(self);
    self.corpse:setJobDelta(0.0);
end

function ButcherCorpseB42Action:perform()
    self.corpse:setJobDelta(0.0);
    self.character:getInventory():setDrawDirty(true);

    local corpseSquare = self.corpseBody:getSquare();
    local args = {
        x = corpseSquare:getX(),
        y = corpseSquare:getY(),
        z = corpseSquare:getZ(),
        corpseIndex = self.corpseBody:getStaticMovingObjectIndex(),
    }

    if isClient() then
        sendClientCommand(self.character, "ButcherCorpsesB42", "ButcherCorpse", args)
    elseif ButcherCorpsesB42Util and ButcherCorpsesB42Util.butcherCorpse then
        ButcherCorpsesB42Util.butcherCorpse(self.character, args)
    end

    local pdata = getPlayerData(self.character:getPlayerNum());
    if pdata ~= nil then
        pdata.playerInventory:refreshBackpacks();
        pdata.lootInventory:refreshBackpacks();
    end

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ButcherCorpseB42Action:new(character, corpse, butcherItem, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.corpse = corpse:getItem();
    o.corpseBody = corpse;
    o.butcherItem = butcherItem;
    o.usesWeapon = instanceof(self.butcherItem, "HandWeapon")
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    o.forceProgressBar = true;
    o.soundTime = 0;

    return o
end
