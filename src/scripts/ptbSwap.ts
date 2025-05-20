import { AggregatorClient, Env } from "@cetusprotocol/aggregator-sdk"
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Transaction } from "@mysten/sui/transactions";
import BN from 'bn.js';

const mnemonics: string = process.env.MNEMONICS!;
const keypair = Ed25519Keypair.deriveKeypair(mnemonics);
const wallet = keypair.toSuiAddress();
console.log(wallet)

const suiClient = new SuiClient({
    url: getFullnodeUrl("mainnet"),
});

// 将异步操作包裹在函数中
async function executeSwap() {
    try {
        const client = new AggregatorClient({
            signer: wallet,
            client: suiClient,
            env: Env.Mainnet,
            overlayFeeRate: 0.01, 
            overlayFeeReceiver: wallet,
        })

        const amount = new BN(1000000)
        const from = "0x2::sui::SUI"
        const target = "0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS"

        const routers = await client.findRouters({
            from,
            target,
            amount,
            byAmountIn: true,
        })

        if (!routers) {
            process.exit(0)
        }
        
        const txb = new Transaction()

        const [coin] = txb.splitCoins(txb.gas, [1000000])
        const targetCoin = await client.routerSwap({
            routers,
            txb,
            inputCoin: coin,
            slippage: 0.01,
        })

        // you can use this target coin object argument to build your ptb.
        client.transferOrDestoryCoin(
            txb,
            targetCoin,
            target,
            client.publishedAtV2()
        )

        console.log(txb.getData());

    } catch (error) {
        console.error("执行交易时出错:", error)
    }
}


// 使用立即执行的异步函数
(async () => {
  try {
    await executeSwap();
    console.log("交换操作完成");
  } catch (error) {
    console.error("交换操作主进程错误:", error);
    process.exit(1);
  }
})();
