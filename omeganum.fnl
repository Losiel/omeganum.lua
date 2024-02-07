(comment "MIT License

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
SOFTWARE.")

(comment "
  This is an implementation of OmegaNum[1] for Lua
coded in Fennel by alonzon. (also `alonzon` on Discord)

[1]: https://github.com/Naruyoko/OmegaNum.js")

(eval-compiler
  ;; Ensure Fennel 1.3.0 is used
  (let [major-and-minor (string.match (or version "") "^(%d+%.%d+)")
        version-n (and major-and-minor (tonumber major-and-minor))]
    (if (not version-n)
        (error "Couldn't detect Fennel version. Make sure to use 1.3.0")
        (< version-n 1.3)
        (error (.. "Use Fennel version 1.3.0\nCurrent version: " version)))))

(local unpack (or table.unpack _G.unpack))
(local abs math.abs)
(local floor math.floor)
(local repeat string.rep)
(local log10 math.log10)
(local tostring tostring)

(local min math.min)
(local max math.max)

(local *MAX-ARROWS* 1000)
(local *MAX-SAFE-INTEGER* 9007199254740991)
(local *MAX-E* (log10 *MAX-SAFE-INTEGER*))
(local *MAX-LUA-NUMBER* 1.7976931348623157E+308)
(local *MAX-LUA-E* (log10 *MAX-LUA-NUMBER*))
(local *NAN* (math.acos 2))
(local *INF* math.huge)
(local *LONG-STRING-MIN-LENGTH* 17)

(fn nan? [n]
  ;; stackoverflow.com/questions/37753694/lua-check-if-a-number-value-is-nan
  (not= n n))

(fn ftostring [n]
  (local f (floor n))
  (if (= f n)
      (tostring f)
      (tostring n)))

(macro assert-type= [value value-type]
  (assert-compile (not (list? value)))
  (assert-compile (not (list? value-type)))
  `(when (not= (type ,value) ,value-type)
     (error ,(if (= :string (type value-type))
                 `(.. ,(.. "Expected " value-type ", got ") (type ,value))
                 `(.. "Expected " ,value-type ", got " (type ,value))))))

(fn false-or-zero? [value]
  (or (= value 0) (not value)))

(fn not-false-or-zero? [value]
  (and value (not= value 0)))

(local omegaNum {})
(set omegaNum.__index omegaNum)

(macro new-omega-num [arr sign]
  `(setmetatable {:array ,arr :sign ,sign} omegaNum))

(set omegaNum.ZERO (new-omega-num [0] 1))
(set omegaNum.ONE (new-omega-num [1] 1))
(set omegaNum.INF (new-omega-num [*INF*] 1))
(set omegaNum.NEG_INF (new-omega-num [*INF*] -1))
(set omegaNum.NAN (new-omega-num [*NAN*] 1))
(set omegaNum.E_MAX_SAFE_INTEGER
     (new-omega-num [*MAX-SAFE-INTEGER* 1] 1))
(set omegaNum.EE_MAX_SAFE_INTEGER
     (new-omega-num [*MAX-SAFE-INTEGER* 2] 1))
(set omegaNum.TETRATED_MAX_SAFE_INTEGER
     (new-omega-num [1e10 9007199254740989] 1))

(fn normalize-magnitude [array]
  (local first (. array 1))
  (local sec (. array 2))
  (if (= (length array) 0)
      nil
      (= 0 (. array (length array)))
      (do (table.remove array)
          (normalize-magnitude array))
      (> first *MAX-SAFE-INTEGER*)
      (do (tset array 1 (log10 first))
          (tset array 2 (+ (or sec 0) 1))
          (normalize-magnitude array))
      (and (< first *MAX-E*) (not-false-or-zero? sec))
      (do (tset array 1 (^ 10 first))
          (tset array 2 (- sec 1))
          (normalize-magnitude array))
      (and (> (length array) 2) (false-or-zero? sec))
      (do
        (var first-non-zero 3)
        (while (and (= 0 (. array first-non-zero))
                    (< first-non-zero (length array)))
          (set first-non-zero (+ first-non-zero 1)))
        (tset array (- first-non-zero 1) first)
        (tset array 1 1)
        (tset array first-non-zero (- (. array first-non-zero) 1))
        (normalize-magnitude array))
      :else
      (let [first-max (faccumulate [res nil
                                    i 2 (length array)
                                    &until res]
                        (when (> (. array i) *MAX-SAFE-INTEGER*)
                          i))]
        (when first-max
          (local _next (+ first-max 1))
          (tset array _next (+ (or (. array _next) 0) 1))
          (tset array 1 (+ (. array first-max) 1))
          (for [i 2 first-max]
            (tset array i 0))
          (normalize-magnitude array)))))

(fn omegaNum.normalize [self]
  ;; fix sign
  (when (not= :number (type self.sign))
    (let [num (tonumber self.sign)]
      (set self.sign (if (and num (< num 0))
                         -1
                         1))))
  
  ;; fix array
  (when (or (not self.array) (= 0 (length self.array)))
    (set self.array [0]))

  (for [i 1 (length self.array)]
    (let [v (. self.array i)]
      (if (nan? v)
          (do
            (set self.array [*NAN*])
            (lua "return self"))
          (= v *INF*)
          (do
            (set self.array [*INF*])
            (lua "return self"))
          (not= (type v) :number)
          (tset self.array i 0)
          (> i 1)
          (tset self.array i (floor v)))))
  
  (normalize-magnitude self.array)
  (when (= 0 (length self.array))
    (set self.array [0]))

  self)

(fn omegaNum.fromArray [arr sign]
  {:fnl/arglist [number]
   :fnl/docstring "Creates an OmegaNum from an array. This function requires you to know OmegaNum's internal format, which is described in OmegaNum's github site"}
  (assert-type= arr :table)
  (assert-type= sign :number)
  (-> (new-omega-num [(unpack arr)] sign)
      (: :normalize)))

(fn omegaNum.fromNumber [num]
  {:fnl/arglist [number]
   :fnl/docstring "Creates an OmegaNum from a number"}
  (assert-type= num :number)
  (-> (new-omega-num [(abs num)]
                     (if (< num 0) -1 1))
      (: :normalize)))

(macro inc [variable amount]
  `(set ,variable (+ ,variable ,(or amount 1))))

(local malformed-error "Malformed expression")

(fn parse-exponent [str i]
  ;; returns (i arrows exp)
  ;; eg: "(10^^^^)^5" would return (11 4 5)

  ;; eat whitespace:
  (var i (or (str:find "%S" i)
             (+ (# str) 1)))

  (case-try (str:find "^%(10(^+)%)^([1-9]%d*)" i)
    (_ patt-end arrows exp) (values (+ patt-end 1) (# arrows) (tonumber exp))
    (catch ?
     (let [(_ patt-end arrows exp) (str:find "^%(10%{([1-9]%d*)%}%)^([1-9]%d*)" i)]
       (if arrows
           (values (+ patt-end 1) (tonumber arrows) (tonumber exp))
           nil)))))

(fn parse-exponents [str i res]
  (let [old-i i
        (i arrows exp) (parse-exponent str i)]
    (if (not i)
        old-i
        (= arrows 1)
        (do (tset res.array 2 (+ (or (. res.array 2) 0) exp))
            (parse-exponents str i res))
        (= arrows 2)
        (let [first (or (. res.array 1) 0)
              sec (or (. res.array 2) 0)]
          (tset res.array 1
                (if (>= first 1e10)
                    (+ sec 2)
                    (>= first 10)
                    (+ sec 1)
                    sec))
          (tset res.array 2 0)
          (tset res.array 3 (+ (or (. res.array 3) 0) exp))
          (parse-exponents str i res))
        (let [a (or (. res.array (+ arrows 1)) 0)
              b (or (. res.array arrows) 0)
              c (or (. res.array (- arrows 1)) 0)]
          (tset res.array 1 (if (>= c 10)
                                (+ b 1)
                                b))
          (tset res.array (+ arrows 1) (+ (or a 0) exp))
          (for [i 2 arrows]
            (tset res.array i 0))
          (parse-exponents str i res)))))

(fn log10-long-string [str]
  (log10 (+ (tonumber (str:sub 1 *LONG-STRING-MIN-LENGTH*))
            (- (# str) *LONG-STRING-MIN-LENGTH*))))

(fn parse-num [literal mag exp]
  ;; literal must be an array of strings
  ;; ["123"] = "123"
  ;; ["" "123"] = "e123"
  ;; ["4" "135"] = "4e135"
  ;; returns mag, exp (or in other words: omegaNum.fromArray([mag, exp], 1))
  (if (> (# literal) 0)
      (do
        (var (mag exp)
             (if (and (< mag *MAX-E*)
                      (= exp 0))
                 (values (^ 10 mag) exp)
                 (values mag (+ exp 1))))
        (local value (table.remove literal))
        (local (integer dot decimal-part) (value:match "^([-+]?%d*)(%.?)(%d*)$"))
        (assert integer malformed-error)
        (local safe-num (if (> (# value) 0) (tonumber value) 0))
        (if (= exp 0)
            (set (mag exp)
                 (if (>= (# integer) *LONG-STRING-MIN-LENGTH*)
                     (values (+ (log10 mag) (log10-long-string integer)) 1)
                     (> (# value) 0)
                     (values (* mag safe-num) exp)
                     (values mag exp)))
            (let [log-num
                  (if (>= (# integer) *LONG-STRING-MIN-LENGTH*)
                      (log10-long-string integer)
                      (> (# integer) 0)
                      (log10 safe-num)
                      0)]
              (set mag
                   (if (= exp 1)
                       (+ mag log-num)
                       (and (= exp 2)
                            (< mag (+ *MAX-E* (log10 log-num))))
                       (+ mag (log10 (+ 1 (^ 10 (- (log10 log-num) mag)))))
                       mag))))
        (if (and (< mag *MAX-E*)
                 (not= exp 0))
            (parse-num literal (^ 10 mag) (- exp 1))
            (> mag *MAX-SAFE-INTEGER*)
            (parse-num literal (log10 mag) (+ exp 1))
            (parse-num literal mag exp)))
      (values mag exp)))

(fn omegaNum.fromString [str]
  {:fnl/arglist [string]
   :fnl/docstring "It parses the string and creates an OmegaNum from it. The format is quite elegant and I would recommend you to check OmegaNum's documentation for that as I don't think I'm fully qualified to explain it. Note that the format isn't 1:1 because I got kinda lazy tbh"}
  (assert-type= str :string)
  (var i 1)

  (local sign
         (case-try (str:match "^[-+]" i)
           sign (do (inc i)
                    (if (= sign "-") -1 1))
           (catch ? 1)))
  
  (local str (str:lower))
  (if (str:match "^nan" i)
      (new-omega-num [*NAN*] sign)
      (str:match "^infinity" i)
      (new-omega-num [*INF*] sign)
      (let [res (new-omega-num [0] sign)]
        (set i (parse-exponents str i res))
        (set i (str:find "%S" i))
        (assert i malformed-error)
        (local (mag exp)
               (parse-num (if string.split ; i hate Luau
                              (string.split (str:sub i) "e")
                              (icollect [num (str:gmatch "[^e]*" i)]
                                num)) (. res.array 1) 0))
        (tset res.array 1 mag)
        (tset res.array 2 (+ (or (. res.array 2) 0) exp))
        (res:normalize))))

(fn omegaNum.new [a b]
  {:fnl/arglist [string-number-or-table sign]
   :fnl/docstring "Creates an OmegaNum from a number, a string, or an array. If an OmegaNum is passed then it is cloned. The sign paramether is for when this function receives an array.

Internally, it calls the functions `omegaNum.fromString`, `omegaNum.fromNumber`, `omegaNum.fromArray` and `omegaNumber.clone` respectively"}
  (if (= (type a) :string)
      (omegaNum.fromString a)
      (= (type a) :number)
      (omegaNum.fromNumber a)
      (and (= (type a) :table) (= a.__index omegaNum))
      (a:clone)
      (= (type a) :table)
      (omegaNum.fromArray a (or b 1))
      :else
      (error (.. "Unexpected type " (type a)))))

(fn omegaNum.clone [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Clones *omeganum*. This is needed because in Lua tables aren't copied everytime you do operations on them. As an example, the following code returns `3`
```lua
local x = {}
local y = x
y.x = 3
print(x.x)
```
OmegaNum clones the number everytime you do an operation on it such as addition or basically any other operation, so most likely you won't need to use this function"}
  (new-omega-num [(unpack self.array)] self.sign))

(fn omegaNum.abs [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Returns *omeganum* as a positive number always"}
  (new-omega-num [(unpack self.array)] 1))

(fn omegaNum.neg [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Returns the *omeganum* with the opposite sign, e.g: 1 -> -1 and -1 -> 1"
   :aliases ["-a" "omegaNum.__unm(a)"]}
  (new-omega-num [(unpack self.array)] (- self.sign)))
(set omegaNum.__unm omegaNum.neg)

(fn omegaNum.isInfinite [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Returns true if *omeganum* is infinite. One way to reach infinity is by doing omegaNum.div(0, 0)"}
  (= (. self.array 1) *INF*))

(fn omegaNum.isFinite [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Returns true if *omeganum* is not an infinite number"}
  (not= (. self.array 1) *INF*))

(fn omegaNum.isNan [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Returns true if *omeganum* is NaN. NaN is the result of an undefined math operation, for example, 0 / 0 returns NaN"}
  (nan? (. self.array 1)))

(fn omegaNum.isOmegaNum [om]
  {:fnl/arglist [any]
   :fnl/docstring "Returns true if *any* is an OmegaNum object"}
  (and (= (type om) :table) (= om.__index omegaNum)))

(fn omegaNum.isNotOmegaNum [om]
  {:fnl/arglist [any]
   :fnl/docstring "Returns true if *any* is not an OmegaNum object"}
  (or (not= (type om) :table)
      (not= om.__index omegaNum)))

(fn compare-same-length-omeganums [a b i]
  (if (< i 1)
      0
      (> (. a.array i) (. b.array i))
      a.sign
      (< (. a.array i) (. b.array i))
      (* a.sign -1)
      (compare-same-length-omeganums a b (- i 1))))

(fn omegaNum.compare [self b]
  {:fnl/arglist [a b]
   :fnl/docstring "Returns 0 if they're equal, 1 if a is greater or -1 if b is greater"}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local b (if (omegaNum.isNotOmegaNum b)
               (omegaNum.new b)
               b))
  (if (or (self:isNan) (b:isNan))
      *NAN*
      (and (self:isInfinite) (b:isFinite))
      self.sign
      (and (self:isFinite) (b:isInfinite))
      (- b.sign)
      (not= self.sign b.sign)
      self.sign
      (> (# self.array) (# b.array))
      self.sign
      (< (# self.array) (# b.array))
      (* -1 self.sign)
      :else
      (compare-same-length-omeganums self b (# self.array))))

(fn omegaNum.log10 [self]
  {:fnl/arglist [n]
   :fnl/docstring "Returns the logarithm of 10 by *n*, or in other words: what is *x* in 10^x = n"}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (if (< self omegaNum.ZERO)
      omegaNum.NAN
      (= self omegaNum.ZERO)
      omegaNum.NEG_INF
      (self:__lte *MAX-SAFE-INTEGER*)
      (omegaNum.fromNumber (log10 (self:toNumber)))
      (self:isInfinite)
      self
      (> self omegaNum.TETRATED_MAX_SAFE_INTEGER)
      self
      :else
      (let [clone (self:clone)]
        (tset clone 2 (- (. clone.array 2) 1))
        (clone:normalize))))

(fn omegaNum.isInteger [self]
  {:fnl/arglist [n]
   :fnl/docstring "Checks if *n* is an integer"}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (if (= self.sign -1)
      (omegaNum.isInteger (self:abs))
      (self:__gt *MAX-SAFE-INTEGER*)
      true
      (let [tn (self:toNumber)]
        (= (floor tn) tn))))

(fn omegaNum.floor [self]
  {:fnl/arglist [n]
   :fnl/docstring "Turns *n* into an integer"}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (if (self:isInteger)
      (self:clone)
      (omegaNum.fromNumber (floor (self:toNumber)))))

(fn omegaNum.reciprocate [self]
  {:fnl/arglist [n]
   :fnl/docstring "Returns the reciprocate, or in other words: 1 / *n*"
   :luau-note? "1/n"
   :aliases ["1/n"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (if (or (self:isNan) (= self omegaNum.ZERO))
      omegaNum.NAN
      (/ omegaNum.ONE self)))

(fn omegaNum.mod [self other]
  {:fnl/arglist [x y]
   :fnl/docstring "Returns the modulo of x over y"
   :luau-note? "a % b"
   :aliases ["a % b"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local other (if (omegaNum.isNotOmegaNum other)
                  (omegaNum.new other)
                  other))
  (if (= other omegaNum.ZERO)
      omegaNum.ZERO
      (= (* self.sign other.sign) -1)
      (- (% (self:abs) (other:abs)))
      (= self.sign -1)
      (% (self:abs) (other:abs))
      (- self (* (floor (: (/ self other) :toNumber)) other))))
(set omegaNum.__mod omegaNum.mod)

(fn omegaNum.pow [self other]
  {:fnl/arglist [a b]
   :fnl/docstring "Exponentiates *a* by *b+"
   :luau-note? "a ^ b"
   :aliases ["a ^ b"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local other (if (omegaNum.isNotOmegaNum other)
                  (omegaNum.new other)
                  other))
  (if (= other omegaNum.ZERO)
      omegaNum.ONE
      (= other omegaNum.ONE)
      self
      (< other omegaNum.ZERO)
      (omegaNum.reciprocate (^ self (- other)))
      (and (< self omegaNum.ZERO)
           (other:isInteger))
      (if (< (other:__mod 2) omegaNum.ONE)
          (^ (self:abs) other)
          (- (^ (self:abs) other)))
      (< self omegaNum.ZERO)
      omegaNum.NAN
      (= self omegaNum.ONE)
      omegaNum.ONE
      (= self omegaNum.ZERO)
      omegaNum.ZERO
      (> (self:max other) omegaNum.TETRATED_MAX_SAFE_INTEGER)
      (self:max other)
      (self:__eq 10)
      (if (> other omegaNum.ZERO)
          (let [clone (other:clone)]
            (tset clone.array 2
                  (if (and (. clone.array 2)
                           (not= (. clone.array 2) -1))
                      (+ (. clone.array 2) 1)
                      1))
            (clone:normalize))
          (omegaNum.fromNumber (^ 10 (other:toNumber))))
      (< other omegaNum.ONE)
      (self:root (other:reciprocate))
      (let [n (^ (self:toNumber) (other:toNumber))]
        (if (<= n *MAX-SAFE-INTEGER*)
            (omegaNum.fromNumber n)
            (omegaNum.__pow 10 (* (self:log10) other))))))
(set omegaNum.__pow omegaNum.pow)

(fn omegaNum.root [self other]
  {:fnl/arglist [x y]
   :fnl/docstring "Returns the *y*-th root of *x*"}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local other (if (omegaNum.isNotOmegaNum other)
                   (omegaNum.new other)
                   other))
  (if (= other omegaNum.ZERO)
      (self:clone)
      (< other omegaNum.ZERO)
      (: (self:root (- other)) :reciprocate)
      (< other omegaNum.ONE)
      (^ self (other:reciprocate))
      (and (< self omegaNum.ZERO)
           (other:isInteger)
           (= (other:__mod 2) omegaNum.ONE))
      (- (: (- self) :root other))
      (< self omegaNum.ZERO)
      omegaNum.NAN
      (= self omegaNum.ONE)
      omegaNum.ONE
      (= self omegaNum.ZERO)
      omegaNum.ZERO
      (> (self:max other) omegaNum.TETRATED_MAX_SAFE_INTEGER)
      (if (> self other)
          (self:clone)
          omegaNum.ZERO)
      (omegaNum.__pow 10 (/ (self:log10) other))))

(fn omegaNum.mul [self other]
  {:fnl/arglist [a b]
   :fnl/docstring "Multiplies *a* by *b*. Note, if a number is too huge you should try powering it by a big number. When doing multiplication by two very big numbers, OmegaNum doesn't botter and just returns the biggest number."
   :luau-note? "a * b"
   :aliases ["a * b"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local other (if (omegaNum.isNotOmegaNum other)
                   (omegaNum.new other)
                   other))
  
  (if (= (* self.sign other.sign) -1)
      (- (* (self:abs) (other:abs)))
      (= self.sign -1)
      (* (self:abs) (other:abs))
      (or (self:isNan) (other:isNan)
          (and (= self omegaNum.ZERO)
               (other:isInfinite))
          (and (self:isInfinite)
               (= (other:abs) omegaNum.ZERO)))
      omegaNum.NAN
      (= other omegaNum.ZERO)
      omegaNum.ZERO
      (= other omegaNum.ONE)
      (self:clone)
      (self:isInfinite)
      self
      (other:isInfinite)
      other
      (> (self:max other) omegaNum.EE_MAX_SAFE_INTEGER)
      (self:max other)
      (let [n (* (self:toNumber) (other:toNumber))]
        (if (<= n *MAX-SAFE-INTEGER*)
            (omegaNum.fromNumber n)
            (omegaNum.__pow 10 (+ (self:log10) (other:log10)))))))
(set omegaNum.__mul omegaNum.mul)

(fn omegaNum.div [self other]
  {:fnl/arglist [a b]
   :fnl/docstring "Divides *a* by *b*"
   :luau-note? "a / b"
   :aliases ["a / b"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local other (if (omegaNum.isNotOmegaNum other)
                   (omegaNum.new other)
                   other))
  (local gt (self:max other))
  
  (if (= (* self.sign other.sign) -1)
      (- (/ (self:abs) (other:abs)))
      (= self.sign -1)
      (/ (self:abs) (other:abs))
      (or (self:isNan)
          (other:isNan)
          (and (self:isInfinite) (other:isInfinite))
          (= self omegaNum.ZERO other))
      omegaNum.NAN
      (= other omegaNum.ZERO)
      omegaNum.INF
      (= other omegaNum.ONE)
      self
      (= self other)
      omegaNum.ONE
      (self:isInfinite)
      self
      (other:isInfinite)
      omegaNum.ZERO
      (gt:__gt omegaNum.EE_MAX_SAFE_INTEGER)
      (if (= gt self)
          self
          omegaNum.ZERO)
      :else
      (let [n (/ (self:toNumber) (other:toNumber))]
        (if (<= n *MAX-SAFE-INTEGER*)
            (omegaNum.fromNumber n)
            (let [pw (omegaNum.__pow 10 (- (self:log10) (other:log10)))
                  fp (pw:floor)]
              (if (< (- pw fp) (omegaNum.fromNumber 1e-9))
                  fp
                  pw))))))
(set omegaNum.__div omegaNum.div)

(fn omegaNum.add [self other]
  {:fnl/arglist [a b]
   :fnl/docstring "Adds *a* and *b*"
   :luau-note? "a + b"
   :aliases ["a + b" "omegaNum.add(a, b)"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local other (if (omegaNum.isNotOmegaNum other)
                   (omegaNum.new other)
                   other))
  (local lw (self:min other))
  (local gt (self:max other))
  (local n (self:__lt other))
  (if (= self.sign -1)
      (- (+ (- self) (- other)))
      (= other.sign -1)
      (- self (- other))
      (= self omegaNum.ZERO)
      other
      (= other omegaNum.ZERO)
      self
      (or (self:isNan) (other:isNan)
          (and (self:isInfinite) (other:isInfinite)
               (not= self.sign other.sign)))
      omegaNum.NAN
      (self:isInfinite)
      self
      (other:isInfinite)
      other
      (or (> gt omegaNum.E_MAX_SAFE_INTEGER)
          (omegaNum.__gt (/ gt lw) *MAX-SAFE-INTEGER*))
      gt
      (false-or-zero? (. gt.array 2))
      (omegaNum.fromNumber (+ (self:toNumber) (other:toNumber)))
      (= (. gt.array 2) 1)
      (let [a (if (false-or-zero? (. lw.array 2))
                  (. lw.array 1)
                  (log10 (. lw.array 1)))
            res (+ a (log10 (+ (^ 10 (- (. gt.array 1) a)) 1)))]
        (new-omega-num [res 1] 1))))
(set omegaNum.__add omegaNum.add)

(fn omegaNum.sub [self other]
  {:fnl/arglist [a b]
   :fnl/docstring "Substracts *b* from *a*"
   :luau-note? "a - b"
   :aliases ["a - b"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (local other (if (omegaNum.isNotOmegaNum other)
                   (omegaNum.new other)
                   other))
  (local lw (self:min other))
  (local gt (self:max other))
  (local n (self:__lt other))
  (if (= self.sign -1)
      (- (- (- self) (- other)))
      (= other.sign -1)
      (+ self (- other))
      (= self other)
      omegaNum.ZERO
      (= other omegaNum.ZERO)
      self
      (or (self:isNan) (other:isNan)
          (and (self:isInfinite) (other:isInfinite)))
      omegaNum.NAN
      (self:isInfinite)
      self
      (other:isInfinite)
      other
      (or (> gt omegaNum.E_MAX_SAFE_INTEGER)
          (omegaNum.__gt (/ gt lw) *MAX-SAFE-INTEGER*))
      (if n
          (doto (gt:clone)
            (tset :sign -1))
          gt)
      (false-or-zero? (. gt.array 2))
      (omegaNum.fromNumber (- (self:toNumber) (other:toNumber)))
      (= (. gt.array 2) 1)
      (let [a (if (false-or-zero? (. lw.array 2))
                  (. lw.array 1)
                  (log10 (. lw.array 1)))
            res (+ a (log10 (- (^ 10 (- (. gt.array 1) a)) 1)))]
        (new-omega-num [res 1] (if n -1 1)))))
(set omegaNum.__sub omegaNum.sub)

(fn omegaNum.eq [self b]
  {:fnl/arglist [a b]
   :fnl/docstring "Returns true if *a* is equal to *b*. Ensure both numbers are OmegaNums when using the `a == b` syntax as doing `omegaNum.new(n) == notAnOmegaNum` returns nil"
   :aliases ["a == b"]}
  (= (omegaNum.compare self b) 0))
(set omegaNum.__eq omegaNum.eq)

(fn omegaNum.lt [self b]
  {:fnl/arglist [a b]
   :fnl/docstring "Returns true if *a* is smaller than *b*"
   :luau-note? "a < b"
   :aliases ["a < b"]}
  (= (omegaNum.compare self b) -1))
(set omegaNum.__lt omegaNum.lt)

(fn omegaNum.lte [self b]
  {:fnl/arglist [a b]
   :fnl/docstring "Returns true if *a* is less or equal than *b*"
   :luau-note? "a <= b"
   :aliases ["a <= b"]}
  (<= (omegaNum.compare self b) 0))
(set omegaNum.__lte omegaNum.lte)

(fn omegaNum.gt [self b]
  {:fnl/arglist [a b]
   :fnl/docstring "Returns true if *a* is greater than *b*"
   :luau-note? "a > b"
   :aliases ["a > b"]}
  (= (omegaNum.compare self b) 1))
(set omegaNum.__gt omegaNum.gt)

(fn omegaNum.__len [self b]
  (length self.array))

(fn omegaNum.min [self b]
  {:fnl/arglist [a b]
   :fnl/docstring "Returns the smallest number, *a* or *b*"
   :aliases ["math.min(a, b) --[[only works in normal Lua]]"]}
  (if (omegaNum.__gt self b)
      b
      self))

(fn omegaNum.max [self b]
  {:fnl/arglist [a b]
   :fnl/docstring "Returns the biggest number, *a* or *b*"
   :aliases ["math.max(a, b) --[[only works in normal Lua]]"]}
  (if (omegaNum.__lt self b)
      b
      self))

(fn omegaNum.toNumber [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Converts an OmegaNum number into a Lua number. Mostly used interanally as there's not much point on using this."}
  (if (= self.sign -1)
      (omegaNum.__mul -1 (: (self:abs) :toNumber))
      (and (>= (length self.array) 2)
           (or (>= (. self.array 2) 2)
               (and (= (. self.array 2) 1)
                    (> (. self.array 1) *MAX-LUA-E*))))
      *INF*
      (= (. self.array 2) 1)
      (^ 10 (. self.array 1))
      :else
      (. self.array 1)))

(fn omegaNum->string [res sign first sec ...]
  ;; must be called like
  ;; (omegaNum->string "" om.sign (unpack om.array))
  (if (nan? first)
      :nan
      (= first *INF*)
      :inf
      (= sign -1)
      (omegaNum->string "-" 1 first sec ...)
      ...
      (let [arr [...]
            i (length arr)
            value (table.remove arr)
            q (repeat (if (>= i 6) (.. "{" i "}") "^") i)
            res (if (> value 1) (.. res "(10" q ")^" value " ")
                    (= value 1) (.. res "10" q)
                    res)]
        (omegaNum->string res sign first sec (unpack arr)))
      (false-or-zero? sec)
      (.. res (ftostring first))
      (< sec 3)
      (let [ff (floor first)]
        (.. res (repeat :e (- sec 1)) (^ 10 (- first ff)) :e ff))
      (< sec 8)
      (.. res (repeat :e sec) (ftostring first))
      :else
      (.. res "(10^)^" (ftostring sec) " " (ftostring first))))

(fn omegaNum.__tostring [self]
  {:fnl/arglist [omeganum]
   :fnl/docstring "Converts a number into a human readable form (a string.)"
   :aliases ["tostring(omeganum)"]}
  (local self (if (omegaNum.isNotOmegaNum self)
                  (omegaNum.new self)
                  self))
  (omegaNum->string "" self.sign (unpack self.array)))

;;
;; tools for developers
;;
(comment "The rest of the code are tool for developers. You shouldn't use these functions in any way.")

(fn write-readme []
  (let [metadata package.loaded.fennel.metadata
        sorted-keys (doto (icollect [k (pairs omegaNum)] k)
                      (table.sort))
        output
        (accumulate [res "# OmegaNum.lua
[Join the Discord server!](https://discord.gg/xZnfNMnQDp)
OmegaNum is a port [of Naryuoko's OmegaNum](https://github.com/Naruyoko/OmegaNum.js) for Lua. This library is highly inaccurate for huge numbers, which is perfect for incremental games that intend to reach very big numbers quickly.
```lua
local om = require(\"omeganum\")
print(tostring(om.add(\"1\", 1))) --> 2
print(tostring(om.new(1) + om.new(1))) --> 2
```
# Contributing to this port
The original code is written in Fennel, a Lisp that compiles for Lua. For convenience I provide a Lua file aswell, but in reality you should edit the Fennel file.

This library also has tests. The tests depend on the [Faith](https://git.sr.ht/~technomancy/faith) library which must be put in the same directory. To run the tests, type in the terminal `fennel faith.fnl --tests tests`. If you're on Emacs, open the `tests.fnl` file and do `M-x inferior-lisp`. If you press <f3> on the original buffer for `tests.fnl` it will run the tests and show the results in the new buffer

To compile the file, run `fennel --plugin omeganum.fnl` and in the repl type `,make`. It should write the documentation to `README.md`, compile to `omeganum.lua` and run the tests

# Reference"
                     _ k (ipairs sorted-keys)]
          (let [v (. omegaNum k)
                fn-meta (metadata:get v)
                {: fnl/docstring
                 : fnl/arglist
                 : aliases} (or fn-meta {})]
            (if (and fn-meta fnl/docstring (not (k:match "^__")))
                (.. res
                    "\n## " k "(" (table.concat fnl/arglist ", ")")"
                    (if aliases
                        (.. "\n- Aliases: "
                            "`" (table.concat aliases "` `") "`"
                            "<br/>")
                        "")
                    (if fn-meta.luau-note?
                        (.. "\n- Note when using Luau: Ensure both numbers are OmegaNums when using the following syntactic sugar: `" fn-meta.luau-note? "`. Otherwise Luau gives an error.<br/>")
                        "")
                    "\n" (or fnl/docstring "")
                    "\n")
                res)))]
    (with-open [out (io.open :README.md :w)]
      (out:write output))))

(fn make []
  (local fennel package.loaded.fennel)
  (with-open [myself (io.open :omeganum.fnl :r)
              out (io.open :omeganum.lua :w)]
    (out:write (pick-values 1 (fennel.compileString (myself:read :*a)))))
  (print "Wrote omeganum.lua")
  
  (write-readme)
  (print "Wrote README.md")

  (local (suc? t) (pcall fennel.dofile :faith.fnl))
  (if suc? (do (set package.loaded.faith t)
            (t.run [:tests]))
      (print "Tests didn't run because `faith.fnl` isn't in the directory.")))

(collect [k v (pairs omegaNum) &into {:repl-command-make make}]
  (values k v))
