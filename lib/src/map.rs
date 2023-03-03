use crate::transaction::YrsTransaction;
use crate::{change::YrsChange, error::CodingError};
use lib0::any::Any;
use std::borrow::BorrowMut;
use std::cell::RefCell;
use std::fmt::Debug;
//use yrs::{types::Value, Array, ArrayRef, Observable};
use yrs::{types::Value, Map, MapRef};
use yrs::types::map::Keys;
use yrs::types::map::Values;

pub(crate) struct YrsMap(RefCell<MapRef>);

// Marks that this type can be transferred across thread boundaries.
unsafe impl Send for YrsMap {} 
// Marks that this type is safe to share references between threads.
unsafe impl Sync for YrsMap {} 

// Provides the implementation for the From trait, supporting
// converting from a MapRef type into a YrsMap type.
impl From<MapRef> for YrsMap {
    fn from(value: MapRef) -> Self {
        YrsMap(RefCell::from(value))
    }
}

/* 
Notes for Self:

- `ReadTxn` is a read-only transaction for reading out information from the data structure
  - (https://docs.rs/yrs/latest/yrs/trait.ReadTxn.html)
- `TransactionMut` is a Read/Write transaction, used for changing the underlying data structure
  - (https://docs.rs/yrs/latest/yrs/struct.TransactionMut.html)

- The Yrs::Map type appears to expect all the keys to be &str - a reference to a string,
  but in Swift, it can be any "hashable" type. Checked with Bartosz and that's expected - a 
  limitation when dealing with the other platforms and expecting primarily text based structures
  coming through. I suppose anything Codable in Swift could be a key, as "encoding" it would return
  a string of JSON, which we could then use as the key in the underling YrsMap, following the 
  pattern set up by YArray.

  Looking at YrsArray's insert:

      pub(crate) fn insert(&self, transaction: &YrsTransaction, index: u32, value: String) {
        let avalue = Any::from_json(value.as_str()).unwrap();

        let mut tx = transaction.transaction();
        ^^ this is getting the transaction that we need to use for the insert on YArray

        let tx = tx.as_mut().unwrap();
                    ^^ converts the underlying type inside the Option to mutable
                             ^^ unwraps the resulting Optional, panicing if it fails

        let arr = self.0.borrow_mut();
                      ^^  grabs the first element of the reference-to-Array that YrsArray wraps
                        ^^ and borrows it as a mutable element
        arr.insert(tx, index, avalue);
    }

    A number of the other methods take in a string type and convert it, with an implicit 
    assumption that the string being passed in is a JSON representation:

    let avalue = Any::from_json(value.as_str()).unwrap();
                                ^^ converts String into &str (a string slice)
                      ^^ uses the From trait to convert the attempt to create an Any enum
                         from the string, presuming it's JSON. This returns an Option - as it
                         might have failed to convert.
                                                ^^ unwraps the Option, of course it didn't fail!

    `Any` is from lib0, and is a Rust enumeration - sometimes in a tree form - that encodes
    JSON values down into a memory efficient binary blob.

 */

impl YrsMap {

  /// Inserts a key/value combination into YrsMap.
  pub(crate) fn insert(&self, transaction: &YrsTransaction, key: String, value: String) {
    // decodes the `value` as JSON and converts it into a lib0::Any enumeration
    let anyValue = Any::from_json(value.as_str()).unwrap();

    // acquire a transaction
    let mut tx = transaction.transaction();
    let tx = tx.as_mut().unwrap();

    // pull out a mutable reference to the YrsMap this type wraps
    let map = self.0.borrow_mut();
    // insert into the wrapped map.
    map.insert(tx, key, anyValue);

    // Documentation note from YrsMap about inserting a preliminary type - for future
    // reference...
    // // insert nested shared type
    // let nested = map.insert(&mut txn, "key2", MapPrelim::from([("inner", "value2")]));
    // nested.insert(&mut txn, "inner2", 100);
  }

  /// Returns the size of the map.
  pub(crate) fn length(&self, transaction: &YrsTransaction) -> u32 {
    let map = self.0.borrow();
    // acquire a transaction, but we don't need to borrow it since we're
    // not mutating anything in this method.
    let tx = transaction.transaction();
    let tx = tx.as_ref().unwrap();
    // If we try and do the above on a single line, I get the error:
    // creates a temporary value which is freed while still in use

    map.len(tx)
  }

  pub(crate) fn contains_key(&self, transaction: &YrsTransaction, key: String) -> bool {
    let map = self.0.borrow();
    // acquire a transaction, but we don't need to borrow it since we're
    // not mutating anything in this method.
    let tx = transaction.transaction();
    let tx = tx.as_ref().unwrap();

    map.contains_key(tx, key.as_str())
  }

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

    // IMPL order:
    // [insert, len, contains_key]
    // [get, remove, clear]
    // [keys, values, iter]

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