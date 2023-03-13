use crate::transaction::YrsTransaction;
use crate::{change::YrsChange, error::CodingError};
use lib0::any::Any;
use std::cell::RefCell;
use std::fmt::Debug;
//use yrs::types::Observable;
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

// A representation of a callback that is invoked from the various
// map iterators, specifically to provide the JSON-string of the iterated 
// value from the map (for example, with `values` or `iter`).
//
// This specifically allows the outside code (Swift, for example) to
// handle the deserialization from JSON string into whatever the appropriate
// type is within the swift language bindings.
//
// The type is boxed and used as a dynamic type:
// `Box<dyn YrsMapIteratorDelegate>`
// rather than having the keys, values, or iter functions expose an iterator
// back to the external language bindings.
pub(crate) trait YrsMapIteratorDelegate: Send + Sync + Debug {
    fn call(&self, value: String);
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

  A number of the other methods take in a string type and convert it, with an implicit
  assumption that the string being passed in is a JSON representation:

  let avalue = Any::from_json(value.as_str()).unwrap();
                              ^^ converts String into &str (a string slice)
                    ^^ uses the From trait to convert the attempt to create an Any enum
                       from the string, presuming it's JSON. This returns an Option - as it
                       might have failed to convert.
                                              ^^ unwraps the Option, of course it didn't fail!

    `Any` is from lib0, and is a Rust enumeration - sometimes in a tree form - that encodes
    JSON values into a memory efficient binary data buffer.

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

    pub(crate) fn remove(
        &self,
        transaction: &YrsTransaction,
        key: String,
    ) -> Result<Option<String>, CodingError> {
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
                    return Ok(Some(buf));
                } else {
                    return Err(CodingError::EncodingError);
                }
            }
            // No value returned from the map on remove, so return the Optional
            // string as None.
            None => {
                return Ok(None);
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

    pub(crate) fn keys(&self, transaction: &YrsTransaction, delegate: Box<dyn YrsMapIteratorDelegate>) {
        // The internal `keys` function in Rust returns an explicit iterator that you can 
        // fiddle with. 
        //
        // fn keys<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Keys<'a, &'a T, T>
        //
        // For these language bindings we're instead holding onto the iterator
        // ourselves, and expecting a delegate type from the relevant language binding side that 
        // we call with each value as it's available.

        // get a mutable transaction
        let binding = transaction.transaction();
        let txn = binding.as_ref().unwrap();

        let map = self.0.borrow();
        map.keys(txn).for_each(|key_value| {
            delegate.call(key_value.to_string());
        });

        // arr.iter(tx).for_each(|val| {
        //     let mut buf = String::new();
        //     if let Value::Any(any) = val {
        //         any.to_json(&mut buf);
        //         delegate.call(buf);
        //     } else {
        //         // @TODO: fix silly handling, it will just call with empty string if casting fails
        //         delegate.call(buf);
        //     }
        // });

    }
    
    // IMPL order:
    // - [X] [insert, len, contains_key]
    // - [X] [get, remove, clear]
    // - [ ] [keys, values, iter]
    //   The equivalent Map methods from `yrs::types::map::Map`:
    //   - fn keys<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Keys<'a, &'a T, T>
    //   - fn values<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Values<'a, &'a T, T>
    //   - fn iter<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> MapIter<'a, &'a T, T>
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
        assert_eq!(unwrapped_return, Some(value_to_insert.clone()));
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

    #[derive(Debug)]
    struct KeyDelegate {
        collected: Vec<String>
    }
    // Marks that this type can be transferred across thread boundaries.
    //unsafe impl Send for RefCell<KeyDelegate> {}
    // Marks that this type is safe to share references between threads.
    unsafe impl Sync for KeyDelegate {}

    impl KeyDelegate {

        fn append(&mut self, value: String) {
            &self.collected.push(value);
        }

        fn new() -> KeyDelegate {
            let newDelegate = KeyDelegate {
                collected: Vec::<String>::new()
            };
            return newDelegate
        }

        // fn test(&self) -> Box<dyn crate::map::YrsMapIteratorDelegate> {
        //     return Box::new(self)
        // }
    }

    impl crate::map::YrsMapIteratorDelegate for Box<KeyDelegate> {
        fn call(&self, key_value: String) {
            self.append(key_value)
        }
    }

    // impl crate::map::YrsMapIteratorDelegate for KeyDelegate {
    //     fn call(&self, key_value: String) {
            
    //     }
    // }

    #[test]
    fn map_keys() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let first_key_to_insert = "AB123".to_string();
        let second_key_to_insert = "890YZ".to_string();
        let value_to_insert = "\"Hello\"".to_string();

        let txn = doc.transact();

        map.insert(&txn, first_key_to_insert.clone(), value_to_insert.clone());
        map.insert(&txn, second_key_to_insert.clone(), value_to_insert.clone());
        assert_eq!(map.length(&txn), 2);

        let delegate = Box::new(KeyDelegate::new());
        map.keys(&txn, delegate);
        assert_eq!(delegate.collected.len(), 2);
    }

}
