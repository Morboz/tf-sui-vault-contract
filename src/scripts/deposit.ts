import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { decodeSuiPrivateKey } from '@mysten/sui/cryptography';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Transaction } from '@mysten/sui/transactions';
import * as dotenv from 'dotenv';
dotenv.config();

// 初始化配置
const TREASURY_PACKAGE = '0x3c7b84ce90116b6d55b4fe06fef2e2a9df00e2fae9a50f618b1f0098e9d3b0f1';
const TREASURY_ID = '0xc7d8ab13f7f9d9dfbe8a67c57da0995aeaf37137b368a042b4f480cfa5893bf5';
const PRIVATE_KEY = process.env.PRIVATE_KEY!; // 管理员或白名单地址的私钥
const DEPOSIT_AMOUNT = 10000000; // 0.01 SUI

async function depositToTreasury() {
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
    
    // 构建交易
    const txb = new Transaction();
    
    // 从发送者钱包中分离出SUI代币
    const [coin] = txb.splitCoins(txb.gas, [DEPOSIT_AMOUNT]);
    
    // 将代币存入金库
    txb.moveCall({
      target: `${TREASURY_PACKAGE}::treasury::deposit`,
      typeArguments: ['0x2::sui::SUI'],
      arguments: [
        txb.object(TREASURY_ID),
        coin,
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
    
    console.log("存款成功!");
    console.log("交易摘要:", result.digest);
    console.log("状态:", result.effects?.status);
    
  } catch (error) {
    console.error("执行存款失败:", error);
  }
}

// 使用立即执行的异步函数
(async () => {
  try {
    await depositToTreasury();
    console.log("存款操作完成");
  } catch (error) {
    console.error("存款操作主进程错误:", error);
    process.exit(1);
  }
})();