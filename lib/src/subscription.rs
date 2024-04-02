use yrs::Subscription;

pub(crate) struct YSubscription {
  #[allow(dead_code)]
  value: Subscription
}

impl YSubscription {
  pub(crate)fn new(value: Subscription) -> YSubscription {
      YSubscription {
        value
      }
  }
}