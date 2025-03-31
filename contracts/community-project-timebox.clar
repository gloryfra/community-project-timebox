;; CommunityProjectTimebox Contract
;; ------------------------------
;; Decentralized community project management system on Stacks blockchain

;; Control parameters
(define-constant OVERSIGHT_CONTROLLER tx-sender)
(define-constant FAILURE_NOT_PERMITTED (err u300))
(define-constant FAILURE_ENTRY_NONEXISTENT (err u301))
(define-constant FAILURE_ASSETS_MOVED (err u302))
(define-constant FAILURE_ASSET_MOVEMENT (err u303))
(define-constant FAILURE_BAD_KEY (err u304))
(define-constant FAILURE_BAD_PARAMETERS (err u305))
(define-constant FAILURE_WRONG_PHASE (err u306))
(define-constant FAILURE_DEADLINE_PASSED (err u307))
(define-constant PROJECT_DURATION u1008) 

;; Core data structures
(define-map VentureRecords
  { venture-id: uint }
  {
    initiator: principal,
    beneficiary: principal,
    resource-amount: uint,
    current-phase: (string-ascii 10),
    genesis-block: uint,
    sunset-block: uint,
    phase-checkpoints: (list 5 uint),
    unlocked-checkpoints: uint
  }
)

(define-data-var latest-venture-id uint u0)

(define-private (verify-beneficiary (beneficiary principal))
  (not (is-eq beneficiary tx-sender))
)

(define-private (verify-venture-exists (venture-id uint))
  (<= venture-id (var-get latest-venture-id))
)

