;; Property Verification and Ownership Contract

(define-constant CONTRACT-OWNER tx-sender)

;; Error Codes
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-PROPERTY-EXISTS (err u2))
(define-constant ERR-PROPERTY-NOT-FOUND (err u3))
(define-constant ERR-INVALID-TRANSFER (err u4))
(define-constant ERR-INVALID-INPUT (err u5))

;; Property Status Enum
(define-constant PROPERTY-STATUS-UNVERIFIED u0)
(define-constant PROPERTY-STATUS-VERIFIED u1)
(define-constant PROPERTY-STATUS-DISPUTED u2)

;; Input Validation Functions
(define-private (is-valid-property-id (property-id uint))
  (and (> property-id u0) (< property-id u10000)))

(define-private (is-valid-description (description (string-utf8 500)))
  (and 
    (> (len description) u10)
    (< (len description) u500)
  )
)

(define-private (is-valid-cadastral-number (number (string-ascii 50)))
  (and 
    (> (len number) u5)
    (< (len number) u50)
  )
)

;; Property Record Structure
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    legal-description: (string-utf8 500),
    cadastral-number: (string-ascii 50),
    verification-status: uint,
    last-transfer-block: uint
  }
)

;; Ownership Transfer Tracking
(define-map ownership-transfers
  { property-id: uint, transfer-id: uint }
  {
    previous-owner: principal,
    new-owner: principal,
    transfer-block: uint,
    transfer-proof: (string-utf8 200)
  }
)

;; Counter for tracking ownership transfers
(define-data-var next-transfer-id uint u0)

;; Verify property details
(define-public (register-property
  (property-id uint)
  (legal-description (string-utf8 500))
  (cadastral-number (string-ascii 50)))
  (begin
    ;; Validate inputs
    (asserts! (is-valid-property-id property-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-description legal-description) ERR-INVALID-INPUT)
    (asserts! (is-valid-cadastral-number cadastral-number) ERR-INVALID-INPUT)
    
    ;; Ensure property doesn't already exist
    (asserts! (is-none (map-get? properties { property-id: property-id })) 
              ERR-PROPERTY-EXISTS)
    
    ;; Register property
    (map-set properties 
      { property-id: property-id }
      {
        owner: tx-sender,
        legal-description: legal-description,
        cadastral-number: cadastral-number,
        verification-status: PROPERTY-STATUS-UNVERIFIED,
        last-transfer-block: block-height
      }
    )
    (ok true)))

;; Transfer property ownership with enhanced security
(define-public (transfer-property
  (property-id uint)
  (new-owner principal)
  (transfer-proof (string-utf8 200)))
  (let 
    (
      (current-property 
        (unwrap! 
          (map-get? properties { property-id: property-id }) 
          ERR-PROPERTY-NOT-FOUND
        )
      )
      (current-owner (get owner current-property))
      (transfer-id (var-get next-transfer-id))
    )
    ;; Validate inputs
    (asserts! (is-valid-property-id property-id) ERR-INVALID-INPUT)
    (asserts! (> (len transfer-proof) u10) ERR-INVALID-INPUT)
    
    ;; Validate current owner
    (asserts! (is-eq tx-sender current-owner) ERR-UNAUTHORIZED)
    (asserts! (not (is-eq current-owner new-owner)) ERR-INVALID-TRANSFER)
    
    ;; Record ownership transfer
    (map-set properties
      { property-id: property-id }
      (merge current-property 
        { 
          owner: new-owner, 
          last-transfer-block: block-height,
          verification-status: PROPERTY-STATUS-UNVERIFIED
        }
      )
    )
    
    ;; Track transfer history
    (map-set ownership-transfers
      { property-id: property-id, transfer-id: transfer-id }
      {
        previous-owner: current-owner,
        new-owner: new-owner,
        transfer-block: block-height,
        transfer-proof: transfer-proof
      }
    )
    
    ;; Increment transfer ID
    (var-set next-transfer-id (+ transfer-id u1))
    
    (ok true)))

;; Verify property details (can only be done by authorized verifier)
(define-public (verify-property
  (property-id uint)
  (verifier principal))
  (let 
    (
      (current-property 
        (unwrap! 
          (map-get? properties { property-id: property-id }) 
          ERR-PROPERTY-NOT-FOUND
        )
      )
    )
    ;; Validate input
    (asserts! (is-valid-property-id property-id) ERR-INVALID-INPUT)
    
    ;; Only contract owner can verify
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    
    ;; Update verification status
    (map-set properties
      { property-id: property-id }
      (merge current-property 
        { 
          verification-status: PROPERTY-STATUS-VERIFIED 
        }
      )
    )
    
    (ok true)))

;; Read property details
(define-read-only (get-property-details (property-id uint))
  (map-get? properties { property-id: property-id }))
