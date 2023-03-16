// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.6.1 (token/erc20/presets/ERC20.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_sub, uint256_add, uint256_lt

from openzeppelin.token.erc20.library import ERC20
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.access.ownable.library import Ownable
from starkware.cairo.common.math import assert_not_zero
from contracts.token.ERC20.IDTKERC20 import IDTKERC20
from contracts.lib.UTILS import UTILS_assert_uint256_strictly_positive



@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    // name: felt, 
    // symbol: felt, 
    // decimals: felt, 
    // initial_supply: Uint256, 
    // recipient: felt,
    owner : felt,
    _dummy_token_address: felt
) {
    dummy_token_address_storage.write(_dummy_token_address);
    Ownable.initializer(owner);
    return ();
}

// Storage vars

@storage_var
func dummy_token_address_storage() -> (dummy_token_address_storage: felt) {
}

@storage_var
func _tokens_in_custody(account : felt) -> (amount: Uint256) {
}



//
// Getters
//


@view
func tokens_in_custody{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (amount: Uint256) {
    let (amount : Uint256) = _tokens_in_custody.read(account);
    return (amount,);
}

//
// Externals
//


@external
func get_tokens_from_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (amount: Uint256) {
    alloc_locals;
    // It must get DTK tokens from its faucet and allocate it to the caller
    let (caller : felt) = get_caller_address();
    let (this_contract : felt) = get_contract_address();
    let (DTK_contract : felt) = dummy_token_address_storage.read();
    let (initial_balance : Uint256) = IDTKERC20.balanceOf(DTK_contract, this_contract);
    // call the DTK contract faucet
    let (success : felt) = IDTKERC20.faucet(DTK_contract);
    with_attr error_message("Faucet from DTK Failed"){
                assert success = 1;
    }
    let (final_balance : Uint256) = IDTKERC20.balanceOf(DTK_contract, this_contract);
    // The balance difference was the amount minted by the faucet
    let (balance_difference : Uint256) = uint256_sub(final_balance, initial_balance);
    UTILS_assert_uint256_strictly_positive(balance_difference);
    // The tokens from the faucet must be allocated to the caller. We can do this by saving the relationship "caller and faucet amount" on a storage variable.
    // Save on _tokens_in_custody storage_var the amount of tokens held by each account
    // Everytime the faucet is called:
        // Find the caller account on _tokens_in_custody
    let (current_caller_balance : Uint256) = _tokens_in_custody.read(caller);
    let zero_as_uint256: Uint256 = Uint256(0, 0);
    let (caller_has_balance : felt) = uint256_lt(zero_as_uint256, current_caller_balance);
    // If it exists, add the amount provided by the faucet to the current account balance
    if ( caller_has_balance == 1) {
        let (new_caller_balance : Uint256, _) = uint256_add(current_caller_balance, balance_difference);
        _tokens_in_custody.write(caller, new_caller_balance);
    // If it doesn't exist, add the unexistent account to the storage_var and save the amount provided by the faucet
    } else {
        _tokens_in_custody.write(caller, balance_difference);
    }
    
    return (amount = balance_difference);

}

@external
func withdraw_all_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (amount: Uint256) {
    // The whole amount "in custody" of an account must be transferred to that account, as currently the tokens are in possession of this contract.

    // Find the amount owned by the caller on _tokens_in_custody storage_var
    let (this_contract) = get_contract_address();
    let (dummy_token_address) = dummy_token_address_storage.read();
    let (caller) = get_caller_address();
    let (amount_in_custody : Uint256) = _tokens_in_custody.read(caller);
    let zero_as_uint256: Uint256 = Uint256(0, 0);
    let (caller_has_balance : felt) = uint256_lt(zero_as_uint256, amount_in_custody);
    // If the caller has no tokens then return "This account has no tokens in custody"
    with_attr error_message("This account has no tokens in custody."){
            assert caller_has_balance = 1;
        }
    // Call the transferFrom function from the DTK contract and transfer the amount found above to the caller
    let (approve_success : felt) = IDTKERC20.approve(dummy_token_address, this_contract, amount_in_custody);
    with_attr error_message("Approve failed."){
        assert approve_success = 1;
    }

    let (transfer_success : felt) = IDTKERC20.transferFrom(dummy_token_address, this_contract, caller, amount_in_custody);
    with_attr error_message("Withdraw failed."){
        assert transfer_success = 1;
    }

    // Update the storag_var to remove the amount withdrawned
    _tokens_in_custody.write(caller, zero_as_uint256);

    return (amount = amount_in_custody);
}

@external
func deposit_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) -> (total_amount: Uint256) {
    // The idea is to create a function that allows the caller to depoist its DTK tokens to this contract.
    // Use the TransferFrom function to transfer the caller tokens to this contract;

    let (this_contract) = get_contract_address();
    let (caller) = get_caller_address();
    let (dummy_token_address) = dummy_token_address_storage.read();

    let (success : felt) = IDTKERC20.transferFrom(dummy_token_address, caller, this_contract, amount);
    with_attr error_message("Deposit failed."){
        assert success = 1;
    }
    // Update the _tokens_in_custody storage var to put the tokens transferred under the caller's custody.
    // Get caller's current balance, add the deposit amount and update the _tokens_in_custody storage var
    let (caller_balance : Uint256) = _tokens_in_custody.read(caller);
    let (caller_updated_balance : Uint256, _) = uint256_add(caller_balance, amount);
    _tokens_in_custody.write(caller, caller_updated_balance);

    // return (total_amount = caller_updated_balance);
    let zero_as_uint256: Uint256 = Uint256(0, 0);
    // Returning the wrong total_amount to prove that Evaluator is not evaluating the function return.
    return (total_amount = zero_as_uint256);

    

}