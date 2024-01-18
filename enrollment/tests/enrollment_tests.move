#[test_only]
module cohort::enrollment_tests {

    use sui::{
        tx_context::{Self, TxContext},
        object::{Self, UID, ID, uid_to_inner},
        transfer,
        table
    };
    use std::{
        string::{String, from_ascii, utf8},
        ascii,
        vector,
        debug::print
    };
    
    use sui::test_scenario as ts;

    use cohort::enrollment::{Self, Cohort, Cadet, InstructorCap};
    use cohort::enrollment::{test_init, create_cohort, toggle_signups, enroll};
    use cohort::enrollment::{update};

    const INSTRUCTOR: address = @0x99;
    const CADET: address = @0xAA;

    fun init_test() : ts::Scenario{
        // first transaction to emulate module initialization
        let scenario_val = ts::begin(INSTRUCTOR);
        let scenario = &mut scenario_val;
        {
            test_init(ts::ctx(scenario));
        };
        scenario_val
    }

    fun create_cohort_test(scenario: &mut ts::Scenario) {
         ts::next_tx(scenario, INSTRUCTOR);
        {
            let cap = ts::take_from_sender<InstructorCap>(scenario);
            let name = "cohort_name";
            create_cohort(&cap, name, ts::ctx(scenario));
            ts::return_to_sender(scenario, cap);
        };
    }

    fun open_enrollment_test(scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, INSTRUCTOR);
        {
            let cap = ts::take_from_sender<InstructorCap>(scenario);
            let cohort = ts::take_shared<Cohort>(scenario);
            toggle_signups(&cap, &mut cohort);
            ts::return_to_sender(scenario, cap);
            ts::return_shared(cohort);
        };
    }

    fun enroll_cadet_test(github:vector<u8>, scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, CADET);
        {
            let cohort = ts::take_shared<Cohort>(scenario);
            enroll(github, &mut cohort, ts::ctx(scenario));
            ts::return_shared(cohort);
        };
    }

    fun update_cadet_test(github:vector<u8>, scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, CADET);
        {
            let cohort = ts::take_shared<Cohort>(scenario);
            update(github, &mut cohort, ts::ctx(scenario));
            ts::return_shared(cohort);
        };
    }

    fun get_cadet_table(github:vector<u8>, scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, CADET);
        {
            let cohort = ts::take_shared<Cohort>(scenario);
            enroll(github, &mut cohort, ts::ctx(scenario));
            ts::return_shared(cohort);
        };
    }

     #[test]
    fun test_cohort_creation_and_enrollment() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Cadet can now enroll
        enroll_cadet_test(b"ivmidable", scenario);
        ts::end(scenario_val);
    }

    #[test]
    fun test_updating_github() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Cadet can now enroll
        enroll_cadet_test(b"ivmidable", scenario);
        update_cadet_test(b"ivmid", scenario);
        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    fun test_updating_github_before_enrolling() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Cadet can now enroll
        update_cadet_test(b"ivmidable", scenario);
        ts::end(scenario_val);
    }


    #[test]
    #[expected_failure]
    fun signup_before_open() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        //enrollment should fail
        enroll_cadet_test(b"ivmidable", scenario);
        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    fun invalid_github_name_start_hyphen() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Enroll cadet
        //these should all fail.
        enroll_cadet_test(b"-ivmidable", scenario);
        //enroll_cadet_test(b"ivmidable-", scenario);
        ts::end(scenario_val);
    }

        fun invalid_github_name_end_hyphen() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Enroll cadet
        //these should all fail.
        enroll_cadet_test(b"ivmidable-", scenario);
        //enroll_cadet_test(b"ivmidable-", scenario);
        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    fun invalid_github_name_space() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Enroll cadet
        //enroll_cadet_test(b"ivmidable-", scenario);
        enroll_cadet_test(b"ivmi dable", scenario);
        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    fun invalid_github_name_double_hyphen() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Enroll cadet
        //these should all fail.
        enroll_cadet_test(b"ivmid--able", scenario);
        ts::end(scenario_val);
    }

    #[test]
    fun github_name_newline() {
        use std::vector;
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Enroll cadet
        let name = b"ivmidable";
        vector::push_back(&mut name, 0x00);
        enroll_cadet_test(name, scenario);
        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    fun invalid_github_name_newline() {
        use std::vector;
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        // Open for enrollment
        open_enrollment_test(scenario);
        // Enroll cadet
        let name = b"ivmidable";
        vector::insert(&mut name, 0x00, 4);
        enroll_cadet_test(name, scenario);
        ts::end(scenario_val);
    }

    #[test]
    fun get_cadet_table() {
        let scenario_val= init_test();
        let scenario = &mut scenario_val;
        // create cohort
        create_cohort_test(scenario);
        //enrollment should fail
        enroll_cadet_test(b"ivmidable", scenario);
        ts::end(scenario_val);
    }
}
