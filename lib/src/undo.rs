use std::fmt::Debug;
use std::sync::{Arc, Mutex, MutexGuard};
use yrs::undo::EventKind;
use crate::doc::{YrsCollectionPtr, YrsOrigin};
use crate::subscription::YSubscription;

pub(crate) struct YrsUndoManager(Mutex<yrs::undo::UndoManager<u64>>);

unsafe impl Send for YrsUndoManager {}
unsafe impl Sync for YrsUndoManager {}

impl From<yrs::undo::UndoManager<u64>> for YrsUndoManager {
    fn from(value: yrs::undo::UndoManager<u64>) -> Self {
        YrsUndoManager(Mutex::new(value))
    }
}

impl YrsUndoManager {

    #[inline]
    fn acquire_lock(&self) -> MutexGuard<yrs::undo::UndoManager<u64>> {
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

    pub(crate) fn add_scope(&self, tracked_ref: YrsCollectionPtr) {
        let mut m = self.acquire_lock();
        m.expand_scope(&tracked_ref);
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

    pub(crate) fn observe_added(&self, delegate: Box<dyn YrsUndoManagerObservationDelegate>) -> Arc<YSubscription> {
        let m = self.acquire_lock();
        let subscription = m.observe_item_added(move |_, e| {
            *e.meta_mut() = delegate.call(YrsUndoEvent::new(e), *e.meta_mut());
        });
        Arc::new(YSubscription::new(subscription))
    }

    pub(crate) fn observe_updated(&self, delegate: Box<dyn YrsUndoManagerObservationDelegate>) -> Arc<YSubscription> {
        let m = self.acquire_lock();
        let subscription = m.observe_item_updated(move |_, e| {
            *e.meta_mut() = delegate.call(YrsUndoEvent::new(e), *e.meta_mut());
        });
        Arc::new(YSubscription::new(subscription))
    }

    pub(crate) fn observe_popped(&self, delegate: Box<dyn YrsUndoManagerObservationDelegate>) -> Arc<YSubscription> {
        let m = self.acquire_lock();
        let subscription = m.observe_item_popped(move |_, e| {
            *e.meta_mut() = delegate.call(YrsUndoEvent::new(e), *e.meta_mut());
        });
        Arc::new(YSubscription::new(subscription))
    }
}

#[derive(Debug, thiserror::Error)]
pub(crate) enum YrsUndoError {
    #[error("Operations failed - there's already an active transaction on a current document")]
    PendingTransaction
}

pub(crate) trait YrsUndoManagerObservationDelegate: Send + Sync + Debug {
    fn call(&self, e: Arc<YrsUndoEvent>, ptr: u64) -> u64;
}

pub(crate) struct YrsUndoEvent {
    inner: &'static mut yrs::undo::Event<u64>,
}

unsafe impl Send for YrsUndoEvent {}
unsafe impl Sync for YrsUndoEvent {}

impl YrsUndoEvent {
    fn new(inner: &mut yrs::undo::Event<u64>) -> Arc<Self> {
        let inner = unsafe { std::mem::transmute(inner) };
        Arc::new(YrsUndoEvent {
            inner
        })
    }

    pub(crate) fn origin(&self) -> Option<YrsOrigin> {
        self.inner.origin().cloned().map(YrsOrigin::from)
    }
    pub(crate) fn kind(&self) -> YrsUndoEventKind {
        match self.inner.kind() {
            EventKind::Undo => YrsUndoEventKind::Undo,
            EventKind::Redo => YrsUndoEventKind::Redo,
        }
    }
    pub(crate) fn has_changed(&self, shared_ref: YrsCollectionPtr) -> bool {
        self.inner.has_changed(&shared_ref)
    }
}

#[repr(u8)]
pub(crate) enum YrsUndoEventKind {
    Undo,
    Redo
}