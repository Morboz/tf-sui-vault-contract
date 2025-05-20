module treasury::treasury {
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};
    use sui::balance::{Self, Balance};
    
    /// 错误码
    const ENotAdmin: u64 = 1;
    const ENotWhitelisted: u64 = 2;
    // const ENonZeroBalance: u64 = 3;
    
    // 事件
    // public struct WithdrawEvent has copy, drop { 
    //     treasury_id: ID,
    //     coin_type: String,
    //     amount: u64,
    //     withdrawer: address,
    // }
    
    // public struct DepositEvent has copy, drop {
    //     treasury_id: ID,
    //     coin_type: String,
    //     amount: u64,
    //     depositor: address,
    // }
    
    // public struct WhitelistAddedEvent has copy, drop {
    //     address: address,
    // }
    
    // public struct WhitelistRemovedEvent has copy, drop {
    //     address: address,
    // }
    
    /// 金库配置
    public struct TreasuryConfig has key {
        id: UID,
        admin: address,
        whitelist: Table<address, bool>,
    }
    
    /// 金库共享对象
    public struct Treasury<phantom T> has key {
        id: UID,
        config_id: ID,
        balance: Balance<T>,  // 添加余额字段
    }
    
    /// 管理员权限检查
    public fun assert_admin(config: &TreasuryConfig, sender: address) {
        assert!(config.admin == sender, ENotAdmin);
    }
    
    /// 白名单检查
    public fun assert_whitelisted(config: &TreasuryConfig, sender: address) {
        assert!(sender == config.admin || 
               (table::contains(&config.whitelist, sender) && 
                *table::borrow(&config.whitelist, sender)), 
               ENotWhitelisted);
    }
    
    /// 创建金库配置
    public fun create_treasury_config(ctx: &mut TxContext): TreasuryConfig {
        let sender = tx_context::sender(ctx);
        let mut whitelist = table::new<address, bool>(ctx);
        
        // 创建者自动添加到白名单
        table::add(&mut whitelist, sender, true);
        
        TreasuryConfig {
            id: object::new(ctx),
            admin: sender,
            whitelist,
        }
    }
    
    /// 创建金库
    public fun create_treasury<T>(
        config: &TreasuryConfig, 
        ctx: &mut TxContext
    ): Treasury<T> {
        Treasury<T> {
            id: object::new(ctx),
            config_id: object::id(config),
            balance: balance::zero(),  // 初始化为零余额
        }
    }
    
    /// 创建并分享金库
    public entry fun create_and_share_treasury<T>(ctx: &mut TxContext) {
        let config = create_treasury_config(ctx);
        let config_id = object::id(&config);
        let treasury = Treasury<T> {
            id: object::new(ctx),
            config_id,
            balance: balance::zero(),  // 初始化为零余额
        };
        
        // 分享配置和金库
        transfer::share_object(config);
        transfer::share_object(treasury);
    }
    
    /// 添加白名单地址
    public entry fun add_to_whitelist(
        config: &mut TreasuryConfig, 
        addr: address, 
        ctx: &mut TxContext
    ) {
        assert_admin(config, tx_context::sender(ctx));
        
        if (!table::contains(&config.whitelist, addr)) {
            table::add(&mut config.whitelist, addr, true);
        } else {
            let value = table::borrow_mut(&mut config.whitelist, addr);
            *value = true;
        }
    }
    
    /// 从白名单中移除地址
    public entry fun remove_from_whitelist(
        config: &mut TreasuryConfig, 
        addr: address, 
        ctx: &mut TxContext
    ) {
        assert_admin(config, tx_context::sender(ctx));
        
        if (table::contains(&config.whitelist, addr)) {
            let value = table::borrow_mut(&mut config.whitelist, addr);
            *value = false;
        }
        
        // event::emit(WhitelistRemovedEvent { address: addr });
    }
    
    /// 从金库提取代币
    public fun withdraw<T>(
        config: &TreasuryConfig,
        treasury: &mut Treasury<T>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<T> {
        let sender = tx_context::sender(ctx);
        assert_whitelisted(config, sender);
        
        // 从金库的余额中提取代币
        coin::from_balance(balance::split(&mut treasury.balance, amount), ctx)
    }
    
    /// 向金库存入代币
    public fun deposit<T>(
        treasury: &mut Treasury<T>,
        coin: Coin<T>,
        ctx: &TxContext
    ) {
        let amount = coin::value(&coin);
        let sender = tx_context::sender(ctx);
        // todo emit event
        
        // 将代币转换为余额并存入金库
        balance::join(&mut treasury.balance, coin::into_balance(coin));
    }
    
    /// 转移金库管理员权限
    public entry fun transfer_admin(
        config: &mut TreasuryConfig,
        new_admin: address,
        ctx: &mut TxContext
    ) {
        assert_admin(config, tx_context::sender(ctx));
        config.admin = new_admin;
        
        // 如果新管理员不在白名单中，将其添加到白名单
        if (!table::contains(&config.whitelist, new_admin)) {
            table::add(&mut config.whitelist, new_admin, true);
        } else {
            let value = table::borrow_mut(&mut config.whitelist, new_admin);
            *value = true;
        }
    }
}