require "TimedActions/ISBaseTimedAction"

ButcherCorpseAction = ISBaseTimedAction:derive("ButcherCorpseAction");
ButcherCorpseAction.soundDelay = 1

function ButcherCorpseAction:isValid()
    if self.corpseBody:getStaticMovingObjectIndex() < 0 then
        return false
    end
    return true
end

function ButcherCorpseAction:waitToStart()
    self.character:faceThisObject(self.corpseBody)
    return self.character:shouldBeTurning();
end

function ButcherCorpseAction:update()
    if self.soundTime + ButcherCorpseAction.soundDelay < getTimestamp() then
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

function ButcherCorpseAction:start()
    self.corpse:setJobType(getText("ContextMenu_ButCor_Butcher_Corpse"));
    self.corpse:setJobDelta(0.0);
    self.character:SetVariable("LootPosition", "Low");
    self:setActionAnim("Loot");

    self.character:reportEvent("EventLootItem");
end

function ButcherCorpseAction:stop()
    if self.sound and self.sound ~= 0 and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound);
    end

    ISBaseTimedAction.stop(self);
    self.corpse:setJobDelta(0.0);
end

function ButcherCorpseAction:perform()
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
        sendClientCommand(self.character, "ButCor", "ButcherCorpse", args)
    elseif ButcherCorpsesUtil and ButcherCorpsesUtil.butcherCorpse then
        ButcherCorpsesUtil.butcherCorpse(self.character, args)
    end

    local pdata = getPlayerData(self.character:getPlayerNum());
    if pdata ~= nil then
        pdata.playerInventory:refreshBackpacks();
        pdata.lootInventory:refreshBackpacks();
    end

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ButcherCorpseAction:new(character, corpse, butcherItem, time)
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
