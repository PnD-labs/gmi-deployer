use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use anyhow::Result;
use log::info;
use serde::{Deserialize, Serialize};

use crate::{env, meme_coin::MemeCoin};

#[derive(Deserialize)]
pub struct CoinRequest {
    address: String,
}
#[derive(Serialize)]
pub struct CreateCoinResponse {
    pub metadata_id: String,
    pub treasury_id: String,
    pub package_id: String,
}

async fn create_coin(req_body: web::Json<CoinRequest>) -> impl Responder {
    // 요청 본문을 읽어 처리합니다.
    let CoinRequest { address } = req_body.into_inner();
    info!("Create coin request received {}", address.clone());

    let directory = &env::DirectoryEnv::new().directory;
    println!("directory = {:?}", directory);
    let meme_coin = match MemeCoin::new(directory.to_string()).await {
        Ok(meme_coin) => meme_coin,
        Err(e) => {
            eprintln!("Error creating meme coin: {}", e);
            return HttpResponse::InternalServerError()
                .body(format!("Failed to create coin: {}", e));
        }
    };

    match meme_coin.send_metadata(address.as_str()).await {
        Ok(_) => HttpResponse::Ok().json(CreateCoinResponse {
            metadata_id: meme_coin.metadata_id.to_string(),
            treasury_id: meme_coin.treasury_id.to_string(),
            package_id: meme_coin.package_id.to_string(),
        }),
        Err(e) => {
            eprintln!("Error sending metadata: {}", e);
            return HttpResponse::InternalServerError().body("Failed to create coin");
        }
    }
}

pub async fn run() -> Result<()> {
    println!("Server is running on http://127.0.0.1:8080");

    HttpServer::new(|| App::new().route("/create_coin", web::post().to(create_coin)))
        .bind(("127.0.0.1", 8080))?
        .run()
        .await
        .map_err(|e| anyhow::anyhow!(e))?;
    Ok(())
}
