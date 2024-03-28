use yrs::Subscription;

pub(crate) struct YSubscription {
  #[allow(dead_code)]
  value: Subscription
}

impl YSubscription {
  pub(crate)fn new(value: Subscription) -> YSubscription {
      // println!("YSubscription is being initialized");

      YSubscription {
        value
      }
  }
}

// impl Drop for YSubscription {
//   fn drop(&mut self) {
//       println!("YSubscription is being deinitialized");
//   }
// }