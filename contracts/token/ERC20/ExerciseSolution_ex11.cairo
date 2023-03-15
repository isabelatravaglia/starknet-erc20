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