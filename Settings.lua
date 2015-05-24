ZO_CreateStringId("SI_BINDING_NAME_THIEFSKNAPSACK_TOGGLE", "Toggle")

local TK = ThiefsKnapsack
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local util = LibStub:GetLibrary("util.rpav-1")
local prnd = util.prnd
local str = util.str

local function tex(name, color)
   if(color) then
      return str("|c", color, "|t16:16:", name, ":inheritColor|t|r")
   else
      return str("|t16:16:", name, "|t")
   end
end

local panel = {
   type = "panel",
   name = "Thief's Knapsack",
   registerForRefresh = true,
}

local anchors = {
   "Center",
   "Left",
   "Right",
}

local anchor_to_text = {
   [TOPLEFT] = "Left",
   [TOPRIGHT] = "Right",
   [TOP] = "Center",
}

local text_to_anchor = {
   ["Left"] = TOPLEFT,
   ["Right"] = TOPRIGHT,
   ["Center"] = TOP,
}

local options = {
   { type = "header",
     name = "Fields", },
   { type = "checkbox",
     name = str(tex("/esoui/art/currency/currency_gold.dds"), " Gold value"),
     tooltip = "Display the total gold value of stolen items",
     getFunc = function() return TK.saved.show.Value; end,
     setFunc = function(x)
        TK.saved.show.Value = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/inventory/inventory_stolenitem_icon.dds"),
                " Stolen item count"),
     tooltip = "Display the total number of stolen items currently held (stacks included!)",
     getFunc = function() return TK.saved.show.Count; end,
     setFunc = function(x)
        TK.saved.show.Count = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/icons/quest_book_001.dds"),
                " Stolen recipe/motif count"),
     tooltip = "Display the number of recipes or racial motifs held",
     getFunc = function() return TK.saved.show.Recipes; end,
     setFunc = function(x)
        TK.saved.show.Recipes = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/icons/mapkey/mapkey_fence.dds", "00FF00"),
                " Legerdemain XP"),
     tooltip = "Because everyone likes to watch the numbers go up",
     getFunc = function() return TK.saved.show.Legerdemain; end,
     setFunc = function(x)
        TK.saved.show.Legerdemain = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/vendor/vendor_tabicon_sell_up.dds"),
                "Show sells (to the fences) remaining"),
     tooltip = "Display the total remaining times you can fence items",
     getFunc = function() return TK.saved.show.SellsLeft; end,
     setFunc = function(x)
        TK.saved.show.SellsLeft = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = "...also show launders remaining",
     tooltip = "Display the total remaining times you can launder items",
     disabled = function() return not TK.saved.show.SellsLeft end,
     getFunc = function() return TK.saved.show.LaundersLeft end,
     setFunc = function(x)
        TK.saved.show.LaundersLeft = x
        TK:UpdateDisplay()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/miscellaneous/gamepad/gp_icon_timer32.dds"),
                "Show the Fence Reset Clock"),
     tooltip = "",
     getFunc = function() return TK.saved.show.FenceTimer; end,
     setFunc = function(x)
        TK.saved.show.FenceTimer = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/miscellaneous/gamepad/gp_icon_timer32.dds", "FF0000"),
                "Show the Bounty Reset Clock"),
     tooltip = "(\"Dynamic Bounty\" will hide this if you have no bounty)",
     getFunc = function() return TK.saved.show.BountyTimer; end,
     setFunc = function(x)
        TK.saved.show.BountyTimer = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/currency/currency_gold.dds", "FF0000"),
                "Show bounty"),
     tooltip = "(\"Dynamic Bounty\" will hide this if you have no bounty)",
     getFunc = function() return TK.saved.show.Bounty; end,
     setFunc = function(x)
        TK.saved.show.Bounty = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/vendor/vendor_tabicon_fence_up.dds"),
                "Show average value"),
     tooltip = "Display the average value of an item (i.e., ratio of value to item count)",
     getFunc = function() return TK.saved.show.Average; end,
     setFunc = function(x)
        TK.saved.show.Average = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/vendor/vendor_tabicon_fence_up.dds", "EECA00"),
                "Show estimated daily profit"),
     tooltip = "Show the estimated daily haul based on remaining fence sells and the average stolen item value",
     getFunc = function() return TK.saved.show.Estimate; end,
     setFunc = function(x)
        TK.saved.show.Estimate = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = str(tex("/esoui/art/crafting/smithing_tabicon_improve_up.dds"),
                "Show average quality"),
     tooltip = "Display the average quality of item",
     getFunc = function() return TK.saved.show.Quality; end,
     setFunc = function(x)
        TK.saved.show.Quality = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = "Show the quality graph",
     tooltip = "Display the graph of item quality to percentage held",
     getFunc = function() return TK.saved.showBars; end,
     setFunc = function(x)
        TK.saved.showBars = x
        TK:UpdateControls()
     end,
   },
   { type = "header",
     name = "Options", },
   { type = "checkbox",
     name = "Don't count junk",
     tooltip = "If a stolen item is marked as junk, it won't be counted",
     getFunc = function() return TK.saved.options.nojunk; end,
     setFunc = function(x)
        TK.saved.options.nojunk = x
        TK:CalcBagGoods()
        TK:UpdateDisplay()
     end,
   },
   { type = "checkbox",
     name = "Separate recipes and motifs",
     tooltip = "If a stolen item is a recipe or motif, count it separately",
     getFunc = function() return TK.saved.options.sep_recipe; end,
     setFunc = function(x)
        TK.saved.options.sep_recipe = x
        TK:CalcBagGoods()
        TK:UpdateDisplay()
     end,
   },
   { type = "checkbox",
     name = "Dynamic bounty/timer",
     tooltip = "Show and hide the bounty and bounty timer automatically, when there is bounty",
     getFunc = function() return TK.saved.dshow.Bounty; end,
     setFunc = function(x)
        TK.saved.dshow.Bounty = x
        TK.saved.dshow.BountyTimer = x
        if(x) then
           TK:DynamicBountyCheck()
        else
           TK:UpdateControls()
        end
     end,
   },

   { type = "submenu",
     name = "Display",
     controls = {
        { type = "slider",
          name = "Scale",
          min = 75,
          max = 200,
          step = 1,
          getFunc = function() return TK.saved.scale*100; end,
          setFunc = function(x)
             TK.saved.scale = x/100
             TK.window:SetScale(1)
             TK:UpdateControls()
             TK.window:SetScale(x/100)
          end,
          warning = "Best to reload the UI after adjusting this.",
        },
        { type = "checkbox",
          name = "Compact alignment",
          tooltip = "If checked, the bar will be more compact, but the size will fluctuate as the numbers change",
          getFunc = function() return TK.saved.compactMode; end,
          setFunc = function(x)
             TK.saved.compactMode = x
             TK:UpdateControls()
          end,
          warning = "Best to reload the UI after adjusting this.",
        },
        { type = "checkbox",
          name = "Show background",
          tooltip = "If this is unchecked, the background will not be displayed",
          getFunc = function() return TK.saved.show.Background end,
          setFunc = function(x)
             TK.saved.show.Background = x
             TK:UpdateControls()
          end,
        },
        {  type = "checkbox",
           name = "Hide in menus",
           tooltip = "When set, the bar will be hidden when in menus and similar",
           getFunc = function() return TK.saved.options.hide_on_menu end,
           setFunc = function(x)
              TK.saved.options.hide_on_menu = x
              -- A bit of a hack
              TK.window:SetHidden(x)
           end
        },
        { type = "dropdown",
          name = "Alignment",
          tooltip = "Set which corner of the screen the bar is relative to",
          choices = anchors,
          getFunc = function() return anchor_to_text[TK.saved.anchor] end,
          setFunc = function(x)
             TK.saved.anchor = text_to_anchor[x]
             TK:ReAnchor()
             TK:SavePosition()
          end,
        },
        { type = "checkbox",
          name = "Snap to center",
          tooltip = "If this is checked and you use Center alignment, the bar will snap to the center",
          getFunc = function() return TK.saved.snapCenter end,
          setFunc = function(x)
             TK.saved.snapCenter = x
             TK:SavePosition()
          end,
        },
        { type = "button",
          name = "Reload UI",
          func = function() ReloadUI() end,
        },
     },
   },
}

function TK:RegisterSettings()
   LAM:RegisterAddonPanel("ThiefsKnapsackOptions", panel)
   LAM:RegisterOptionControls("ThiefsKnapsackOptions", options)
end
