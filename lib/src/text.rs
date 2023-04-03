use crate::attrs::YrsAttrs;
use crate::delta::YrsDelta;
use crate::transaction::YrsTransaction;
use lib0::any::Any;
use std::cell::RefCell;
use std::collections::HashMap;
use std::fmt::Debug;
use yrs::{GetString, Observable, Text, TextRef};

pub(crate) struct YrsText(RefCell<TextRef>);

unsafe impl Send for YrsText {}
unsafe impl Sync for YrsText {}

impl From<TextRef> for YrsText {
    fn from(value: TextRef) -> Self {
        YrsText(RefCell::from(value))
    }
}

pub(crate) trait YrsTextObservationDelegate: Send + Sync + Debug {
    fn call(&self, value: Vec<YrsDelta>);
}

impl YrsText {
    pub(crate) fn format(
        &self,
        transaction: &YrsTransaction,
        index: u32,
        length: u32,
        attrs: String,
    ) {
        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        let a = YrsAttrs::from(attrs);

        self.0.borrow_mut().format(tx, index, length, a.0)
    }

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

    pub(crate) fn insert_with_attributes(
        &self,
        transaction: &YrsTransaction,
        index: u32,
        chunk: String,
        attrs: String,
    ) {
        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        let a = YrsAttrs::from(attrs);

        self.0
            .borrow_mut()
            .insert_with_attributes(tx, index, chunk.as_str(), a.0)
    }

    pub(crate) fn insert_embed(&self, transaction: &YrsTransaction, index: u32, content: String) {
        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        let avalue = Any::from_json(content.as_str()).unwrap();

        self.0.borrow_mut().insert_embed(tx, index, avalue);
    }

    pub(crate) fn insert_embed_with_attributes(
        &self,
        transaction: &YrsTransaction,
        index: u32,
        content: String,
        attrs: String,
    ) {
        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        let avalue = Any::from_json(content.as_str()).unwrap();

        let a = YrsAttrs::from(attrs);

        self.0
            .borrow_mut()
            .insert_embed_with_attributes(tx, index, avalue, a.0);
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

    pub(crate) fn observe(&self, delegate: Box<dyn YrsTextObservationDelegate>) -> u32 {
        let subscription_id = self
            .0
            .borrow_mut()
            .observe(move |transaction, text_event| {
                let delta = text_event.delta(transaction);
                let result: Vec<YrsDelta> =
                    delta.iter().map(|change| YrsDelta::from(change)).collect();
                delegate.call(result)
            })
            .into();

        subscription_id
    }

    pub(crate) fn unobserve(&self, subscription_id: u32) {
        self.0.borrow_mut().unobserve(subscription_id);
    }
}
