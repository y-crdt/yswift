use std::sync::{Arc, Mutex};
use yrs::Subscription;

/// The delegate a yrs callback forwards to, behind a slot the subscription can
/// empty. Cloned out of the lock before each call so a delegate that cancels
/// its own subscription from inside the callback does not deadlock.
pub(crate) type DelegateSlot<D> = Arc<Mutex<Option<Arc<D>>>>;

pub(crate) fn delegate_slot<D: ?Sized>(delegate: Box<D>) -> DelegateSlot<D> {
    Arc::new(Mutex::new(Some(Arc::from(delegate))))
}

pub(crate) fn delegate_of<D: ?Sized>(slot: &DelegateSlot<D>) -> Option<Arc<D>> {
    slot.lock().unwrap().clone()
}

/// Ends an observation when dropped.
///
/// Since yrs 0.27 dropping a [Subscription] only *queues* the callback's
/// removal — the observer applies it on its next trigger, through a weak
/// handle that is safe even if the document is already gone — so the closure
/// itself would live until the next event on that type. What a caller
/// actually needs released at once is the delegate it handed in, so the
/// subscription empties that delegate's slot on drop and lets yrs retire the
/// (now inert) callback at its own pace.
pub(crate) struct YSubscription {
    _inner: Subscription,
    release: Mutex<Option<Box<dyn FnOnce() + Send>>>,
}

impl YSubscription {
    pub(crate) fn new(inner: Subscription) -> YSubscription {
        YSubscription {
            _inner: inner,
            release: Mutex::new(None),
        }
    }

    pub(crate) fn with_delegate<D: ?Sized + Send + Sync + 'static>(
        inner: Subscription,
        slot: DelegateSlot<D>,
    ) -> YSubscription {
        YSubscription {
            _inner: inner,
            release: Mutex::new(Some(Box::new(move || {
                slot.lock().unwrap().take();
            }))),
        }
    }
}

impl Drop for YSubscription {
    fn drop(&mut self) {
        if let Some(release) = self.release.get_mut().map(Option::take).unwrap_or(None) {
            release();
        }
    }
}
