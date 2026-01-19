--- demo: Example module showing proper documentation
---
--- This module demonstrates the documentation format expected by the
--- cosmic-lua documentation validator.
---
---@module demo

local record MathModule
  --- Add two numbers together
  ---
  ---@param a number First number to add
  ---@param b number Second number to add
  ---@return number The sum of a and b
  ---@example
  ---   local math = require("demo")
  ---   print(math.add(5, 3))  -- outputs: 8
  add: function(a: number, b: number): number

  --- Multiply two numbers
  ---
  ---@param a number First number to multiply
  ---@param b number Second number to multiply
  ---@return number The product of a and b
  ---@example
  ---   local math = require("demo")
  ---   print(math.multiply(4, 7))  -- outputs: 28
  multiply: function(a: number, b: number): number
end

--- Add two numbers together
---
--- Performs simple addition of two numeric values.
---
---@param a number First number to add
---@param b number Second number to add
---@return number The sum of a and b
---@example
---   local math = require("demo")
---   local result = math.add(5, 3)
---   print(result)  -- outputs: 8
local function add(a: number, b: number): number
  return a + b
end

--- Multiply two numbers
---
--- Performs simple multiplication of two numeric values.
---
---@param a number First number to multiply
---@param b number Second number to multiply
---@return number The product of a and b
---@example
---   local math = require("demo")
---   local result = math.multiply(4, 7)
---   print(result)  -- outputs: 28
local function multiply(a: number, b: number): number
  return a * b
end

local M: MathModule = {
  add = add,
  multiply = multiply,
}

return M
