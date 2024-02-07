(local t (require :faith))
(local om (require :omeganum))

(local log10 math.log10)
(local inf math.huge)
(local -inf (- math.huge))
(local nan (math.acos 2))

(local max-safe-integer 9007199254740991)
(local max-safe-integer+1 (+ max-safe-integer 1))
(local max-e (log10 max-safe-integer))
(local ee-max-safe-integer+1 "ee9007199254740992")
(local tetrated-max-safe-integer+1
       (om.new (.. "(10^^)^1 " max-safe-integer+1)))

(fn nan? [n]
  (not= n n))

(fn test-omeganum-normalize [_data]
  (t.= {:array [0] :sign 1} (om.new []))
  (t.= {:array [0] :sign 1} (om.new [0]))
  (t.= {:array [0] :sign 1} (om.new [nil]))
  (let [n (om.new [1 2 nan 3 4])]
      (t.not= (. n.array 1) (. n.array 1)))
  (t.= (om.new [1 5]) (om.new [1 5.5]))
  (t.= {:array [0.5] :sign 1} (om.new [0.5]))

  (t.= {:array [10] :sign 1} (om.new [10 0]))
  (t.= {:array [max-safe-integer] :sign 1} (om.new [max-safe-integer]))
  (t.= {:array [max-e 1] :sign 1} (om.new [max-safe-integer+1]))
  (t.= {:array [max-e 1 1 1 1] :sign 1} (om.new [max-e 1.5 1.5 1.5 1.5]))
  (t.= {:array [10] :sign 1} (om.new [0 2]))
  (t.= {:array [10] :sign 1} (om.new [1 0 1]))
  (t.= {:array [1e10 8] :sign 1} (om.new [1 0 2]))
  (t.= {:array [1e10 8 8] :sign 1} (om.new [1 0 0 2]))
  (t.= {:array [1e10 8 8 1] :sign 1} (om.new [1 0 0 3]))
  (t.= {:array [max-e 1 1] :sign 1} (om.new [max-safe-integer+1 max-safe-integer+1]))
  (t.= {:array [max-e 1 0 1] :sign 1} (om.new [max-safe-integer+1 max-safe-integer+1 max-safe-integer+1])))

(fn test-omeganum-new-with-numbers [_data]
  (t.= {:array [0] :sign 1} (om.new 0))
  (t.= {:array [1] :sign 1} (om.new 1))
  (t.= {:array [1] :sign -1} (om.new -1))
  (t.= {:array [100 1] :sign 1} (om.new 1e100))
  (t.= {:array [inf] :sign 1} (om.new 1e1000))
  (t.= {:array [inf] :sign -1} (om.new -1e1000))
  (t.= {:array [1e-100] :sign 1} (om.new 1e-100))
  (t.= {:array [0] :sign -1} (om.new 1e-1000))
  (let [n (om.new nan)]
      (t.is (nan? (. n.array 1)))))

(fn test-omeganum-new-with-strings [_data]
  (t.= {:array [0] :sign 1} (om.new "+0"))
  (t.= {:array [0] :sign -1} (om.new "-0"))
  (t.is (om.isNan (om.new "NaN")))
  (t.= {:array [inf] :sign 1} (om.new "Infinity"))
  (t.error "Malformed expression" #(om.new ""))
  (t.error "Malformed expression" #(om.new "(9^)^1 1"))
  (t.error "Malformed expression" #(om.new "(10^)^1"))
  (t.error "Malformed expression" #(om.new "(10{0})^1 1"))
  (t.error "Malformed expression" #(om.new "(10{1})^0 1"))
  ;; (t.error "Malformed expression" #(om.new "1e"))
  (t.= {:array [10] :sign 1} (om.new "(10^)^1 1"))
  (t.= {:array [1e10 8] :sign 1} (om.new "(10^^)^2 1"))
  (t.= {:array [1e10 9007199254740989] :sign 1}
       (om.new (.. "(10^^)^1 " max-safe-integer)))
  (t.= {:array [1e10 (- 1e10 2)] :sign 1} (om.new "(10^^)^2 2"))
  (t.= {:array [1e10 (- 1e10 2)] :sign 1} (om.new "(10^^)^2 2"))
  (t.= {:array [1e10 8 8 8 8 3] :sign 1} (om.new "(10{5})^5 1"))
  (t.= {:array [1e10 8 8 8 8 8] :sign 1} (om.new "(10{5})^5 (10{5})^5 1"))
  (t.= {:array [10] :sign 1} (om.new "1e1") (om.new "e1"))
  (t.= {:array [16 1] :sign 1} (om.new (.. "1" (string.rep "0" "16"))))
  (let [n (om.new "5e5e5e5e5")]
    (t.almost= 500000.69897 (. n.array 1) 10)))

(fn test-omeganum-compare [_data]
  (t.is (nan? (om.compare nan 1)))
  (t.is (nan? (om.compare 1 nan)))
  (t.= -1 (om.compare -inf 1))
  (t.= 1 (om.compare 1 -inf))
  (t.= 0 (om.compare [0] [0]))
  (t.= -1 (om.compare -1 1))
  (t.= -1 (om.compare (om.new [16 1] -1) 1))
  (t.= 1 (om.compare 1 (om.new [16 1] -1)))
  (t.= 1 (om.compare [16 2] [16 1]))
  (t.= -1 (om.compare [16 1] [16 2]))
  (t.= 0 (om.compare [16 1] [16 1])))

(fn test-omeganum-math [_data]
  ;; division
  (t.= {:array [5] :sign -1} (om.__div 10 -2))
  (t.= {:array [5] :sign 1} (om.__div -10 -2))
  (t.is (om.isNan (om.__div 1 nan)))
  (t.is (om.isNan (om.__div nan 1)))
  (t.is (om.isNan (om.__div inf inf)))
  (t.is (om.isNan (om.__div 0 0)))
  (t.= {:array [inf] :sign 1} (om.__div 1 0))
  (t.= {:array [5] :sign 1} (om.__div 5 1))
  (t.= {:array [1] :sign 1} (om.__div 5 5))
  (t.= {:array [inf] :sign -1} (om.__div -inf 5))
  (t.= {:array [1] :sign 1} (om.__div 5 inf))
  (t.= (om.new ee-max-safe-integer+1) (om.__div ee-max-safe-integer+1 2))
  (t.= {:array [0] :sign 1} (om.__div 1 ee-max-safe-integer+1))
  (t.= {:array [5] :sign 1} (om.__div 10 2))
  (t.= (om.new [max-e 1]) (om.__div (/ max-safe-integer+1 2) 0.5))
  ;; multiplication
  (t.= {:array [20] :sign -1} (om.mul 10 -2))
  (t.= {:array [20] :sign 1} (om.mul -10 -2))
  (t.is (om.isNan (om.mul 1 nan)))
  (t.is (om.isNan (om.mul nan 1)))
  (t.is (om.isNan (om.mul 0 inf)))
  (t.is (om.isNan (om.mul inf 0)))
  (t.= {:array [0] :sign 1} (om.mul 1 0))
  (t.= {:array [10] :sign 1} (om.mul 10 1))
  (t.= {:array [inf] :sign -1} (om.mul -inf 2))
  (t.= {:array [inf] :sign -1} (om.mul 2 -inf))
  (t.= (om.new ee-max-safe-integer+1)
       (om.mul 2 ee-max-safe-integer+1))
  (t.= {:array [20] :sign 1} (om.mul 10 2))
  (t.= {:array [max-e 1] :sign 1}
       (om.mul (/ max-safe-integer+1 2) 2))
  ;; powering
  (t.= {:array [1] :sign 1} (om.__pow 10 0))
  (t.= {:array [10] :sign 1} (om.__pow 10 1))
  (t.= {:array [(^ 10 0.5)] :sign 1} (om.__pow 10 0.5))
  (t.= {:array [4.0] :sign 1} (om.__pow -2 2))
  (t.= {:array [8] :sign -1} (om.__pow -2 3))
  (t.is (om.isNan (om.__pow -1 1.5)))
  (t.= {:array [1] :sign 1} (om.__pow 1 999))
  (t.= {:array [0] :sign 1} (om.__pow 0 999))
  (t.= {:array [0] :sign 1} (om.__pow 0 999))
  (t.= tetrated-max-safe-integer+1
       (om.__pow tetrated-max-safe-integer+1 10))
  (t.= tetrated-max-safe-integer+1
       (om.__pow 10 tetrated-max-safe-integer+1))
  (t.= {:array [(^ 10 5)] :sign 1} (om.__pow 10 5))
  (t.= {:array [(^ 10 -5)] :sign 1} (om.__pow 10 -5))
  (t.= {:array [(math.sqrt 10)] :sign 1} (om.__pow 10 0.5))
  (t.= {:array [4096] :sign 1} (om.__pow 64 2))
  (t.= {:array [max-e 1] :sign 1}
       (om.__pow (math.sqrt max-safe-integer+1) 2)))

{: test-omeganum-new-with-numbers
 : test-omeganum-new-with-strings
 : test-omeganum-normalize
 : test-omeganum-compare
 : test-omeganum-math}

;; Local Variables:
;; eval: (local-set-key (kbd "<f3>") (lambda () (interactive) (comint-send-string (inferior-lisp-proc) "(do (set package.loaded.tests nil) (set package.loaded.omeganum nil) ((. (require :faith) :run) [:tests]))\n")))
;; End:
