use crate::transaction::YrsTransaction;
use std::cell::RefCell;
use yrs::{GetString, Text as YText, TextRef};

pub(crate) struct YrsText(RefCell<TextRef>);

unsafe impl Send for YrsText {}
unsafe impl Sync for YrsText {}

impl From<TextRef> for YrsText {
    fn from(value: TextRef) -> Self {
        YrsText(RefCell::from(value))
    }
}

impl YrsText {
    pub(crate) fn append(&self, tx: &YrsTransaction, text: String) {
        let mut tx = tx.transaction();
        let tx = tx.as_mut().unwrap();

        self.0.borrow_mut().push(tx, text.as_str());
    }

    pub(crate) fn insert(&self, tx: &YrsTransaction, index: u32, chunk: String) {
        let mut tx = tx.transaction();
        let tx = tx.as_mut().unwrap();

        self.0.borrow_mut().insert(tx, index, chunk.as_str())
    }

    pub(crate) fn get_string(&self, tx: &YrsTransaction) -> String {
        let mut tx = tx.transaction();
        let tx = tx.as_mut().unwrap();

        self.0.borrow().get_string(tx)
    }

    pub(crate) fn remove_range(&self, transaction: &YrsTransaction, start: u32, length: u32) {
        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        self.0.borrow_mut().remove_range(tx, start, length)
    }

    pub(crate) fn length(&self, transaction: &YrsTransaction) -> u32 {
        let tx = transaction.transaction();
        let tx = tx.as_ref().unwrap();

        self.0.borrow().len(tx)
    }
}
