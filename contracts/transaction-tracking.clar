;; Transaction Tracking Contract
;; This contract records qualifying purchases for the loyalty program

(define-data-var admin principal tx-sender)

;; Transaction structure
(define-map transactions
  uint
  {
    customer: principal,
    retailer: principal,
    amount: uint,
    timestamp: uint,
    processed: bool
  })

(define-data-var transaction-counter uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-RETAILER u101)
(define-constant ERR-INVALID-CUSTOMER u102)
(define-constant ERR-TRANSACTION-NOT-FOUND u103)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Record a new transaction
(define-public (record-transaction (customer principal) (retailer principal) (amount uint))
  (let ((tx-id (var-get transaction-counter)))
    (begin
      ;; In a real implementation, we would check if retailer is verified and customer is active
      ;; by calling the respective contracts
      (asserts! (is-eq tx-sender retailer) (err ERR-NOT-AUTHORIZED))
      (map-set transactions tx-id
        {
          customer: customer,
          retailer: retailer,
          amount: amount,
          timestamp: block-height,
          processed: false
        })
      (var-set transaction-counter (+ tx-id u1))
      (ok tx-id))))

;; Mark transaction as processed
(define-public (mark-processed (tx-id uint))
  (let ((tx (unwrap! (map-get? transactions tx-id) (err ERR-TRANSACTION-NOT-FOUND))))
    (begin
      (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
      (ok (map-set transactions tx-id
        {
          customer: (get customer tx),
          retailer: (get retailer tx),
          amount: (get amount tx),
          timestamp: (get timestamp tx),
          processed: true
        })))))

;; Get transaction details
(define-read-only (get-transaction (tx-id uint))
  (map-get? transactions tx-id))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))))
