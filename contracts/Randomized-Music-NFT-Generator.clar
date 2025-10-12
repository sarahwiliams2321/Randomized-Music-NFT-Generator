(define-non-fungible-token music-track uint)

(define-data-var next-token-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-map track-metadata uint {
  title: (string-ascii 64),
  genre: (string-ascii 32),
  tempo: uint,
  key: (string-ascii 8),
  instruments: (list 5 (string-ascii 32)),
  duration: uint,
  seed: uint
})

(define-map owner-track-count principal uint)

(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))

(define-constant GENRES (list "Electronic" "Rock" "Jazz" "Classical" "Ambient" "Hip-Hop" "Techno" "House"))
(define-constant KEYS (list "C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B"))
(define-constant INSTRUMENTS (list "Piano" "Guitar" "Bass" "Drums" "Synth" "Violin" "Trumpet" "Flute" "Saxophone" "Cello"))

(define-read-only (get-track-metadata (token-id uint))
  (map-get? track-metadata token-id)
)

(define-read-only (get-owner (token-id uint))
  (nft-get-owner? music-track token-id)
)

(define-read-only (get-next-token-id)
  (var-get next-token-id)
)

(define-read-only (get-track-count (owner principal))
  (default-to u0 (map-get? owner-track-count owner))
)

(define-private (random-from-seed (seed uint) (max uint))
  (mod seed max)
)

(define-private (generate-title (seed uint))
  (let ((title-num (random-from-seed seed u100)))
    (if (< title-num u25)
      "Midnight Beats"
      (if (< title-num u50)
        "Digital Dreams"
        (if (< title-num u75)
          "Cosmic Waves"
          "Electric Soul"
        )
      )
    )
  )
)

(define-private (generate-genre (seed uint))
  (let ((genre-index (random-from-seed (+ seed u1) u8)))
    (unwrap-panic (element-at GENRES genre-index))
  )
)

(define-private (generate-key (seed uint))
  (let ((key-index (random-from-seed (+ seed u2) u12)))
    (unwrap-panic (element-at KEYS key-index))
  )
)

(define-private (generate-tempo (seed uint))
  (+ u60 (random-from-seed (+ seed u3) u140))
)

(define-private (generate-duration (seed uint))
  (+ u120 (random-from-seed (+ seed u4) u300))
)

(define-private (generate-instruments (seed uint))
  (let (
    (inst1-idx (random-from-seed (+ seed u5) u10))
    (inst2-idx (random-from-seed (+ seed u6) u10))
    (inst3-idx (random-from-seed (+ seed u7) u10))
  )
    (list 
      (unwrap-panic (element-at INSTRUMENTS inst1-idx))
      (unwrap-panic (element-at INSTRUMENTS inst2-idx))
      (unwrap-panic (element-at INSTRUMENTS inst3-idx))
    )
  )
)

(define-private (create-track-seed (token-id uint))
  (+ token-id u12345)
)

(define-public (mint-track (recipient principal))
  (let (
    (token-id (var-get next-token-id))
    (seed (create-track-seed token-id))
  )
    (try! (nft-mint? music-track token-id recipient))
    (map-set track-metadata token-id {
      title: (generate-title seed),
      genre: (generate-genre seed),
      tempo: (generate-tempo seed),
      key: (generate-key seed),
      instruments: (generate-instruments seed),
      duration: (generate-duration seed),
      seed: seed
    })
    (map-set owner-track-count 
      recipient 
      (+ (get-track-count recipient) u1)
    )
    (var-set next-token-id (+ token-id u1))
    (ok token-id)
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (nft-get-owner? music-track token-id)) ERR-NOT-FOUND)
    (try! (nft-transfer? music-track token-id sender recipient))
    (map-set owner-track-count sender (- (get-track-count sender) u1))
    (map-set owner-track-count recipient (+ (get-track-count recipient) u1))
    (ok true)
  )
)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-public (burn (token-id uint))
  (let ((owner (unwrap! (nft-get-owner? music-track token-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (try! (nft-burn? music-track token-id owner))
    (map-delete track-metadata token-id)
    (map-set owner-track-count owner (- (get-track-count owner) u1))
    (ok true)
  )
)

(define-read-only (get-track-uri (token-id uint))
  (ok (some "https://music-nft.stacks/metadata"))
)

(define-public (batch-mint (recipients (list 10 principal)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (map mint-track recipients))
  )
)

(define-read-only (get-last-token-id)
  (- (var-get next-token-id) u1)
)


(define-map rarity-scores uint uint)
(define-map genre-rarity (string-ascii 32) uint)
(define-map key-rarity (string-ascii 8) uint)

(define-constant RARITY-GENRE-WEIGHTS (list 
  { genre: "Electronic", weight: u10 }
  { genre: "Rock", weight: u15 }
  { genre: "Jazz", weight: u25 }
  { genre: "Classical", weight: u30 }
  { genre: "Ambient", weight: u35 }
  { genre: "Hip-Hop", weight: u20 }
  { genre: "Techno", weight: u12 }
  { genre: "House", weight: u18 }
))

(define-constant RARITY-KEY-WEIGHTS (list
  { key: "C", weight: u5 } { key: "C#", weight: u15 }
  { key: "D", weight: u8 } { key: "D#", weight: u20 }
  { key: "E", weight: u10 } { key: "F", weight: u12 }
  { key: "F#", weight: u25 } { key: "G", weight: u7 }
  { key: "G#", weight: u18 } { key: "A", weight: u6 }
  { key: "A#", weight: u22 } { key: "B", weight: u16 }
))

(define-private (get-genre-rarity-weight (target-genre (string-ascii 32)))
  (if (is-eq target-genre "Electronic") u10
    (if (is-eq target-genre "Rock") u15
      (if (is-eq target-genre "Jazz") u25
        (if (is-eq target-genre "Classical") u30
          (if (is-eq target-genre "Ambient") u35
            (if (is-eq target-genre "Hip-Hop") u20
              (if (is-eq target-genre "Techno") u12
                (if (is-eq target-genre "House") u18 u10)
              )
            )
          )
        )
      )
    )
  )
)

(define-private (get-key-rarity-weight (target-key (string-ascii 8)))
  (if (is-eq target-key "C") u5
    (if (is-eq target-key "C#") u15
      (if (is-eq target-key "D") u8
        (if (is-eq target-key "D#") u20
          (if (is-eq target-key "E") u10
            (if (is-eq target-key "F") u12
              (if (is-eq target-key "F#") u25
                (if (is-eq target-key "G") u7
                  (if (is-eq target-key "G#") u18
                    (if (is-eq target-key "A") u6
                      (if (is-eq target-key "A#") u22
                        (if (is-eq target-key "B") u16 u5)
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

(define-private (calculate-tempo-rarity (tempo uint))
  (if (or (< tempo u80) (> tempo u180)) u30 u10)
)

(define-private (calculate-duration-rarity (duration uint))
  (if (or (< duration u180) (> duration u360)) u25 u8)
)

(define-private (calculate-rarity-score (token-id uint))
  (let ((metadata (unwrap-panic (get-track-metadata token-id))))
    (+ 
      (get-genre-rarity-weight (get genre metadata))
      (get-key-rarity-weight (get key metadata))
      (calculate-tempo-rarity (get tempo metadata))
      (calculate-duration-rarity (get duration metadata))
    )
  )
)

(define-public (compute-track-rarity (token-id uint))
  (let ((score (calculate-rarity-score token-id)))
    (map-set rarity-scores token-id score)
    (ok score)
  )
)

(define-read-only (get-rarity-score (token-id uint))
  (map-get? rarity-scores token-id)
)

(define-read-only (get-rarity-tier (token-id uint))
  (let ((score (default-to u0 (get-rarity-score token-id))))
    (if (>= score u80) "Legendary"
      (if (>= score u60) "Epic"
        (if (>= score u40) "Rare"
          "Common"
        )
      )
    )
  )
)

(define-map listings uint {
  seller: principal,
  price: uint,
  active: bool
})

(define-map original-minters uint principal)
(define-map royalty-earnings principal uint)

(define-constant ERR-NOT-OWNER (err u403))
(define-constant ERR-LISTING-NOT-FOUND (err u405))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u406))
(define-constant ROYALTY-PERCENTAGE u5)

(define-public (list-track (token-id uint) (price uint))
  (let ((owner (unwrap! (nft-get-owner? music-track token-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender owner) ERR-NOT-OWNER)
    (map-set listings token-id {
      seller: owner,
      price: price,
      active: true
    })
    (ok true)
  )
)

(define-public (delist-track (token-id uint))
  (let ((listing (unwrap! (map-get? listings token-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-OWNER)
    (map-set listings token-id (merge listing { active: false }))
    (ok true)
  )
)

(define-public (purchase-track (token-id uint))
  (let (
    (listing (unwrap! (map-get? listings token-id) ERR-LISTING-NOT-FOUND))
    (seller (get seller listing))
    (price (get price listing))
    (royalty-amount (/ (* price ROYALTY-PERCENTAGE) u100))
    (original-minter (default-to seller (map-get? original-minters token-id)))
  )
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
    (try! (stx-transfer? price tx-sender seller))
    (try! (nft-transfer? music-track token-id seller tx-sender))
    (if (not (is-eq seller original-minter))
      (begin
        (try! (stx-transfer? royalty-amount seller original-minter))
        (map-set royalty-earnings original-minter 
          (+ (default-to u0 (map-get? royalty-earnings original-minter)) royalty-amount))
        true
      )
      true
    )
    (map-set owner-track-count seller (- (get-track-count seller) u1))
    (map-set owner-track-count tx-sender (+ (get-track-count tx-sender) u1))
    (map-set listings token-id (merge listing { active: false }))
    (ok true)
  )
)

(define-read-only (get-listing (token-id uint))
  (map-get? listings token-id)
)

(define-read-only (get-royalty-earnings (creator principal))
  (default-to u0 (map-get? royalty-earnings creator))
)