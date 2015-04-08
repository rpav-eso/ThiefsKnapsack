ZO_CreateStringId("SI_BINDING_NAME_THIEFSKNAPSACK_TOGGLE", "Toggle")

local TK = ThiefsKnapsack
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local util = LibStub:GetLibrary("util.rpav-1")
local prnd = util.prnd

local panel = {
   type = "panel",
   name = "Thief's Knapsack",
}

local options = {
   { type = "header",
     name = "Display", },
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
   },
   { type = "checkbox",
     name = "Show gold value",
     tooltip = "Display the total gold value of stolen items",
     getFunc = function() return TK.saved.show.Value; end,
     setFunc = function(x)
        TK.saved.show.Value = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = "Show stolen item count",
     tooltip = "Display the total number of stolen items currently held (stacks included!)",
     getFunc = function() return TK.saved.show.Count; end,
     setFunc = function(x)
        TK.saved.show.Count = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = "Show stolen recipe/motif count",
     tooltip = "Display the number of recipes or racial motifs held",
     getFunc = function() return TK.saved.show.Recipes; end,
     setFunc = function(x)
        TK.saved.show.Recipes = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = "Show average value",
     tooltip = "Display the average value of an item (i.e., ratio of value to item count)",
     getFunc = function() return TK.saved.show.Average; end,
     setFunc = function(x)
        TK.saved.show.Average = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = "Show estimated daily profit",
     tooltip = "Show the estimated daily haul based on remaining fence sells and the average stolen item value",
     getFunc = function() return TK.saved.show.Estimate; end,
     setFunc = function(x)
        TK.saved.show.Estimate = x
        TK:UpdateControls()
     end,
   },
   { type = "checkbox",
     name = "Show average quality",
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
}

function TK:RegisterSettings()
   LAM:RegisterAddonPanel("ThiefsKnapsackOptions", panel)
   LAM:RegisterOptionControls("ThiefsKnapsackOptions", options)
end
