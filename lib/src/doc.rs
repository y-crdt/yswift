use crate::error::CodingError;
use crate::text::Text;
use crate::transaction::Transaction;
use std::sync::Arc;
use std::{borrow::Borrow, cell::RefCell};
use yrs::ReadTxn;
use yrs::{updates::decoder::Decode, OffsetKind, Options, StateVector, Transact};

pub(crate) struct Doc(RefCell<yrs::Doc>);

unsafe impl Send for Doc {}
unsafe impl Sync for Doc {}

impl Doc {
    pub(crate) fn new() -> Self {
        let mut options = Options::default();
        options.offset_kind = OffsetKind::Utf32;
        let doc = yrs::Doc::with_options(options);

        Self(RefCell::from(doc))
    }

    pub(crate) fn encode_diff_v1(
        &self,
        transaction: &Transaction,
        state_vector: Vec<u8>,
    ) -> Result<Vec<u8>, CodingError> {
        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        StateVector::decode_v1(state_vector.borrow())
            .map_err(|_e| CodingError::DecodingError)
            .map(|sv| tx.encode_diff_v1(&sv))
    }

    pub(crate) fn get_text(&self, name: String) -> Arc<Text> {
        let text_ref = self.0.borrow().get_or_insert_text(name.as_str());
        Arc::from(Text::from(text_ref))
    }

    pub(crate) fn transact<'doc>(&self) -> Arc<Transaction> {
        let tx = self.0.borrow();
        let tx = tx.transact_mut();
        Arc::from(Transaction::from(tx))
    }
}
