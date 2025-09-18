script {
     use std::vector;
     use supra_framework::supra_governance;

     fun epoch_change_proposal(proposal_id: u64) {
         let framework_signer = supra_governance::resolve_supra_multi_step_proposal(proposal_id, @0x1, vector::empty());
        
         supra_governance::reconfigure(&framework_signer);
     }
}


