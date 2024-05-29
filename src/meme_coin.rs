use crate::sui::get_client;
use std::{str::FromStr, sync::Arc};

use anyhow::{Error, Result};
use serde::Deserialize;
use std::process::{Command, Output};
use sui_config::{sui_config_dir, SUI_KEYSTORE_FILENAME};
use sui_keys::keystore::{AccountKeystore, FileBasedKeystore};
use sui_sdk::{
    json::SuiJsonValue,
    rpc_types::{
        Coin, Page, SuiTransactionBlockResponse, SuiTransactionBlockResponseOptions, SuiTypeTag,
    },
    types::{
        base_types::{ObjectID, SuiAddress},
        programmable_transaction_builder::ProgrammableTransactionBuilder,
        quorum_driver_types::ExecuteTransactionRequestType,
        transaction::{Argument, CallArg, ObjectArg, Transaction},
        Identifier,
    },
    SuiClient,
};
use sui_shared_crypto::intent::Intent;
use tracing::info;

pub const SUI_COIN_TYPE: &str = "0x2::sui::SUI";
pub const MEME_MODULE: &str = "meme_coin";
pub const MEME_INIT_FUNCTION: &str = "init_coin";

pub struct Bot {
    pub key: FileBasedKeystore,
    pub address: SuiAddress,
    pub client: SuiClient,
}
impl Bot {
    pub async fn new() -> Self {
        let key = FileBasedKeystore::new(&sui_config_dir().unwrap().join(SUI_KEYSTORE_FILENAME))
            .unwrap_or_else(|e| panic!("Failed to initialize keystore: {}", e));

        let addresses = key.addresses();
        if addresses.is_empty() {
            panic!("No addresses found in keystore");
        }

        let address = addresses[0];
        info!("address = {:?}", address);

        Bot {
            key,
            address,
            client: get_client("testnet").await,
        }
    }

    pub async fn get_coin(&self, coin_type: Option<String>) -> Result<Page<Coin, ObjectID>> {
        let coin = self
            .client
            .coin_read_api()
            .get_coins(self.address, coin_type, None, None)
            .await?;
        // info!("{:?}", coin);
        Ok(coin)
    }

    pub async fn get_gas_coin(&self) -> Result<Coin> {
        let coins = self
            .client
            .coin_read_api()
            .get_coins(self.address, Some(SUI_COIN_TYPE.to_string()), None, None)
            .await?;
        // info!("{:?}", coin);
        let coin = coins.data.into_iter().next().unwrap();
        Ok(coin)
    }
}

#[derive(Debug, Clone)]
pub struct CoinData {
    pub name: String,
    pub symbol: String,
    pub description: String,
    pub image_url: String,
}
#[derive(Debug, Deserialize)]
struct Event {
    id: EventId,
    packageId: String,
    transactionModule: String,
    sender: String,
    #[serde(rename = "type")]
    event_type: String,
    parsedJson: MemeCoinParsedJson,
    bcs: String,
}
#[derive(Debug, Deserialize)]
struct EventId {
    txDigest: String,
    eventSeq: String,
}
#[derive(Debug, Deserialize)]
struct MemeCoinParsedJson {
    metadata: String,
    treasury: String,
}
pub struct MemeCoin {
    // pub digest: String,
    pub package_id: ObjectID,
    pub treasury_id: ObjectID,
    pub metadata_id: ObjectID,
    pub bot: Bot,
}

impl MemeCoin {
    pub async fn new(directory: String) -> Result<Self, Box<dyn std::error::Error>> {
        info!("Deploying...");

        let output = Command::new("sui")
            .arg("client")
            .arg("publish")
            .arg("--json")
            .current_dir(directory)
            .output()?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let json_value: serde_json::Value = serde_json::from_str(&stdout)?;

        info!("Deploying complete!");
        let events = json_value.get("events").ok_or("Missing 'events' field")?;

        let events: Vec<Event> = serde_json::from_value(events.clone())?;

        if let Some(event) = events.get(0) {
            let bot = Bot::new().await;
            Ok(MemeCoin {
                // digest,
                package_id: ObjectID::from_str(event.packageId.as_str())?,
                metadata_id: ObjectID::from_str(event.parsedJson.metadata.as_str())?,
                treasury_id: ObjectID::from_str(event.parsedJson.treasury.as_str())?,
                bot,
            })
        } else {
            Err("No events found".into())
        }
    }

    pub async fn send_metadata(&self, recipeint: &str) -> Result<()> {
        info!("Sending Metadata {:?}", self.metadata_id);

        let send_metadata_tx = self
            .bot
            .client
            .transaction_builder()
            .transfer_object(
                self.bot.address,
                self.metadata_id,
                None,
                15_000_000,
                SuiAddress::from_str(recipeint)?,
            )
            .await?;
        info!("{:?}", send_metadata_tx.clone());
        let signature = self.bot.key.sign_secure(
            &self.bot.address,
            &send_metadata_tx,
            Intent::sui_transaction(),
        )?;
        let response: SuiTransactionBlockResponse = self
            .bot
            .client
            .quorum_driver_api()
            .execute_transaction_block(
                Transaction::from_data(send_metadata_tx, vec![signature]),
                SuiTransactionBlockResponseOptions::full_content(),
                Some(ExecuteTransactionRequestType::WaitForLocalExecution),
            )
            .await?;

        info!(
            "Transfer metadata_id = {:?} to recipeint = {:?} successfully! digest = {:?}",
            self.metadata_id, recipeint, response.digest
        );
        Ok(())
    }
}
