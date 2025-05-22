;; Retailer Verification Contract
;; This contract validates participating merchants in the loyalty program

(define-data-var admin principal tx-sender)

;; Map to store verified retailers
(define-map verified-retailers principal bool)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-NOT-VERIFIED u102)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Add a retailer to the verified list
(define-public (add-retailer (retailer principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-none (map-get? verified-retailers retailer)) (err ERR-ALREADY-VERIFIED))
    (ok (map-set verified-retailers retailer true))))

;; Remove a retailer from the verified list
(define-public (remove-retailer (retailer principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-some (map-get? verified-retailers retailer)) (err ERR-NOT-VERIFIED))
    (ok (map-delete verified-retailers retailer))))

;; Check if a retailer is verified
(define-read-only (is-verified-retailer (retailer principal))
  (default-to false (map-get? verified-retailers retailer)))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))))
