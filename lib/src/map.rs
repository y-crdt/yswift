use crate::error::CodingError;
use crate::mapchange::{YrsEntryChange, YrsMapChange};
use crate::subscription::YSubscription;
use crate::transaction::YrsTransaction;
use std::cell::RefCell;
use std::fmt::Debug;
use std::sync::Arc;
use yrs::branch::Branch;
use yrs::Observable;
use yrs::{types::Value, Any, Map, MapRef};
use crate::doc::YrsCollectionPtr;

pub(crate) struct YrsMap(RefCell<MapRef>);

// Marks that this type can be transferred across thread boundaries.
unsafe impl Send for YrsMap {}
// Marks that this type is safe to share references between threads.
unsafe impl Sync for YrsMap {}

impl AsRef<Branch> for YrsMap {
    fn as_ref(&self) -> &Branch {
        //FIXME: after yrs v0.18 use logical references
        let branch = &*self.0.borrow();
        unsafe { std::mem::transmute(branch.as_ref()) }
    }
}

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
// This allows the outside code (Swift, for example) to
// handle the deserialization from JSON string into whatever the appropriate
// type is within the swift language bindings. The `keys` iterator doesn't
// need this "translation", while `values` does.
//
// The type is boxed and used as a dynamic type:
// `Box<dyn YrsMapIteratorDelegate>`
// rather than having the keys, values, or iter functions expose an iterator
// back to the external language bindings.
pub(crate) trait YrsMapIteratorDelegate: Send + Sync + Debug {
    fn call(&self, value: String);
}

pub(crate) trait YrsMapKVIteratorDelegate: Send + Sync + Debug {
    fn call(&self, key: String, value: String);
}

pub(crate) trait YrsMapObservationDelegate: Send + Sync + Debug {
    fn call(&self, value: Vec<YrsMapChange>);
}

/*
IMPL order:
- [X] [insert, len, contains_key]
- [X] [get, remove, clear]
- [X] [keys, values, iter]
- [ ] [observe, unobserve]
 */

impl YrsMap {
    pub(crate) fn raw_ptr(&self) -> YrsCollectionPtr {
        let borrowed = self.0.borrow();
        YrsCollectionPtr::from(borrowed.as_ref())
    }

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

    pub(crate) fn keys(
        &self,
        transaction: &YrsTransaction,
        delegate: Box<dyn YrsMapIteratorDelegate>,
    ) {
        // The internal `keys` function in Rust returns an explicit iterator that you can
        // fiddle with.
        //
        // fn keys<'a, T: ReadTxn + 'a>(&'a self, txn: &'a T) -> Keys<'a, &'a T, T>
        //
        // For these language bindings we're instead holding onto the iterator
        // ourselves, and expecting a delegate type from the language binding side that
        // we call with each value as it is available.

        // get a mutable transaction
        let binding = transaction.transaction();
        let txn = binding.as_ref().unwrap();

        let map = self.0.borrow();
        map.keys(txn).for_each(|key_value| {
            delegate.call(key_value.to_string());
        });
    }

    pub(crate) fn values(
        &self,
        transaction: &YrsTransaction,
        delegate: Box<dyn YrsMapIteratorDelegate>,
    ) {
        // Like the `keys` iterator pattern, we're holding onto the Rust iterator
        // ourselves, and expecting a delegate type from the language binding side that
        // we call with each value as it is available.

        // get a mutable transaction
        let binding = transaction.transaction();
        let txn = binding.as_ref().unwrap();

        let map = self.0.borrow();
        let iterator = map.values(txn);
        iterator.for_each(|value_list| {
            // value is being returned as Vec<Value> from YrsMap - unclear
            // why, but maybe we iterate over each element and attempt to any.to_json on it?
            // 20mar2023 - checking w/ Bartosz on if I'm missing something about
            // the values iterator here.
            //
            // The upstream yrs value iterator goes into the Yrs internal type
            // `Item`, which can potentially contain a list of values within it.
            // In practice, it appears to contains a single value for this usage of it.
            value_list.iter().for_each(|val_in_list| {
                let mut buf = String::new();
                if let Value::Any(any) = val_in_list {
                    any.to_json(&mut buf);
                    delegate.call(buf);
                } else {
                    // @TODO: fix silly handling, it will just call with empty string if casting fails
                    delegate.call(buf);
                }
            });
        });
    }

    pub(crate) fn each(
        &self,
        transaction: &YrsTransaction,
        delegate: Box<dyn YrsMapKVIteratorDelegate>,
    ) {
        // Like the `keys` and `values` iterator pattern, we're holding onto the Rust iterator
        // ourselves, and expecting a delegate type from the language binding side that
        // we call with each value as it is available.

        // get a mutable transaction
        let binding = transaction.transaction();
        let txn = binding.as_ref().unwrap();

        let map = self.0.borrow();
        let iterator = map.iter(txn);
        iterator.for_each(|key_value_pair| {
            // key_value_pair is being returned as a tuple of (&str, Value)
            // we'll pass the key value (String) straight through to the delegate,
            // but do the extra work to convert Value to a JSON string for decoding
            // on the far side of the language binding - or at least try to.
            let mut buf = String::new();
            if let Value::Any(any) = key_value_pair.1 {
                any.to_json(&mut buf);
                delegate.call(key_value_pair.0.to_string(), buf);
            } else {
                // @TODO: fix silly handling, it will just call with empty string if casting fails
                delegate.call(key_value_pair.0.to_string(), buf);
            }
        });
    }

    pub(crate) fn observe(&self, delegate: Box<dyn YrsMapObservationDelegate>) -> Arc<YSubscription> {
        let subscription = self
            .0
            .borrow_mut()
            .observe(move |transaction, map_event| {
                let delta = map_event.keys(transaction);
                let result: Vec<YrsMapChange> = delta
                    .iter()
                    .map(|val| YrsMapChange {
                        key: val.0.to_string(),
                        change: YrsEntryChange::from(val.1),
                    })
                    .collect();
                delegate.call(result)
            });

            Arc::new(YSubscription::new(subscription))
    }
}

#[cfg(test)]
mod tests {
    use crate::YrsDoc;

    #[test]
    fn verify_new_map_has_zero_count() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let txn = doc.transact(None);
        assert_eq!(map.length(&txn), 0);
    }

    #[test]
    fn map_insert_and_count() {
        let doc = YrsDoc::new();
        let map = doc.get_map("example_map".to_string());

        let key_to_insert = "AB123".to_string();
        let value_to_insert = "\"Hello\"".to_string();

        let txn = doc.transact(None);

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

        let txn = doc.transact(None);

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

        let txn = doc.transact(None);

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

        let txn = doc.transact(None);

        map.insert(&txn, key_to_insert.clone(), value_to_insert.clone());
        assert_eq!(map.length(&txn), 1);

        map.clear(&txn);
        assert_eq!(map.length(&txn), 0);
    }

    /*
        ## The section below is Joe trying to sort out the pieces to make a unit test
        that "works" the code structure when you invoke "keys" - which involves multiple
        calls to a delegate object that you need to provide. I haven't been able to figure
        out how to structure the dyn Box<T> object and get it implementing the required
        trait on the Rust side of things: `crate::map::YrsMapIteratorDelegate`

        I'll work/test the pattern through the Swift language side of this binding setup,
        but I'd really like to understand how to get it working on the Rust side as well.
        For now, however, I'll just leave this at where I got to - and hope to come back to
        resolve it in the future with some more experience Rust brains alongside.

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
    //                     ^^^^^^^^ the trait `YrsMapIteratorDelegate` is not implemented for `KeyDelegate`
    //                     Compiler error when invoking `cargo test`
            assert_eq!(delegate.collected.len(), 2);
        }

     */
}
