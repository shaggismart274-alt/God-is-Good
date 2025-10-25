;; transfer-app
;; Short & error-free Clarity contract for a decentralized file-sharing app like Xender

(define-data-var transfer-counter uint u0)

(define-map transfers {id: uint}
  {sender: principal,
   file-hash: (string-ascii 64),
   recipient: principal,
   status: (string-ascii 12)})

;; Initiate a file transfer
(define-public (initiate-transfer (file-hash (string-ascii 64)) (recipient principal))
  (let
    (
      (id (var-get transfer-counter))
    )
    (map-set transfers {id: id}
      {sender: tx-sender,
       file-hash: file-hash,
       recipient: recipient,
       status: "pending"})
    (var-set transfer-counter (+ id u1))
    (ok id)
  )
)

;; Accept a file transfer
(define-public (accept-transfer (id uint))
  (match (map-get? transfers {id: id})
    transfer
    (if (and (is-eq (get status transfer) "pending") (is-eq tx-sender (get recipient transfer)))
      (begin
        (map-set transfers {id: id}
          {sender: (get sender transfer),
           file-hash: (get file-hash transfer),
           recipient: (get recipient transfer),
           status: "accepted"})
        (ok "Transfer accepted")
      )
      (err u1)) ;; not pending or not recipient
    (err u2) ;; transfer not found
  )
)

;; Cancel a file transfer
(define-public (cancel-transfer (id uint))
  (match (map-get? transfers {id: id})
    transfer
    (if (and (is-eq (get status transfer) "pending") (is-eq tx-sender (get sender transfer)))
      (begin
        (map-set transfers {id: id}
          {sender: (get sender transfer),
           file-hash: (get file-hash transfer),
           recipient: (get recipient transfer),
           status: "cancelled"})
        (ok "Transfer cancelled")
      )
      (err u3)) ;; not pending or not sender
    (err u4) ;; transfer not found
  )
)