use crate::error::CodingError;
use crate::text::Text;
use std::cell::{RefCell, RefMut};
use std::sync::Arc;
use yrs::{updates::decoder::Decode, updates::encoder::Encode, ReadTxn, TransactionMut, Update};

pub(crate) struct Transaction(pub(crate) RefCell<Option<TransactionMut<'static>>>);

unsafe impl Send for Transaction {}
unsafe impl Sync for Transaction {}

impl Transaction {}

impl<'doc> From<TransactionMut<'doc>> for Transaction {
    fn from(txn: TransactionMut<'doc>) -> Self {
        let txn: TransactionMut<'static> = unsafe { std::mem::transmute(txn) };
        Transaction(RefCell::from(Some(txn)))
    }
}

impl Transaction {
    pub(crate) fn transaction(&self) -> RefMut<'_, Option<TransactionMut<'static>>> {
        self.0.borrow_mut()
    }

    pub(crate) fn transaction_state_vector(&self) -> Vec<u8> {
        self.transaction()
            .as_ref()
            .unwrap()
            .state_vector()
            .encode_v1()
    }

    pub(crate) fn transaction_apply_update(&self, update: Vec<u8>) -> Result<(), CodingError> {
        Update::decode_v1(update.as_slice())
            .map_err(|_e| CodingError::DecodingError)
            .map(|u| self.transaction().as_mut().unwrap().apply_update(u))
    }

    pub(crate) fn transaction_get_text(&self, name: String) -> Option<Arc<Text>> {
        self.transaction()
            .as_ref()
            .unwrap()
            .get_text(name.as_str())
            .map(Text::from)
            .map(Arc::from)
    }

    pub(crate) fn free(&self) {
        self.0.replace(None);
    }
}
