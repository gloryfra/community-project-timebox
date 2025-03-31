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

;; Core project management operations

;; Begin a new community project
(define-public (initialize-community-project (beneficiary principal) (resources uint) (phase-checkpoints (list 5 uint)))
  (let
    (
      (venture-id (+ (var-get latest-venture-id) u1))
      (sunset-timestamp (+ block-height PROJECT_DURATION))
    )
    (asserts! (> resources u0) FAILURE_BAD_PARAMETERS)
    (asserts! (verify-beneficiary beneficiary) FAILURE_WRONG_PHASE)
    (asserts! (> (len phase-checkpoints) u0) FAILURE_WRONG_PHASE)
    (match (stx-transfer? resources tx-sender (as-contract tx-sender))
      success
        (begin
          (map-set VentureRecords
            { venture-id: venture-id }
            {
              initiator: tx-sender,
              beneficiary: beneficiary,
              resource-amount: resources,
              current-phase: "active",
              genesis-block: block-height,
              sunset-block: sunset-timestamp,
              phase-checkpoints: phase-checkpoints,
              unlocked-checkpoints: u0
            }
          )
          (var-set latest-venture-id venture-id)
          (ok venture-id)
        )
      error FAILURE_ASSET_MOVEMENT
    )
  )
)

;; Approve and release checkpoint resources
(define-public (approve-checkpoint-advancement (venture-id uint))
  (begin
    (asserts! (verify-venture-exists venture-id) FAILURE_BAD_KEY)
    (let
      (
        (venture-record (unwrap! (map-get? VentureRecords { venture-id: venture-id }) FAILURE_ENTRY_NONEXISTENT))
        (checkpoints (get phase-checkpoints venture-record))
        (completed-checkpoints (get unlocked-checkpoints venture-record))
        (beneficiary (get beneficiary venture-record))
        (total-resources (get resource-amount venture-record))
        (resources-to-release (/ total-resources (len checkpoints)))
      )
      (asserts! (< completed-checkpoints (len checkpoints)) FAILURE_ASSETS_MOVED)
      (asserts! (is-eq tx-sender OVERSIGHT_CONTROLLER) FAILURE_NOT_PERMITTED)
      (match (stx-transfer? resources-to-release (as-contract tx-sender) beneficiary)
        success
          (begin
            (map-set VentureRecords
              { venture-id: venture-id }
              (merge venture-record { unlocked-checkpoints: (+ completed-checkpoints u1) })
            )
            (ok true)
          )
        error FAILURE_ASSET_MOVEMENT
      )
    )
  )
)




