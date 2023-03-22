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



// Storage vars

@storage_var
func _minters(account : felt) -> (minter : felt) {
}


@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, 
    symbol: felt, 
    decimals: felt, 
    initial_supply: Uint256, 
    recipient: felt,
    owner : felt
) {
    ERC20.initializer(name, symbol, decimals);
    Ownable.initializer(owner);
    ERC20._mint(recipient, initial_supply);
    _minters.write(owner,1);
    return ();
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
func is_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (true: felt) {
     with_attr error_message("The zero address can't be a minter") {
        assert_not_zero(account);
    }
// level 0 should mean that the account is not allowed to use the faucet
    let (true : felt) = _minters.read(account);
    return (true,);
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

// @external
// func mint_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount : Uint256) -> (amount: Uint256) {
//     alloc_locals;
//     assert_only_minters();

//     let (recipient) = get_caller_address();
//     let (token_address : felt) = get_contract_address();


//     let (success: felt) = IERC20.transfer(contract_address=token_address, recipient=recipient, amount=amount);
//     with_attr error_message("Minting Failed"){
//         assert success = 1;
//     }

//     return (amount,);
// }

@external
func mint_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount : Uint256) -> (success : felt) {
    alloc_locals;
    assert_only_minters();

    let (recipient) = get_caller_address();
    let (token_address : felt) = get_contract_address();

    ERC20._mint(recipient=recipient, amount=amount);

    return (success=1);
}


@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) -> (success : felt) {
    let (caller) = get_caller_address();
    ERC20._burn(caller, amount);
    return (success = 1);
}

@external
func burnFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, amount: Uint256
) -> (success : felt) {
    let (caller) = get_caller_address();
    ERC20._spend_allowance(account, caller, amount);
    ERC20._burn(account, amount);
    return (success = 1);
}

@external
func add_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account : felt) -> (success: felt) {
    Ownable.assert_only_owner();
    _minters.write(account, 1);
    return (success = 1);
}


func assert_only_minters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (true: felt) {
    alloc_locals;
    let (caller) = get_caller_address();
    let (is_minter : felt) = _minters.read(caller);
    with_attr error_message("Caller is not a minter") {
        assert is_minter = 1;
    }
    return (true = is_minter);
}
