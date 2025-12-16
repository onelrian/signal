use anyhow::{Context, Result};
use std::env;
use std::time::Duration;

#[derive(Debug)]
pub struct Config {
    pub loki_url: String,
    pub netbird_api_url: String,
    pub netbird_api_token: String,
    pub check_interval: Duration,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        Ok(Self {
            loki_url: env::var("LOKI_URL").unwrap_or_else(|_| "http://loki:3100".to_string()),
            netbird_api_url: env::var("NETBIRD_API_URL")
                .unwrap_or_else(|_| "https://api.netbird.io".to_string())
                .trim_end_matches('/')
                .to_string(),
            netbird_api_token: env::var("NETBIRD_API_TOKEN")
                .context("NETBIRD_API_TOKEN is required")?,
            check_interval: Duration::from_secs(
                env::var("CHECK_INTERVAL")
                    .unwrap_or_else(|_| "10".to_string())
                    .parse()
                    .unwrap_or(10),
            ),
        })
    }
}
