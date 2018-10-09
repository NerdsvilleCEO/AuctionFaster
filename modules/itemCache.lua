---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @class ItemCache
local ItemCache = AuctionFaster:NewModule('ItemCache');

function ItemCache:Enable()
	if AuctionFaster.db.auctionDb then
		-- upgrade db
		local upgradeNeeded = false;
		for key, val in pairs(AuctionFaster.db.auctionDb) do
			if val.auctions then
				upgradeNeeded = true;
				break;
			end
		end

		if upgradeNeeded then
			self:WipeItemCache();
		end
	end
end

local function isDateOlder(date1, date2)
	if date1.year < date2.year then
		return true;
	end

	if date1.month < date2.month then
		return true
	end

	if date1.day < date2.day then
		return true;
	end

	return false; -- same day
end


function ItemCache:RefreshHistoricalData(itemRecord, serverTime, auctions)
	---@type Pricing
	local Pricing = AuctionFaster:GetModule('Pricing');

	if not itemRecord.prices then
		itemRecord.prices = {};
	end

	-- we need to filter out the same items
	local filter = function(auction)
		return itemRecord.itemName == auction.name and itemRecord.itemId == auction.itemId;
	end

	local auctionInfo = Pricing:CalculateStatData(itemRecord, auctions, 1, 1, filter);
	auctionInfo.itemRecord = nil;
	auctionInfo.auctions = nil;
	auctionInfo.stackSize = nil;
	auctionInfo.scanTime = serverTime;


	local cacheLifetime = AuctionFaster.db.historical.keepDays * 24 * 60 * 60;
	local limit = serverTime - cacheLifetime;

	for i = #itemRecord.prices, 1, -1 do
		local historicalData = itemRecord.prices[i];

		if historicalData.scanTime < limit then
			-- remove old records
			tremove(itemRecord.prices, i);
		end
	end

	-- if there are no records, just insert and bail out
	if #itemRecord.prices == 0 then
		tinsert(itemRecord.prices, auctionInfo);
		return;
	end

	-- since it is impossible to perform future scans we can be sure that last record is newest
	local lastHistoricalData = itemRecord.prices[#itemRecord.prices];
	local lastDate = date('*t', lastHistoricalData.scanTime);
	local currentDate = date('*t', serverTime);

	if isDateOlder(lastDate, currentDate) then
		-- last date is older than today, we can safely insert new one
		tinsert(itemRecord.prices, auctionInfo);
	else
		-- same day, replace last record
		itemRecord.prices[#itemRecord.prices] = auctionInfo;
	end
end

function ItemCache:GetLastScanPrice(itemId, itemName)
	local itemRecord = self:GetItemFromCache(itemId, itemName);
	if not itemRecord then
		return nil;
	end

	return itemRecord.buy;
end

function ItemCache:GetItemFromCache(itemId, itemName)
	if not itemId or not itemName then
		return nil;
	end

	if AuctionFaster.db.auctionDb[itemId .. itemName] then
		return AuctionFaster.db.auctionDb[itemId .. itemName];
	else
		return nil;
	end
end

--- Puts a blank item in cache as template
function ItemCache:FindOrCreateCacheItem(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if AuctionFaster.db.auctionDb[cacheKey] then
		return AuctionFaster.db.auctionDb[cacheKey];
	end

	AuctionFaster.db.auctionDb[cacheKey] = {
		itemName     = itemName,
		itemId       = itemId,
		icon         = GetItemIcon(itemId),
		settings     = AuctionFaster:GetDefaultItemSettings(),
		bid          = nil,
		buy          = nil,
		prices       = {}
	};

	return AuctionFaster.db.auctionDb[cacheKey];
end

function ItemCache:UpdateItemSettingsInCache(cacheKey, settingName, settingValue)
	if not AuctionFaster.db.auctionDb[cacheKey] then
		AuctionFaster:Echo(3, 'Invalid cache key');
		return ;
	end

	AuctionFaster.db.auctionDb[cacheKey].settings[settingName] = settingValue;
end

function ItemCache:WipeItemCache()
	AuctionFaster.db.auctionDb = {};
end
