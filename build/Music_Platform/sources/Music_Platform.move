module Music_Platform::Music_Platform {
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::coin::{CoinMetadata};
    use sui::math;

    // Errors
    const EInsufficientShareAmount: u64 = 0;
    const EInvalidReleaseTime: u64 = 2;
    const EInvalidArtist: u64 = 3;

    public struct MUSIC_PLATFORM has drop {}

    public struct AdminAuthority has key {id: UID}

    public struct Song<phantom OwnerCoin, phantom RoyaltyCoin> has key, store {
        id: UID,
        // Amount of {RoyaltyCoin} to give to owners per second.
        royalties_per_second: u64,
        // The timestamp in seconds that this song will start distributing royalties.
        release_timestamp: u64,
        // Last timestamp that the song was updated.
        last_royalty_timestamp: u64,
        // Total amount of royalties per share distributed by this song.
        accrued_royalties_per_share: u256,
        // {OwnerCoin} deposited in this song.
        balance_owner_coin: Balance<OwnerCoin>,
        // {RoyaltyCoin} deposited in this song.
        balance_royalty_coin: Balance<RoyaltyCoin>,
        // The decimal scalar of the {OwnerCoin}.
        owner_coin_decimal_factor: u64,
        // The sui::object::ID of the {OwnerCap} that "owns" this song.
        owned_by: ID
    }

    public struct SongAuthority has key, store {
        id: UID,
        song: ID
    }

    public struct Account<phantom OwnerCoin, phantom RoyaltyCoin> has key, store {
        id: UID,
        // The sui::object::ID of the song to which this account belongs to.
        song_id: ID,
        // The amount of {OwnerCoin} the user has in the {Song}.
        amount: u64,
        // Amount of royalties the {Song} has already paid the user.
        royalty_debt: u256
    }

    fun init(_platform: MUSIC_PLATFORM, ctx: &mut TxContext) {
        transfer::transfer(AdminAuthority{id: object::new(ctx)}, ctx.sender());
    }

    public fun new_song<OwnerCoin, RoyaltyCoin>(
        owner_coin_metadata: &CoinMetadata<OwnerCoin>,
        clock: &Clock,
        royalties_per_second: u64,
        release_timestamp: u64,
        ctx: &mut TxContext
    ): (Song<OwnerCoin, RoyaltyCoin>, SongAuthority) {
        assert!(release_timestamp > clock_timestamp_s(clock), EInvalidReleaseTime);
        let song_id = object::new(ctx);
        let inner_id = object::uid_to_inner(&song_id);

        let authority_id = object::new(ctx);
        let authority_inner = object::uid_to_inner(&authority_id);

        let authority = SongAuthority {
            id: authority_id,
            song: inner_id
        };

        let song = Song {
          id: song_id,
          release_timestamp,
          last_royalty_timestamp: release_timestamp,
          royalties_per_second,
          accrued_royalties_per_share: 0,
          owner_coin_decimal_factor: math::pow(10, coin::get_decimals(owner_coin_metadata)),
          owned_by: authority_inner,
          balance_owner_coin: balance::zero(),
          balance_royalty_coin: balance::zero(),
        };

        (song, authority)
    }  
     
    public fun new_account<OwnerCoin, RoyaltyCoin>(
        self: &Song<OwnerCoin, RoyaltyCoin>,
        ctx: &mut TxContext
    ): Account<OwnerCoin, RoyaltyCoin> {
        Account {
        id: object::new(ctx),
        song_id: object::id(self),
        amount: 0,
        royalty_debt: 0
        }
    }   

    public fun pending_royalties<OwnerCoin, RoyaltyCoin>(
        song: &Song<OwnerCoin, RoyaltyCoin>,
        account: &Account<OwnerCoin, RoyaltyCoin>,
        clock: &Clock,
    ): u64 {
        if (object::id(song) != account.song_id) return 0;

        let total_owner_value = balance::value(&song.balance_owner_coin);
        let now = clock_timestamp_s(clock);

        let cond = total_owner_value == 0 || song.last_royalty_timestamp >= now;

        let accrued_royalties_per_share = if (cond) {
          song.accrued_royalties_per_share
        } else {
          calculate_accrued_royalties_per_share(
          song.royalties_per_second,
          song.accrued_royalties_per_share,
          total_owner_value,
          balance::value(&song.balance_royalty_coin),
          song.owner_coin_decimal_factor,
          now - song.last_royalty_timestamp
          )
        };
        calculate_pending_royalties(account, song.owner_coin_decimal_factor, accrued_royalties_per_share)
    }

    public fun stake_owner<OwnerCoin, RoyaltyCoin>(
        song: &mut Song<OwnerCoin, RoyaltyCoin>,
        account: &mut Account<OwnerCoin, RoyaltyCoin>,
        owner_coin: Coin<OwnerCoin>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<RoyaltyCoin> {
        assert!(object::id(song) == account.song_id, EInvalidArtist);

        update(song, clock_timestamp_s(clock));

        let stake_amount = coin::value(&owner_coin);

        let mut royalty_coin = coin::zero<RoyaltyCoin>(ctx);

        if (account.amount != 0) {
        let pending_royalty = calculate_pending_royalties(
          account,
          song.owner_coin_decimal_factor,
          song.accrued_royalties_per_share
        );
        let pending_royalty = min_u64(pending_royalty, song.balance_royalty_coin.value());
        if (pending_royalty != 0) {
          royalty_coin.balance_mut().join(song.balance_royalty_coin.split(pending_royalty));
        }
        };

        if (stake_amount != 0) {
          song.balance_owner_coin.join(owner_coin.into_balance());
          account.amount = account.amount + stake_amount;
        } else {
          owner_coin.destroy_zero()
        };

        account.royalty_debt = calculate_royalty_debt(
          account.amount,
          song.owner_coin_decimal_factor,
          song.accrued_royalties_per_share
        );
        royalty_coin
    }

    public fun unstake_owner<OwnerCoin, RoyaltyCoin>(
        song: &mut Song<OwnerCoin, RoyaltyCoin>,
        account: &mut Account<OwnerCoin, RoyaltyCoin>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): (Coin<OwnerCoin>, Coin<RoyaltyCoin>) {
        assert!(object::id(song) == account.song_id, EInvalidArtist);
        update(song, clock_timestamp_s(clock));

        assert!(account.amount >= amount, EInsufficientShareAmount);

        let pending_royalty = calculate_pending_royalties(
          account,
          song.owner_coin_decimal_factor,
          song.accrued_royalties_per_share
        );

        let mut owner_coin = coin::zero<OwnerCoin>(ctx);
        let mut royalty_coin = coin::zero<RoyaltyCoin>(ctx);

        if (amount != 0) {
          account.amount = account.amount - amount;
          owner_coin.balance_mut().join(song.balance_owner_coin.split(amount));
        };

        if (pending_royalty != 0) {
          let pending_royalty = min_u64(pending_royalty, song.balance_royalty_coin.value());
          royalty_coin.balance_mut().join(song.balance_royalty_coin.split(pending_royalty));
        };

        account.royalty_debt = calculate_royalty_debt(
          account.amount,
          song.owner_coin_decimal_factor,
          song.accrued_royalties_per_share
        );

        (owner_coin, royalty_coin)
    } 

    public fun add_royalties<OwnerCoin, RoyaltyCoin>(
        self: &mut Song<OwnerCoin, RoyaltyCoin>, clock: &Clock, royalty: Coin<RoyaltyCoin>
    ) {
        update(self, clock_timestamp_s(clock));
        self.balance_royalty_coin.join(royalty.into_balance());
    }

    // Private functions

    fun clock_timestamp_s(clock: &Clock): u64 {
        clock::timestamp_ms(clock) / 1000
    }

    fun calculate_pending_royalties<OwnerCoin, RoyaltyCoin>(acc: &Account<OwnerCoin, RoyaltyCoin>, owner_factor: u64, accrued_royalties_per_share: u256): u64 {
        ((((acc.amount as u256) * accrued_royalties_per_share / (owner_factor as u256)) - acc.royalty_debt) as u64)
    }

    fun update<OwnerCoin, RoyaltyCoin>(song: &mut Song<OwnerCoin, RoyaltyCoin>, now: u64) {
        if (song.last_royalty_timestamp >= now || song.release_timestamp > now) return;

        let total_owner_value = balance::value(&song.balance_owner_coin);

        let prev_royalty_time_stamp = song.last_royalty_timestamp;
        song.last_royalty_timestamp = now;

        if (total_owner_value == 0) return;

        let total_royalty_value = balance::value(&song.balance_royalty_coin);

        song.accrued_royalties_per_share = calculate_accrued_royalties_per_share(
          song.royalties_per_second,
          song.accrued_royalties_per_share,
          total_owner_value,
          total_royalty_value,
          song.owner_coin_decimal_factor,
          now - prev_royalty_time_stamp
        );
    }

    fun calculate_accrued_royalties_per_share(
        royalties_per_second: u64,
        last_accrued_royalties_per_share: u256,
        total_owner_token: u64,
        total_royalty_value: u64,
        owner_factor: u64,
        timestamp_delta: u64
    ): u256 {

        let (total_owner_token, total_royalty_value, royalties_per_second, owner_factor, timestamp_delta) =
         (
          (total_owner_token as u256),
          (total_royalty_value as u256),
          (royalties_per_second as u256),
          (owner_factor as u256),
          (timestamp_delta as u256)
         );

        let royalty = min(total_royalty_value, royalties_per_second * timestamp_delta);

        last_accrued_royalties_per_share + ((royalty * owner_factor) / total_owner_token)
    }
    fun calculate_royalty_debt(owner_amount: u64, owner_factor: u64, accrued_royalties_per_share: u256): u256 {
        let (owner_amount, owner_factor) = (
          (owner_amount as u256),
          (owner_factor as u256)
        );
        (owner_amount * accrued_royalties_per_share) / owner_factor
    }

    fun min(x: u256, y: u256): u256 {
        if (x < y) x else y
    }
    fun min_u64(x: u64, y: u64): u64 {
        if (x < y) x else y
    }
}

