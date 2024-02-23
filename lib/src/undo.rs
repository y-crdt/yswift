use std::sync::Mutex;
use crate::doc::YrsOrigin;

pub struct YrsUndoManager(Mutex<yrs::undo::UndoManager<()>>);

unsafe impl Send for YrsUndoManager {}
unsafe impl Sync for YrsUndoManager {}

impl YrsUndoManager {
    pub(crate) fn add_origin(&self, origin: YrsOrigin) {
        todo!()
    }

    pub(crate) fn remove_origin(&self, origin: YrsOrigin) {
        todo!()
    }

    pub(crate) fn undo(&self) -> bool {
        todo!()
    }

    pub(crate) fn redo(&self) -> bool {
        todo!()
    }

    pub(crate) fn clear(&self) {
        todo!()
    }

    pub(crate) fn wrap_changes(&self) {
        todo!()
    }
}