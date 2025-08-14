;; Treasury Management Protocol
;; Version 7: Treasury and fund management approach

;; Treasury Governance
(define-constant treasury-steward tx-sender)
(define-constant treasury-err-access-violation (err u800))
(define-constant treasury-err-fund-shortage (err u801))
(define-constant treasury-err-amount-invalid (err u802))
(define-constant treasury-err-yield-insufficient (err u803))
(define-constant treasury-err-asset-incompatible (err u804))
(define-constant treasury-err-operation-failure (err u805))
(define-constant treasury-err-fund-operational (err u806))
(define-constant treasury-err-fund-dormant (err u807))

;; Treasury Asset Holdings
(define-data-var treasury-primary-holdings uint u0)
(define-data-var treasury-secondary-holdings uint u0)
(define-data-var treasury-units-issued uint u0)
(define-data-var treasury-operational bool false)

;; Secondary Asset Registry
(define-data-var secondary-asset-registry principal .token)

;; Investor Unit Holdings
(define-map investor-units principal uint)

;; Treasury Operations Log
(define-map operations-log 
  { operation-ref: uint }
  { 
    investor: principal,
    primary-inflow: uint,
    secondary-outflow: uint,
    primary-outflow: uint,
    secondary-inflow: uint,
    operation-timestamp: uint
  }
)

(define-data-var operation-ref-counter uint u0)

;; Asset Management Interface
(define-trait treasury-asset
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; Financial Calculation Utilities

;; Select smaller portfolio allocation
(define-private (smaller-allocation (allocation-a uint) (allocation-b uint))
  (if (< allocation-a allocation-b) allocation-a allocation-b))

;; Treasury Information Access

(define-read-only (review-treasury-holdings)
  {
    primary-holdings: (var-get treasury-primary-holdings),
    secondary-holdings: (var-get treasury-secondary-holdings)
  }
)

(define-read-only (review-investor-units (investor principal))
  (default-to u0 (map-get? investor-units investor))
)

(define-read-only (review-total-units)
  (var-get treasury-units-issued)
)

(define-read-only (review-treasury-status)
  (var-get treasury-operational)
)

(define-read-only (review-secondary-asset)
  (var-get secondary-asset-registry)
)

;; Treasury Yield Calculations (0.3% management fee)
(define-read-only (calculate-portfolio-yield (investment-amount uint) (investment-holdings uint) (target-holdings uint))
  (if (or (is-eq investment-amount u0) (is-eq investment-holdings u0) (is-eq target-holdings u0))
    u0
    (let (
      (net-investment (* investment-amount u997))
      (yield-numerator (* net-investment target-holdings))
      (yield-denominator (+ (* investment-holdings u1000) net-investment))
    )
    (/ yield-numerator yield-denominator)))
)

(define-read-only (calculate-investment-requirement (target-yield uint) (investment-holdings uint) (target-holdings uint))
  (if (or (is-eq target-yield u0) (is-eq investment-holdings u0) (is-eq target-holdings u0))
    u0
    (let (
      (requirement-numerator (* (* investment-holdings target-yield) u1000))
      (requirement-denominator (* (- target-holdings target-yield) u997))
    )
    (+ (/ requirement-numerator requirement-denominator) u1)))
)

(define-read-only (calculate-unit-allocation (asset-investment uint) (asset-holdings uint) (paired-holdings uint))
  (if (is-eq asset-holdings u0)
    u0
    (/ (* asset-investment paired-holdings) asset-holdings))
)

;; Treasury Operations Management

(define-public (establish-treasury (asset-registry <treasury-asset>) (primary-seed uint) (secondary-seed uint))
  (let (
    (initial-unit-issue (smaller-allocation primary-seed secondary-seed))
  )
    (asserts! (not (var-get treasury-operational)) treasury-err-fund-operational)
    (asserts! (> primary-seed u0) treasury-err-amount-invalid)
    (asserts! (> secondary-seed u0) treasury-err-amount-invalid)
    (asserts! (> initial-unit-issue u0) treasury-err-fund-shortage)
    
    (var-set secondary-asset-registry (contract-of asset-registry))
    
    (try! (contract-call? asset-registry transfer secondary-seed tx-sender (as-contract tx-sender) none))
    
    (var-set treasury-primary-holdings primary-seed)
    (var-set treasury-secondary-holdings secondary-seed)
    (var-set treasury-units-issued initial-unit-issue)
    (var-set treasury-operational true)
    
    (map-set investor-units tx-sender initial-unit-issue)
    
    (ok initial-unit-issue)
  )
)

(define-public (fund-treasury (asset-registry <treasury-asset>) (primary-contribution uint) (secondary-contribution uint) (min-unit-issue uint))
  (let (
    (current-primary-holdings (var-get treasury-primary-holdings))
    (current-secondary-holdings (var-get treasury-secondary-holdings))
    (current-units-outstanding (var-get treasury-units-issued))
    (new-unit-issue (smaller-allocation 
                     (/ (* primary-contribution current-units-outstanding) current-primary-holdings)
                     (/ (* secondary-contribution current-units-outstanding) current-secondary-holdings)))
    (current-investor-units (review-investor-units tx-sender))
  )
    (asserts! (var-get treasury-operational) treasury-err-fund-dormant)
    (asserts! (is-eq (contract-of asset-registry) (var-get secondary-asset-registry)) treasury-err-asset-incompatible)
    (asserts! (> primary-contribution u0) treasury-err-amount-invalid)
    (asserts! (> secondary-contribution u0) treasury-err-amount-invalid)
    (asserts! (>= new-unit-issue min-unit-issue) treasury-err-yield-insufficient)
    
    (try! (contract-call? asset-registry transfer secondary-contribution tx-sender (as-contract tx-sender) none))
    
    (var-set treasury-primary-holdings (+ current-primary-holdings primary-contribution))
    (var-set treasury-secondary-holdings (+ current-secondary-holdings secondary-contribution))
    (var-set treasury-units-issued (+ current-units-outstanding new-unit-issue))
    
    (map-set investor-units tx-sender (+ current-investor-units new-unit-issue))
    
    (ok new-unit-issue)
  )
)

(define-public (liquidate-treasury-position (asset-registry <treasury-asset>) (unit-redemption uint) (min-primary uint) (min-secondary uint))
  (let (
    (current-primary-holdings (var-get treasury-primary-holdings))
    (current-secondary-holdings (var-get treasury-secondary-holdings))
    (current-units-outstanding (var-get treasury-units-issued))
    (current-investor-units (review-investor-units tx-sender))
    (primary-redemption (/ (* unit-redemption current-primary-holdings) current-units-outstanding))
    (secondary-redemption (/ (* unit-redemption current-secondary-holdings) current-units-outstanding))
  )
    (asserts! (var-get treasury-operational) treasury-err-fund-dormant)
    (asserts! (is-eq (contract-of asset-registry) (var-get secondary-asset-registry)) treasury-err-asset-incompatible)
    (asserts! (> unit-redemption u0) treasury-err-amount-invalid)
    (asserts! (>= current-investor-units unit-redemption) treasury-err-fund-shortage)
    (asserts! (>= primary-redemption min-primary) treasury-err-yield-insufficient)
    (asserts! (>= secondary-redemption min-secondary) treasury-err-yield-insufficient)
    
    (var-set treasury-primary-holdings (- current-primary-holdings primary-redemption))
    (var-set treasury-secondary-holdings (- current-secondary-holdings secondary-redemption))
    (var-set treasury-units-issued (- current-units-outstanding unit-redemption))
    
    (map-set investor-units tx-sender (- current-investor-units unit-redemption))
    
    (try! (as-contract (stx-transfer? primary-redemption tx-sender tx-sender)))
    (try! (as-contract (contract-call? asset-registry transfer secondary-redemption tx-sender tx-sender none)))
    
    (ok { primary: primary-redemption, secondary: secondary-redemption })
  )
)

(define-public (execute-primary-to-secondary-trade (asset-registry <treasury-asset>) (primary-investment uint) (min-secondary-yield uint))
  (let (
    (current-primary-holdings (var-get treasury-primary-holdings))
    (current-secondary-holdings (var-get treasury-secondary-holdings))
    (secondary-yield (calculate-portfolio-yield primary-investment current-primary-holdings current-secondary-holdings))
    (operation-ref (var-get operation-ref-counter))
  )
    (asserts! (var-get treasury-operational) treasury-err-fund-dormant)
    (asserts! (is-eq (contract-of asset-registry) (var-get secondary-asset-registry)) treasury-err-asset-incompatible)
    (asserts! (> primary-investment u0) treasury-err-amount-invalid)
    (asserts! (>= secondary-yield min-secondary-yield) treasury-err-yield-insufficient)
    (asserts! (< secondary-yield current-secondary-holdings) treasury-err-fund-shortage)
    
    (var-set treasury-primary-holdings (+ current-primary-holdings primary-investment))
    (var-set treasury-secondary-holdings (- current-secondary-holdings secondary-yield))
    
    (try! (as-contract (contract-call? asset-registry transfer secondary-yield tx-sender tx-sender none)))
    
    (map-set operations-log 
      { operation-ref: operation-ref }
      { 
        investor: tx-sender,
        primary-inflow: primary-investment,
        secondary-outflow: secondary-yield,
        primary-outflow: u0,
        secondary-inflow: u0,
        operation-timestamp: block-height
      }
    )
    (var-set operation-ref-counter (+ operation-ref u1))
    
    (ok secondary-yield)
  )
)

(define-public (execute-secondary-to-primary-trade (asset-registry <treasury-asset>) (secondary-investment uint) (min-primary-yield uint))
  (let (
    (current-primary-holdings (var-get treasury-primary-holdings))
    (current-secondary-holdings (var-get treasury-secondary-holdings))
    (primary-yield (calculate-portfolio-yield secondary-investment current-secondary-holdings current-primary-holdings))
    (operation-ref (var-get operation-ref-counter))
  )
    (asserts! (var-get treasury-operational) treasury-err-fund-dormant)
    (asserts! (is-eq (contract-of asset-registry) (var-get secondary-asset-registry)) treasury-err-asset-incompatible)
    (asserts! (> secondary-investment u0) treasury-err-amount-invalid)
    (asserts! (>= primary-yield min-primary-yield) treasury-err-yield-insufficient)
    (asserts! (< primary-yield current-primary-holdings) treasury-err-fund-shortage)
    
    (try! (contract-call? asset-registry transfer secondary-investment tx-sender (as-contract tx-sender) none))
    
    (var-set treasury-primary-holdings (- current-primary-holdings primary-yield))
    (var-set treasury-secondary-holdings (+ current-secondary-holdings secondary-investment))
    
    (try! (as-contract (stx-transfer? primary-yield tx-sender tx-sender)))
    
    (map-set operations-log 
      { operation-ref: operation-ref }
      { 
        investor: tx-sender,
        primary-inflow: u0,
        secondary-outflow: u0,
        primary-outflow: primary-yield,
        secondary-inflow: secondary-investment,
        operation-timestamp: block-height
      }
    )
    (var-set operation-ref-counter (+ operation-ref u1))
    
    (ok primary-yield)
  )
)