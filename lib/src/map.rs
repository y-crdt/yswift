use crate::transaction::YrsTransaction;
use crate::{change::YrsChange, error::CodingError};
use lib0::any::Any;
use std::cell::RefCell;
use std::fmt::Debug;
//use yrs::{types::Value, Array, ArrayRef, Observable};
use yrs::{types::Value, Map, MapRef, Keys, Values};

pub(crate) struct YrsMap(RefCell<MapRef>);

unsafe impl Send for YrsMap {}
unsafe impl Sync for YrsMap {}

// Provides the implementation for the From trait, supporting
// converting from a MapRef type into a YrsMap type.
impl From<MapRef> for YrsMap {
    fn from(value: MapRef) -> Self {
        YrsMap(RefCell::from(value))
    }
}

/* 
IMPL / Rust learning questions:

- what are Sync, Send, and Debug - traits, but what's their intention?
- What's a RefCell and how does it work/how is it expected to be used?

- `From` is a trait for converting between types, copied whole-hog from YrsArray

- `ReadTxn` is a read-only transaction for reading out information from the data structure
  - (https://docs.rs/yrs/latest/yrs/trait.ReadTxn.html)
- `TransactionMut` is a Read/Write transaction, used for changing the underlying data structure
  - (https://docs.rs/yrs/latest/yrs/struct.TransactionMut.html)

- The Yrs::Map type appears to expect all the keys to be &str - a reference to a string,
  but in Swift, it can be any "hashable" type. I'll have to figure out how to handle
  that impedance mismatch for full conformance, but at the moment constraining it to Strings
  is probably the easiest path to get started.

  Looking at YrsArray's insert:

      pub(crate) fn insert(&self, transaction: &YrsTransaction, index: u32, value: String) {
        let avalue = Any::from_json(value.as_str()).unwrap();

        let mut tx = transaction.transaction();
        ^^ this is getting the transaction that we need to use for the insert on YArray

        let tx = tx.as_mut().unwrap();
        ^^ kinda unclear on what's being unwrapped here

        let arr = self.0.borrow_mut();
        ^^ totally confused as to what this represents, and how we end up with a
        RefMut<ArrayRef> type here

        arr.insert(tx, index, avalue);
        ^^ this part I get well enough ;-)
    }

 */


impl YrsMap {
    // Array implemented a number of code array-ish methods:
    // these match up with the definitions within the trait
    // defining an `Array` type within Yrs (`yrs::types::array::Array`)
    // (https://docs.rs/yrs/latest/yrs/types/map/trait.Map.html)
    // - each (wraps `iter`)
    // - get
    // - insert
    // - insert_range
    // - length (len)
    // - push_back
    // - push_front
    // - remove
    // - remove_range

    // There's a few trait pieces that aren't replicated (yet?)
    // move_to, move_range_to

    // And then there's methods that support observation of changes:
    // observe
    // unobserve

    // Probably obvious, but I'm not sure what `to_a` is about. It
    // roughly looks like a means to convert YrsArray into a string,
    // assuming the guts of YrsArray match up with something convertible
    // to a String type.

    // The equivalent Map methods from `yrs::types::map::Map`:
    // - fn len<T: ReadTxn>(&self, txn: &T) -> u32
    // - fn keys<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Keys<'a, &'a T, T>
    // - fn values<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Values<'a, &'a T, T>
    // - fn iter<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> MapIter<'a, &'a T, T>
    // - fn insert<K, V>(&self, txn: &mut TransactionMut<'_>, key: K, value: V) -> V::Return where K: Into<Rc<str>>, V: Prelim,
    // - fn remove(&self, txn: &mut TransactionMut<'_>, key: &str) -> Option<Value>
    // - fn get<T: ReadTxn>(&self, txn: &T, key: &str) -> Option<Value>
    // - fn contains_key<T: ReadTxn>(&self, txn: &T, key: &str) -> bool
    // - fn clear(&self, txn: &mut TransactionMut<'_>)

    // The Swift `Dictionary` methods we'll want to support:
    // - var isEmpty: Bool
    // - var count: Int
    // - var capacity: Int
    // - fn subscript(Key) -> Value?
    // - fn subscript(Key, default _: () -> Value) -> Value
    // - var keys
    // - var values

    // - updateValue(Value, forKey: Key) -> Value?
    // - removeValue(forKey: Key) -> Value?
    // - removeAll(keepingCapacity: Bool)

    // And at least Sequence (https://developer.apple.com/documentation/swift/sequence/)
    // and Collection (https://developer.apple.com/documentation/swift/collection/)
    // protocol conformances:
    // - makeIterator()
    // - next()
    // - index types and getting data in and out via those Indicies

}