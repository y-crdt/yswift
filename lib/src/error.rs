#[derive(Debug, thiserror::Error)]
pub enum CodingError {
    #[error("EncodingError")]
    EncodingError,
    #[error("DecodingError")]
    DecodingError,
    /// The update decoded, and integrating it into the document failed —
    /// yrs's `UpdateError`, e.g. a block whose parent is not a shared type.
    #[error("ApplyError")]
    ApplyError,
}
