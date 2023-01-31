use lib0::any::Any;
use std::collections::HashMap;
use std::ops::{Deref, DerefMut};
use std::rc::Rc;
use yrs::types::Attrs;

pub(crate) struct YrsAttrs(pub(crate) Attrs);

impl From<Attrs> for YrsAttrs {
    fn from(value: Attrs) -> Self {
        YrsAttrs(value)
    }
}

impl From<HashMap<String, String>> for YrsAttrs {
    fn from(value: HashMap<String, String>) -> Self {
        let mut attrs = Attrs::new();

        value.iter().for_each(|pair| {
            let key = Rc::from(pair.0.as_str());
            let value = Any::from_json(pair.1.as_str()).unwrap();
            attrs.insert(key, value);
        });

        YrsAttrs(attrs)
    }
}

impl From<YrsAttrs> for HashMap<String, String> {
    fn from(attrs: YrsAttrs) -> Self {
        let mut hash_map_attrs = HashMap::new();

        attrs.0.into_iter().for_each(|(key, val)| {
            let mut buf = String::new();
            val.to_json(&mut buf);
            hash_map_attrs.insert(key.to_string(), buf);
        });

        hash_map_attrs
    }
}

impl Deref for YrsAttrs {
    type Target = Attrs;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl DerefMut for YrsAttrs {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}
