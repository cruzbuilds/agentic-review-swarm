# orders

Order lifecycle:

```
CART -> PLACED -> PAID -> SHIPPED -> DELIVERED
                   |
                   v
               CANCELLED (refund issued if a charge was captured)
```

An order is charged exactly once. `payment_id` is set when the charge is captured and is the
record of that charge. Coupons can be applied any time before shipping.
