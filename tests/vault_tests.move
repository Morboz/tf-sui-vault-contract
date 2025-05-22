#[test_only]
module vault::vault_tests {
    use sui::{
        coin::{Self, Coin},
        test_scenario::{Self as ts, Scenario},
        sui::SUI,
        balance,
        url,
    };
    use suifund::suifund::{Self, SupporterReward};
    use vault::vault::{
        Self,
        AccessList,
        Record,
        BalanceManager,
        AdminCap,
        Version as VaultVersion,
    };

    const ADMIN: address = @0x1111;
    const USER: address = @0x2222;
    const BOT: address = @0x3333;
    const PROJECT_NAME: vector<u8> = b"TradingFlow";
    const SUI_AMOUNT: u64 = 10_000_000_000; // 10 SUI
    const MIN_AMOUNT: u64 = 1_000_000_000;  // 1 SUI

    // 测试场景：初始化环境
    fun setup_test(): Scenario {
        let mut scenario = ts::begin(ADMIN);

        // 初始化 Suifund 和 Vault 合约
        {
            vault::init_for_testing(ts::ctx(&mut scenario));
        };

        scenario
    }

    fun create_mock_supporter_reward(ctx: &mut TxContext): SupporterReward {
        let new_object_uid = object::new(ctx); // 创建 UID 并存储
        let new_object_id = object::uid_to_inner(&new_object_uid); // 获取 ID 的副本
        object::delete(new_object_uid); // 显式删除 UID

        // 注意：这里使用了suifund模块中的测试函数
        suifund::new_sp_rwd_for_testing(
            std::ascii::string(PROJECT_NAME), // 项目名称
            new_object_id, // 模拟项目ID
            url::new_unsafe_from_bytes(b"https://example.com/image"), // 图片URL
            1000, // 代币数量
            balance::create_for_testing<SUI>(MIN_AMOUNT), // SUI余额
            0, // 开始时间
            1000000, // 结束时间
            ctx
        )
    }

    // 测试场景：创建项目并获取 SupporterReward
    fun setup_project_and_reward(scenario: &mut Scenario): SupporterReward {
        create_mock_supporter_reward(ts::ctx(scenario))
    }
    
    // 测试用例：完整场景测试
    #[test]
    fun test_vault_workflow() {
        let mut scenario = setup_test();
        let supporter_reward = setup_project_and_reward(&mut scenario);
        
        // 创建用户的 BalanceManager
        ts::next_tx(&mut scenario, USER);
        {
            let mut record = ts::take_shared<Record>(&scenario);
            let vault_version = ts::take_shared<VaultVersion>(&scenario);
            
            // 创建余额管理器
            vault::create_balance_manager(
                &mut record,
                &supporter_reward,
                &vault_version,
                ts::ctx(&mut scenario)
            );
            
            ts::return_shared(record);
            ts::return_shared(vault_version);
        };
        
        // 用户存款操作
        ts::next_tx(&mut scenario, USER);
        {
            let mut balance_manager = ts::take_shared<BalanceManager>(&scenario);
            let vault_version = ts::take_shared<VaultVersion>(&scenario);
            
            // 铸造SUI用于存款
            let deposit_coin = mint_sui(SUI_AMOUNT, ts::ctx(&mut scenario));
            
            // 用户存款
            vault::user_deposit<SUI>(
                &mut balance_manager,
                deposit_coin,
                &supporter_reward,
                &vault_version,
                ts::ctx(&mut scenario)
            );
            // 查询余额
            let balance = vault::query<SUI>(&mut balance_manager);
            assert!(balance == SUI_AMOUNT, 0);
            
            ts::return_shared(balance_manager);
            ts::return_shared(vault_version);
        };
        
        // 用户取款操作
        ts::next_tx(&mut scenario, USER);
        {
            let mut balance_manager = ts::take_shared<BalanceManager>(&scenario);
            let vault_version = ts::take_shared<VaultVersion>(&scenario);
            
            // 用户提取一半的SUI
            vault::user_withdraw<SUI>(
                &mut balance_manager,
                SUI_AMOUNT / 2,
                &supporter_reward,
                &vault_version,
                ts::ctx(&mut scenario)
            );
            
            // 查询余额
            let balance = vault::query<SUI>(&mut balance_manager);
            assert!(balance == SUI_AMOUNT / 2, 1);
            
            ts::return_shared(balance_manager);
            ts::return_shared(vault_version);
        };
        
        // 机器人操作测试：添加机器人到白名单
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut access_list = ts::take_shared<AccessList>(&scenario);
            
            // 添加机器人到白名单
            vault::acl_add(&admin_cap, &mut access_list, BOT);
            
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(access_list);
        };
        
        // 机器人存款操作
        ts::next_tx(&mut scenario, BOT);
        {
            let mut balance_manager = ts::take_shared<BalanceManager>(&scenario);
            let access_list = ts::take_shared<AccessList>(&scenario);
            
            // 铸造SUI用于机器人存款
            let bot_deposit = mint_sui(SUI_AMOUNT, ts::ctx(&mut scenario));
            
            // 机器人存款
            vault::bot_deposit<SUI>(
                &access_list,
                &mut balance_manager,
                bot_deposit,
                MIN_AMOUNT, // 最小金额检查
                ts::ctx(&mut scenario)
            );
            
            // 查询余额
            let balance = vault::query<SUI>(&mut balance_manager);
            assert!(balance == SUI_AMOUNT / 2 + SUI_AMOUNT, 2);
            
            ts::return_shared(balance_manager);
            ts::return_shared(access_list);
        };
        
        // 机器人取款操作
        ts::next_tx(&mut scenario, BOT);
        {
            let mut balance_manager = ts::take_shared<BalanceManager>(&scenario);
            let access_list = ts::take_shared<AccessList>(&scenario);
            
            // 机器人取款
            let withdrawn_coin = vault::bot_withdraw<SUI>(
                &access_list,
                &mut balance_manager,
                SUI_AMOUNT / 4,
                ts::ctx(&mut scenario)
            );
            
            // 验证取款金额
            assert!(coin::value(&withdrawn_coin) == SUI_AMOUNT / 4, 3);
            transfer::public_transfer(withdrawn_coin, BOT);
            
            // 查询剩余余额
            let balance = vault::query<SUI>(&mut balance_manager);
            assert!(balance == SUI_AMOUNT / 2 + SUI_AMOUNT - SUI_AMOUNT / 4, 4);
            
            ts::return_shared(balance_manager);
            ts::return_shared(access_list);
        };
        
        // 清理
        ts::next_tx(&mut scenario, USER);
        {
            transfer::public_transfer(supporter_reward, USER);
        };
        
        ts::end(scenario);
    }
    
    // 辅助函数：铸造SUI代币
    fun mint_sui(amount: u64, ctx: &mut TxContext): Coin<SUI> {
        coin::mint_for_testing<SUI>(amount, ctx)
    }
}