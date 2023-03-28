use yrs::types::{EntryChange, Value};

pub struct YrsMapChange {
    pub key: String,
    pub change: YrsEntryChange,
}

pub enum YrsEntryChange {
    Inserted {
        value: String,
    },
    Updated {
        old_value: String,
        new_value: String,
    },
    Removed {
        value: String,
    },
}

impl From<&EntryChange> for YrsEntryChange {
    fn from(item: &EntryChange) -> Self {
        match item {
            EntryChange::Inserted(value) => {
                if let Value::Any(val) = value {
                    let mut buf = String::new();
                    val.to_json(&mut buf);
                    YrsEntryChange::Inserted { value: buf }
                } else {
                    // @TODO: fix silly handling, it will just call with empty string if casting fails
                    YrsEntryChange::Inserted { value: "".into() }
                }
            }
            EntryChange::Updated(old_value, new_value) => {
                if let (Value::Any(old), Value::Any(new)) = (old_value, new_value) {
                    let mut old_string = String::new();
                    let mut new_string = String::new();
                    old.to_json(&mut old_string);
                    new.to_json(&mut new_string);
                    YrsEntryChange::Updated {
                        old_value: old_string,
                        new_value: new_string,
                    }
                } else {
                    // @TODO: fix silly handling, it will just call with empty string if casting fails
                    YrsEntryChange::Updated {
                        old_value: "".into(),
                        new_value: "".into(),
                    }
                }
            }
            EntryChange::Removed(value) => {
                if let Value::Any(val) = value {
                    let mut buf = String::new();
                    val.to_json(&mut buf);
                    YrsEntryChange::Removed { value: buf }
                } else {
                    // @TODO: fix silly handling, it will just call with empty string if casting fails
                    YrsEntryChange::Removed { value: "".into() }
                }
            }
        }
    }
}
