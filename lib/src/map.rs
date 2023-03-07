use crate::transaction::YrsTransaction;
use crate::{change::YrsChange, error::CodingError};
use lib0::any::Any;
use std::cell::RefCell;
use std::fmt::Debug;
//use yrs::{types::Value, Array, ArrayRef, Observable};
use yrs::types::map::Keys;
use yrs::types::map::Values;
use yrs::{types::Value, Map, MapRef};

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
    /// Inserts the key and value you provide into the map.
    pub(crate) fn insert(&self, transaction: &YrsTransaction, key: String, value: String) {
        // decodes the `value` as JSON and converts it into a lib0::Any enumeration
        let any_value = Any::from_json(value.as_str()).unwrap();

        // acquire a *mutable* transaction
        let mut binding = transaction.transaction();
        let tx = binding.as_mut().unwrap();

        // pull out a mutable reference to the YrsMap this type wraps
        let map = self.0.borrow_mut();
        // insert into the wrapped map.
        map.insert(tx, key, any_value);

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
        let binding = transaction.transaction();
        let tx = binding.as_ref().unwrap();
        // If we try and do the above on a single line, I get the error:
        // creates a temporary value which is freed while still in use

        map.len(tx)
    }

    /// Returns a Boolean value that indicates whether the map contains the key you provide.
    pub(crate) fn contains_key(&self, transaction: &YrsTransaction, key: String) -> bool {
        let map = self.0.borrow();
        // acquire a transaction, but we don't need to borrow it since we're
        // not mutating anything in this method.
        let tx = transaction.transaction();
        let tx = tx.as_ref().unwrap();

        map.contains_key(tx, key.as_str())
    }

    pub(crate) fn get(
        &self,
        transaction: &YrsTransaction,
        key: String,
    ) -> Result<String, CodingError> {
        let binding = transaction.transaction();
        let tx = binding.as_ref().unwrap();
        let map = self.0.borrow();
        let v = map.get(tx, key.as_str()).unwrap();
        let mut buf = String::new();
        if let Value::Any(any) = v {
            any.to_json(&mut buf);
            Ok(buf)
        } else {
            Err(CodingError::EncodingError)
        }
    }


    // TODO(heckj): The signature is notably different from other map.remove. The others
    // tend to return Option<Value>, where here we're trying to helpfully indicate there
    // was a decoding error in the flight as well. Something I'd like to chat with Aidar
    // about...
    pub(crate) fn remove(
        &self,
        transaction: &YrsTransaction,
        key: String,
    ) -> Result<String, CodingError> {
        // acquire a *mutable* transaction
        let mut binding = transaction.transaction();
        let tx = binding.as_mut().unwrap();

        // get a mutable reference to the YrsMap this type wraps
        let map = self.0.borrow_mut();

        let optional_value = map.remove(tx, key.as_str());
        match optional_value {
            // there was some kind of value in the map, try to cast it and convert
            // to JSON
            Some(v) => {
                if let Value::Any(any) = v {
                    let mut buf = String::new();
                    any.to_json(&mut buf);
                    return Ok(buf);
                } else {
                    return Err(CodingError::EncodingError);
                }
            }
            // No value returned from the map on remove (key didn't exist there)
            // thinking it makes the most sense to return an empty string rather
            // than an Error type here.
            None => {
                let mut buf = String::new();
                return Ok(buf);
            }
        }
    }

    pub(crate) fn clear(&self, transaction: &YrsTransaction) {
        // acquire a *mutable* transaction
        let mut binding = transaction.transaction();
        let tx = binding.as_mut().unwrap();

        // get a mutable reference to the YrsMap this type wraps
        let map = self.0.borrow_mut();

        map.clear(tx);
    }
    // The equivalent Map methods from `yrs::types::map::Map`:
    // - fn keys<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Keys<'a, &'a T, T>
    // - fn values<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Values<'a, &'a T, T>
    // - fn iter<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> MapIter<'a, &'a T, T>
    // - fn remove(&self, txn: &mut TransactionMut<'_>, key: &str) -> Option<Value>
    // - fn get<T: ReadTxn>(&self, txn: &T, key: &str) -> Option<Value>
    // - fn clear(&self, txn: &mut TransactionMut<'_>)

    // IMPL order:
    // - [X] [insert, len, contains_key]
    // - [X] [get, remove, clear]
    // - [ ] [keys, values, iter]
    // - [ ] [observe, unobserve]

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

#[cfg(test)]
mod tests {
    use crate::YrsDoc;
    use lib0::any::{self, Any};

    #[test]
    fn verify_new_map_has_zero_count() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let txn = doc.transact();
        assert_eq!(map.length(&txn), 0);
    }

    #[test]
    fn map_insert_and_count() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let key_to_insert = "AB123".to_string();
        let value_to_insert = "\"Hello\"".to_string();

        let txn = doc.transact();

        assert_eq!(map.contains_key(&txn, key_to_insert.clone()), false);

        map.insert(&txn, key_to_insert.clone(), value_to_insert);
        assert_eq!(map.length(&txn), 1);

        assert_eq!(map.contains_key(&txn, key_to_insert), true);
    }

    #[test]
    fn map_insert_and_get() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let key_to_insert = "AB123".to_string();
        let value_to_insert = "\"Hello\"".to_string();

        let txn = doc.transact();

        assert_eq!(map.contains_key(&txn, key_to_insert.clone()), false);

        map.insert(&txn, key_to_insert.clone(), value_to_insert.clone());
        assert_eq!(map.length(&txn), 1);

        let result = map.get(&txn, key_to_insert.clone()).unwrap();
        assert_eq!(result, value_to_insert);
    }

    #[test]
    fn map_remove() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let key_to_insert = "AB123".to_string();
        let value_to_insert = "\"Hello\"".to_string();

        let txn = doc.transact();

        assert_eq!(map.contains_key(&txn, key_to_insert.clone()), false);

        map.insert(&txn, key_to_insert.clone(), value_to_insert.clone());

        let returned = map.remove(&txn, key_to_insert.clone());
        let unwrapped_return = returned.unwrap();
        assert_eq!(unwrapped_return, value_to_insert.clone());
        assert_eq!(map.length(&txn), 0);
    }

    #[test]
    fn map_clear() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let key_to_insert = "AB123".to_string();
        let value_to_insert = "\"Hello\"".to_string();

        let txn = doc.transact();

        map.insert(&txn, key_to_insert.clone(), value_to_insert.clone());
        assert_eq!(map.length(&txn), 1);

        map.clear(&txn);
        assert_eq!(map.length(&txn), 0);
    }
}
