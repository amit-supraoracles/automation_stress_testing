script {
     use std::vector;
     use supra_framework::supra_governance;
     use supra_framework::automation_registry;

     fun update_automation_registry_config_proposal(proposal_id: u64) {
         let framework_signer = supra_governance::resolve_supra_multi_step_proposal(proposal_id, @0x1, vector::empty());

         let task_duration_cap_in_secs = 720000;
         let registry_max_gas_cap = 10000000;
         let automation_base_fee_in_quants_per_sec = 1000;
         let flat_registration_fee_in_quants = 50000000;
         let congestion_threshold_percentage = 25;
         let congestion_base_fee_in_quants_per_sec = 20000;
         let congestion_exponent = 6;
         let task_capacity = 600;
         automation_registry::update_config(
            &framework_signer,
            task_duration_cap_in_secs,
            registry_max_gas_cap,
            automation_base_fee_in_quants_per_sec,
            flat_registration_fee_in_quants,
            congestion_threshold_percentage,
            congestion_base_fee_in_quants_per_sec,
            congestion_exponent,
            task_capacity,
         );
     }
}


