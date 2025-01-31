;; Fungible Token Trait Contract
(define-trait ft-trait
  (
    ;; Transfer tokens from sender to recipient
    (transfer (uint principal principal) (response bool uint))
    
    ;; Get token balance of an account
    (get-balance (principal) (response uint uint))
    
    ;; Get total token supply
    (get-total-supply () (response uint uint))
    
    ;; Get token name
    (get-name () (response (string-ascii 32) uint))
    
    ;; Get token symbol
    (get-symbol () (response (string-ascii 10) uint))
    
    ;; Get token decimals
    (get-decimals () (response uint uint))
  )
)
