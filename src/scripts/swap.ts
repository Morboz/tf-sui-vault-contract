import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { decodeSuiPrivateKey } from '@mysten/sui/cryptography';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Transaction } from '@mysten/sui/transactions';
import { AggregatorClient, Env } from '@cetusprotocol/aggregator-sdk';
import BN from 'bn.js';
import * as dotenv from 'dotenv';
dotenv.config();

// 初始化配置
const TREASURY_PACKAGE = '0x3c7b84ce90116b6d55b4fe06fef2e2a9df00e2fae9a50f618b1f0098e9d3b0f1';
const SUI_TREASURY_CONFIG_ID = '0xfdae722af3f6452ca6ff9a153a57d7fc31e6518dd529f930ad177076623dde62';
const SUI_TREASURY_ID = '0xc7d8ab13f7f9d9dfbe8a67c57da0995aeaf37137b368a042b4f480cfa5893bf5';
const CETUS_TREASURY_ID = '0xbff107c2995246188ee82d7e9719219c214bd56b6f27d39af4b721e4d8a9a4b4';
const PRIVATE_KEY = process.env.PRIVATE_KEY!; // 管理员或白名单地址的私钥
const SWAP_AMOUNT = 1000000; // 0.001 SUI

async function swapFromTreasury() {
  try {
    // 初始化客户端
    const suiClient = new SuiClient({
      url: getFullnodeUrl("mainnet"),
    });
    
    // 使用 decodeSuiPrivateKey 解析私钥并创建密钥对
    const parsedKeypair = decodeSuiPrivateKey(PRIVATE_KEY);
    
    let keypair;
    if (parsedKeypair.schema === 'ED25519') {
      keypair = Ed25519Keypair.fromSecretKey(parsedKeypair.secretKey);
    } else {
      throw new Error(`不支持的密钥类型: ${parsedKeypair.schema}`);
    }
    
    const wallet = keypair.toSuiAddress();
    console.log('钱包地址:', wallet);
    
    // 初始化聚合器客户端
    const aggregatorClient = new AggregatorClient({
      signer: wallet,
      client: suiClient,
      env: Env.Mainnet,
      overlayFeeRate: 0.01,
      overlayFeeReceiver: wallet,
    });
    
    // 定义代币类型
    const fromCoinType = '0x2::sui::SUI';
    const toCoinType = '0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS';
    
    // 构建交易
    const txb = new Transaction();
    txb.setGasBudget(10000000);
    
    // 从金库提取代币
    const withdrawResult = txb.moveCall({
      target: `${TREASURY_PACKAGE}::treasury::withdraw`,
      typeArguments: [fromCoinType],
      arguments: [
        txb.object(SUI_TREASURY_CONFIG_ID),
        txb.object(SUI_TREASURY_ID),
        txb.pure.u64(SWAP_AMOUNT),
      ]
    });
    
    // 计算最佳交换路由
    const routers = await aggregatorClient.findRouters({
      from: fromCoinType,
      target: toCoinType,
      amount: new BN(SWAP_AMOUNT),
      byAmountIn: true,
    });
    
    if (!routers) {
      throw new Error("未找到交换路径");
    }
    
    // 执行代币交换
    const swapResultCoin = await aggregatorClient.routerSwap({
      routers,
      txb,
      inputCoin: withdrawResult,
      slippage: 0.01,
    });
    
    // 将交换后的代币存回金库
    txb.moveCall({
      target: `${TREASURY_PACKAGE}::treasury::deposit`,
      typeArguments: [toCoinType],
      arguments: [
        txb.object(CETUS_TREASURY_ID),
        swapResultCoin,
      ]
    });
    
    // 签名并执行交易
    const result = await suiClient.signAndExecuteTransaction({
      transaction: txb,
      signer: keypair,
      options: {
        showEffects: true,
        showEvents: true,
      }
    });
      
    console.log("交易执行成功!");
    console.log("交易摘要:", result.digest);
    console.log("状态:", result.effects?.status);
    console.log("事件:", result.events);
    
  } catch (error) {
    console.error("执行交换失败:", error);
  }
}

// 使用立即执行的异步函数
(async () => {
  try {
    await swapFromTreasury();
    console.log("交换操作完成");
  } catch (error) {
    console.error("交换操作主进程错误:", error);
    process.exit(1);
  }
})();