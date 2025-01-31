;; Property Marketplace Smart Contract
;; Enables buying and selling of property tokens

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
(define-constant ERR-LISTING-NOT-FOUND (err u1))
(define-constant ERR-INSUFFICIENT-FUNDS (err u2))
(define-constant ERR-NOT-OWNER (err u3))
(define-constant ERR-INVALID-PRICE (err u4))
(define-constant ERR-INVALID-TOKEN-ID (err u5))
(define-constant ERR-INVALID-TOKEN-CONTRACT (err u6))

;; Property listing map
(define-map property-listings 
  { token-id: uint }
  { 
    price: uint, 
    seller: principal, 
    is-active: bool 
  }
)

;; Validate token ID
(define-private (is-valid-token-id (token-id uint))
  (and (> token-id u0) (< token-id u10000)))

;; Validate token contract
(define-private (is-valid-token-contract (token-contract <ft-trait>))
  (let 
    (
      (name (contract-call? token-contract get-name))
      (symbol (contract-call? token-contract get-symbol))
    )
    (and 
      (is-ok name)
      (is-ok symbol)
    )
  )
)

;; List a property token for sale
(define-public (list-property-token 
  (token-contract <ft-trait>) 
  (token-id uint) 
  (price uint))
  (begin
    ;; Validate token contract
    (asserts! (is-valid-token-contract token-contract) ERR-INVALID-TOKEN-CONTRACT)
    
    ;; Validate inputs
    (asserts! (is-valid-token-id token-id) ERR-INVALID-TOKEN-ID)
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! 
      (> 
        (unwrap! 
          (contract-call? token-contract get-balance tx-sender) 
          ERR-NOT-OWNER
        )
        u0
      ) 
      ERR-NOT-OWNER
    )
    
    ;; Create listing
    (map-set property-listings 
      { token-id: token-id }
      { 
        price: price, 
        seller: tx-sender, 
        is-active: true 
      }
    )
    (ok true)))

;; Purchase a listed property token
(define-public (buy-property-token 
  (token-contract <ft-trait>) 
  (token-id uint))
  (begin
    ;; Validate token contract
    (asserts! (is-valid-token-contract token-contract) ERR-INVALID-TOKEN-CONTRACT)
    
    ;; Validate token ID
    (asserts! (is-valid-token-id token-id) ERR-INVALID-TOKEN-ID)
    
    ;; Get listing details
    (let 
      (
        (listing (unwrap! 
          (map-get? property-listings { token-id: token-id }) 
          ERR-LISTING-NOT-FOUND
        ))
        (seller (get seller listing))
        (price (get price listing))
      )
      ;; Additional validation checks
      (asserts! (get is-active listing) ERR-LISTING-NOT-FOUND)
      (asserts! (not (is-eq tx-sender seller)) ERR-NOT-OWNER)
      
      ;; Complete transaction
      (try! (stx-transfer? price tx-sender seller))
      (try! (contract-call? token-contract transfer token-id seller tx-sender))
      
      ;; Update listing status
      (map-set property-listings 
        { token-id: token-id }
        { 
          price: price, 
          seller: tx-sender, 
          is-active: false 
        }
      )
      (ok true))))
