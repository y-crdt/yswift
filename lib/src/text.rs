use crate::transaction::Transaction;
use std::cell::RefCell;
use yrs::{GetString, Text as YrsText, TextRef};

pub(crate) struct Text(RefCell<TextRef>);

impl Text {
    pub(crate) fn append(&self, tx: &Transaction, text: String) {
        let mut tx = tx.transaction();
        let tx = tx.as_mut().unwrap();

        self.0.borrow_mut().push(tx, text.as_str());
    }

    pub(crate) fn get_string(&self, tx: &Transaction) -> String {
        let mut tx = tx.transaction();
        let tx = tx.as_mut().unwrap();

        self.0.borrow().get_string(tx)
    }

    pub(crate) fn insert(&self, tx: &Transaction, index: u32, chunk: String) {
        let mut tx = tx.transaction();
        let tx = tx.as_mut().unwrap();

        self.0.borrow_mut().insert(tx, index, chunk.as_str())
    }
}

unsafe impl Send for Text {}
unsafe impl Sync for Text {}

impl From<TextRef> for Text {
    fn from(value: TextRef) -> Self {
        Text(RefCell::from(value))
    }
}
