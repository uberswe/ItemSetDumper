ItemSetDumper = {}

ItemSetDumper.name = "ItemSetDumper"
ItemSetDumper.savedData = {}

local function isempty(s)
    return s == nil or s == ''
end

function ItemSetDumper:Initialize()
    -- Do some init stuff
    ItemSetDumper.savedData = ZO_SavedVars:NewAccountWide('ItemSetDumperSavedVariables', 1, nil, systemDefault, nil, 'ItemSetDumper')

    -- wait 5 seconds or so before we begin dumping so we don't do it right when we load in
    zo_callLater(function()
        CHAT_ROUTER:AddSystemMessage("ItemSetDumper starting")

        for k in pairs(ItemSetDumper.savedData) do
            ItemSetDumper.savedData[k] = nil
        end

        local function GetNextItemSetCollectionIdIter(_, lastItemSetId)
            return GetNextItemSetCollectionId(lastItemSetId)
        end

        for itemSetId in GetNextItemSetCollectionIdIter do
            if itemSetId == nil then
                break
            end
            ItemSetDumper.ProcessItem(itemSetId, "collection")
        end

        -- That loop finds all the collection sets but we are missing crafted sets.

        for itemSetId = 46000, 250000, 1 do
            ItemSetDumper.ProcessItem(itemSetId, "crafted")
        end

        CHAT_ROUTER:AddSystemMessage("ItemSetDumper finished")
    end, 5500)
end

function ItemSetDumper.ProcessItem(itemSetId, type)
    if type == "collection" then
        if not ItemSetDumper.savedData[itemSetId] then
            ItemSetDumper.savedData[itemSetId] = {}
        end
        local itemSetCollectionCategoryId = GetItemSetCollectionCategoryId(itemSetId)
        local itemSetCollectionCategoryName = GetItemSetCollectionCategoryName(itemSetCollectionCategoryId)
        local itemSetCollectionParentCategoryID = GetItemSetCollectionCategoryParentId(itemSetCollectionCategoryId)
        local itemSetCollectionParentCategoryName = GetItemSetCollectionCategoryName(itemSetCollectionParentCategoryID)
        local numPieces = GetNumItemSetCollectionPieces(itemSetId)
        local pieceId, slot = GetItemSetCollectionPieceInfo(itemSetId, 1)
        local itemLink = GetItemSetCollectionPieceItemLink(pieceId, LINK_STYLE_DEFAULT, ITEM_TRAIT_TYPE_NONE)
        local armorType = GetItemLinkArmorType(itemLink)
        local hasSet, setName, numBonuses, numNormalEquipped, maxEquipped, setId, numPerfectedEquipped = GetItemLinkSetInfo(itemLink)
        ItemSetDumper.savedData[itemSetId]["pieces"] = numPieces
        ItemSetDumper.savedData[itemSetId]["itemLink"] = itemLink
        ItemSetDumper.savedData[itemSetId]["setName"] = setName
        ItemSetDumper.savedData[itemSetId]["numNormalEquipped"] = numNormalEquipped
        ItemSetDumper.savedData[itemSetId]["maxEquipped"] = maxEquipped
        ItemSetDumper.savedData[itemSetId]["setId"] = setId
        ItemSetDumper.savedData[itemSetId]["numPerfectedEquipped"] = numPerfectedEquipped
        ItemSetDumper.savedData[itemSetId]["hasSet"] = hasSet
        ItemSetDumper.savedData[itemSetId]["slot"] = slot
        ItemSetDumper.savedData[itemSetId]["categoryID"] = itemSetCollectionCategoryId
        ItemSetDumper.savedData[itemSetId]["categoryName"] = itemSetCollectionCategoryName
        ItemSetDumper.savedData[itemSetId]["parentCategoryID"] = itemSetCollectionParentCategoryID
        ItemSetDumper.savedData[itemSetId]["parentCategoryName"] = itemSetCollectionParentCategoryName
        if armorType == ARMORTYPE_HEAVY then
            ItemSetDumper.savedData[itemSetId]["armorType"] = "Heavy"
        elseif armorType == ARMORTYPE_MEDIUM then
            ItemSetDumper.savedData[itemSetId]["armorType"] = "Medium"
        elseif armorType == ARMORTYPE_LIGHT then
            ItemSetDumper.savedData[itemSetId]["armorType"] = "Light"
        end
        ItemSetDumper.savedData[itemSetId]["type"] = type

        if not ItemSetDumper.savedData[itemSetId]["bonuses"] then
            ItemSetDumper.savedData[itemSetId]["bonuses"] = {}
        end
        for bonusIndex = 1, numBonuses do
            local _, bonusDescription, _ = GetItemLinkSetBonusInfo(itemLink, false, bonusIndex)
            ItemSetDumper.savedData[itemSetId]["bonuses"][bonusIndex] = bonusDescription
        end
    elseif type == "crafted" then
        local itemLink = string.format("|H1:item:%d:%d:50:0:0:0:0:0:0:0:0:0:0:0:0:%d:%d:0:0:%d:0|h|h", itemSetId, 370, ITEMSTYLE_NONE, 1, 10000)
        local hasSet, setName, numBonuses, numNormalEquipped, maxEquipped, setId, numPerfectedEquipped = GetItemLinkSetInfo(itemLink)

        if not isempty(setName) and not ItemSetDumper.savedData[setId] then

            ItemSetDumper.savedData[setId] = {}
            ItemSetDumper.savedData[setId]["setName"] = setName
            ItemSetDumper.savedData[setId]["itemLink"] = itemLink
            ItemSetDumper.savedData[setId]["numNormalEquipped"] = numNormalEquipped
            ItemSetDumper.savedData[setId]["maxEquipped"] = maxEquipped
            ItemSetDumper.savedData[setId]["setId"] = setId
            ItemSetDumper.savedData[setId]["numPerfectedEquipped"] = numPerfectedEquipped
            ItemSetDumper.savedData[setId]["hasSet"] = hasSet
            ItemSetDumper.savedData[setId]["type"] = type

            if not ItemSetDumper.savedData[setId]["bonuses"] then
                ItemSetDumper.savedData[setId]["bonuses"] = {}
            end
            for bonusIndex = 1, numBonuses do
                local _, bonusDescription, _ = GetItemLinkSetBonusInfo(itemLink, false, bonusIndex)
                ItemSetDumper.savedData[setId]["bonuses"][bonusIndex] = bonusDescription
            end
        end
    end
end

function ItemSetDumper.OnAddOnLoaded(event, addonName)
    if addonName == ItemSetDumper.name then
        ItemSetDumper:Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(ItemSetDumper.name, EVENT_ADD_ON_LOADED, ItemSetDumper.OnAddOnLoaded)