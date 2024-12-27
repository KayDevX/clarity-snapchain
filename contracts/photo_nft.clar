;; SnapChain - Photography NFT Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-insufficient-payment (err u103))

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

;; Data vars
(define-data-var last-token-id uint u0)

;; Mint new photo NFT
(define-public (mint-photo 
    (title (string-utf8 100))
    (camera (string-utf8 50))
    (location (string-utf8 100))
    (description (string-utf8 500)))
    
    (let
        ((token-id (+ (var-get last-token-id) u1)))
        (try! (nft-mint? photo-nft token-id tx-sender))
        (map-set photo-metadata token-id {
            photographer: tx-sender,
            title: title,
            timestamp: block-height,
            camera: camera,
            location: location,
            description: description
        })
        (var-set last-token-id token-id)
        (ok token-id)
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

;; Buy listed photo
(define-public (buy-photo (token-id uint))
    (let (
        (listing (unwrap! (map-get? token-listings token-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
    )
        (asserts! (>= (stx-get-balance tx-sender) price) err-insufficient-payment)
        (try! (stx-transfer? price tx-sender seller))
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