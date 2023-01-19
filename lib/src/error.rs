#[derive(Debug, thiserror::Error)]
pub enum CodingError {
    #[error("EncodingError")]
    EncodingError,
    #[error("DecodingError")]
    DecodingError,
}
