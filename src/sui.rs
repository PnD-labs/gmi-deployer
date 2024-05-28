use sui_sdk::{SuiClient, SuiClientBuilder};

const SUI_MAINNET_HTTPS: &str = "https://fullnode.mainnet.sui.io:443";
const SUI_MAINNET_WSS: &str = "wss://fullnode.mainnet.sui.io:443";
const SUI_DEVNET_WSS: &str = "wss://fullnode.devnet.sui.io:443";
const SUI_TESTNET_WSS: &str = "wss://fullnode.testnet.sui.io:443";

pub async fn get_client(build: &str) -> SuiClient {
    let client = match build {
        "testnet" => SuiClientBuilder::default()
            .ws_url(SUI_TESTNET_WSS)
            .build_testnet()
            .await
            .unwrap_or_else(|e| panic!("Failed to build testnet client: {}", e)),
        "devnet" => SuiClientBuilder::default()
            .ws_url(SUI_DEVNET_WSS)
            .build_devnet()
            .await
            .unwrap_or_else(|e| panic!("Failed to build devnet client: {}", e)),
        "mainnet" => SuiClientBuilder::default()
            .ws_url(SUI_MAINNET_WSS)
            .build(SUI_MAINNET_HTTPS)
            .await
            .unwrap_or_else(|e| panic!("Failed to build mainnet client: {}", e)),
        _ => panic!("Invalid build type: {}", build),
    };

    client
}
