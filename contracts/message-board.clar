;; Simple Message Board Contract
;; This contract allows users to read and post messages for a fee in sBTC.

;; Define contract owner
(define-constant CONTRACT_OWNER tx-sender)

;; Define error codes
(define-constant ERR_NOT_ENOUGH_SBTC (err u1004))
(define-constant ERR_NOT_CONTRACT_OWNER (err u1005))
(define-constant ERR_BLOCK_NOT_FOUND (err u1003))

;; Define a map to store messages
;; Each message has an ID, content, author, and Bitcoin block height timestamp
(define-map messages
  uint
  {
    message: (string-utf8 280),
    author: principal,
    time: uint,
  }
)

;; Counter for total messages
(define-data-var message-count uint u0)