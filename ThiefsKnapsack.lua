ThiefsKnapsack = {
   name = "ThiefsKnapsack",
   version = "1",

   defaults = {
      anchor = TOPLEFT,
      x = 0,
      y = 0,
      scale = 1,
      border = 10,
      hidden = false,
      snapCenter = true,

      compactMode = false,

      show = {
         Value = true,
         Count = true,
         Legerdemain = false,
         SellsLeft = true,
         LaundersLeft = true,
         FenceTimer = false,
         BountyTimer = false,
         Bounty = false,
         Recipes = false,
         Average = false,
         Quality = true,
         Estimate = true,
         Background = true,
      },
      dshow = {
         Bounty = true,
         BountyTimer = true,
      },
      showBars = true,

      options = {
         nojunk = true,
         sep_recipe = false,
         hide_on_menu = false,
      },

      bounty_start = 0,
   },

   delaying = false,
   quality = { [0] = 0, 0, 0, 0, 0, 0 },

   legerdemain = 0,

   dshow = { },

   last_fence_d = 0,
}
local TK = ThiefsKnapsack

local WM = WINDOW_MANAGER

local util = LibStub:GetLibrary("util.rpav-1")
local prnd = util.prnd

local function zeroStats()
   TK.itemCount = 0
   TK.totalValue = 0
   TK.totalQual = 0
   TK.recipeCount = 0

   for i = 0,5 do
      TK.quality[i] = 0
   end
end

local function isRecipe(itemtype)
   return ((itemtype == ITEMTYPE_RECIPE) or (itemtype == ITEMTYPE_RACIAL_STYLE_MOTIF))
end

local function incrGoods(count, quality, itemtype, isJunk, value)
   if(not (TK.saved.options.nojunk and isJunk)) then
      if(not (TK.saved.options.sep_recipe and isRecipe(itemtype))) then
         TK.itemCount        = math.max(0, TK.itemCount + count)
         TK.totalQual        = math.max(0, TK.totalQual + (quality * count))
         TK.totalValue       = math.max(0, TK.totalValue + (value * count))
         TK.quality[quality] = math.max(0, (TK.quality[quality] or 0) + count)
      end

      if(isRecipe(itemtype)) then
         TK.recipeCount = math.max(0, TK.recipeCount + count)
      end
   end
end

local function incrGoodsFromSlot(slot, neg)
   neg = neg or 1
   incrGoods(slot.stackCount * neg, slot.quality, slot.itemType, slot.isJunk, slot.sellPrice)
end

function TK:CalcBagGoods()
   if(TK.delaying) then return; end

   zeroStats()

   local slots = PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK].slots
   for i,slot in pairs(slots) do
      if(type(i) == "number") then
         if(slot.stolen) then
            incrGoodsFromSlot(slot)
         end
      end
   end
end

function TK:DelayedCalcGoods()
   if(TK.delaying) then return end

   TK.delaying = true
   EVENT_MANAGER:RegisterForUpdate(TK.name.."DelayedCalc", 250,
                                   function()
                                      EVENT_MANAGER:UnregisterForUpdate(TK.name.."DelayedCalc")
                                      TK.delaying = false
                                      TK:CalcBagGoods()
                                      TK:UpdateDisplay()
   end)
end

function TK:SavePosition()
   local w = TK.window
   local a = TK.saved.anchor
   local x, y

   y = w:GetTop()

   if(a == RIGHT or a == TOPRIGHT) then
      x = w:GetRight()
   else
      x = w:GetLeft()
   end

   if(TK.saved.snapCenter and a == TOP) then
      x = 0
      w:ClearAnchors()
      w:SetAnchor(TK.saved.anchor, GuiRoot, TK.saved.anchor, x, y)
   end

   TK.saved.x = x
   TK.saved.y = y
end

local function updateLegerdemainText()
   if(TK.legerdemain == 0) then
      TK.window.l_legerdemain:SetText("??")
      return
   end

   local name, rank = GetSkillLineInfo(SKILL_TYPE_WORLD, TK.legerdemain)
   local lrxp, nrxp, cxp = GetSkillLineXPInfo(SKILL_TYPE_WORLD, TK.legerdemain)
   local str = util.str("(|cEECA2A", rank, "|r) ", cxp-lrxp, "/", nrxp-lrxp)
   TK.window.l_legerdemain:SetText(str)
end

function TK:UpdateDisplay()
   local w = TK.window
   local sellsLeft = FENCE_MANAGER.totalSells - FENCE_MANAGER.sellsUsed
   local laundersLeft = FENCE_MANAGER.totalLaunders - FENCE_MANAGER.laundersUsed

   if(TK.saved.show.LaundersLeft) then
      w.l_sellsleft:SetText(string.format("%d/%d", sellsLeft, laundersLeft))
   else
      w.l_sellsleft:SetText(string.format("%d", sellsLeft))
   end

   w.l_value:SetText(string.format("%d", TK.totalValue))
   w.l_count:SetText(string.format("%d", TK.itemCount))
   w.l_recipes:SetText(string.format("%d", TK.recipeCount))
   w.l_bounty:SetText(string.format("%d", GetReducedBountyPayoffAmount()))

   updateLegerdemainText()

   if(TK.itemCount < 1) then
      w.l_average:SetText(string.format("%.2f", 0))
      w.l_estimate:SetText(string.format("%d", 0))
      w.l_quality:SetText(string.format("%.2f", 0))

      for i = 0,5 do
         w.bar[i]:SetHeight(0)
      end
   else
      w.l_average:SetText(string.format("%.2f", TK.totalValue/TK.itemCount))
      w.l_estimate:SetText(string.format("%d",
                                         math.floor(TK.totalValue/TK.itemCount) * sellsLeft))
      w.l_quality:SetText(string.format("%.2f", TK.totalQual/TK.itemCount))

      for i = 0,5 do
         if(TK.quality[i] and TK.quality[i] > 0) then
            local percent = TK.quality[i] / TK.itemCount
            -- No LabelControl:GetMaxAscender() :/
            w.bar[i]:SetHeight(math.max(1, percent * 14))
         else
            w.bar[i]:SetHeight(0)
         end
      end
   end
end

function TK:toggle()
   local w = TK.window

   if(w:IsHidden()) then
      TK:CalcBagGoods()
      TK:UpdateDisplay()
   end

   TK.saved.hidden = not w:IsHidden()
   w:SetHidden(not w:IsHidden())
end

local function onLayerChange(evc, index, active)
   if(not TK.saved.options.hide_on_menu) then return end

   -- Is there some CONSTANT for this?
   TK.window:SetHidden((active ~= 2))
end

local function onSlotUpdate(evCode, bagId, slotId, isNew, isc, reason)
   if(TK.delaying) then return end
   if(bagId ~= INVENTORY_BACKPACK) then return end
   if(isNew) then return end

   local slot = PLAYER_INVENTORY.inventories[bagId].slots[slotId]
   if(not slot or not slot.stolen) then return end

   -- All right, we've got some bag management going on, so don't
   -- update every time.
   TK:DelayedCalcGoods()
end

local function onLoot(evc, receiver, name, count, isc, itemtype, isself, ispicked)
   if(not isself) then return end

   -- No way to tell if the item was stolen!  IsItemLinkStolen()
   -- doesn't return true.  Doing this in onSlotUpdate() means we
   -- can't tell if it's being added to a stack, or splitting a stack.
   TK:DelayedCalcGoods()
end

local function onLaunder(evc, res)
   if(res ~= ITEM_LAUNDER_RESULT_SUCCESS) then return end

   -- Likewise, no apparent way to get what was laundered, etc
   TK:DelayedCalcGoods()
end

local function onFence(status)
   if(status) then
      -- See event reg below for note
      TK.isFencing = true
   elseif(TK.isFencing) then
      TK.isFencing = false
      TK:UpdateDisplay()
   end
end

local function onApprehended(evc)
   zeroStats()
   TK:UpdateDisplay()
end

local function onSold(evc, il, count, money)
   if(not TK.isFencing) then return end

   -- There's no way to tell if the itemlink is junk,
   -- so we can't tell whether to (un)track it or not
   TK:DelayedCalcGoods()
end

local function onRemoved(bagId, slotIndex, slot)
   if(not slot.stolen or TK.isFencing) then return end

   incrGoodsFromSlot(slot, -1)
   TK:UpdateDisplay()
end

local function resetBountyWatch()
   TK.bounty = GetBounty()

   if(TK.bounty == 0) then
      TK.saved.bounty_start = 0
      TK.window.l_bountytimer:SetText("00:00")
   else
      TK.saved.bounty_start = GetTimeStamp()
   end
end

local function bountyCheck(now, drift)
   if(TK.saved.bounty_start == 0) then return end

   local bounty = GetBounty()

   if(drift ~= 0) then
      TK.saved.bounty_start = TK.saved.bounty_start + drift
   end

   if(bounty ~= TK.bounty) then
      resetBountyWatch()
      TK:UpdateDisplay()
      TK:DynamicBountyCheck()
   end

   local estimate = ((bounty / 5) * 180) - (now - TK.saved.bounty_start)

   if(estimate < 0) then
      TK.window.l_bountytimer:SetText("00:00")
   else
      local timestr = FormatTimeSeconds(estimate, TIME_FORMAT_STYLE_COLONS,
                                        TIME_FORMAT_DIRECTION_DESCENDING,
                                        TIME_FORMAT_PRECISION_SECONDS)
      TK.window.l_bountytimer:SetText(timestr)
   end
end

function TK:DynamicBountyCheck()
   if(not TK.saved.dshow.Bounty) then return; end

   value = GetBounty()

   if(value == 0) then
      TK.dshow.Bounty = false
      TK.dshow.BountyTimer = false
   else
      TK.dshow.Bounty = true
      TK.dshow.BountyTimer = true
   end

   TK:UpdateDisplay()
   TK:UpdateControls()
end

local function onBountyChange(evc, old, new)
   resetBountyWatch()
   if((new == 0) or (old == 0 and new ~= 0)) then
      TK:DynamicBountyCheck()
   end
end

function TK:TimeToFenceReset(t)
   -- Seems to reset at 3am utc
   local fence_start = 10800

   t = t or GetTimeStamp()

   local one_day = (24*60*60)
   local d = one_day - ((t - fence_start) % one_day)

   local timestr =
      FormatTimeSeconds(d, 
                        TIME_FORMAT_STYLE_COLONS,
                        TIME_FORMAT_DIRECTION_DESCENDING,
                        TIME_FORMAT_PRECISION_SECONDS)   

   return timestr, d
end
SLASH_COMMANDS["/tk.fencetime"] = function()
   local str = TK:TimeToFenceReset()
   prnd("Fence will reset in ", str)
end

local function fenceCheck(now, drift)
   local reset, d = TK:TimeToFenceReset(now)
   TK.window.l_fencetimer:SetText(reset)

   if(d > TK.last_fence_d) then
      GetFenceSellTransactionInfo()
      GetFenceLaunderTransactionInfo()
      TK:UpdateDisplay()
   end

   TK.last_fence_d = d
end

local function onTick()
   local now = GetTimeStamp()
   local drift = (now - TK.lasttick - 1)

   bountyCheck(now, drift)
   fenceCheck(now, drift)

   TK.lasttick = now
end

local function setupTimer()
   TK.lasttick = GetTimeStamp()
   TK.bounty = GetBounty()
   TK:DynamicBountyCheck()

   TK.last_fence_count = FENCE_MANAGER.totalSells - FENCE_MANAGER.sellsUsed
   EVENT_MANAGER:RegisterForUpdate(TK.name.."OnTick", 1000, onTick)
end


-- this is idiotic
local function findLegerdemain()
   local nsl = GetNumSkillLines(SKILL_TYPE_WORLD)
   for i = 1,nsl do
      local name, rank = GetSkillLineInfo(SKILL_TYPE_WORLD, i)
      -- There has _got_ to be a less hacktastic way to get this
      if(name == "Legerdemain" or name == "Lug und Trug^N" or name == "Escroquerie") then
         TK.legerdemain = i
         break
      end
   end
end

local function onSkillXpUpdate(evc, skillType, skillIndex, reason, rank, prev, cur)
   if(TK.legerdemain == 0) then return end

   if(skillType == SKILL_TYPE_WORLD and skillIndex == TK.legerdemain) then
      updateLegerdemainText()
   end
end

local function onSkillLineAdded(evc, skillType, skillIndex)
   findLegerdemain()
end

local function setupXpWatch()
   findLegerdemain()

   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_SKILL_XP_UPDATE, onSkillXpUpdate)
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_SKILL_LINE_ADDED, onSkillLineAdded)
end

local function pfx(x) return TK.name.."Window"..(x or "") end

local function make_control(name, rel, lrel, offset, str, dds)
   local w = TK.window

   local make_icon = function(name, rel, offset, dds)
      local icon = WM:CreateControl(pfx("Icon"..name), w.bg, CT_TEXTURE)
      icon:SetTexture(dds)
      icon:SetDimensions(16,16)

      if(rel) then
         icon:SetAnchor(LEFT, rel, RIGHT, offset, 0)
      else
         icon:SetAnchor(LEFT, w.bg, LEFT, offset, 0)
      end

      return icon
   end

   local make_label = function(name, rel, offset, str)
      local label = WM:CreateControl(pfx("Label"..name), w.bg, CT_LABEL)
      label:SetFont("ZoFontChat")

      if(rel) then
         label:SetAnchor(LEFT, rel, RIGHT, offset, 0)
      else
         label:SetAnchor(LEFT, w.bg, LEFT, offset, 0)
      end

      label:SetText(str)
      label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
      label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
      return label
   end

   local icon = make_icon(name, rel, offset * TK.saved.scale, dds)
   local label = make_label(name, icon, math.min(lrel, TK.saved.scale*lrel), str)

   name = string.lower(name)

   w["icon_"..name] = icon
   w["l_"..name] = label

   return label
end

local function make_bars(rel)
   local w = TK.window
   local last_bar = rel

   local make_bar = function(name, r, g, b, offsetx, offsety)
      local bar = WM:CreateControl(pfx("Bar"..name), w.bg, CT_TEXTURE)
      bar:SetAnchor(BOTTOMLEFT, last_bar, BOTTOMRIGHT, 4+(offsetx or 0), (offsety or 0))
      bar:SetDimensions(8, 0)
      bar:SetColor(r/255, g/255, b/255, 1)

      last_bar = bar

      return bar
   end

   w.bar = {}
   w.bar[0] = make_bar("0", 127, 127, 127, 4, -4) -- Grey   / Crap
   w.bar[1] = make_bar("1", 255, 255, 255)        -- White  / Normal
   w.bar[2] = make_bar("2",  45, 197,  14)        -- Green  / Fine
   w.bar[3] = make_bar("3",  58, 146, 255)        -- Blue   / Superior
   w.bar[4] = make_bar("4", 160,  46, 247)        -- Purple / Epic
   w.bar[5] = make_bar("5", 238, 202,  42)        -- Yellow / Legendary
end

-- White fence icon: "/esoui/art/icons/servicetooltipicons/servicetooltipicon_fence.dds"

local controls = {
   {"Value",        0,  8, "00000",    "/esoui/art/currency/currency_gold.dds"},
   {"Count",       14,  8, "000",      "/esoui/art/inventory/inventory_stolenitem_icon.dds"},
   {"Recipes",     10,  8, "000",      "/esoui/art/icons/quest_book_001.dds"},
   {"Legerdemain", 10,  8, "(00) 0000/0000", "/esoui/art/icons/mapkey/mapkey_fence.dds", { 0, 255, 0 }},
   {"SellsLeft",   10,  6, "000/000",  "/esoui/art/vendor/vendor_tabicon_sell_up.dds"},
   {"FenceTimer",  10,  8, "00:00:00", "/esoui/art/miscellaneous/gamepad/gp_icon_timer32.dds"},
   {"BountyTimer", 10,  8, "00:00:00", "/esoui/art/miscellaneous/gamepad/gp_icon_timer32.dds", { 255, 0, 0 }},
   {"Bounty",      10,  8, "000",      "/esoui/art/currency/currency_gold.dds", { 255, 0, 0 }},
   {"Average",     10,  6, "000.00",   "/esoui/art/vendor/vendor_tabicon_fence_up.dds"},
   {"Estimate",    10,  6, "00000",    "/esoui/art/vendor/vendor_tabicon_fence_up.dds"},
   {"Quality",     10,  8, "0.00",     "/esoui/art/crafting/smithing_tabicon_improve_up.dds"},
}

function TK:ReAnchor()
   local w = TK.window

   w:ClearAnchors()
   w:SetAnchor(TK.saved.anchor, GuiRoot, TK.saved.anchor, 0, 0)
end

function TK:UpdateControls()
   local w = TK.window
   local last

   -- Why yes this _is_ a craptastic hack
   for i,v in ipairs(controls) do
      local name = string.lower(v[1])
      local icon = w["icon_"..name]
      local label = w["l_"..name]

      if((not TK.saved.dshow[v[1]] and TK.saved.show[v[1]]) or
         (TK.saved.dshow[v[1]] and TK.dshow[v[1]])) then
         label:SetParent(w.bg)
         label:ClearAnchors()

         icon:SetParent(w.bg)
         icon:ClearAnchors()

         if(not TK.saved.compactMode) then
            local text = label:GetText()
            label:SetText(v[4])
            label:SetDimensionConstraints((label:GetTextWidth()*math.min(1.0,TK.saved.scale))+8, 0, 0, 0)
            label:SetText(text)
         else
            label:SetDimensionConstraints(0,0,0,0)
            label:SetWidth(0)
         end

         if(v[6]) then
            local color = v[6]
            icon:SetColor(color[1], color[2], color[3])
         end

         if(last) then
            icon:SetAnchor(LEFT, last, RIGHT, v[2]*TK.saved.scale, 0)
         else
            icon:SetAnchor(LEFT, w.bg, LEFT, TK.saved.border, 0)
         end

         label:SetAnchor(LEFT, icon, RIGHT, v[3], 0)
         last = label
      else
         icon:SetParent(nil)
         label:SetParent(nil)
      end
   end

   if(TK.saved.showBars) then
      for i = 0,5 do
         w.bar[i]:SetParent(w.bg)
      end

      w.bar[0]:ClearAnchors()
      w.bar[0]:SetAnchor(BOTTOMLEFT, last, BOTTOMRIGHT,
                         8*TK.saved.scale/2, -4*TK.saved.scale)
   else
      for i = 0,5 do
         w.bar[i]:SetParent(nil)
      end
   end

   if(TK.saved.show.Background) then
      w.bg:SetCenterColor(0, 0, 0, 1)
      w.bg:SetEdgeColor(0, 0, 0, 1)
   else
      w.bg:SetCenterColor(0, 0, 0, 0)
      w.bg:SetEdgeColor(0, 0, 0, 0)
   end
end

function TK:BuildUI()
   local w = WM:CreateTopLevelWindow(pfx())
   local border = TK.saved.border

   -- Toplevel
   w:SetHidden(TK.saved.hidden)
   w:SetMovable(true)
   w:SetMouseEnabled(true)
   w:SetClampedToScreen(true)
   w:SetClampedToScreenInsets(-2, -4, -2, -4)
   w:SetAnchor(TK.saved.anchor, GuiRoot, TK.saved.anchor, TK.saved.x, TK.saved.y)
   w:SetHandler("OnMoveStop", TK.SavePosition)
   w:SetResizeToFitDescendents(true)
   TK.window = w

   -- Background
   w.bg = WM:CreateControl(pfx("BG"), w, CT_BACKDROP)
   w.bg:SetEdgeTexture("/esoui/art/chatwindow/chat_bg_edge.dds", 256, 256, border)
   w.bg:SetCenterTexture("/esoui/art/chatwindow/chat_bg_center.dds")
   w.bg:SetInsets(border, border, -border, -border)
   w.bg:SetAnchor(BOTTOMLEFT, w, BOTTOMLEFT, 0, 0)
   w.bg:SetResizeToFitDescendents(true)
   w.bg:SetResizeToFitPadding(border*2, border)

   -- Controls
   local last
   for i,v in ipairs(controls) do
      last = make_control(v[1], last, v[2], v[3], v[4], v[5])
   end

   make_bars(last)

   findLegerdemain()

   TK:CalcBagGoods()
   TK:UpdateControls()
   TK:UpdateDisplay()
   w:SetScale(TK.saved.scale)

   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onSlotUpdate)
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_LOOT_RECEIVED, onLoot)
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_ITEM_LAUNDER_RESULT, onLaunder)
   --EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_END_CRAFTING_STATION_INTERACT, ...)
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_JUSTICE_STOLEN_ITEMS_REMOVED, onApprehended)

   -- EVENT_CLOSE_FENCE doens't seem to fire, instead we get EVENT_OPEN_FENCE and EVENT_CLOSE_STORE.
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_OPEN_FENCE, function(evc) onFence(true) end)
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_CLOSE_STORE, function(evc) onFence(false) end)
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_SELL_RECEIPT, onSold)

   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_ACTION_LAYER_PUSHED, onLayerChange)
   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_ACTION_LAYER_POPPED, onLayerChange)

   SHARED_INVENTORY:RegisterCallback("SlotRemoved", onRemoved)

   EVENT_MANAGER:RegisterForEvent(TK.name, EVENT_JUSTICE_BOUNTY_PAYOFF_AMOUNT_UPDATED, onBountyChange)

   setupTimer()
   setupXpWatch()
end
