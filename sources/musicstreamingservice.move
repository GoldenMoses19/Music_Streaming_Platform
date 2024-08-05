module Music_Streaming::Music_Platform {

    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::option::{Self, Option};

    // Constants for Error Handling
    const ERROR_INVALID_SONG: u64 = 1;
    const ERROR_INVALID_OWNER: u64 = 2;
    const ERROR_INVALID_LISTENER: u64 = 3;
    const ERROR_NOT_OWNER: u64 = 7;
    const ERROR_NOT_ARTIST: u64 = 11;
    const ERROR_INVALID_TRACK: u64 = 12;
    const ERROR_VOTE_MISMATCH: u64 = 13;

    /* Structs */
    public struct Song has key, store {
        id: UID,
        details: vector<u8>,
        owners: Table<address, u64>, // address of owners and their ownership share (in basis points)
        total_royalties: Balance<SUI>,
        owner_list: vector<address>, // Track owners separately for iteration
        lock: bool // To prevent reentrancy attacks
    }

    public struct Artist has key, store {
        id: UID,
        artist_address: address,
        name: vector<u8>,
        track_history: Table<u64, Track>,
        track_list: vector<u64> // Track list separately for iteration
    }

    public struct Listener has key, store {
        id: UID,
        listener_address: address,
        escrow: Balance<SUI>,
        name: vector<u8>
    }

    public struct Track has key, store {
        id: UID,
        details: vector<u8>,
        artist: address,
        promoted: bool
    }

    public struct Playlist has key, store {
        id: UID,
        name: vector<u8>,
        tracks: Table<u64, Track>,
        track_list: vector<u64> // Track list separately for iteration
    }

    public struct User has key, store {
        id: UID,
        user_address: address,
        details: vector<u8>
    }

    public struct ChangeProposal has key, store {
        id: UID,
        votes: Table<address, bool>,
        voter_list: vector<address>, // Track voters separately for iteration
        approved: bool
    }

    /* Functions */

    // Function to register a new Song
    public fun register_song(
        details: vector<u8>,
        owners: vector<address>,
        ownership_shares: vector<u64>,
        ctx: &mut TxContext
    ) : Song {
        assert!(vector::length(&owners) == vector::length(&ownership_shares), ERROR_INVALID_SONG);
        let mut owners_table = table::new<address, u64>(ctx);
        let total_shares = 10000;
        let mut total_share_check = 0;
        let length = vector::length(&owners);
        let mut owner_list = vector::empty<address>();
        let mut i = 0;
        while (i < length) {
            let owner = *vector::borrow(&owners, i);
            let share = *vector::borrow(&ownership_shares, i);
            table::add(&mut owners_table, owner, share);
            vector::push_back(&mut owner_list, owner);
            total_share_check = total_share_check + share;
            i = i + 1;
        }
        assert!(total_share_check == total_shares, ERROR_INVALID_SONG);

        Song {
            id: object::new(ctx),
            details: details,
            owners: owners_table,
            total_royalties: balance::zero(),
            owner_list: owner_list,
            lock: false
        }
    }

    // Function to distribute royalties to song owners with reentrancy protection
    public fun distribute_royalties(song: &mut Song, mut payment: Coin<SUI>, ctx: &mut TxContext) {
        assert!(!song.lock, ERROR_INVALID_SONG);
        song.lock = true;

        let total_amount = coin::value(&payment);
        let length = vector::length(&song.owner_list);
        let mut i = 0;
        while (i < length) {
            let owner = *vector::borrow(&song.owner_list, i);
            let share = *table::borrow(&song.owners, owner);
            let owner_payment = (total_amount * share) / 10000;
            let coin = coin::split(&mut payment, owner_payment, ctx);
            transfer::public_transfer(coin, owner);
            i = i + 1;
        }
        balance::join(&mut song.total_royalties, coin::into_balance(payment));

        song.lock = false;
    }

    // Function to claim royalties for a song owner
    public fun claim_royalties(song: &mut Song, owner: address, ctx: &mut TxContext) {
        assert!(table::contains(&song.owners, owner), ERROR_INVALID_OWNER);
        let share = *table::borrow(&song.owners, owner);
        let total_amount = balance::value(&song.total_royalties);
        let owner_payment = (total_amount * share) / 10000;
        let coin = coin::take(&mut song.total_royalties, owner_payment, ctx);
        transfer::public_transfer(coin, owner);
    }

    // Function to update song details
    public fun update_song_details(song: &mut Song, new_details: vector<u8>, ctx: &mut TxContext) {
        let owner_address = tx_context::sender(ctx);
        assert!(table::contains(&song.owners, owner_address), ERROR_NOT_OWNER);
        song.details = new_details;
    }

    // Function to revoke a song by majority consensus
    public fun revoke_song(song: &mut Song, ctx: &mut TxContext) {
        let owner_address = tx_context::sender(ctx);
        assert!(table::contains(&song.owners, owner_address), ERROR_NOT_OWNER);
        // Logic to check majority consensus and revoke the song
        // Placeholder for consensus logic
        let length = vector::length(&song.owner_list);
        let mut approval_count = 0;
        let mut i = 0;
        while (i < length) {
            let owner = *vector::borrow(&song.owner_list, i);
            if (owner == owner_address) {
                approval_count = approval_count + 1;
            }
            i = i + 1;
        }
        if (approval_count > (length / 2)) {
            // Logic to revoke the song
        } else {
            assert!(false, ERROR_INVALID_SONG);
        }
    }

    // Function to register a new Artist
    public fun register_artist(name: vector<u8>, artist_address: address, ctx: &mut TxContext) : Artist {
        Artist {
            id: object::new(ctx),
            artist_address: artist_address,
            name: name,
            track_history: table::new<u64, Track>(ctx),
            track_list: vector::empty<u64>()
        }
    }

    // Function to register a new Listener
    public fun register_listener(name: vector<u8>, listener_address: address, ctx: &mut TxContext) : Listener {
        Listener {
            id: object::new(ctx),
            listener_address: listener_address,
            escrow: balance::zero(),
            name: name
        }
    }

    // Function to upload a new track
    public fun upload_track(artist: &mut Artist, track_details: vector<u8>, track_id: u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == artist.artist_address, ERROR_NOT_OWNER);
        let track = Track {
            id: object::new(ctx),
            details: track_details,
            artist: artist.artist_address,
            promoted: false
        };
        table::add(&mut artist.track_history, track_id, track);
        vector::push_back(&mut artist.track_list, track_id);
    }

    // Function to stream a track
    public fun stream_track(listener: &mut Listener, artist: &mut Artist, track_id: u64, ctx: &mut TxContext) {
        let track = table::borrow_mut(&mut artist.track_history, track_id);
        assert!(track.artist != listener.listener_address, ERROR_INVALID_LISTENER);

        let stream_fee = 100; // arbitrary fee for streaming
        let coin = coin::take(&mut listener.escrow, stream_fee, ctx);
        transfer::public_transfer(coin, track.artist);
    }

    // Function to tip an artist
    public fun tip_artist(listener: &mut Listener, artist: &mut Artist, amount: u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == listener.listener_address, ERROR_INVALID_LISTENER);
        let coin = coin::take(&mut listener.escrow, amount, ctx);
        transfer::public_transfer(coin, artist.artist_address);
    }

    // Function to create a playlist
    public fun create_playlist(name: vector<u8>, ctx: &mut TxContext) : Playlist {
        Playlist {
            id: object::new(ctx),
            name: name,
            tracks: table::new<u64, Track>(ctx),
            track_list: vector::empty<u64>()
        }
    }

    // Function to add a track to a playlist
    public fun add_track_to_playlist(playlist: &mut Playlist, track: Track, track_id: u64, _ctx: &mut TxContext) {
        table::add(&mut playlist.tracks, track_id, track);
        vector::push_back(&mut playlist.track_list, track_id);
    }

    // Function to get playlist details
    public fun get_playlist_details(playlist: &Playlist): (vector<u8>, u64, bool) {
        let playlist_name = playlist.name;
        let first_track_id = if (vector::length(&playlist.track_list) > 0) {
            *vector::borrow(&playlist.track_list, 0)
        } else {
            0 // Default track ID if playlist is empty
        };
        let is_first_track_promoted = if (first_track_id != 0) {
            table::borrow(&playlist.tracks, first_track_id).promoted
        } else {
            false
        };
        (playlist_name, first_track_id, is_first_track_promoted)
    }

    // Function to get song details
    public fun get_song_details(song: &Song): (vector<u8>, &Balance<SUI>) {
        (song.details, &song.total_royalties)
    }

    // Function to get track details
    public fun get_track_details(track: &Track): vector<u8> {
        track.details
    }

    // Function to register a user
    public fun register_user(user_address: address, user_details: vector<u8>, ctx: &mut TxContext): User {
        User {
            id: object::new(ctx),
            user_address: user_address,
            details: user_details
        }
    }

    // Function to get user details
    public fun get_user_details(user: &User): vector<u8> {
        user.details
    }

    // Function to split payments and shares dynamically with reentrancy protection
    public fun split_payments(song: &mut Song, mut payments: Coin<SUI>, ctx: &mut TxContext) {
        assert!(!song.lock, ERROR_INVALID_SONG);
        song.lock = true;

        let total_amount = coin::value(&payments);
        let length = vector::length(&song.owner_list);
        let mut i = 0;
        while (i < length) {
            let owner = *vector::borrow(&song.owner_list, i);
            let share = *table::borrow(&song.owners, owner);
            let owner_payment = (total_amount * share) / 10000;
            let coin = coin::split(&mut payments, owner_payment, ctx);
            transfer::public_transfer(coin, owner);
            i = i + 1;
        }
        balance::join(&mut song.total_royalties, coin::into_balance(payments));

        song.lock = false;
    }

    // Function to provide detailed analytics on royalties
    public fun get_royalty_analytics(song: &Song): (u64, u64) {
        let total_royalties = balance::value(&song.total_royalties);
        let length = vector::length(&song.owner_list);
        (total_royalties, length)
    }

    // Function to enable user interaction and feedback
    public fun add_feedback(listener: &mut Listener, track: &mut Track, feedback: vector<u8>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == listener.listener_address, ERROR_INVALID_LISTENER);
        track.details = feedback;
    }

    // Function to promote tracks
    public fun promote_track(artist: &mut Artist, track_id: u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == artist.artist_address, ERROR_NOT_ARTIST);
        let track = table::borrow_mut(&mut artist.track_history, track_id);
        track.promoted = true;
        // Logic to actually promote the track
        // For instance, the platform could prioritize this track in recommendations
    }

    // Function for governance and voting
    public fun vote_on_change(user: &mut User, change_proposal: &mut ChangeProposal, vote: bool, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == user.user_address, ERROR_INVALID_OWNER);
        table::add(&mut change_proposal.votes, user.user_address, vote);
        vector::push_back(&mut change_proposal.voter_list, user.user_address);
        // Logic for determining if the proposal is approved
        let length = vector::length(&change_proposal.voter_list);
        let mut yes_votes = 0;
        let mut no_votes = 0;
        let mut i = 0;
        while (i < length) {
            let voter = *vector::borrow(&change_proposal.voter_list, i);
            if (*table::borrow(&change_proposal.votes, voter)) {
                yes_votes = yes_votes + 1;
            } else {
                no_votes = no_votes + 1;
            }
            i = i + 1;
        }
        change_proposal.approved = yes_votes > no_votes;
    }
}
