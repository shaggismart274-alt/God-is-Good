;; Simple STX vesting contract (portable + minimal)
;; - Owner initializes a beneficiary, start height, duration, and total amount (in microSTX)
;; - Anyone can fund the contract with STX via `fund` (transfers STX into the contract)
;; - Beneficiary calls `claim` any time to withdraw the vested portion
;; - Linear vesting from `start` over `duration` blocks

(define-data-var beneficiary (optional principal) none)
(define-data-var start uint u0)
(define-data-var duration uint u0)
(define-data-var total-vested uint u0)
(define-data-var claimed uint u0)
(define-data-var initialized bool false)

(define-constant ERR-NOT-OWNER u100)
(define-constant ERR-ALREADY-INIT u101)
(define-constant ERR-NO-BENEFICIARY u102)
(define-constant ERR-NOTHING-TO-CLAIM u103)

;; --- helpers ---
(define-read-only (owner)
  (ok (contract-owner))
)

(define-read-only (is-owner (who principal))
  (is-eq who (contract-owner))
)

(define-read-only (elapsed)
  (if (<= (var-get start) block-height)
      (- block-height (var-get start))
      u0))

(define-read-only (vested)
  (let ((d (var-get duration))
        (t (var-get total-vested))
        (e (elapsed)))
    (if (is-eq d u0)
        u0
        (/ (* t (if (> e d) d e)) d)))
)

(define-read-only (available)
  (let ((v (vested)) (c (var-get claimed)))
    (if (> v c) (- v c) u0)))

;; --- admin ---
(define-public (init (ben principal) (start-h uint) (dur uint) (total uint))
  (begin
    (asserts! (is-eq tx-sender (contract-owner)) (err ERR-NOT-OWNER))
    (asserts! (not (var-get initialized)) (err ERR-ALREADY-INIT))
    (var-set beneficiary (some ben))
    (var-set start start-h)
    (var-set duration dur)
    (var-set total-vested total)
    (var-set initialized true)
    (ok true)))

;; Transfer STX from caller into the contract
(define-public (fund (amount uint))
  (stx-transfer? amount tx-sender (as-contract tx)))

;; --- user ---
(define-public (claim)
  (match (var-get beneficiary)
    ben
    (let ((amt (available)))
      (asserts! (> amt u0) (err ERR-NOTHING-TO-CLAIM))
      (var-set claimed (+ (var-get claimed) amt))
      (try! (stx-transfer? amt (as-contract tx) ben))
      (ok amt))
    (err ERR-NO-BENEFICIARY)))

;; --- views ---
(define-read-only (get-state)
  { beneficiary: (var-get beneficiary)
  , start: (var-get start)
  , duration: (var-get duration)
  , total: (var-get total-vested)
  , claimed: (var-get claimed)
  , initialized: (var-get initialized) })

(define-read-only (get-available)
  (available))
