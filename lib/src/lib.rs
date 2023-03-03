mod array;
mod attrs;
mod change;
mod delta;
mod doc;
mod error;
mod map;
mod text;
mod transaction;

use crate::array::YrsArray;
use crate::array::YrsArrayEachDelegate;
use crate::array::YrsArrayObservationDelegate;
use crate::change::YrsChange;
use crate::delta::YrsDelta;
use crate::doc::YrsDoc;
use crate::error::CodingError;
use crate::map::YrsMap;
use crate::text::YrsText;
use crate::text::YrsTextObservationDelegate;
use crate::transaction::YrsTransaction;

// uniffi_macros::include_scaffolding!("yniffi");
uniffi::include_scaffolding!("yniffi");
