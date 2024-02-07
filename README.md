# OmegaNum.lua
[Join the Discord server!](https://discord.gg/xZnfNMnQDp)
OmegaNum is a port [of Naryuoko's OmegaNum](https://github.com/Naruyoko/OmegaNum.js) for Lua. This library is highly inaccurate for huge numbers, which is perfect for incremental games that intend to reach very big numbers quickly.
```lua
local om = require("omeganum")
print(tostring(om.add("1", 1))) --> 2
print(tostring(om.new(1) + om.new(1))) --> 2
```
# Contributing to this port
The original code is written in Fennel, a Lisp that compiles for Lua. For convenience I provide a Lua file aswell, but in reality you should edit the Fennel file.

This library also has tests. The tests depend on the [Faith](https://git.sr.ht/~technomancy/faith) library which must be put in the same directory. To run the tests, type in the terminal `fennel faith.fnl --tests tests`. If you're on Emacs, open the `tests.fnl` file and do `M-x inferior-lisp`. If you press <f3> on the original buffer for `tests.fnl` it will run the tests and show the results in the new buffer

To compile the file, run `fennel --plugin omeganum.fnl` and in the repl type `,make`. It should write the documentation to `README.md`, compile to `omeganum.lua` and run the tests

# Reference
## abs(omeganum)
Returns *omeganum* as a positive number always

## add(a, b)
- Aliases: `a + b` `omegaNum.add(a, b)`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a + b`. Otherwise Luau gives an error.<br/>
Adds *a* and *b*

## clone(omeganum)
Clones *omeganum*. This is needed because in Lua tables aren't copied everytime you do operations on them. As an example, the following code returns `3`
```lua
local x = {}
local y = x
y.x = 3
print(x.x)
```
OmegaNum clones the number everytime you do an operation on it such as addition or basically any other operation, so most likely you won't need to use this function

## compare(a, b)
Returns 0 if they're equal, 1 if a is greater or -1 if b is greater

## div(a, b)
- Aliases: `a / b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a / b`. Otherwise Luau gives an error.<br/>
Divides *a* by *b*

## eq(a, b)
- Aliases: `a == b`<br/>
Returns true if *a* is equal to *b*. Ensure both numbers are OmegaNums when using the `a == b` syntax as doing `omegaNum.new(n) == notAnOmegaNum` returns nil

## floor(n)
Turns *n* into an integer

## fromArray(number)
Creates an OmegaNum from an array. This function requires you to know OmegaNum's internal format, which is described in OmegaNum's github site

## fromNumber(number)
Creates an OmegaNum from a number

## fromString(string)
It parses the string and creates an OmegaNum from it. The format is quite elegant and I would recommend you to check OmegaNum's documentation for that as I don't think I'm fully qualified to explain it. Note that the format isn't 1:1 because I got kinda lazy tbh

## gt(a, b)
- Aliases: `a > b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a > b`. Otherwise Luau gives an error.<br/>
Returns true if *a* is greater than *b*

## isFinite(omeganum)
Returns true if *omeganum* is not an infinite number

## isInfinite(omeganum)
Returns true if *omeganum* is infinite. One way to reach infinity is by doing omegaNum.div(0, 0)

## isInteger(n)
Checks if *n* is an integer

## isNan(omeganum)
Returns true if *omeganum* is NaN. NaN is the result of an undefined math operation, for example, 0 / 0 returns NaN

## isNotOmegaNum(any)
Returns true if *any* is not an OmegaNum object

## isOmegaNum(any)
Returns true if *any* is an OmegaNum object

## log10(n)
Returns the logarithm of 10 by *n*, or in other words: what is *x* in 10^x = n

## lt(a, b)
- Aliases: `a < b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a < b`. Otherwise Luau gives an error.<br/>
Returns true if *a* is smaller than *b*

## lte(a, b)
- Aliases: `a <= b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a <= b`. Otherwise Luau gives an error.<br/>
Returns true if *a* is less or equal than *b*

## max(a, b)
- Aliases: `math.max(a, b) --[[only works in normal Lua]]`<br/>
Returns the biggest number, *a* or *b*

## min(a, b)
- Aliases: `math.min(a, b) --[[only works in normal Lua]]`<br/>
Returns the smallest number, *a* or *b*

## mod(x, y)
- Aliases: `a % b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a % b`. Otherwise Luau gives an error.<br/>
Returns the modulo of x over y

## mul(a, b)
- Aliases: `a * b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a * b`. Otherwise Luau gives an error.<br/>
Multiplies *a* by *b*. Note, if a number is too huge you should try powering it by a big number. When doing multiplication by two very big numbers, OmegaNum doesn't botter and just returns the biggest number.

## neg(omeganum)
- Aliases: `-a` `omegaNum.__unm(a)`<br/>
Returns the *omeganum* with the opposite sign, e.g: 1 -> -1 and -1 -> 1

## new(string-number-or-table, sign)
Creates an OmegaNum from a number, a string, or an array. If an OmegaNum is passed then it is cloned. The sign paramether is for when this function receives an array.

Internally, it calls the functions `omegaNum.fromString`, `omegaNum.fromNumber`, `omegaNum.fromArray` and `omegaNumber.clone` respectively

## pow(a, b)
- Aliases: `a ^ b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a ^ b`. Otherwise Luau gives an error.<br/>
Exponentiates *a* by *b+

## reciprocate(n)
- Aliases: `1/n`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `1/n`. Otherwise Luau gives an error.<br/>
Returns the reciprocate, or in other words: 1 / *n*

## root(x, y)
Returns the *y*-th root of *x*

## sub(a, b)
- Aliases: `a - b`<br/>
- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `a - b`. Otherwise Luau gives an error.<br/>
Substracts *b* from *a*

## toNumber(omeganum)
Converts an OmegaNum number into a Lua number. Mostly used interanally as there's not much point on using this.
