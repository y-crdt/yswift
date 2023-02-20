use yrs::types::{Change, Value};

pub enum YrsChange {
    Added { elements: Vec<String> },
    Removed { range: u32 },
    Retained { range: u32 },
}

// Watch out for XML types here, because underlying
// elements from Change::added event could XMLElement instances as well
// and things might break due to that

impl From<&Change> for YrsChange {
    fn from(item: &Change) -> Self {
        match item {
            Change::Added(added) => {
                let mut res = Vec::new();
                added.iter().for_each(|v| {
                    let mut buf = String::new();
                    if let Value::Any(any) = v {
                        any.to_json(&mut buf);
                        res.push(buf);
                    }
                });
                YrsChange::Added { elements: res }
            }
            Change::Removed(range) => YrsChange::Removed { range: *range },
            Change::Retain(range) => YrsChange::Retained { range: *range },
        }
    }
}
