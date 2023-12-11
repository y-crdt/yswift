use crate::attrs::YrsAttrs;
use yrs::types::{Delta, Value};

pub enum YrsDelta {
    Inserted { value: String, attrs: String },
    Deleted { index: u32 },
    Retained { index: u32, attrs: String },
}

// Watch out for XML types here, because underlying
// value from Delta::Inserted event could be XMLText instances as well
// and things might break due to that

impl From<&Delta> for YrsDelta {
    fn from(item: &Delta) -> Self {
        match item {
            Delta::Inserted(value, attrs) => {
                let mut buf = String::new();
                if let Value::Any(any) = value {
                    any.to_json(&mut buf);
                    let attrs = YrsAttrs::from(*attrs.clone().unwrap_or_default());
                    YrsDelta::Inserted {
                        value: (buf),
                        attrs: (attrs.into()),
                    }
                } else {
                    // @TODO: fix silly handling, it will just call with empty string if casting fails
                    YrsDelta::Inserted {
                        value: ("".into()),
                        attrs: ("".into()),
                    }
                }
            }
            Delta::Retain(index, attrs) => {
                let attrs = YrsAttrs::from(*attrs.clone().unwrap_or_default());
                YrsDelta::Retained {
                    index: (*index),
                    attrs: (attrs.into()),
                }
            }
            Delta::Deleted(index) => YrsDelta::Deleted { index: (*index) },
        }
    }
}
