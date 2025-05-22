;; Partner Exchange Contract
;; This contract enables transfers between loyalty programs

(define-data-var admin principal tx-sender)

;; Partner program structure
(define-map partner-programs
  principal
  {
    name: (string-ascii 50),
    exchange-rate: uint,  ;; Rate is multiplied by 100 for precision (e.g., 150 = 1.5x)
    active: bool
  })

;; Exchange history
(define-map exchange-history
  uint
  {
    customer: principal,
    partner: principal,
    points-sent: uint,
    points-received: uint,
    timestamp: uint
  })

(define-data-var exchange-counter uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-PARTNER-NOT-FOUND u101)
(define-constant ERR-PARTNER-INACTIVE u102)
(define-constant ERR-INSUFFICIENT-POINTS u103)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Add a partner program
(define-public (add-partner (partner principal) (name (string-ascii 50)) (exchange-rate uint))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (map-set partner-programs partner
      {
        name: name,
        exchange-rate: exchange-rate,
        active: true
      }))))

;; Update partner exchange rate
(define-public (update-exchange-rate (partner principal) (exchange-rate uint))
  (let ((program (unwrap! (map-get? partner-programs partner) (err ERR-PARTNER-NOT-FOUND))))
    (begin
      (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
      (ok (map-set partner-programs partner
        {
          name: (get name program),
          exchange-rate: exchange-rate,
          active: (get active program)
        })))))

;; Deactivate partner program
(define-public (deactivate-partner (partner principal))
  (let ((program (unwrap! (map-get? partner-programs partner) (err ERR-PARTNER-NOT-FOUND))))
    (begin
      (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
      (ok (map-set partner-programs partner
        {
          name: (get name program),
          exchange-rate: (get exchange-rate program),
          active: false
        })))))

;; Exchange points with partner program
;; In a real implementation, this would interact with the reward-issuance contract
;; and potentially with the partner's contract
(define-public (exchange-points (partner principal) (points uint))
  (let ((program (unwrap! (map-get? partner-programs partner) (err ERR-PARTNER-NOT-FOUND)))
        (exchange-id (var-get exchange-counter))
        (points-received (/ (* points (get exchange-rate program)) u100)))
    (begin
      (asserts! (get active program) (err ERR-PARTNER-INACTIVE))
      ;; In a real implementation, we would check if customer has enough points
      ;; and transfer them between programs
      (map-set exchange-history exchange-id
        {
          customer: tx-sender,
          partner: partner,
          points-sent: points,
          points-received: points-received,
          timestamp: block-height
        })
      (var-set exchange-counter (+ exchange-id u1))
      (ok exchange-id))))

;; Get partner program details
(define-read-only (get-partner-program (partner principal))
  (map-get? partner-programs partner))

;; Get exchange details
(define-read-only (get-exchange (exchange-id uint))
  (map-get? exchange-history exchange-id))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))))
