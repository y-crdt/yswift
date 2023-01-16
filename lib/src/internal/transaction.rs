use std::cell::{RefCell, RefMut};
use yrs::{TransactionMut};

pub(crate) struct Transaction(pub(crate) RefCell<Option<TransactionMut<'static>>>);

unsafe impl Send for Transaction {}
unsafe impl Sync for Transaction {}

impl Transaction {
  pub(crate) fn transaction(&self) -> RefMut<'_, Option<TransactionMut<'static>>> {
    self.0.borrow_mut()
  }

  pub(crate) fn free(&self) {
    self.0.replace(None);
  }
}

impl<'doc> From<TransactionMut<'doc>> for Transaction {
  fn from(txn: TransactionMut<'doc>) -> Self {
    let txn: TransactionMut<'static> = unsafe { std::mem::transmute(txn) };
    Transaction(RefCell::from(Some(txn)))
  }
}
