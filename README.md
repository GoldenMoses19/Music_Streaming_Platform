## Music Platform Module Documentation

### Overview
The Music Platform module is a decentralized application built on the Sui blockchain. It enables the management of music tracks, artists, listeners, playlists, and royalties. The module provides functionalities for registering songs, artists, listeners, and playlists, distributing royalties, streaming tracks, promoting tracks, and facilitating user interactions through feedback and voting mechanisms.

### Constants
- `Error_InvalidSong: u64 = 1`: Error code for invalid song.
- `Error_InvalidOwner: u64 = 2`: Error code for invalid owner.
- `Error_InvalidListener: u64 = 3`: Error code for invalid listener.
- `Error_NotOwner: u64 = 7`: Error code for not an owner.
- `Error_NotArtist: u64 = 11`: Error code for not an artist.

### Structs
#### Song
Represents a song in the platform.
- `id: UID`: Unique identifier for the song.
- `details: vector<u8>`: Details of the song.
- `owners: Table<address, u64>`: Table mapping owner addresses to their ownership share (in basis points).
- `total_royalties: Balance<SUI>`: Total royalties accumulated for the song.
- `owner_list: vector<address>`: List of owner addresses.

#### Artist
Represents an artist in the platform.
- `id: UID`: Unique identifier for the artist.
- `artist_address: address`: Address of the artist.
- `name: vector<u8>`: Name of the artist.
- `track_history: Table<u64, Track>`: Table mapping track IDs to tracks.
- `track_list: vector<u64>`: List of track IDs.

#### Listener
Represents a listener in the platform.
- `id: UID`: Unique identifier for the listener.
- `listener_address: address`: Address of the listener.
- `escrow: Balance<SUI>`: Escrow balance of the listener.
- `name: vector<u8>`: Name of the listener.

#### Track
Represents a track in the platform.
- `id: UID`: Unique identifier for the track.
- `details: vector<u8>`: Details of the track.
- `artist: address`: Address of the artist.
- `promoted: bool`: Indicates if the track is promoted.

#### Playlist
Represents a playlist in the platform.
- `id: UID`: Unique identifier for the playlist.
- `name: vector<u8>`: Name of the playlist.
- `tracks: Table<u64, Track>`: Table mapping track IDs to tracks.
- `track_list: vector<u64>`: List of track IDs.

#### User
Represents a user in the platform.
- `id: UID`: Unique identifier for the user.
- `user_address: address`: Address of the user.
- `details: vector<u8>`: Details of the user.

#### ChangeProposal
Represents a change proposal in the platform.
- `id: UID`: Unique identifier for the change proposal.
- `votes: Table<address, bool>`: Table mapping voter addresses to their votes.
- `voter_list: vector<address>`: List of voter addresses.
- `approved: bool`: Indicates if the proposal is approved.

### Functions

#### Register Song
Registers a new song with specified details, owners, and ownership shares.
```move
public fun register_song(details: vector<u8>, owners: vector<address>, ownership_shares: vector<u64>, ctx: &mut TxContext) : Song
```
- `details: vector<u8>`: Details of the song.
- `owners: vector<address>`: List of owner addresses.
- `ownership_shares: vector<u64>`: List of ownership shares corresponding to each owner.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
let song = Music_Platform::register_song(b"Song Details", owners, ownership_shares, &mut ctx);
```

#### Distribute Royalties
Distributes royalties to song owners based on their ownership shares.
```move
public fun distribute_royalties(song: &mut Song, mut payment: Coin<SUI>, ctx: &mut TxContext)
```
- `song: &mut Song`: Reference to the song object.
- `payment: Coin<SUI>`: Payment coin representing the royalties to be distributed.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::distribute_royalties(&mut song, payment, &mut ctx);
```

#### Claim Royalties
Allows a song owner to claim their share of royalties.
```move
public fun claim_royalties(song: &mut Song, owner: address, ctx: &mut TxContext)
```
- `song: &mut Song`: Reference to the song object.
- `owner: address`: Address of the song owner.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::claim_royalties(&mut song, owner_address, &mut ctx);
```

#### Update Song Details
Updates the details of a song by its owner.
```move
public fun update_song_details(song: &mut Song, new_details: vector<u8>, ctx: &mut TxContext)
```
- `song: &mut Song`: Reference to the song object.
- `new_details: vector<u8>`: New details of the song.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::update_song_details(&mut song, b"New Song Details", &mut ctx);
```

#### Revoke Song
Revokes a song by majority consensus of its owners.
```move
public fun revoke_song(song: &mut Song, ctx: &mut TxContext)
```
- `song: &mut Song`: Reference to the song object.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::revoke_song(&mut song, &mut ctx);
```

#### Register Artist
Registers a new artist with a specified name and address.
```move
public fun register_artist(name: vector<u8>, artist_address: address, ctx: &mut TxContext) : Artist
```
- `name: vector<u8>`: Name of the artist.
- `artist_address: address`: Address of the artist.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
let artist = Music_Platform::register_artist(b"Artist Name", artist_address, &mut ctx);
```

#### Register Listener
Registers a new listener with a specified name and address.
```move
public fun register_listener(name: vector<u8>, listener_address: address, ctx: &mut TxContext) : Listener
```
- `name: vector<u8>`: Name of the listener.
- `listener_address: address`: Address of the listener.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
let listener = Music_Platform::register_listener(b"Listener Name", listener_address, &mut ctx);
```

#### Upload Track
Allows an artist to upload a new track.
```move
public fun upload_track(artist: &mut Artist, track_details: vector<u8>, track_id: u64, ctx: &mut TxContext)
```
- `artist: &mut Artist`: Reference to the artist object.
- `track_details: vector<u8>`: Details of the track.
- `track_id: u64`: Unique identifier for the track.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::upload_track(&mut artist, b"Track Details", track_id, &mut ctx);
```

#### Stream Track
Allows a listener to stream a track by paying a fee.
```move
public fun stream_track(listener: &mut Listener, artist: &mut Artist, track_id: u64, ctx: &mut TxContext)
```
- `listener: &mut Listener`: Reference to the listener object.
- `artist: &mut Artist`: Reference to the artist object.
- `track_id: u64`: Unique identifier for the track.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::stream_track(&mut listener, &mut artist, track_id, &mut ctx);
```

#### Tip Artist
Allows a listener to tip an artist.
```move
public fun tip_artist(listener: &mut Listener, artist: &mut Artist, amount: u64, ctx: &mut TxContext)
```
- `listener: &mut Listener`: Reference to the listener object.
- `artist: &mut Artist`: Reference to the artist object.
- `amount: u64`: Amount to be tipped.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::tip_artist(&mut listener, &mut artist, amount, &mut ctx);
```

#### Create Playlist
Creates a new playlist.
```move
public fun create_playlist(name: vector<u8>, ctx: &mut TxContext) : Playlist
```
- `name: vector<u8>`: Name of the playlist.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
let playlist = Music_Platform::create_playlist(b"Playlist Name", &mut ctx);
```

#### Add Track to Playlist
Adds a track to a playlist.
```move
public fun add_track_to_playlist(playlist: &mut Playlist, track: Track, track_id: u64, _ctx: &mut TxContext)
```
- `playlist: &mut Playlist`: Reference to the playlist object.
- `track: Track`: Track object to be added.
- `track_id: u64`: Unique identifier for the track.
- `_ctx: &mut TxContext`:

 Transaction context.

Example:
```move
Music_Platform::add_track_to_playlist(&mut playlist, track, track_id, &mut ctx);
```

#### Get Playlist Details
Retrieves details of a playlist including the tracks.
```move
public fun get_playlist_details(playlist: &Playlist): (vector<u8>, u64, bool)
```
- `playlist: &Playlist`: Reference to the playlist object.

Returns:
- `vector<u8>`: Playlist name.
- `u64`: First track ID.
- `bool`: Promotion status of the first track.

Example:
```move
let (name, track_id, promoted) = Music_Platform::get_playlist_details(&playlist);
```

#### Get Song Details
Retrieves details of a song including total royalties.
```move
public fun get_song_details(song: &Song) : (vector<u8>, &Balance<SUI>)
```
- `song: &Song`: Reference to the song object.

Returns:
- `vector<u8>`: Song details.
- `&Balance<SUI>`: Total royalties balance.

Example:
```move
let (details, royalties) = Music_Platform::get_song_details(&song);
```

#### Get Track Details
Retrieves details of a track.
```move
public fun get_track_details(track: &Track) : vector<u8>
```
- `track: &Track`: Reference to the track object.

Returns:
- `vector<u8>`: Track details.

Example:
```move
let details = Music_Platform::get_track_details(&track);
```

#### Register User
Registers a new user with specified details.
```move
public fun register_user(user_address: address, user_details: vector<u8>, ctx: &mut TxContext) : User
```
- `user_address: address`: Address of the user.
- `user_details: vector<u8>`: Details of the user.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
let user = Music_Platform::register_user(user_address, b"User Details", &mut ctx);
```

#### Get User Details
Retrieves details of a user.
```move
public fun get_user_details(user: &User) : vector<u8>
```
- `user: &User`: Reference to the user object.

Returns:
- `vector<u8>`: User details.

Example:
```move
let details = Music_Platform::get_user_details(&user);
```

#### Split Payments
Splits payments and distributes shares dynamically.
```move
public fun split_payments(song: &mut Song, mut payments: Coin<SUI>, ctx: &mut TxContext)
```
- `song: &mut Song`: Reference to the song object.
- `payments: Coin<SUI>`: Payment coin to be split.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::split_payments(&mut song, payments, &mut ctx);
```

#### Get Royalty Analytics
Provides detailed analytics on royalties.
```move
public fun get_royalty_analytics(song: &Song) : (u64, u64)
```
- `song: &Song`: Reference to the song object.

Returns:
- `u64`: Total royalties.
- `u64`: Number of owners.

Example:
```move
let (total_royalties, num_owners) = Music_Platform::get_royalty_analytics(&song);
```

#### Add Feedback
Allows a listener to add feedback on a track.
```move
public fun add_feedback(listener: &mut Listener, track: &mut Track, feedback: vector<u8>, ctx: &mut TxContext)
```
- `listener: &mut Listener`: Reference to the listener object.
- `track: &mut Track`: Reference to the track object.
- `feedback: vector<u8>`: Feedback details.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::add_feedback(&mut listener, &mut track, b"Great track!", &mut ctx);
```

#### Promote Track
Allows an artist to promote a track.
```move
public fun promote_track(artist: &mut Artist, track_id: u64, ctx: &mut TxContext)
```
- `artist: &mut Artist`: Reference to the artist object.
- `track_id: u64`: Unique identifier for the track.
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::promote_track(&mut artist, track_id, &mut ctx);
```

#### Vote on Change
Allows users to vote on a change proposal.
```move
public fun vote_on_change(user: &mut User, change_proposal: &mut ChangeProposal, vote: bool, ctx: &mut TxContext)
```
- `user: &mut User`: Reference to the user object.
- `change_proposal: &mut ChangeProposal`: Reference to the change proposal object.
- `vote: bool`: Vote value (true for approval, false for rejection).
- `ctx: &mut TxContext`: Transaction context.

Example:
```move
Music_Platform::vote_on_change(&mut user, &mut change_proposal, true, &mut ctx);
```

### How to Operate the Platform

#### Registering an Artist or Listener
1. To register as an artist:
   ```move
   let artist = Music_Platform::register_artist(b"Artist Name", artist_address, &mut ctx);
   ```
2. To register as a listener:
   ```move
   let listener = Music_Platform::register_listener(b"Listener Name", listener_address, &mut ctx);
   ```

#### Uploading and Managing Songs
1. To register a new song:
   ```move
   let song = Music_Platform::register_song(b"Song Details", owners, ownership_shares, &mut ctx);
   ```
2. To update song details:
   ```move
   Music_Platform::update_song_details(&mut song, b"New Song Details", &mut ctx);
   ```

#### Managing Playlists
1. To create a new playlist:
   ```move
   let playlist = Music_Platform::create_playlist(b"Playlist Name", &mut ctx);
   ```
2. To add a track to a playlist:
   ```move
   Music_Platform::add_track_to_playlist(&mut playlist, track, track_id, &mut ctx);
   ```

#### Distributing and Claiming Royalties
1. To distribute royalties for a song:
   ```move
   Music_Platform::distribute_royalties(&mut song, payment, &mut ctx);
   ```
2. To claim royalties for a song:
   ```move
   Music_Platform::claim_royalties(&mut song, owner_address, &mut ctx);
   ```

#### Interacting with Tracks
1. To stream a track:
   ```move
   Music_Platform::stream_track(&mut listener, &mut artist, track_id, &mut ctx);
   ```
2. To tip an artist:
   ```move
   Music_Platform::tip_artist(&mut listener, &mut artist, amount, &mut ctx);
   ```

#### Governance and Voting
1. To vote on a change proposal:
   ```move
   Music_Platform::vote_on_change(&mut user, &mut change_proposal, true, &mut ctx);
   
   ```


## UNITTEST

```bash
$ sui --version
sui 1.2.7.0-0362997459

$ sui move test
INCLUDING DEPENDENCY Sui
INCLUDING DEPENDENCY MoveStdlib
BUILDING sui_music_platform
Running Move unit tests
[ PASS    ] 0x0::sui_music_platform_tests::test_register_song
[ PASS    ] 0x0::sui_music_platform_tests::test_distribute_royalties
[ PASS    ] 0x0::sui_music_platform_tests::test_claim_royalties
[ PASS    ] 0x0::sui_music_platform_tests::test_update_song_details
[ PASS    ] 0x0::sui_music_platform_tests::test_revoke_song
[ PASS    ] 0x0::sui_music_platform_tests::test_register_artist
[ PASS    ] 0x0::sui_music_platform_tests::test_register_listener
[ PASS    ] 0x0::sui_music_platform_tests::test_upload_track
[ PASS    ] 0x0::sui_music_platform_tests::test_stream_track
[ PASS    ] 0x0::sui_music_platform_tests::test_tip_artist
[ PASS    ] 0x0::sui_music_platform_tests::test_create_playlist
[ PASS    ] 0x0::sui_music_platform_tests::test_add_track_to_playlist


[ PASS    ] 0x0::sui_music_platform_tests::test_get_playlist_details
[ PASS    ] 0x0::sui_music_platform_tests::test_get_song_details
[ PASS    ] 0x0::sui_music_platform_tests::test_get_track_details
[ PASS    ] 0x0::sui_music_platform_tests::test_register_user
[ PASS    ] 0x0::sui_music_platform_tests::test_get_user_details
[ PASS    ] 0x0::sui_music_platform_tests::test_split_payments
[ PASS    ] 0x0::sui_music_platform_tests::test_get_royalty_analytics
[ PASS    ] 0x0::sui_music_platform_tests::test_add_feedback
[ PASS    ] 0x0::sui_music_platform_tests::test_promote_track
[ PASS    ] 0x0::sui_music_platform_tests::test_vote_on_change
Test result: OK. Total tests: 22; passed: 22; failed: 0
```

## Deployment

To deploy the Music Platform module on the Sui blockchain:

1. Ensure you have Sui CLI installed and configured.

2. Build and deploy the module:
    ```bash
    sui move build
    sui client publish --gas-budget <GAS_BUDGET>
    ```
This documentation provides an overview of the functionalities and how to use the Music Platform module effectively. For more detailed usage and examples, refer to the specific function implementations.


This documentation provides an overview of the functionalities and how to use the Music Platform module effectively. 
