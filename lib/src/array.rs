use crate::error::CodingError;
use crate::transaction::Transaction;
use lib0::any::Any;
use std::cell::RefCell;
use yrs::{types::Value, Array as YrsArray, ArrayRef};

pub(crate) struct YArray(RefCell<ArrayRef>);

unsafe impl Send for YArray {}
unsafe impl Sync for YArray {}

impl From<ArrayRef> for YArray {
    fn from(value: ArrayRef) -> Self {
        YArray(RefCell::from(value))
    }
}

impl YArray {
    pub(crate) fn get(&self, transaction: &Transaction, index: u32) -> Result<String, CodingError> {
        let tx = transaction.transaction();
        let tx = tx.as_ref().unwrap();

        let arr = self.0.borrow();

        let v = arr.get(tx, index).unwrap();

        let mut buf = String::new();

        if let Value::Any(any) = v {
            any.to_json(&mut buf);
            Ok(buf)
        } else {
            Err(CodingError::EncodingError)
        }
    }

    pub(crate) fn insert(&self, transaction: &Transaction, index: u32, json: String) {
        let avalue = Any::from_json(json.as_str()).unwrap();

        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        let arr = self.0.borrow_mut();
        arr.insert(tx, index, avalue);
    }
}
