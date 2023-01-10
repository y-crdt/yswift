use std::cell::RefCell;
use std::sync::Arc;
use yrs::{OffsetKind, Options, Transact};
use crate::text::Text;
use crate::transaction::Transaction;

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
