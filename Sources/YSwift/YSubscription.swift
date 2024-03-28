import Foundation
import Yniffi

/// Handler for an active subscription.
/// Once the subscription is deinitialized, it will automatically unsubscribe.
/// You can explicitly cancel the subscription by calling `cancel`.
public final class YSubscription {
    private var subscription: Yniffi.YSubscription?

    init(subscription: Yniffi.YSubscription) {
        self.subscription = subscription
    }

    public func cancel() {
        subscription = nil
    }

    deinit {
        cancel()
    }
}
