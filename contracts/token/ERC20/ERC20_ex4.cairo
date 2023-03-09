// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.6.1 (token/erc20/presets/ERC20.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.library import ERC20
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.access.ownable.library import Ownable
from starkware.cairo.common.math import assert_not_zero


@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, 
    symbol: felt, 
    decimals: felt, 
    initial_supply: Uint256, 
    recipient: felt,
    owner : felt, 
    _allowed_amount : Uint256
) {
    ERC20.initializer(name, symbol, decimals);
    Ownable.initializer(owner);
    allowed_amount.write(_allowed_amount);
    ERC20._mint(recipient, initial_supply);
    return ();
}

// Storage vars

//  Allowed Amount per mint
@storage_var
func allowed_amount() -> (withdraw_value : Uint256){
}

@storage_var
func allow_list(account : felt) -> (level : felt) {
}


//
// Getters
//

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC20.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC20.symbol();
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC20.total_supply();
    return (totalSupply=totalSupply);
}

@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    return ERC20.decimals();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    return ERC20.balance_of(account);
}

@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, spender: felt
) -> (remaining: Uint256) {
    return ERC20.allowance(owner, spender);
}

@view
func allowlist_level{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (level: felt) {
     with_attr error_message("The zero address can't be on the list") {
        assert_not_zero(account);
    }
// level 0 should mean that the account is not allowed to use the faucet
    let (level : felt) = allow_list.read(account);
    return (level,);
}

//
// Externals
//

@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer(recipient, amount);
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer_from(sender, recipient, amount);
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.approve(spender, amount);
}

@external
func increaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, added_value: Uint256
) -> (success: felt) {
    return ERC20.increase_allowance(spender, added_value);
}

@external
func decreaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, subtracted_value: Uint256
) -> (success: felt) {
    return ERC20.decrease_allowance(spender, subtracted_value);
}

@external
func get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (amount: Uint256) {
    alloc_locals;
    // assert_only_whitelisted();

    let (recipient) = get_caller_address();
    let (amount : Uint256) = allowed_amount.read();
    let (token_address : felt) = get_contract_address();
    let (is_whitelisted) = allow_list.read(recipient);
    let zero_as_uint256 : Uint256 = Uint256(0, 0);

    if (is_whitelisted == 1) {
        let (success: felt) = IERC20.transfer(contract_address=token_address, recipient=recipient, amount=amount);
        with_attr error_message("Faucet Failed"){
            assert success = 1;
        }
        return(amount,);
    } else {
        return (amount = zero_as_uint256);
        // let (success: felt) = IERC20.transfer(contract_address=token_address, recipient=recipient, amount=zero_as_uint256);
        // with_attr error_message("Faucet Failed"){
        //     assert success = 1;
        // }
        // return(amount,);
    }

}

@external
func request_allowlist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (level_granted: felt) {
// Should return 1 when the account is whitelisted
    let (requester : felt) = get_caller_address();
    allow_list.write(requester, 1);
    return (level_granted = 1);
}

// func assert_only_whitelisted{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() {
//     let (sender_address) = get_caller_address();
//     let (is_whitelisted) = allow_list.read(sender_address);
//     with_attr error_message("Caller is not a whitelisted") {
//         assert is_whitelisted = 1;
//     }
//     return ();
// }