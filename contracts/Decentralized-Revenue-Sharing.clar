;; Decentralized Revenue Sharing Contract
;; Transparent profit distribution for collaborative projects

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-PROJECT-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-MEMBER (err u103))
(define-constant ERR-NOT-MEMBER (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-PERCENTAGE (err u106))
(define-constant ERR-PROJECT-LOCKED (err u107))
(define-constant ERR-NO-FUNDS-TO-DISTRIBUTE (err u108))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-PERCENTAGE u10000) ;; 100.00% in basis points

;; Data structures
(define-map projects
  { project-id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    total-shares: uint,
    total-revenue: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map project-members
  { project-id: uint, member: principal }
  {
    shares: uint,
    total-withdrawn: uint,
    joined-at: uint
  }
)

(define-map project-balances
  { project-id: uint }
  { balance: uint }
)

;; Global variables
(define-data-var next-project-id uint u1)
(define-data-var total-projects uint u0)

;; Read-only functions
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-project-member (project-id uint) (member principal))
  (map-get? project-members { project-id: project-id, member: member })
)

(define-read-only (get-project-balance (project-id uint))
  (default-to { balance: u0 } (map-get? project-balances { project-id: project-id }))
)

(define-read-only (calculate-member-share (project-id uint) (member principal))
  (let (
    (project-data (unwrap! (get-project project-id) (err ERR-PROJECT-NOT-FOUND)))
    (member-data (unwrap! (get-project-member project-id member) (err ERR-NOT-MEMBER)))
    (project-balance (get balance (get-project-balance project-id)))
    (total-shares (get total-shares project-data))
    (member-shares (get shares member-data))
  )
    (if (is-eq total-shares u0)
      (ok u0)
      (ok (/ (* project-balance member-shares) total-shares))
    )
  )
)

(define-read-only (calculate-withdrawable-amount (project-id uint) (member principal))
  (let (
    (total-share (unwrap! (calculate-member-share project-id member) (err ERR-NOT-MEMBER)))
    (member-data (unwrap! (get-project-member project-id member) (err ERR-NOT-MEMBER)))
    (already-withdrawn (get total-withdrawn member-data))
  )
    (if (> total-share already-withdrawn)
      (ok (- total-share already-withdrawn))
      (ok u0)
    )
  )
)

(define-read-only (get-total-projects)
  (var-get total-projects)
)

;; Public functions
(define-public (create-project (name (string-ascii 100)))
  (let (
    (project-id (var-get next-project-id))
  )
    (map-set projects
      { project-id: project-id }
      {
        name: name,
        owner: tx-sender,
        total-shares: u0,
        total-revenue: u0,
        is-active: true,
        created-at: block-height
      }
    )
    (map-set project-balances
      { project-id: project-id }
      { balance: u0 }
    )
    (var-set next-project-id (+ project-id u1))
    (var-set total-projects (+ (var-get total-projects) u1))
    (ok project-id)
  )
)

(define-public (add-project-member (project-id uint) (member principal) (shares uint))
  (let (
    (project-data (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (existing-member (map-get? project-members { project-id: project-id, member: member }))
  )
    (asserts! (is-eq tx-sender (get owner project-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active project-data) ERR-PROJECT-LOCKED)
    (asserts! (> shares u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none existing-member) ERR-ALREADY-MEMBER)
    
    ;; Add member
    (map-set project-members
      { project-id: project-id, member: member }
      {
        shares: shares,
        total-withdrawn: u0,
        joined-at: block-height
      }
    )
    
    ;; Update project total shares
    (map-set projects
      { project-id: project-id }
      (merge project-data { total-shares: (+ (get total-shares project-data) shares) })
    )
    
    (ok true)
  )
)

(define-public (update-member-shares (project-id uint) (member principal) (new-shares uint))
  (let (
    (project-data (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (member-data (unwrap! (get-project-member project-id member) ERR-NOT-MEMBER))
    (old-shares (get shares member-data))
    (shares-diff (if (> new-shares old-shares) 
                   (- new-shares old-shares) 
                   (- old-shares new-shares)))
  )
    (asserts! (is-eq tx-sender (get owner project-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active project-data) ERR-PROJECT-LOCKED)
    (asserts! (> new-shares u0) ERR-INVALID-AMOUNT)
    
    ;; Update member shares
    (map-set project-members
      { project-id: project-id, member: member }
      (merge member-data { shares: new-shares })
    )
    
    ;; Update project total shares
    (map-set projects
      { project-id: project-id }
      (merge project-data { 
        total-shares: (if (> new-shares old-shares)
                       (+ (get total-shares project-data) shares-diff)
                       (- (get total-shares project-data) shares-diff))
      })
    )
    
    (ok true)
  )
)

(define-public (deposit-revenue (project-id uint) (amount uint))
  (let (
    (project-data (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (current-balance (get balance (get-project-balance project-id)))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (get is-active project-data) ERR-PROJECT-LOCKED)
    
    ;; Transfer STX from sender to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update project balance
    (map-set project-balances
      { project-id: project-id }
      { balance: (+ current-balance amount) }
    )
    
    ;; Update project total revenue
    (map-set projects
      { project-id: project-id }
      (merge project-data { total-revenue: (+ (get total-revenue project-data) amount) })
    )
    
    (ok true)
  )
)

(define-public (withdraw-share (project-id uint))
  (let (
    (project-data (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (member-data (unwrap! (get-project-member project-id tx-sender) ERR-NOT-MEMBER))
    (withdrawable-amount (unwrap! (calculate-withdrawable-amount project-id tx-sender) ERR-NOT-MEMBER))
    (current-balance (get balance (get-project-balance project-id)))
  )
    (asserts! (> withdrawable-amount u0) ERR-NO-FUNDS-TO-DISTRIBUTE)
    (asserts! (>= current-balance withdrawable-amount) ERR-INSUFFICIENT-BALANCE)
    
    ;; Transfer STX to member
    (try! (as-contract (stx-transfer? withdrawable-amount tx-sender tx-sender)))
    
    ;; Update member's withdrawn amount
    (map-set project-members
      { project-id: project-id, member: tx-sender }
      (merge member-data { 
        total-withdrawn: (+ (get total-withdrawn member-data) withdrawable-amount) 
      })
    )
    
    ;; Update project balance
    (map-set project-balances
      { project-id: project-id }
      { balance: (- current-balance withdrawable-amount) }
    )
    
    (ok withdrawable-amount)
  )
)

(define-public (toggle-project-status (project-id uint))
  (let (
    (project-data (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get owner project-data)) ERR-NOT-AUTHORIZED)
    
    (map-set projects
      { project-id: project-id }
      (merge project-data { is-active: (not (get is-active project-data)) })
    )
    
    (ok (not (get is-active project-data)))
  )
)

(define-public (remove-project-member (project-id uint) (member principal))
  (let (
    (project-data (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (member-data (unwrap! (get-project-member project-id member) ERR-NOT-MEMBER))
    (member-shares (get shares member-data))
  )
    (asserts! (is-eq tx-sender (get owner project-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active project-data) ERR-PROJECT-LOCKED)
    
    ;; Remove member
    (map-delete project-members { project-id: project-id, member: member })
    
    ;; Update project total shares
    (map-set projects
      { project-id: project-id }
      (merge project-data { 
        total-shares: (- (get total-shares project-data) member-shares) 
      })
    )
    
    (ok true)
  )
)