use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HentaiErrorCode {
    Validation,
    DbInitFailed,
    DbQueryFailed,
}

#[derive(Debug, Clone, Error)]
#[error("{code:?}: {message}")]
pub struct HentaiError {
    pub code: HentaiErrorCode,
    pub message: String,
    pub context: Option<String>,
}

impl HentaiError {
    pub fn validation(message: impl Into<String>) -> Self {
        Self {
            code: HentaiErrorCode::Validation,
            message: message.into(),
            context: None,
        }
    }

    pub fn db_init_failed(message: impl Into<String>, context: Option<String>) -> Self {
        Self {
            code: HentaiErrorCode::DbInitFailed,
            message: message.into(),
            context,
        }
    }

    pub fn db_query_failed(message: impl Into<String>, context: Option<String>) -> Self {
        Self {
            code: HentaiErrorCode::DbQueryFailed,
            message: message.into(),
            context,
        }
    }
}
