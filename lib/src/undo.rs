use std::sync::{Mutex, MutexGuard};
use yrs::UndoManager;
use crate::doc::YrsOrigin;

pub(crate) struct YrsUndoManager(Mutex<yrs::undo::UndoManager<()>>);

unsafe impl Send for YrsUndoManager {}
unsafe impl Sync for YrsUndoManager {}

impl From<yrs::undo::UndoManager<()>> for YrsUndoManager {
    fn from(value: yrs::undo::UndoManager<()>) -> Self {
        YrsUndoManager(Mutex::new(value))
    }
}

impl YrsUndoManager {

    #[inline]
    fn acquire_lock(&self) -> MutexGuard<UndoManager> {
        // unwrap should be safe, as the only occasion to cause error would be a panic
        // while holding a lock and all operations holding a lock here only do so for
        // a time needed to perform a non-panicing operation
        self.0.lock().unwrap()
    }

    pub(crate) fn add_origin(&self, origin: YrsOrigin) {
        let mut m = self.acquire_lock();
        m.include_origin(origin)
    }

    pub(crate) fn remove_origin(&self, origin: YrsOrigin) {
        let mut m = self.acquire_lock();
        m.exclude_origin(origin);
    }

    pub(crate) fn undo(&self) -> Result<bool, YrsUndoError> {
        let mut m = self.acquire_lock();
        m.undo().map_err(|_| YrsUndoError::PendingTransaction)
    }

    pub(crate) fn redo(&self) -> Result<bool, YrsUndoError> {
        let mut m = self.acquire_lock();
        m.redo().map_err(|_| YrsUndoError::PendingTransaction)
    }

    pub(crate) fn clear(&self) -> Result<(), YrsUndoError> {
        let mut m = self.acquire_lock();
        m.clear().map_err(|_| YrsUndoError::PendingTransaction)
    }

    pub(crate) fn wrap_changes(&self) {
        let mut m = self.acquire_lock();
        m.reset();
    }
}

#[derive(Debug, thiserror::Error)]
pub(crate) enum YrsUndoError {
    #[error("Operations failed - there's already an active transaction on a current document")]
    PendingTransaction
}