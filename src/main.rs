use anyhow::Result;
use deployer::server;

#[tokio::main]
async fn main() -> Result<()> {
    dotenv::dotenv().ok();
    server::run().await?;
    println!("Hello, world!");
    Ok(())
}
