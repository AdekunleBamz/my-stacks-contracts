;; Stacks Message Board (sBTC)
;; Users can post a short message by paying an sBTC fee.
;; The deployer can withdraw accumulated sBTC.

(define-constant CONTRACT_OWNER tx-sender)

;; Error codes
(define-constant ERR_BLOCK_NOT_FOUND (err u1003))
(define-constant ERR_NOT_ENOUGH_SBTC (err u1004))
(define-constant ERR_NOT_CONTRACT_OWNER (err u1005))
(define-constant ERR_CONTRACT_HASH_MISSING (err u1006))
(define-constant ERR_CONTRACT_HASH_MISMATCH (err u1007))
(define-constant ERR_RATE_LIMITED (err u1008))
(define-constant ERR_INVALID_FEE (err u1009))

;; Messages
(define-map messages
  uint
  {
    message: (string-utf8 280),
    author: principal,
    time: uint,
    stack-time: uint,
  }
)

;; Per-principal last post burn block height (for rate limiting)
(define-map last-post-height
  principal
  uint
)

(define-data-var message-count uint u0)
(define-data-var token-contract-hash (optional (buff 32)) none)

;; Config
(define-data-var message-fee uint u1)
;; Default is 1: prevents multiple posts in the same burn block.
(define-data-var min-post-interval uint u1)

;; Read-only helpers
(define-read-only (get-message-fee)
  (var-get message-fee)
)

(define-read-only (get-min-post-interval)
  (var-get min-post-interval)
)

(define-read-only (can-post-now (who principal))
  (let ((last (default-to u0 (map-get? last-post-height who))))
    (>= (- burn-block-height last) (var-get min-post-interval))
  )
)

;; Admin
(define-public (set-message-fee (fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_CONTRACT_OWNER)
    (asserts! (> fee u0) ERR_INVALID_FEE)
    (var-set message-fee fee)
    (ok fee)
  )
)

(define-public (set-min-post-interval (blocks uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_CONTRACT_OWNER)
    (var-set min-post-interval blocks)
    (ok blocks)
  )
)

;; Public: post a message
;; @format-ignore
(define-public (add-message (content (string-utf8 280)))
  (let (
        (id (+ (var-get message-count) u1))
        (fee (var-get message-fee))
        (last (default-to u0 (map-get? last-post-height contract-caller)))
        (actual-hash-res (contract-hash? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token))
       )
    (asserts! (>= (- burn-block-height last) (var-get min-post-interval)) ERR_RATE_LIMITED)
    (match actual-hash-res actual
      (begin
        ;; initialize expected hash once, then enforce equality
        (match (var-get token-contract-hash) expected
          (asserts! (is-eq expected actual) ERR_CONTRACT_HASH_MISMATCH)
          (var-set token-contract-hash (some actual))
        )

          (try! (restrict-assets? contract-caller
            ((with-ft 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token "sbtc-token" fee))
            (unwrap!
              (contract-call? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token
                transfer fee contract-caller current-contract none
              )
              ERR_NOT_ENOUGH_SBTC
            )
          ))

          (map-set messages id {
            message: content,
            author: contract-caller,
            time: burn-block-height,
            stack-time: stacks-block-time,
          })
          (map-set last-post-height contract-caller burn-block-height)
          (var-set message-count id)

          (print {
            event: "[Stacks Dev Quickstart] New Message",
            message: content,
            id: id,
            author: contract-caller,
            author-ascii: (unwrap-panic (to-ascii? contract-caller)),
            time: burn-block-height,
            stack-time: stacks-block-time,
          })

          (ok id)
        )
        err ERR_CONTRACT_HASH_MISSING
      )
  )
)

;; Withdraw accumulated sBTC to the deployer
(define-public (withdraw-funds)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_CONTRACT_OWNER)
    (let ((balance (unwrap-panic (contract-call? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token
      get-balance current-contract
    ))))
      (if (> balance u0)
        (contract-call? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token
          transfer balance current-contract CONTRACT_OWNER none
        )
        (ok false)
      )
    )
  )
)

;; Read-only message getters
(define-read-only (get-message (id uint))
  (map-get? messages id)
)

(define-read-only (get-message-author (id uint))
  (get author (map-get? messages id))
)

(define-read-only (get-message-count-at-block (block uint))
  (ok (at-block
    (unwrap! (get-stacks-block-info? id-header-hash block) ERR_BLOCK_NOT_FOUND)
    (var-get message-count)
  ))
)

;; Read-only helper to report the tracked and live contract hash for sBTC
(define-read-only (get-token-hash-status)
  (let (
        (expected (var-get token-contract-hash))
        (actual-res (contract-hash? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token))
       )
    (match actual-res actual
      (let ((actual-opt (some actual)))
        {
          expected: expected,
          actual: actual-opt,
          matches: (and (is-some expected) (is-eq expected actual-opt))
        }
      )
      err {
        expected: expected,
        actual: none,
        matches: false
      }
    )
  )
)
