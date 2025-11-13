# TODO: Modify Track Booking Screen for Feedback Handling

## Steps to Complete

- [x] Update booking partitioning logic in StreamBuilder to keep "Service Complete" bookings in Active tab until feedback is submitted.
- [x] Modify ProgressTracker class to accept an onFeedbackPressed callback parameter.
- [x] Update ProgressTracker instantiation in _buildBookingCard to pass the feedback dialog callback.
- [ ] Test the changes to ensure bookings move to Completed tab after feedback submission.
