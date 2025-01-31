;; Property Token Smart Contract
;; Manages fractional property ownership tokens

(define-fungible-token property-share)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-FUNDS (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-INVALID-RECIPIENT (err u4))

;; Token metadata
(define-data-var token-name (string-ascii 32) "RealEstate Token")
(define-data-var token-symbol (string-ascii 10) "RETOKEN")
(define-data-var total-supply uint u0)

;; Mint tokens for a specific property
(define-public (mint-tokens 
  (amount uint) 
  (recipient principal)
  (property-id uint))
  (begin
    ;; Validate input
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (not (is-eq recipient tx-sender)) ERR-INVALID-RECIPIENT)
    
    ;; Mint tokens with checks
    (try! (ft-mint? property-share amount recipient))
    
    ;; Update total supply
    (var-set total-supply (+ (var-get total-supply) amount))
    
    (print { 
      event: "mint", 
      amount: amount, 
      recipient: recipient, 
      property-id: property-id 
    })
    (ok true)))

;; Transfer property tokens
(define-public (transfer-tokens 
  (amount uint) 
  (sender principal) 
  (recipient principal))
  (begin
    ;; Validate input
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (not (is-eq sender recipient)) ERR-INVALID-RECIPIENT)
    
    ;; Transfer tokens with checks
    (try! (ft-transfer? property-share amount sender recipient))
    (print { 
      event: "transfer", 
      amount: amount, 
      sender: sender, 
      recipient: recipient 
    })
    (ok true)))

;; Get token balance
(define-read-only (get-balance (account principal))
  (ft-get-balance property-share account))

;; Implement ft-trait methods
(define-read-only (get-name)
  (ok (var-get token-name)))

(define-read-only (get-symbol)
  (ok (var-get token-symbol)))

(define-read-only (get-decimals)
  (ok u6))

(define-read-only (get-total-supply)
  (ok (var-get total-supply)))
