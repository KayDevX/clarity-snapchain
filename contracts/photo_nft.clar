;; SnapChain - Photography NFT Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-invalid-royalty (err u104))
(define-constant royalty-rate u50) ;; 5% royalty (denominator 1000)

;; Define NFT
(define-non-fungible-token photo-nft uint)

;; Data structures
(define-map photo-metadata
    uint 
    {
        photographer: principal,
        title: (string-utf8 100),
        timestamp: uint,
        camera: (string-utf8 50),
        location: (string-utf8 100),
        description: (string-utf8 500)
    }
)

(define-map token-listings
    uint 
    {
        price: uint,
        seller: principal
    }
)

(define-map photographer-stats
    principal
    {
        total-sales: uint,
        royalties-earned: uint,
        photos-minted: uint
    }
)

;; Data vars
(define-data-var last-token-id uint u0)

;; Initialize photographer stats
(define-private (init-photographer-stats (photographer principal))
    (map-set photographer-stats photographer {
        total-sales: u0,
        royalties-earned: u0,
        photos-minted: u0
    })
)

;; Mint new photo NFT
(define-public (mint-photo 
    (title (string-utf8 100))
    (camera (string-utf8 50))
    (location (string-utf8 100))
    (description (string-utf8 500)))
    
    (let
        ((token-id (+ (var-get last-token-id) u1))
         (stats (default-to 
            {total-sales: u0, royalties-earned: u0, photos-minted: u0}
            (map-get? photographer-stats tx-sender))))
        (try! (nft-mint? photo-nft token-id tx-sender))
        (map-set photo-metadata token-id {
            photographer: tx-sender,
            title: title,
            timestamp: block-height,
            camera: camera,
            location: location,
            description: description
        })
        (map-set photographer-stats tx-sender {
            total-sales: (get total-sales stats),
            royalties-earned: (get royalties-earned stats),
            photos-minted: (+ (get photos-minted stats) u1)
        })
        (var-set last-token-id token-id)
        (ok token-id)
    )
)

;; Batch mint multiple photos
(define-public (batch-mint-photos
    (titles (list 10 (string-utf8 100)))
    (cameras (list 10 (string-utf8 50)))
    (locations (list 10 (string-utf8 100)))
    (descriptions (list 10 (string-utf8 500))))
    
    (let ((token-ids (list 10 uint)))
        (map mint-photo titles cameras locations descriptions)
        (ok true)
    )
)

;; Transfer photo NFT
(define-public (transfer (token-id uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender (nft-get-owner? photo-nft token-id)) err-not-token-owner)
        (try! (nft-transfer? photo-nft token-id tx-sender recipient))
        (ok true)
    )
)

;; List photo for sale
(define-public (list-for-sale (token-id uint) (price uint))
    (begin
        (asserts! (is-eq tx-sender (nft-get-owner? photo-nft token-id)) err-not-token-owner)
        (map-set token-listings token-id {
            price: price,
            seller: tx-sender
        })
        (ok true)
    )
)

;; Buy listed photo with royalty payment
(define-public (buy-photo (token-id uint))
    (let (
        (listing (unwrap! (map-get? token-listings token-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
        (metadata (unwrap! (map-get? photo-metadata token-id) err-listing-not-found))
        (photographer (get photographer metadata))
        (royalty (/ (* price royalty-rate) u1000))
        (seller-payment (- price royalty))
    )
        (asserts! (>= (stx-get-balance tx-sender) price) err-insufficient-payment)
        ;; Pay royalty to photographer
        (if (not (is-eq photographer seller))
            (try! (stx-transfer? royalty tx-sender photographer))
            true
        )
        ;; Update photographer stats
        (let ((stats (default-to 
            {total-sales: u0, royalties-earned: u0, photos-minted: u0}
            (map-get? photographer-stats photographer))))
            (map-set photographer-stats photographer {
                total-sales: (+ (get total-sales stats) u1),
                royalties-earned: (+ (get royalties-earned stats) royalty),
                photos-minted: (get photos-minted stats)
            })
        )
        ;; Transfer payment and NFT
        (try! (stx-transfer? seller-payment tx-sender seller))
        (try! (nft-transfer? photo-nft token-id seller tx-sender))
        (map-delete token-listings token-id)
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-photo-data (token-id uint))
    (map-get? photo-metadata token-id)
)

(define-read-only (get-listing (token-id uint))
    (map-get? token-listings token-id)
)

(define-read-only (get-token-uri (token-id uint))
    (some (concat "https://snapchain.io/metadata/" (uint-to-ascii token-id)))
)

(define-read-only (get-photographer-stats (photographer principal))
    (map-get? photographer-stats photographer)
)
