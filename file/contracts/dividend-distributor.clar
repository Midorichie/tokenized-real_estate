;; Dividend Distributor Smart Contract
;; Manages dividend distribution for property tokens

(define-trait ft-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 10) uint))
    (get-decimals () (response uint uint))
  )
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-FUNDS (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-INVALID-PROPERTY-ID (err u4))

;; Dividend tracking
(define-map property-dividends 
  { property-id: uint }
  { 
    total-dividend: uint, 
    last-distribution-block: uint 
  }
)

;; Validate property ID
(define-private (is-valid-property-id (property-id uint))
  (and (> property-id u0) (< property-id u1000)))

;; Record incoming rental income
(define-public (record-rental-income 
  (property-id uint) 
  (amount uint))
  (begin
    ;; Validate input
    (asserts! (is-valid-property-id property-id) ERR-INVALID-PROPERTY-ID)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    ;; Record dividend
    (map-set property-dividends
      { property-id: property-id }
      { 
        total-dividend: amount, 
        last-distribution-block: block-height 
      }
    )
    (ok true)))

;; Distribute dividends to token holders
(define-public (distribute-dividends 
  (token-contract <ft-trait>) 
  (property-id uint))
  (begin
    ;; Validate property ID
    (asserts! (is-valid-property-id property-id) ERR-INVALID-PROPERTY-ID)
    
    ;; Get dividend details
    (let 
      (
        (dividend-info (unwrap! 
          (map-get? property-dividends { property-id: property-id }) 
          ERR-INSUFFICIENT-FUNDS
        ))
        (total-dividend (get total-dividend dividend-info))
      )
      ;; Validate dividend distribution
      (asserts! (> total-dividend u0) ERR-INSUFFICIENT-FUNDS)
      
      ;; Distribute dividends
      (try! (as-contract (stx-transfer? total-dividend tx-sender .property-marketplace)))
      (ok true))))
