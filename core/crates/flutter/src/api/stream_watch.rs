use hentai_core::HentaiError;

use crate::api::init::HentaiErrorDto;
use crate::frb_generated::{SseEncode, StreamSink};

/// Dart 侧取消 Stream 订阅后，向已关闭的 [StreamSink] 写入会失败；这是正常生命周期，不是错误。
pub const STREAM_CLOSED: &str = "stream closed";

#[flutter_rust_bridge::frb(ignore)]
pub fn emit_or_closed<T>(sink: &StreamSink<T>, item: T) -> Result<(), HentaiError>
where
    T: SseEncode,
{
    sink.add(item)
        .map_err(|_| HentaiError::validation(STREAM_CLOSED))
}

/// 将 watch 循环结果中的「流已关闭」规范为成功退出。
#[flutter_rust_bridge::frb(ignore)]
pub fn normalize_watch_result(
    result: Result<(), HentaiError>,
) -> Result<(), HentaiErrorDto> {
    match result {
        Ok(()) => Ok(()),
        Err(error) if error.message == STREAM_CLOSED => Ok(()),
        Err(error) => Err(HentaiErrorDto::from(error)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_watch_result_treats_stream_closed_as_ok() {
        let result = normalize_watch_result(Err(HentaiError::validation(STREAM_CLOSED)));
        assert!(result.is_ok());
    }

    #[test]
    fn normalize_watch_result_preserves_real_errors() {
        let result =
            normalize_watch_result(Err(HentaiError::db_query_failed("boom", None)));
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().message, "boom");
    }
}
