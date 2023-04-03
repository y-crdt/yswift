use lib0::any::Any;
use std::ops::{Deref, DerefMut};
use std::rc::Rc;
use yrs::types::Attrs;

pub(crate) struct YrsAttrs(pub(crate) Attrs);

impl From<Attrs> for YrsAttrs {
    fn from(value: Attrs) -> Self {
        YrsAttrs(value)
    }
}

impl From<String> for YrsAttrs {
    fn from(value: String) -> YrsAttrs {
        let any = Any::from_json(value.as_str()).unwrap();
        match any {
            Any::Map(m) => YrsAttrs(m.into_iter().map(|(k, v)| (Rc::from(&k[..]), v)).collect()),
            _ => YrsAttrs(Attrs::new()),
        }
    }
}

impl From<YrsAttrs> for String {
    fn from(value: YrsAttrs) -> String {
        let mut buf = String::new();
        let attrs_map = value
            .0
            .iter()
            .map(|(k, v)| (k.to_string(), v.clone()))
            .collect();
        let any_map = Any::Map(Box::new(attrs_map));
        any_map.to_json(&mut buf);
        buf
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
