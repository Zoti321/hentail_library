use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HentaiErrorCode {
    Validation,
    DbInitFailed,
    DbQueryFailed,
    ReaderNotFound,
    ReaderKindMismatch,
    ReaderUnsupportedType,
    ReaderInvalidContent,
    ReaderSessionNotOpen,
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

    pub fn reader_not_found(path: impl Into<String>) -> Self {
        Self {
            code: HentaiErrorCode::ReaderNotFound,
            message: format!("路径不存在: {}", path.into()),
            context: None,
        }
    }

    pub fn reader_kind_mismatch(message: impl Into<String>) -> Self {
        Self {
            code: HentaiErrorCode::ReaderKindMismatch,
            message: message.into(),
            context: None,
        }
    }

    pub fn reader_unsupported_type(resource_type: impl Into<String>) -> Self {
        Self {
            code: HentaiErrorCode::ReaderUnsupportedType,
            message: format!("暂不支持的资源类型: {}", resource_type.into()),
            context: None,
        }
    }

    pub fn reader_invalid_content(message: impl Into<String>) -> Self {
        Self {
            code: HentaiErrorCode::ReaderInvalidContent,
            message: message.into(),
            context: None,
        }
    }

    pub fn reader_session_not_open(comic_id: impl Into<String>) -> Self {
        Self {
            code: HentaiErrorCode::ReaderSessionNotOpen,
            message: format!("阅读会话未打开: {}", comic_id.into()),
            context: None,
        }
    }
}
