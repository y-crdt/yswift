mod array;
mod attrs;
mod change;
mod delta;
mod doc;
mod error;
mod map;
mod mapchange;
mod text;
mod transaction;
mod undo;

pub trait YrsSharedRef: Send + Sync { }

use crate::doc::YrsOrigin;
use crate::array::YrsArray;
use crate::array::YrsArrayEachDelegate;
use crate::array::YrsArrayObservationDelegate;
use crate::change::YrsChange;
use crate::delta::YrsDelta;
use crate::doc::YrsDoc;
use crate::error::CodingError;
use crate::map::YrsMap;
use crate::map::YrsMapIteratorDelegate;
use crate::map::YrsMapKVIteratorDelegate;
use crate::map::YrsMapObservationDelegate;
use crate::mapchange::YrsEntryChange;
use crate::mapchange::YrsMapChange;
use crate::text::YrsText;
use crate::text::YrsTextObservationDelegate;
use crate::transaction::YrsTransaction;
use crate::undo::YrsUndoManager;

uniffi::include_scaffolding!("yniffi");
