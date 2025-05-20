import { SuiClient } from '@mysten/sui/client';

async function main() {
  // 连接到 Sui devnet
  const client = new SuiClient({
    url: 'https://fullnode.devnet.sui.io:443'
  });
  
  // 获取 Sui 网络状态
  const status = await client.getLatestCheckpointSequenceNumber();
  console.log('Latest checkpoint:', status);
}

main().catch(console.error);