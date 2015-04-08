local MAJOR, MINOR = "util.rpav-1", 1
local util, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if(not util) then return; end

function util.toargs(...)
   local arg = {}
   local nargs = select('#',...)

   for i = 1,nargs do
      arg[i] = select(i,...)
   end

   arg.size = nargs

   return arg
end

function util.str_a(arg)
   local str = ""

   for i = 1,arg.size do
      local v = arg[i]
      local t = type(v)
      if(v == nil) then
         str = str .. "(nil)";
      elseif(t == "table") then
         str = str .. util.table_tostr(v)
      else
         str = str .. tostring(v)
      end
   end

   return str
end

function util.str(...)
   return util.str_a(util.toargs(...))
end

function util.prn(...)
   local str = util.str_a(util.toargs(...))

   if(LUAConsole) then
      LUAConsole.PrintStr(str)
   else
      d(str)
   end
end

function util.prnd(...)
   local str = util.str_a(util.toargs(...))
   d(str)
end

function util.table_count(t)
   local c = 0
   for x in pairs(t) do c = c + 1 end
   return c
end

local TABLE_INCR = 4
local TABLE_MAX_DEPTH = 5
function util.table_tostr(t, c)
   if(c and c > TABLE_MAX_DEPTH * TABLE_INCR) then
      return "<Max Depth Exceeded>,\n"
   end

   local c = c or 0
   local tab0 = string.rep(" ", c)
   local tab1 = string.rep(" ", c + TABLE_INCR)
   local s = "{\n"

   for k,v in pairs(t) do
      if(type(v) == "table") then
         s = s .. util.str(tab1, "[", k, "] = ")
         s = s .. util.table_tostr(v, c + TABLE_INCR)
      else
         s = s .. util.str(tab1, "[", k, "] = ", v, ",\n")
      end
   end

   s = s .. util.str(tab0, "}\n")

   return s
end

function util.clamp(v, min, max)
   return math.min(math.max(v, min), max)
end
