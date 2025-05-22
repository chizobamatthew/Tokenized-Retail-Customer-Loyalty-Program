;; Reward Issuance Contract
;; This contract manages point allocation and redemption

(define-data-var admin principal tx-sender)

;; Points balance for each customer
(define-map points-balance principal uint)

;; Redemption history
(define-map redemption-history
  uint
  {
    customer: principal,
    points: uint,
    reward: (string-ascii 100),
    timestamp: uint
  })

(define-data-var redemption-counter uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INSUFFICIENT-POINTS u101)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Award points to a customer
(define-public (award-points (customer principal) (points uint))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (let ((current-points (default-to u0 (map-get? points-balance customer))))
      (ok (map-set points-balance customer (+ current-points points))))))

;; Redeem points for a reward
(define-public (redeem-points (points uint) (reward (string-ascii 100)))
  (let ((current-points (default-to u0 (map-get? points-balance tx-sender)))
        (redemption-id (var-get redemption-counter)))
    (begin
      (asserts! (>= current-points points) (err ERR-INSUFFICIENT-POINTS))
      (map-set points-balance tx-sender (- current-points points))
      (map-set redemption-history redemption-id
        {
          customer: tx-sender,
          points: points,
          reward: reward,
          timestamp: block-height
        })
      (var-set redemption-counter (+ redemption-id u1))
      (ok redemption-id))))

;; Get customer points balance
(define-read-only (get-points-balance (customer principal))
  (default-to u0 (map-get? points-balance customer)))

;; Get redemption details
(define-read-only (get-redemption (redemption-id uint))
  (map-get? redemption-history redemption-id))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))))
