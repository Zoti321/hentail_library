use hentai_core::HentaiError;

#[derive(Debug, Clone)]
pub struct HentaiErrorDto {
    pub code: String,
    pub message: String,
    pub context: Option<String>,
}

impl From<HentaiError> for HentaiErrorDto {
    fn from(value: HentaiError) -> Self {
        let code = format!("{:?}", value.code);
        Self {
            code,
            message: value.message,
            context: value.context,
        }
    }
}
