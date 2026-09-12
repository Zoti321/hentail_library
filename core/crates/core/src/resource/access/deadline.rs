//! Bounded Local Resource access helpers.
//!
//! Unreachable mounts (NAS/SMB) can block indefinitely inside `std::fs`. We run
//! probes on a worker thread and fail with [HentaiError::timed_out] when the
//! deadline elapses. The worker may outlive the call on a stuck I/O; that is
//! preferred over hanging the Read session forever.

use std::sync::mpsc;
use std::time::Duration;

use crate::error::HentaiError;

/// Default deadline for Local list / stat / open probes.
pub const LOCAL_IO_TIMEOUT: Duration = Duration::from_secs(30);

pub fn run_with_deadline<T, F>(deadline: Duration, work: F) -> Result<T, HentaiError>
where
    T: Send + 'static,
    F: FnOnce() -> Result<T, HentaiError> + Send + 'static,
{
    let (tx, rx) = mpsc::channel();
    std::thread::Builder::new()
        .name("local-resource-io".into())
        .spawn(move || {
            let _ = tx.send(work());
        })
        .map_err(|e| HentaiError::validation(format!("无法启动 Resource access 探测线程: {e}")))?;

    match rx.recv_timeout(deadline) {
        Ok(result) => result,
        Err(mpsc::RecvTimeoutError::Timeout) => Err(HentaiError::timed_out(format!(
            "Local Resource access 超时（{}s）",
            deadline.as_secs().max(1)
        ))),
        Err(mpsc::RecvTimeoutError::Disconnected) => Err(HentaiError::validation(
            "Local Resource access 探测线程异常退出",
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error::HentaiErrorCode;
    use std::thread;
    use std::time::Instant;

    #[test]
    fn run_with_deadline_returns_work_result() {
        let value = run_with_deadline(Duration::from_secs(1), || Ok(42)).expect("ok");
        assert_eq!(value, 42);
    }

    #[test]
    fn run_with_deadline_times_out_slow_work() {
        let started = Instant::now();
        let err = run_with_deadline(Duration::from_millis(40), || {
            thread::sleep(Duration::from_secs(2));
            Ok(())
        })
        .expect_err("timeout");
        assert_eq!(err.code, HentaiErrorCode::TimedOut);
        assert!(started.elapsed() < Duration::from_secs(1));
    }
}
