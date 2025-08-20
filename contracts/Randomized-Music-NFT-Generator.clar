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
