pub fn get_env(key: &str) -> String {
    println!("{:?}", key);
    std::env::var(key).unwrap()
}

#[derive(Debug, Clone)]
pub struct DirectoryEnv {
    pub directory: String,
}

impl DirectoryEnv {
    pub fn new() -> Self {
        DirectoryEnv {
            directory: get_env("DEPLOY_DIRECTORY"),
        }
    }
}
