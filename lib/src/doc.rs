use crate::array::YrsArray;
use crate::error::CodingError;
use crate::map::YrsMap;
use crate::text::YrsText;
use crate::transaction::YrsTransaction;
use std::sync::Arc;
use std::{borrow::Borrow, cell::RefCell};
use yrs::{updates::decoder::Decode, ArrayRef, Doc, OffsetKind, Options, StateVector, Transact, Origin};
use yrs::{MapRef, ReadTxn};
use yrs::branch::Branch;
use crate::undo::YrsUndoManager;
use crate::UniffiCustomTypeConverter;

pub(crate) struct YrsDoc(RefCell<Doc>);

unsafe impl Send for YrsDoc {}
unsafe impl Sync for YrsDoc {}

impl YrsDoc {
    pub(crate) fn new() -> Self {
        let mut options = Options::default();
        options.offset_kind = OffsetKind::Utf16;
        let doc = yrs::Doc::with_options(options);

        Self(RefCell::from(doc))
    }

    pub(crate) fn encode_diff_v1(
        &self,
        transaction: &YrsTransaction,
        state_vector: Vec<u8>,
    ) -> Result<Vec<u8>, CodingError> {
        let mut tx = transaction.transaction();
        let tx = tx.as_mut().unwrap();

        // An empty slice means "seen nothing": the diff from the empty state
        // vector is the whole document. The V1 decoder would reject it (a state
        // vector always carries a client count), so it is handled here.
        if state_vector.is_empty() {
            return Ok(tx.encode_diff_v1(&StateVector::default()));
        }
        StateVector::decode_v1(state_vector.borrow())
            .map_err(|_e| CodingError::DecodingError)
            .map(|sv| tx.encode_diff_v1(&sv))
    }

    pub(crate) fn get_text(&self, name: String) -> Arc<YrsText> {
        let text_ref = self.0.borrow().get_or_insert_text(name.as_str());
        Arc::from(YrsText::from(text_ref))
    }

    pub(crate) fn get_array(&self, name: String) -> Arc<YrsArray> {
        let array_ref: ArrayRef = self.0.borrow().get_or_insert_array(name.as_str()).into();
        Arc::from(YrsArray::from(array_ref))
    }

    pub(crate) fn get_map(&self, name: String) -> Arc<YrsMap> {
        let map_ref: MapRef = self.0.borrow().get_or_insert_map(name.as_str()).into();
        Arc::from(YrsMap::from(map_ref))
    }

    pub(crate) fn transact<'doc>(&self, origin: Option<YrsOrigin>) -> Arc<YrsTransaction> {
        let tx = self.0.borrow();
        let tx = if let Some(origin) = origin {
            tx.transact_mut_with(origin)
        } else {
            tx.transact_mut()
        };
        Arc::from(YrsTransaction::from(tx))
    }

    pub(crate) fn undo_manager(&self, tracked_refs: Vec<YrsCollectionPtr>) -> Arc<YrsUndoManager> {
        let doc = self.0.borrow().clone();
        let mut undo_manager = yrs::undo::UndoManager::new();
        for tracked in tracked_refs {
            undo_manager.expand_scope(&doc, &tracked);
        }
        Arc::new(YrsUndoManager::new(doc, undo_manager))
    }
}

#[derive(Clone)]
pub(crate) struct YrsOrigin(Arc<[u8]>);

impl From<Origin> for YrsOrigin {
    fn from(value: Origin) -> Self {
        YrsOrigin(Arc::from(value.as_ref()))
    }
}

impl Into<Origin> for YrsOrigin {
    fn into(self) -> Origin {
        Origin::from(self.0.as_ref())
    }
}

impl UniffiCustomTypeConverter for YrsOrigin {
    type Builtin = Vec<u8>;

    fn into_custom(val: Self::Builtin) -> uniffi::Result<Self> where Self: Sized {
        Ok(YrsOrigin(val.into()))
    }

    fn from_custom(obj: Self) -> Self::Builtin {
        obj.0.to_vec()
    }
}

#[derive(Copy, Clone)]
#[repr(transparent)]
pub(crate) struct YrsCollectionPtr(*const Branch);

unsafe impl Send for YrsCollectionPtr { }
unsafe impl Sync for YrsCollectionPtr { }

impl AsRef<Branch> for YrsCollectionPtr {
    #[inline]
    fn as_ref(&self) -> &Branch {
        unsafe { self.0.as_ref() }.unwrap()
    }
}

impl<'a> From<&'a Branch> for YrsCollectionPtr {
    #[inline]
    fn from(value: &'a Branch) -> Self {
        let ptr = value as *const Branch;
        YrsCollectionPtr(ptr)
    }
}

impl UniffiCustomTypeConverter for YrsCollectionPtr {
    type Builtin = u64;

    fn into_custom(val: Self::Builtin) -> uniffi::Result<Self> where Self: Sized {
        let ptr = val as usize as *const Branch;
        Ok(YrsCollectionPtr(ptr))
    }

    fn from_custom(obj: Self) -> Self::Builtin {
        obj.0 as usize as u64
    }
}
#[cfg(test)]
mod tests {
    use crate::error::CodingError;
    use crate::YrsDoc;
    use yrs::updates::decoder::Decode;
    use yrs::updates::encoder::Encode;
    use yrs::{ClientID, Doc, GetString, Options, ReadTxn, StateVector, Text, Transact, Update};

    /// A client id above 2^32 must land in a peer's state vector unchanged. yrs 0.18's
    /// V1 decoder read the id as a u32, which is how a 53-bit author became a
    /// different, truncated author on the receiving side and forked the document.
    #[test]
    fn a_53_bit_client_id_survives_the_v1_round_trip() {
        // The pycrdt-authored id from the incident this fork exists for; well above 2^32
        // and inside yrs's 53-bit range (ClientID::new masks above bit 53).
        let author: u64 = 967_714_667_641_833;
        assert!(author > u32::MAX as u64);
        assert!(author < (1u64 << 53));

        let mut options = Options::default();
        options.client_id = ClientID::new(author);
        let source = Doc::with_options(options);
        let text = source.get_or_insert_text("prompt");
        let update = {
            let mut txn = source.transact_mut();
            text.insert(&mut txn, 0, "hello");
            txn.encode_state_as_update_v1(&StateVector::default())
        };

        let peer = Doc::new();
        let peer_text = peer.get_or_insert_text("prompt");
        {
            let mut txn = peer.transact_mut();
            txn.apply_update(Update::decode_v1(&update).unwrap()).unwrap();
        }
        let txn = peer.transact();
        assert_eq!(peer_text.get_string(&txn), "hello");
        // Compare the raw ids the peer holds, not lookups through ClientID::new —
        // under `small-client` that constructor truncates the key too, and a lookup
        // would find the truncated block and pass for the wrong reason.
        let credited = |sv: &StateVector| -> Vec<(u64, u32)> {
            sv.iter().map(|(client, clock)| (client.get(), *clock)).collect()
        };
        let sv = txn.state_vector();
        assert_eq!(credited(&sv), vec![(author, 5)], "the block is credited to the 53-bit author");
        // Re-encoding must carry the same id back out.
        let decoded = StateVector::decode_v1(&sv.encode_v1()).unwrap();
        assert_eq!(credited(&decoded), vec![(author, 5)]);
    }

    fn varint(mut v: u64, out: &mut Vec<u8>) {
        loop {
            let byte = (v & 0x7f) as u8;
            v >>= 7;
            if v == 0 {
                out.push(byte);
                return;
            }
            out.push(byte | 0x80);
        }
    }

    /// A syntactically valid V1 update that cannot be integrated: its one item
    /// names another ITEM (the "h" of "hello") as its parent, and a parent has
    /// to be a shared type. yrs reports that as UpdateError::InvalidParent, which
    /// the binding surfaces as ApplyError — not DecodingError, the bytes were fine.
    #[test]
    fn an_update_that_decodes_but_cannot_integrate_is_an_apply_error() {
        let author: u64 = 967_714_667_641_833;
        let doc = YrsDoc::new();
        let seed = {
            let mut options = Options::default();
            options.client_id = ClientID::new(author);
            let source = Doc::with_options(options);
            let text = source.get_or_insert_text("prompt");
            let mut txn = source.transact_mut();
            text.insert(&mut txn, 0, "hello");
            txn.encode_state_as_update_v1(&StateVector::default())
        };
        let txn = doc.transact(None);
        txn.transaction_apply_update(seed).unwrap();

        let mut bad = Vec::new();
        varint(1, &mut bad); // one client
        varint(1, &mut bad); // one struct
        varint(author, &mut bad);
        varint(5, &mut bad); // clock after "hello"
        bad.push(4); // item info: no origins, no parent sub, content = string
        varint(0, &mut bad); // parent_info 0: parent is an ID, not a root name
        varint(author, &mut bad);
        varint(0, &mut bad); // (author, 0) is the "h" item
        varint(1, &mut bad);
        bad.push(b'x');
        varint(0, &mut bad); // empty delete set

        assert!(matches!(
            txn.transaction_apply_update(bad),
            Err(CodingError::ApplyError)
        ));
        assert!(matches!(
            txn.transaction_apply_update(vec![0xff, 0xff, 0xff]),
            Err(CodingError::DecodingError)
        ));
        txn.free();
    }

    #[test]
    fn an_empty_state_vector_diffs_the_whole_document() {
        let doc = YrsDoc::new();
        let text = doc.get_text("prompt".into());
        let txn = doc.transact(None);
        text.insert(&txn, 0, "hello".into());
        let whole = doc.encode_diff_v1(&txn, vec![]).unwrap();
        let from_zero = doc.encode_diff_v1(&txn, vec![0]).unwrap(); // encoded empty sv
        assert_eq!(whole, from_zero);
        txn.free();
    }
}
