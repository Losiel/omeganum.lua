--[[ "MIT License

Copyright (c) 2024 alonzon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE." ]]
--[[ "
  This is an implementation of OmegaNum[1] for Lua
coded in Fennel by alonzon. (also `alonzon` on Discord)

[1]: https://github.com/Naruyoko/OmegaNum.js" ]]
local unpack = (table.unpack or _G.unpack)
local abs = math.abs
local floor = math.floor
local _repeat = string.rep
local log10 = math.log10
local tostring = tostring
local min = math.min
local max = math.max
local _2aMAX_ARROWS_2a = 1000
local _2aMAX_SAFE_INTEGER_2a = 9007199254740991
local _2aMAX_E_2a = log10(_2aMAX_SAFE_INTEGER_2a)
local _2aMAX_LUA_NUMBER_2a = 1.7976931348623e+308
local _2aMAX_LUA_E_2a = log10(_2aMAX_LUA_NUMBER_2a)
local _2aNAN_2a = math.acos(2)
local _2aINF_2a = math.huge
local _2aLONG_STRING_MIN_LENGTH_2a = 17
local function nan_3f(n)
  return (n ~= n)
end
local function ftostring(n)
  local f = floor(n)
  if (f == n) then
    return tostring(f)
  else
    return tostring(n)
  end
end
local function false_or_zero_3f(value)
  return ((value == 0) or not value)
end
local function not_false_or_zero_3f(value)
  return (value and (value ~= 0))
end
local omegaNum = {}
omegaNum.__index = omegaNum
omegaNum.ZERO = setmetatable({array = {0}, sign = 1}, omegaNum)
omegaNum.ONE = setmetatable({array = {1}, sign = 1}, omegaNum)
omegaNum.INF = setmetatable({array = {_2aINF_2a}, sign = 1}, omegaNum)
omegaNum.NEG_INF = setmetatable({array = {_2aINF_2a}, sign = -1}, omegaNum)
omegaNum.NAN = setmetatable({array = {_2aNAN_2a}, sign = 1}, omegaNum)
omegaNum.E_MAX_SAFE_INTEGER = setmetatable({array = {_2aMAX_SAFE_INTEGER_2a, 1}, sign = 1}, omegaNum)
omegaNum.EE_MAX_SAFE_INTEGER = setmetatable({array = {_2aMAX_SAFE_INTEGER_2a, 2}, sign = 1}, omegaNum)
omegaNum.TETRATED_MAX_SAFE_INTEGER = setmetatable({array = {10000000000.0, 9007199254740989}, sign = 1}, omegaNum)
local function normalize_magnitude(array)
  local first = array[1]
  local sec = array[2]
  if (#array == 0) then
    return nil
  elseif (0 == array[#array]) then
    table.remove(array)
    return normalize_magnitude(array)
  elseif (first > _2aMAX_SAFE_INTEGER_2a) then
    array[1] = log10(first)
    do end (array)[2] = ((sec or 0) + 1)
    return normalize_magnitude(array)
  elseif ((first < _2aMAX_E_2a) and not_false_or_zero_3f(sec)) then
    array[1] = (10 ^ first)
    do end (array)[2] = (sec - 1)
    return normalize_magnitude(array)
  elseif ((#array > 2) and false_or_zero_3f(sec)) then
    local first_non_zero = 3
    while ((0 == array[first_non_zero]) and (first_non_zero < #array)) do
      first_non_zero = (first_non_zero + 1)
    end
    array[(first_non_zero - 1)] = first
    array[1] = 1
    array[first_non_zero] = (array[first_non_zero] - 1)
    return normalize_magnitude(array)
  elseif "else" then
    local first_max
    do
      local res = nil
      for i = 2, #array do
        if res then break end
        if (array[i] > _2aMAX_SAFE_INTEGER_2a) then
          res = i
        else
          res = nil
        end
      end
      first_max = res
    end
    if first_max then
      local _next = (first_max + 1)
      do end (array)[_next] = ((array[_next] or 0) + 1)
      do end (array)[1] = (array[first_max] + 1)
      for i = 2, first_max do
        array[i] = 0
      end
      return normalize_magnitude(array)
    else
      return nil
    end
  else
    return nil
  end
end
omegaNum.normalize = function(self)
  if ("number" ~= type(self.sign)) then
    local num = tonumber(self.sign)
    if (num and (num < 0)) then
      self.sign = -1
    else
      self.sign = 1
    end
  else
  end
  if (not self.array or (0 == #self.array)) then
    self.array = {0}
  else
  end
  for i = 1, #self.array do
    local v = self.array[i]
    if nan_3f(v) then
      self.array = {_2aNAN_2a}
      return self
    elseif (v == _2aINF_2a) then
      self.array = {_2aINF_2a}
      return self
    elseif (type(v) ~= "number") then
      self.array[i] = 0
    elseif (i > 1) then
      self.array[i] = floor(v)
    else
    end
  end
  normalize_magnitude(self.array)
  if (0 == #self.array) then
    self.array = {0}
  else
  end
  return self
end
omegaNum.fromArray = function(arr, sign)
  if (type(arr) ~= "table") then
    error(("Expected table, got " .. type(arr)))
  else
  end
  if (type(sign) ~= "number") then
    error(("Expected number, got " .. type(sign)))
  else
  end
  return setmetatable({array = {unpack(arr)}, sign = sign}, omegaNum):normalize()
end
omegaNum.fromNumber = function(num)
  if (type(num) ~= "number") then
    error(("Expected number, got " .. type(num)))
  else
  end
  local _13_
  if (num < 0) then
    _13_ = -1
  else
    _13_ = 1
  end
  return setmetatable({array = {abs(num)}, sign = _13_}, omegaNum):normalize()
end
local malformed_error = "Malformed expression"
local function parse_exponent(str, i)
  local i0 = (str:find("%S", i) or (#str + 1))
  local function _15_(...)
    local _16_, _17_, _18_, _19_ = ...
    if (true and (nil ~= _17_) and (nil ~= _18_) and (nil ~= _19_)) then
      local _ = _16_
      local patt_end = _17_
      local arrows = _18_
      local exp = _19_
      return (patt_end + 1), #arrows, tonumber(exp)
    else
      local _3f = _16_
      local _, patt_end, arrows, exp = str:find("^%(10%{([1-9]%d*)%}%)^([1-9]%d*)", i0)
      if arrows then
        return (patt_end + 1), tonumber(arrows), tonumber(exp)
      else
        return nil
      end
    end
  end
  return _15_(str:find("^%(10(^+)%)^([1-9]%d*)", i0))
end
local function parse_exponents(str, i, res)
  local old_i = i
  local i0, arrows, exp = parse_exponent(str, i)
  if not i0 then
    return old_i
  elseif (arrows == 1) then
    res.array[2] = ((res.array[2] or 0) + exp)
    return parse_exponents(str, i0, res)
  elseif (arrows == 2) then
    local first = (res.array[1] or 0)
    local sec = (res.array[2] or 0)
    local _22_
    if (first >= 10000000000.0) then
      _22_ = (sec + 2)
    elseif (first >= 10) then
      _22_ = (sec + 1)
    else
      _22_ = sec
    end
    res.array[1] = _22_
    res.array[2] = 0
    res.array[3] = ((res.array[3] or 0) + exp)
    return parse_exponents(str, i0, res)
  else
    local a = (res.array[(arrows + 1)] or 0)
    local b = (res.array[arrows] or 0)
    local c = (res.array[(arrows - 1)] or 0)
    local _24_
    if (c >= 10) then
      _24_ = (b + 1)
    else
      _24_ = b
    end
    res.array[1] = _24_
    res.array[(arrows + 1)] = ((a or 0) + exp)
    for i1 = 2, arrows do
      res.array[i1] = 0
    end
    return parse_exponents(str, i0, res)
  end
end
local function log10_long_string(str)
  return log10((tonumber(str:sub(1, _2aLONG_STRING_MIN_LENGTH_2a)) + (#str - _2aLONG_STRING_MIN_LENGTH_2a)))
end
local function parse_num(literal, mag, exp)
  if (#literal > 0) then
    local mag0, exp0 = nil, nil
    if ((mag < _2aMAX_E_2a) and (exp == 0)) then
      mag0, exp0 = (10 ^ mag), exp
    else
      mag0, exp0 = mag, (exp + 1)
    end
    local value = table.remove(literal)
    local integer, dot, decimal_part = value:match("^([-+]?%d*)(%.?)(%d*)$")
    assert(integer, malformed_error)
    local safe_num
    if (#value > 0) then
      safe_num = tonumber(value)
    else
      safe_num = 0
    end
    if (exp0 == 0) then
      if (#integer >= _2aLONG_STRING_MIN_LENGTH_2a) then
        mag0, exp0 = (log10(mag0) + log10_long_string(integer)), 1
      elseif (#value > 0) then
        mag0, exp0 = (mag0 * safe_num), exp0
      else
        mag0, exp0 = mag0, exp0
      end
    else
      local log_num
      if (#integer >= _2aLONG_STRING_MIN_LENGTH_2a) then
        log_num = log10_long_string(integer)
      elseif (#integer > 0) then
        log_num = log10(safe_num)
      else
        log_num = 0
      end
      if (exp0 == 1) then
        mag0 = (mag0 + log_num)
      elseif ((exp0 == 2) and (mag0 < (_2aMAX_E_2a + log10(log_num)))) then
        mag0 = (mag0 + log10((1 + (10 ^ (log10(log_num) - mag0)))))
      else
        mag0 = mag0
      end
    end
    if ((mag0 < _2aMAX_E_2a) and (exp0 ~= 0)) then
      return parse_num(literal, (10 ^ mag0), (exp0 - 1))
    elseif (mag0 > _2aMAX_SAFE_INTEGER_2a) then
      return parse_num(literal, log10(mag0), (exp0 + 1))
    else
      return parse_num(literal, mag0, exp0)
    end
  else
    return mag, exp
  end
end
omegaNum.fromString = function(str)
  if (type(str) ~= "string") then
    error(("Expected string, got " .. type(str)))
  else
  end
  local i = 1
  local sign
  local function _36_(...)
    local _37_ = ...
    if (nil ~= _37_) then
      local sign0 = _37_
      i = (i + 1)
      if (sign0 == "-") then
        return -1
      else
        return 1
      end
    else
      local _3f = _37_
      return 1
    end
  end
  sign = _36_(str:match("^[-+]", i))
  local str0 = str:lower()
  if str0:match("^nan", i) then
    return setmetatable({array = {_2aNAN_2a}, sign = sign}, omegaNum)
  elseif str0:match("^infinity", i) then
    return setmetatable({array = {_2aINF_2a}, sign = sign}, omegaNum)
  else
    local res = setmetatable({array = {0}, sign = sign}, omegaNum)
    i = parse_exponents(str0, i, res)
    i = str0:find("%S", i)
    assert(i, malformed_error)
    local mag, exp = nil, nil
    local _40_
    if string.split then
      _40_ = string.split(str0:sub(i), "e")
    else
      local tbl_18_auto = {}
      local i_19_auto = 0
      for num in str0:gmatch("[^e]*", i) do
        local val_20_auto = num
        if (nil ~= val_20_auto) then
          i_19_auto = (i_19_auto + 1)
          do end (tbl_18_auto)[i_19_auto] = val_20_auto
        else
        end
      end
      _40_ = tbl_18_auto
    end
    mag, exp = parse_num(_40_, res.array[1], 0)
    do end (res.array)[1] = mag
    res.array[2] = ((res.array[2] or 0) + exp)
    return res:normalize()
  end
end
omegaNum.new = function(a, b)
  if (type(a) == "string") then
    return omegaNum.fromString(a)
  elseif (type(a) == "number") then
    return omegaNum.fromNumber(a)
  elseif ((type(a) == "table") and (a.__index == omegaNum)) then
    return a:clone()
  elseif (type(a) == "table") then
    return omegaNum.fromArray(a, (b or 1))
  elseif "else" then
    return error(("Unexpected type " .. type(a)))
  else
    return nil
  end
end
omegaNum.clone = function(self)
  return setmetatable({array = {unpack(self.array)}, sign = self.sign}, omegaNum)
end
omegaNum.abs = function(self)
  return setmetatable({array = {unpack(self.array)}, sign = 1}, omegaNum)
end
omegaNum.neg = function(self)
  return setmetatable({array = {unpack(self.array)}, sign = ( - self.sign)}, omegaNum)
end
omegaNum.__unm = omegaNum.neg
omegaNum.isInfinite = function(self)
  return (self.array[1] == _2aINF_2a)
end
omegaNum.isFinite = function(self)
  return (self.array[1] ~= _2aINF_2a)
end
omegaNum.isNan = function(self)
  return nan_3f(self.array[1])
end
omegaNum.isOmegaNum = function(om)
  return ((type(om) == "table") and (om.__index == omegaNum))
end
omegaNum.isNotOmegaNum = function(om)
  return ((type(om) ~= "table") or (om.__index ~= omegaNum))
end
local function compare_same_length_omeganums(a, b, i)
  if (i < 1) then
    return 0
  elseif (a.array[i] > b.array[i]) then
    return a.sign
  elseif (a.array[i] < b.array[i]) then
    return (a.sign * -1)
  else
    return compare_same_length_omeganums(a, b, (i - 1))
  end
end
omegaNum.compare = function(self, b)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local b0
  if omegaNum.isNotOmegaNum(b) then
    b0 = omegaNum.new(b)
  else
    b0 = b
  end
  if (self0:isNan() or b0:isNan()) then
    return _2aNAN_2a
  elseif (self0:isInfinite() and b0:isFinite()) then
    return self0.sign
  elseif (self0:isFinite() and b0:isInfinite()) then
    return ( - b0.sign)
  elseif (self0.sign ~= b0.sign) then
    return self0.sign
  elseif (#self0.array > #b0.array) then
    return self0.sign
  elseif (#self0.array < #b0.array) then
    return (-1 * self0.sign)
  elseif "else" then
    return compare_same_length_omeganums(self0, b0, #self0.array)
  else
    return nil
  end
end
omegaNum.log10 = function(self)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  if (self0 < omegaNum.ZERO) then
    return omegaNum.NAN
  elseif (self0 == omegaNum.ZERO) then
    return omegaNum.NEG_INF
  elseif self0:__lte(_2aMAX_SAFE_INTEGER_2a) then
    return omegaNum.fromNumber(log10(self0:toNumber()))
  elseif self0:isInfinite() then
    return self0
  elseif (self0 > omegaNum.TETRATED_MAX_SAFE_INTEGER) then
    return self0
  elseif "else" then
    local clone = self0:clone()
    do end (clone)[2] = (clone.array[2] - 1)
    return clone:normalize()
  else
    return nil
  end
end
omegaNum.isInteger = function(self)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  if (self0.sign == -1) then
    return omegaNum.isInteger(self0:abs())
  elseif self0:__gt(_2aMAX_SAFE_INTEGER_2a) then
    return true
  else
    local tn = self0:toNumber()
    return (floor(tn) == tn)
  end
end
omegaNum.floor = function(self)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  if self0:isInteger() then
    return self0:clone()
  else
    return omegaNum.fromNumber(floor(self0:toNumber()))
  end
end
omegaNum.reciprocate = function(self)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  if (self0:isNan() or (self0 == omegaNum.ZERO)) then
    return omegaNum.NAN
  else
    return (omegaNum.ONE / self0)
  end
end
omegaNum.mod = function(self, other)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local other0
  if omegaNum.isNotOmegaNum(other) then
    other0 = omegaNum.new(other)
  else
    other0 = other
  end
  if (other0 == omegaNum.ZERO) then
    return omegaNum.ZERO
  elseif ((self0.sign * other0.sign) == -1) then
    return ( - (self0:abs() % other0:abs()))
  elseif (self0.sign == -1) then
    return (self0:abs() % other0:abs())
  else
    return (self0 - (floor(((self0 / other0)):toNumber()) * other0))
  end
end
omegaNum.__mod = omegaNum.mod
omegaNum.pow = function(self, other)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local other0
  if omegaNum.isNotOmegaNum(other) then
    other0 = omegaNum.new(other)
  else
    other0 = other
  end
  if (other0 == omegaNum.ZERO) then
    return omegaNum.ONE
  elseif (other0 == omegaNum.ONE) then
    return self0
  elseif (other0 < omegaNum.ZERO) then
    return omegaNum.reciprocate((self0 ^ ( - other0)))
  elseif ((self0 < omegaNum.ZERO) and other0:isInteger()) then
    if (other0:__mod(2) < omegaNum.ONE) then
      return (self0:abs() ^ other0)
    else
      return ( - (self0:abs() ^ other0))
    end
  elseif (self0 < omegaNum.ZERO) then
    return omegaNum.NAN
  elseif (self0 == omegaNum.ONE) then
    return omegaNum.ONE
  elseif (self0 == omegaNum.ZERO) then
    return omegaNum.ZERO
  elseif (self0:max(other0) > omegaNum.TETRATED_MAX_SAFE_INTEGER) then
    return self0:max(other0)
  elseif self0:__eq(10) then
    if (other0 > omegaNum.ZERO) then
      local clone = other0:clone()
      local _64_
      if (clone.array[2] and (clone.array[2] ~= -1)) then
        _64_ = (clone.array[2] + 1)
      else
        _64_ = 1
      end
      clone.array[2] = _64_
      return clone:normalize()
    else
      return omegaNum.fromNumber((10 ^ other0:toNumber()))
    end
  elseif (other0 < omegaNum.ONE) then
    return self0:root(other0:reciprocate())
  else
    local n = (self0:toNumber() ^ other0:toNumber())
    if (n <= _2aMAX_SAFE_INTEGER_2a) then
      return omegaNum.fromNumber(n)
    else
      return omegaNum.__pow(10, (self0:log10() * other0))
    end
  end
end
omegaNum.__pow = omegaNum.pow
omegaNum.root = function(self, other)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local other0
  if omegaNum.isNotOmegaNum(other) then
    other0 = omegaNum.new(other)
  else
    other0 = other
  end
  if (other0 == omegaNum.ZERO) then
    return self0:clone()
  elseif (other0 < omegaNum.ZERO) then
    return self0:root(( - other0)):reciprocate()
  elseif (other0 < omegaNum.ONE) then
    return (self0 ^ other0:reciprocate())
  elseif ((self0 < omegaNum.ZERO) and other0:isInteger() and (other0:__mod(2) == omegaNum.ONE)) then
    return ( - (( - self0)):root(other0))
  elseif (self0 < omegaNum.ZERO) then
    return omegaNum.NAN
  elseif (self0 == omegaNum.ONE) then
    return omegaNum.ONE
  elseif (self0 == omegaNum.ZERO) then
    return omegaNum.ZERO
  elseif (self0:max(other0) > omegaNum.TETRATED_MAX_SAFE_INTEGER) then
    if (self0 > other0) then
      return self0:clone()
    else
      return omegaNum.ZERO
    end
  else
    return omegaNum.__pow(10, (self0:log10() / other0))
  end
end
omegaNum.mul = function(self, other)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local other0
  if omegaNum.isNotOmegaNum(other) then
    other0 = omegaNum.new(other)
  else
    other0 = other
  end
  if ((self0.sign * other0.sign) == -1) then
    return ( - (self0:abs() * other0:abs()))
  elseif (self0.sign == -1) then
    return (self0:abs() * other0:abs())
  elseif (self0:isNan() or other0:isNan() or ((self0 == omegaNum.ZERO) and other0:isInfinite()) or (self0:isInfinite() and (other0:abs() == omegaNum.ZERO))) then
    return omegaNum.NAN
  elseif (other0 == omegaNum.ZERO) then
    return omegaNum.ZERO
  elseif (other0 == omegaNum.ONE) then
    return self0:clone()
  elseif self0:isInfinite() then
    return self0
  elseif other0:isInfinite() then
    return other0
  elseif (self0:max(other0) > omegaNum.EE_MAX_SAFE_INTEGER) then
    return self0:max(other0)
  else
    local n = (self0:toNumber() * other0:toNumber())
    if (n <= _2aMAX_SAFE_INTEGER_2a) then
      return omegaNum.fromNumber(n)
    else
      return omegaNum.__pow(10, (self0:log10() + other0:log10()))
    end
  end
end
omegaNum.__mul = omegaNum.mul
omegaNum.div = function(self, other)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local other0
  if omegaNum.isNotOmegaNum(other) then
    other0 = omegaNum.new(other)
  else
    other0 = other
  end
  local gt = self0:max(other0)
  if ((self0.sign * other0.sign) == -1) then
    return ( - (self0:abs() / other0:abs()))
  elseif (self0.sign == -1) then
    return (self0:abs() / other0:abs())
  elseif (self0:isNan() or other0:isNan() or (self0:isInfinite() and other0:isInfinite()) or (function(_79_,_80_,_81_) return (_79_ == _80_) and (_80_ == _81_) end)(self0,omegaNum.ZERO,other0)) then
    return omegaNum.NAN
  elseif (other0 == omegaNum.ZERO) then
    return omegaNum.INF
  elseif (other0 == omegaNum.ONE) then
    return self0
  elseif (self0 == other0) then
    return omegaNum.ONE
  elseif self0:isInfinite() then
    return self0
  elseif other0:isInfinite() then
    return omegaNum.ZERO
  elseif gt:__gt(omegaNum.EE_MAX_SAFE_INTEGER) then
    if (gt == self0) then
      return self0
    else
      return omegaNum.ZERO
    end
  elseif "else" then
    local n = (self0:toNumber() / other0:toNumber())
    if (n <= _2aMAX_SAFE_INTEGER_2a) then
      return omegaNum.fromNumber(n)
    else
      local pw = omegaNum.__pow(10, (self0:log10() - other0:log10()))
      local fp = pw:floor()
      if ((pw - fp) < omegaNum.fromNumber(1e-09)) then
        return fp
      else
        return pw
      end
    end
  else
    return nil
  end
end
omegaNum.__div = omegaNum.div
omegaNum.add = function(self, other)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local other0
  if omegaNum.isNotOmegaNum(other) then
    other0 = omegaNum.new(other)
  else
    other0 = other
  end
  local lw = self0:min(other0)
  local gt = self0:max(other0)
  local n = self0:__lt(other0)
  if (self0.sign == -1) then
    return ( - (( - self0) + ( - other0)))
  elseif (other0.sign == -1) then
    return (self0 - ( - other0))
  elseif (self0 == omegaNum.ZERO) then
    return other0
  elseif (other0 == omegaNum.ZERO) then
    return self0
  elseif (self0:isNan() or other0:isNan() or (self0:isInfinite() and other0:isInfinite() and (self0.sign ~= other0.sign))) then
    return omegaNum.NAN
  elseif self0:isInfinite() then
    return self0
  elseif other0:isInfinite() then
    return other0
  elseif ((gt > omegaNum.E_MAX_SAFE_INTEGER) or omegaNum.__gt((gt / lw), _2aMAX_SAFE_INTEGER_2a)) then
    return gt
  elseif false_or_zero_3f(gt.array[2]) then
    return omegaNum.fromNumber((self0:toNumber() + other0:toNumber()))
  elseif (gt.array[2] == 1) then
    local a
    if false_or_zero_3f(lw.array[2]) then
      a = lw.array[1]
    else
      a = log10(lw.array[1])
    end
    local res = (a + log10(((10 ^ (gt.array[1] - a)) + 1)))
    return setmetatable({array = {res, 1}, sign = 1}, omegaNum)
  else
    return nil
  end
end
omegaNum.__add = omegaNum.add
omegaNum.sub = function(self, other)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  local other0
  if omegaNum.isNotOmegaNum(other) then
    other0 = omegaNum.new(other)
  else
    other0 = other
  end
  local lw = self0:min(other0)
  local gt = self0:max(other0)
  local n = self0:__lt(other0)
  if (self0.sign == -1) then
    return ( - (( - self0) - ( - other0)))
  elseif (other0.sign == -1) then
    return (self0 + ( - other0))
  elseif (self0 == other0) then
    return omegaNum.ZERO
  elseif (other0 == omegaNum.ZERO) then
    return self0
  elseif (self0:isNan() or other0:isNan() or (self0:isInfinite() and other0:isInfinite())) then
    return omegaNum.NAN
  elseif self0:isInfinite() then
    return self0
  elseif other0:isInfinite() then
    return other0
  elseif ((gt > omegaNum.E_MAX_SAFE_INTEGER) or omegaNum.__gt((gt / lw), _2aMAX_SAFE_INTEGER_2a)) then
    if n then
      local _92_ = gt:clone()
      do end (_92_)["sign"] = -1
      return _92_
    else
      return gt
    end
  elseif false_or_zero_3f(gt.array[2]) then
    return omegaNum.fromNumber((self0:toNumber() - other0:toNumber()))
  elseif (gt.array[2] == 1) then
    local a
    if false_or_zero_3f(lw.array[2]) then
      a = lw.array[1]
    else
      a = log10(lw.array[1])
    end
    local res = (a + log10(((10 ^ (gt.array[1] - a)) - 1)))
    local _95_
    if n then
      _95_ = -1
    else
      _95_ = 1
    end
    return setmetatable({array = {res, 1}, sign = _95_}, omegaNum)
  else
    return nil
  end
end
omegaNum.__sub = omegaNum.sub
omegaNum.eq = function(self, b)
  return (omegaNum.compare(self, b) == 0)
end
omegaNum.__eq = omegaNum.eq
omegaNum.lt = function(self, b)
  return (omegaNum.compare(self, b) == -1)
end
omegaNum.__lt = omegaNum.lt
omegaNum.lte = function(self, b)
  return (omegaNum.compare(self, b) <= 0)
end
omegaNum.__lte = omegaNum.lte
omegaNum.gt = function(self, b)
  return (omegaNum.compare(self, b) == 1)
end
omegaNum.__gt = omegaNum.gt
omegaNum.__len = function(self, b)
  return #self.array
end
omegaNum.min = function(self, b)
  if omegaNum.__gt(self, b) then
    return b
  else
    return self
  end
end
omegaNum.max = function(self, b)
  if omegaNum.__lt(self, b) then
    return b
  else
    return self
  end
end
omegaNum.toNumber = function(self)
  if (self.sign == -1) then
    return omegaNum.__mul(-1, self:abs():toNumber())
  elseif ((#self.array >= 2) and ((self.array[2] >= 2) or ((self.array[2] == 1) and (self.array[1] > _2aMAX_LUA_E_2a)))) then
    return _2aINF_2a
  elseif (self.array[2] == 1) then
    return (10 ^ self.array[1])
  elseif "else" then
    return self.array[1]
  else
    return nil
  end
end
local function omegaNum__3estring(res, sign, first, sec, ...)
  if nan_3f(first) then
    return "nan"
  elseif (first == _2aINF_2a) then
    return "inf"
  elseif (sign == -1) then
    return omegaNum__3estring("-", 1, first, sec, ...)
  elseif ... then
    local arr = {...}
    local i = #arr
    local value = table.remove(arr)
    local q
    local _101_
    if (i >= 6) then
      _101_ = ("{" .. i .. "}")
    else
      _101_ = "^"
    end
    q = _repeat(_101_, i)
    local res0
    if (value > 1) then
      res0 = (res .. "(10" .. q .. ")^" .. value .. " ")
    elseif (value == 1) then
      res0 = (res .. "10" .. q)
    else
      res0 = res
    end
    return omegaNum__3estring(res0, sign, first, sec, unpack(arr))
  elseif false_or_zero_3f(sec) then
    return (res .. ftostring(first))
  elseif (sec < 3) then
    local ff = floor(first)
    return (res .. _repeat("e", (sec - 1)) .. (10 ^ (first - ff)) .. "e" .. ff)
  elseif (sec < 8) then
    return (res .. _repeat("e", sec) .. ftostring(first))
  elseif "else" then
    return (res .. "(10^)^" .. ftostring(sec) .. " " .. ftostring(first))
  else
    return nil
  end
end
omegaNum.__tostring = function(self)
  local self0
  if omegaNum.isNotOmegaNum(self) then
    self0 = omegaNum.new(self)
  else
    self0 = self
  end
  return omegaNum__3estring("", self0.sign, unpack(self0.array))
end
--[[ "The rest of the code are tool for developers. You shouldn't use these functions in any way." ]]
local function write_readme()
  local metadata = package.loaded.fennel.metadata
  local sorted_keys
  do
    local _106_
    do
      local tbl_18_auto = {}
      local i_19_auto = 0
      for k in pairs(omegaNum) do
        local val_20_auto = k
        if (nil ~= val_20_auto) then
          i_19_auto = (i_19_auto + 1)
          do end (tbl_18_auto)[i_19_auto] = val_20_auto
        else
        end
      end
      _106_ = tbl_18_auto
    end
    table.sort(_106_)
    sorted_keys = _106_
  end
  local output
  do
    local res = "# OmegaNum.lua\n[Join the Discord server!](https://discord.gg/xZnfNMnQDp)\nOmegaNum is a port [of Naryuoko's OmegaNum](https://github.com/Naruyoko/OmegaNum.js) for Lua. This library is highly inaccurate for huge numbers, which is perfect for incremental games that intend to reach very big numbers quickly.\n```lua\nlocal om = require(\"omeganum\")\nprint(tostring(om.add(\"1\", 1))) --> 2\nprint(tostring(om.new(1) + om.new(1))) --> 2\n```\n# Contributing to this port\nThe original code is written in Fennel, a Lisp that compiles for Lua. For convenience I provide a Lua file aswell, but in reality you should edit the Fennel file.\n\nThis library also has tests. The tests depend on the [Faith](https://git.sr.ht/~technomancy/faith) library which must be put in the same directory. To run the tests, type in the terminal `fennel faith.fnl --tests tests`. If you're on Emacs, open the `tests.fnl` file and do `M-x inferior-lisp`. If you press <f3> on the original buffer for `tests.fnl` it will run the tests and show the results in the new buffer\n\nTo compile the file, run `fennel --plugin omeganum.fnl` and in the repl type `,make`. It should write the documentation to `README.md`, compile to `omeganum.lua` and run the tests\n\n# Reference"
    for _, k in ipairs(sorted_keys) do
      local v = omegaNum[k]
      local fn_meta = metadata:get(v)
      local _let_108_ = (fn_meta or {})
      local fnl_2fdocstring = _let_108_["fnl/docstring"]
      local fnl_2farglist = _let_108_["fnl/arglist"]
      local aliases = _let_108_["aliases"]
      if (fn_meta and fnl_2fdocstring and not k:match("^__")) then
        local function _109_()
          if aliases then
            return ("\n- Aliases: " .. "`" .. table.concat(aliases, "` `") .. "`" .. "<br/>")
          else
            return ""
          end
        end
        local function _110_()
          if fn_meta["luau-note?"] then
            return ("\n- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `" .. fn_meta["luau-note?"] .. "`. Otherwise Luau gives an error.<br/>")
          else
            return ""
          end
        end
        res = (res .. "\n## " .. k .. "(" .. table.concat(fnl_2farglist, ", ") .. ")" .. _109_() .. _110_() .. "\n" .. (fnl_2fdocstring or "") .. "\n")
      else
        res = res
      end
    end
    output = res
  end
  local out = io.open("README.md", "w")
  local function close_handlers_10_auto(ok_11_auto, ...)
    out:close()
    if ok_11_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _113_()
    return out:write(output)
  end
  return close_handlers_10_auto(_G.xpcall(_113_, (package.loaded.fennel or debug).traceback))
end
local function make()
  local fennel = package.loaded.fennel
  do
    local myself = io.open("omeganum.fnl", "r")
    local out = io.open("omeganum.lua", "w")
    local function close_handlers_10_auto(ok_11_auto, ...)
      out:close()
      myself:close()
      if ok_11_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _115_()
      local function _117_()
        local _116_ = fennel.compileString(myself:read("*a"))
        return _116_
      end
      return out:write(_117_())
    end
    close_handlers_10_auto(_G.xpcall(_115_, (package.loaded.fennel or debug).traceback))
  end
  print("Wrote omeganum.lua")
  write_readme()
  print("Wrote README.md")
  local suc_3f, t = pcall(fennel.dofile, "faith.fnl")
  if suc_3f then
    package.loaded.faith = t
    return t.run({"tests"})
  else
    return print("Tests didn't run because `faith.fnl` isn't in the directory.")
  end
end
local tbl_14_auto = {["repl-command-make"] = make}
for k, v in pairs(omegaNum) do
  local k_15_auto, v_16_auto = k, v
  if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
    tbl_14_auto[k_15_auto] = v_16_auto
  else
  end
end
return tbl_14_auto