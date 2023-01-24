use crate::array::YArray;
use crate::error::CodingError;
use crate::text::Text;
use std::borrow::Borrow;
use std::cell::{RefCell, RefMut};
use std::sync::Arc;
use yrs::{
    updates::decoder::Decode, updates::encoder::Encode, ReadTxn, StateVector, TransactionMut,
    Update,
};

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

    pub(crate) fn transaction_encode_update(&self) -> Vec<u8> {
        self.transaction().as_ref().unwrap().encode_update_v1()
    }

    pub(crate) fn transaction_encode_state_as_update_from_sv(
        &self,
        state_vector: Vec<u8>,
    ) -> Result<Vec<u8>, CodingError> {
        let mut tx = self.transaction();
        let tx = tx.as_mut().unwrap();

        StateVector::decode_v1(state_vector.borrow())
            .map_err(|_e| CodingError::DecodingError)
            .map(|sv: StateVector| tx.encode_state_as_update_v1(&sv))
    }

    pub(crate) fn transaction_encode_state_as_update(&self) -> Vec<u8> {
        let mut tx = self.transaction();
        let tx = tx.as_mut().unwrap();
        tx.encode_state_as_update_v1(&StateVector::default())
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

    pub(crate) fn transaction_get_array(&self, name: String) -> Option<Arc<YArray>> {
        self.transaction()
            .as_ref()
            .unwrap()
            .get_array(name.as_str())
            .map(YArray::from)
            .map(Arc::from)
    }

    pub(crate) fn free(&self) {
        self.0.replace(None);
    }
}
