use anyhow::Result;
use deployer::server;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();
    dotenv::dotenv().ok();
    server::run().await?;
    println!("Hello, world!");
    Ok(())
}
