module cohort::enrollment {

    use sui::{
        tx_context::{Self, TxContext},
        object::{Self, UID, ID},
        transfer,
        table,
        event
    };
    use std::{
        string::{String, from_ascii},
        ascii,
        vector,
        debug::print
    };

    const EEnrollmentNotOpen:u64 = 0;
    const EInvalidGithubAccount: u64 = 1;
    const ENotSignedUp:u64 = 2;
    const EAlreadySignedUp:u64 = 3;

    struct Cohort has key, store {
        id: UID,
        cadets: table::Table<address, String>,
        open_for_enrollment: bool
    }

    struct Cadet has key, store {
        id: UID,
        github:String,
        cohort:ID
    }

    struct CadetEvent has copy, drop {
        id: ID,
        github:String,
        cohort:ID
    }

    struct InstructorCap has key { id: UID }

    // Part 3: Module initializer to be executed when this module is published
    fun init(ctx: &mut TxContext) {
         transfer::transfer(InstructorCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx))
    }

    public entry fun add_instructor(_: &InstructorCap, recipient:address, ctx: &mut TxContext) {
        transfer::transfer(InstructorCap {
            id: object::new(ctx)
        }, recipient)
    }

    public entry fun create_cohort(_: &InstructorCap, ctx: &mut TxContext) {
        transfer::share_object(
        Cohort {
            id: object::new(ctx),
            cadets: table::new(ctx),
            open_for_enrollment: false
        })
    }

    public entry fun toggle_signups(_: &InstructorCap, cohort: &mut Cohort) {
        if (cohort.open_for_enrollment == false) {
            cohort.open_for_enrollment = true;
        } else {
            cohort.open_for_enrollment = false;
        }
    }

    public entry fun enroll(github: vector<u8>, cohort: &mut Cohort, ctx: &mut TxContext) {
        internal_enroll(&github, cohort, ctx);
        let name = from_ascii(ascii::string(github));
        let cadet = Cadet {
             id: object::new(ctx),
             github:name,
             cohort: object::id(cohort),
        };

        event::emit(CadetEvent {
            id: object::id(&cadet),
            github:name,
            cohort: object::id(cohort)
        });

        transfer::transfer(cadet, tx_context::sender(ctx))
    }

    public entry fun update(github: vector<u8>, cohort: &mut Cohort, ctx: &TxContext) {
        assert!(table::contains(&cohort.cadets, tx_context::sender(ctx)) == true, ENotSignedUp);
        table::remove(&mut cohort.cadets, tx_context::sender(ctx));
        print(cohort);
        internal_enroll(&github, cohort, ctx)
    }

    public fun cadets(self: &Cohort): &table::Table<address, String> {
        &self.cadets
    }

    fun internal_enroll(github: &vector<u8>, cohort: &mut Cohort, ctx: &TxContext) {
        assert!(cohort.open_for_enrollment == true, EEnrollmentNotOpen);
        assert!(table::contains(&cohort.cadets, tx_context::sender(ctx)) == false, EAlreadySignedUp);
        assert!(validate_github_username(github) == true, EInvalidGithubAccount);
        let str_github = from_ascii(ascii::string(*github));
        table::add(&mut cohort.cadets, tx_context::sender(ctx), str_github)
    }

    fun validate_github_username(bytes: &vector<u8>): bool {
        let length = vector::length(bytes);
        if (length_too_long(length)) return false;
        if (hyphen(*vector::borrow(bytes, 0))) return false;
        if (hyphen(*vector::borrow(bytes, length-1))) return false;


        let i = 0;
        while (i < length) {
            let letter = *vector::borrow(bytes, i);
            if (lower_a_to_z(letter) || upper_a_to_z(letter) || zero_to_nine(letter)) {
            } else if (hyphen(letter)) {
                if (double_hyphen(bytes, i)) return false
            } else if (null_term(letter)) {
                if (i != length-1) return false
            } else {
                return false
            };
            i = i + 1;
        };

        true
    }



    fun length_too_long(length:u64) : bool {
        length > 39
    }

    fun double_hyphen(bytes:&vector<u8>, i:u64) : bool {
        hyphen(*vector::borrow(bytes, i+1))
    }

    fun hyphen(byte:u8) : bool {
        byte == 0x2d
    }

    fun null_term(byte:u8) : bool {
        byte == 0x00
    }

    fun upper_a_to_z(byte:u8) : bool  {
        byte >= 0x41 &&
        byte <= 0x5A
    }

    fun zero_to_nine(byte:u8) : bool {
        byte >= 0x30 &&
        byte <= 0x39
    }

    fun lower_a_to_z(byte:u8) : bool {
        byte >= 0x61 &&
        byte <= 0x7A
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}