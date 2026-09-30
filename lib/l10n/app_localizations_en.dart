// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose the language for this device';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSubtitle => 'Choose how the app looks on this device';

  @override
  String get light => 'Light';

  @override
  String get auto => 'Auto';

  @override
  String get dark => 'Dark';

  @override
  String get chats => 'Chats';

  @override
  String get chatsSubtitle => 'View conversations from all your bookings';

  @override
  String get notifications => 'Notifications';

  @override
  String get clientNotificationsSubtitle =>
      'Review booking updates and invoice alerts';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Update the password for this account';

  @override
  String get manageAccount => 'Manage account';

  @override
  String get manageAccountSubtitle =>
      'Update your name, email, phone, and photo';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get savedAddressesSubtitle => 'Manage pickup and drop locations';

  @override
  String get monthlyVehicleHiring => 'Monthly Vehicle Hiring';

  @override
  String get monthlyVehicleHiringSubtitle => 'Hire a truck on a monthly basis';

  @override
  String get finance => 'Finance';

  @override
  String get financeSubtitle => 'Invoices, settlements, and earnings insights.';

  @override
  String get invoices => 'Invoices';

  @override
  String get invoicesSubtitle => 'Review bookings and invoice actions';

  @override
  String get settlements => 'Settlements';

  @override
  String get settlementsSubtitle => 'View payouts and settlement status';

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsSubtitle => 'Track this month vs last month';

  @override
  String get brokerNotificationsSectionSubtitle =>
      'Open your notification inbox.';

  @override
  String get brokerNotificationsSubtitle => 'Open your notification inbox';

  @override
  String get back => 'Back';

  @override
  String get account => 'Account';

  @override
  String get manageAccountTitleCase => 'Manage Account';

  @override
  String get driverManageAccountSubtitle =>
      'Profile details, security, and preferences';

  @override
  String get kycRegistration => 'KYC Registration';

  @override
  String get checkingVerificationStatus => 'Checking verification status';

  @override
  String get verified => 'Verified';

  @override
  String get completeDriverVerification => 'Complete your driver verification';

  @override
  String get earnings => 'Earnings';

  @override
  String get driverEarningsSubtitle =>
      'Trip payouts and completed delivery earnings';

  @override
  String get communication => 'Communication';

  @override
  String get openingChat => 'Opening chat...';

  @override
  String get messageMyBroker => 'Message My Broker';

  @override
  String get messageMyBrokerSubtitle => 'Open your direct broker conversation';

  @override
  String get allChats => 'All Chats';

  @override
  String get allChatsSubtitle => 'View every driver conversation';

  @override
  String get security => 'Security';

  @override
  String get changePasswordTitleCase => 'Change Password';

  @override
  String get driverChangePasswordSubtitle => 'Update your sign-in credentials';

  @override
  String get logout => 'Logout';

  @override
  String get logoutSubtitle => 'Sign out from this device';

  @override
  String get driverAccount => 'Driver account';

  @override
  String get noAccountConnected => 'No account connected';

  @override
  String get kycPending => 'KYC Pending';

  @override
  String get driver => 'Driver';

  @override
  String get enterEmailAndPassword => 'Enter both email and password.';

  @override
  String get googleNoIdToken => 'Google did not return an ID token.';

  @override
  String get googleSignInCancelled => 'Google sign-in was cancelled.';

  @override
  String get googleSignInFailed => 'Google sign-in failed.';

  @override
  String get couldNotOpenRegistration => 'Could not open registration link.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get login => 'Login';

  @override
  String get appleSignInComingSoon => 'Apple sign-in is coming soon.';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create account';

  @override
  String get registerAsBrokerDriver => 'Register as Broker/Driver';

  @override
  String get newEnquiry => 'New Enquiry';

  @override
  String get signInToManageEnquiries => 'Sign in to manage enquiries';

  @override
  String get signInToManageEnquiriesSubtitle =>
      'We need an active client session before we can load monthly hiring requests.';

  @override
  String get retry => 'Retry';

  @override
  String get couldNotLoadEnquiries => 'Could not load enquiries';

  @override
  String get couldNotLoadEnquiriesSubtitle =>
      'Pull to refresh or try again in a moment.';

  @override
  String get noEnquiriesYet => 'No enquiries yet';

  @override
  String get noEnquiriesYetSubtitle =>
      'Tell us where and for how long you need a truck, and our team will follow up.';

  @override
  String get noEnquiriesMatchSearch => 'No enquiries match your search';

  @override
  String get noEnquiriesMatchSearchSubtitle =>
      'Try another location, truck type, or status.';

  @override
  String get searchMonthlyEnquiries => 'Search monthly enquiries...';

  @override
  String get monthlyTruckHiring => 'Monthly Truck Hiring';

  @override
  String get contacted => 'Contacted';

  @override
  String get closed => 'Closed';

  @override
  String get open => 'Open';

  @override
  String get perKm => 'Per KM';

  @override
  String get fixedRate => 'Fixed Rate';

  @override
  String get locationNotSpecified => 'Location not specified';

  @override
  String get submittedRecently => 'Submitted recently';

  @override
  String submittedOn(Object date) {
    return 'Submitted $date';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get monthlyHiringFormIntro =>
      'Tell us what you need — our team will get back to you with options.';

  @override
  String get locationRoute => 'Location / Route';

  @override
  String get monthlyHiringLocationHint =>
      'e.g. Pune, or Pune to Mumbai corridor';

  @override
  String get truckCategory => 'Truck Category';

  @override
  String get anyCategory => 'Any category';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get selectStartDate => 'Select start date';

  @override
  String get selectEndDate => 'Select end date';

  @override
  String get pricingPreference => 'Pricing Preference';

  @override
  String get perKmRate => 'Per KM Rate';

  @override
  String get budgetPerKmOptional => 'Budget (₹ per km) (optional)';

  @override
  String get monthlyBudgetOptional => 'Monthly Budget (₹) (optional)';

  @override
  String get expectedBudgetHint => 'Your expected budget';

  @override
  String get additionalDetailsOptional => 'Additional Details (optional)';

  @override
  String get monthlyHiringDetailsHint =>
      'Anything else that would help — cargo type, expected daily runs, etc.';

  @override
  String get cancel => 'Cancel';

  @override
  String get submitting => 'Submitting...';

  @override
  String get submitEnquiry => 'Submit Enquiry';

  @override
  String get monthlyHiringLocationRequired =>
      'Please tell us where you need the vehicle';

  @override
  String get monthlyHiringDatesRequired =>
      'Please select both a start and end date';

  @override
  String get monthlyHiringEndDateAfterStart =>
      'End date must be after the start date';

  @override
  String get signInAgainToSubmit => 'Please sign in again to submit.';

  @override
  String get validBudgetRequired => 'Please enter a valid budget amount';

  @override
  String get enquirySubmitted =>
      'Enquiry submitted — our team will get in touch soon';

  @override
  String get driverPhoneUnavailable => 'Driver phone number is not available.';

  @override
  String get couldNotOpenPhoneApp => 'Could not open the phone app.';

  @override
  String get signInAgainToCancelBooking =>
      'Please sign in again to cancel this booking.';

  @override
  String get cancelledByClient => 'Cancelled by client';

  @override
  String get bookingCancelledSuccessfully => 'Booking cancelled successfully.';

  @override
  String get paymentAmountUnavailable => 'Payment amount is unavailable.';

  @override
  String get continueToPayment => 'Continue to payment?';

  @override
  String paymentCheckoutMessage(Object amount) {
    return 'This will open secure checkout for ₹$amount.';
  }

  @override
  String get payNow => 'Pay now';

  @override
  String get bookingPaymentDescription => 'Booking payment';

  @override
  String get paymentCompletedSuccessfully => 'Payment completed successfully.';

  @override
  String get signInAgainToShareTracking =>
      'Please sign in again to share tracking.';

  @override
  String get trackingLinkUnavailable => 'Tracking link is unavailable.';

  @override
  String get trackYourShipment => 'Track your shipment';

  @override
  String trackingShareText(
    Object trackingId,
    Object fromLocation,
    Object toLocation,
    Object shareUrl,
  ) {
    return 'Track $trackingId ($fromLocation to $toLocation)\n$shareUrl';
  }

  @override
  String get trackingLinkReadyToShare => 'Tracking link is ready to share.';

  @override
  String get trackingLinkCopied => 'Tracking link copied to clipboard.';

  @override
  String get invoiceFileEmpty => 'Invoice file is empty.';

  @override
  String invoiceDownloadedTo(Object path) {
    return 'Invoice downloaded to $path.';
  }

  @override
  String get invoiceReadyToSaveOrShare => 'Invoice ready to save or share.';

  @override
  String get invoiceDownloadFailed =>
      'Failed to download invoice. Please restart the app and try again.';

  @override
  String get invoiceDownloadFailedTryAgain =>
      'Failed to download invoice. Please try again.';

  @override
  String get myProfile => 'My Profile';

  @override
  String get shipments => 'Shipments';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get preferences => 'Preferences';

  @override
  String get help => 'Help';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get termsPrivacy => 'Terms & Privacy';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get featureComingSoon => 'This feature is coming soon.';

  @override
  String get sskVersion => 'SSK Logistics v1.0.0';

  @override
  String get appearanceLightSubtitle => 'Liquid glass light mode';

  @override
  String get appearanceDarkSubtitle => 'Liquid glass dark mode';

  @override
  String get liquidGlassAppearance => 'Liquid glass appearance';

  @override
  String get client => 'Client';

  @override
  String get notProvided => 'Not provided';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get bookings => 'Bookings';

  @override
  String get spent => 'Spent';

  @override
  String get delivered => 'Delivered';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get retryAccountStats => 'Retry account stats';

  @override
  String get memberSince => 'Member Since';

  @override
  String get activeShipments => 'Active Shipments';

  @override
  String get lifetimeValue => 'Lifetime Value';

  @override
  String get signOut => 'Sign Out';

  @override
  String get support => 'Support';

  @override
  String get brokerAccount => 'Broker account';

  @override
  String get noEmailConnected => 'No email connected';

  @override
  String get standardPlan => 'Standard Plan';

  @override
  String get brokerEarningsSubtitle => 'Revenue and settlement performance';

  @override
  String get completeBrokerVerification => 'Complete your broker verification';

  @override
  String get brokerHelpSubtitle => 'Contact support for account or trip issues';

  @override
  String get removeFromMyList => 'Remove from my list?';

  @override
  String get removeFromMyListDescription =>
      'This only removes it from your own list. There\'s no undo.';

  @override
  String get remove => 'Remove';

  @override
  String get bookingRemovedFromList => 'Booking removed from your list.';

  @override
  String invoiceForBooking(Object trackingId) {
    return 'Invoice for booking $trackingId';
  }

  @override
  String invoiceEmailDefaultMessage(Object bookingRef) {
    return 'Please find attached the invoice for booking $bookingRef.';
  }

  @override
  String get invoiceEmailedSuccessfully => 'Invoice emailed successfully.';

  @override
  String get clientNotifiedInvoiceShared =>
      'Client notified — invoice shared to their portal.';

  @override
  String get stopMarkedComplete => 'Stop marked complete.';

  @override
  String get forceTripStatus => 'Force trip status?';

  @override
  String forceTripStatusDescription(Object status) {
    return 'This moves the trip to \"$status\" on the driver\'s behalf. Use only if the driver is unreachable.';
  }

  @override
  String get apply => 'Apply';

  @override
  String get tripStatusUpdated => 'Trip status updated.';

  @override
  String get paymentRecorded => 'Payment recorded.';

  @override
  String get tripNotFound => 'Trip not found';

  @override
  String get couldNotLoadJobDetails => 'Could not load job details';

  @override
  String get completeDelivery => 'Complete Delivery';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Saving...';

  @override
  String get invoice => 'Invoice';

  @override
  String get emailAction => 'Email';

  @override
  String get sending => 'Sending...';

  @override
  String get notify => 'Notify';

  @override
  String get removing => 'Removing...';

  @override
  String get jobDetails => 'Job Details';

  @override
  String get truck => 'Truck';

  @override
  String get date => 'Date';

  @override
  String get distance => 'Distance';

  @override
  String get cargo => 'Cargo';

  @override
  String get earningsPayment => 'Earnings & Payment';

  @override
  String get amount => 'Amount';

  @override
  String get platformFee => 'Platform Fee';

  @override
  String get netEarnings => 'Net Earnings';

  @override
  String get payment => 'Payment';

  @override
  String get mode => 'Mode';

  @override
  String get timeTaken => 'Time Taken';

  @override
  String get recording => 'Recording...';

  @override
  String get cash => 'Cash';

  @override
  String routeTo(Object from, Object to) {
    return '$from to $to';
  }

  @override
  String get driverTakeoverTitle => 'Driver unreachable? Take over this trip';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get driverTakeoverDescription =>
      'Use this only if the driver\'s phone is dead, their app crashed, or they\'ve lost signal. Actions happen directly on the driver\'s behalf.';

  @override
  String get retryLoadingTrip => 'Retry loading trip';

  @override
  String get loadingUnloadingStops => 'LOADING & UNLOADING STOPS';

  @override
  String get forceStatus => 'FORCE STATUS';

  @override
  String get applying => 'Applying...';

  @override
  String get done => 'Done';

  @override
  String get pending => 'Pending';

  @override
  String get markLoaded => 'Mark Loaded';

  @override
  String get markUnloaded => 'Mark Unloaded';

  @override
  String get loadingUnloadingStopsTitle => 'Loading & Unloading Stops';

  @override
  String get proofOfDelivery => 'Proof of Delivery';

  @override
  String get awaitingClientReview => 'Awaiting client review';

  @override
  String get clientApproved => 'Client approved';

  @override
  String get clientRejectedReuploading =>
      'Client rejected — driver re-uploading';

  @override
  String get sendInvoiceByEmail => 'Send invoice by email';

  @override
  String get to => 'To';

  @override
  String get subject => 'Subject';

  @override
  String get message => 'Message';

  @override
  String get send => 'Send';

  @override
  String get reassignmentHistory => 'Reassignment History';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get unknown => 'Unknown';

  @override
  String reassignedBy(Object name, Object date) {
    return 'By $name · $date';
  }

  @override
  String get locationPending => 'Location pending';

  @override
  String includedHaltingCharge(Object hours, Object amount) {
    return 'Incl. halting (${hours}h): $amount';
  }

  @override
  String includedDelayCharge(Object hours, Object amount) {
    return 'Incl. delay (${hours}h): $amount';
  }

  @override
  String clientReason(Object reason) {
    return 'Client\'s reason: $reason';
  }

  @override
  String get online => 'Online';

  @override
  String get navHome => 'Home';

  @override
  String get navActivity => 'Activity';

  @override
  String get navProfile => 'Profile';

  @override
  String get navNewBooking => 'New Booking';

  @override
  String get navActive => 'Active';

  @override
  String get navVehicles => 'Vehicles';

  @override
  String get navTracking => 'Tracking';

  @override
  String get navHistory => 'History';

  @override
  String get navNewTravel => 'New travel';

  @override
  String get navEarnings => 'Earnings';

  @override
  String get broker => 'Broker';

  @override
  String goodMorningName(Object name) {
    return 'Good morning, $name';
  }

  @override
  String helloName(Object name) {
    return 'Hello, $name';
  }

  @override
  String get activeJobs => 'Active Jobs';

  @override
  String get newBookingsWaiting => 'New bookings waiting for you';

  @override
  String get jobsInProgress => 'Jobs currently in progress';

  @override
  String get manageFleetAtGlance => 'Manage your fleet at a glance';

  @override
  String get monitorDriverMovement => 'Monitor driver movement';

  @override
  String get reviewRecentBookings => 'Review recent bookings';

  @override
  String get bookingId => 'Booking ID';

  @override
  String get pickup => 'Pickup';

  @override
  String get drop => 'Drop';

  @override
  String get dropOff => 'Drop-off';

  @override
  String get truckType => 'Truck Type';

  @override
  String get status => 'Status';

  @override
  String get bookingsCsvCopied => 'Bookings CSV copied to clipboard.';

  @override
  String get signInToViewBookings => 'Sign in to view bookings';

  @override
  String get signInToViewBookingsSubtitle =>
      'We need an active client session before we can load your activity feed.';

  @override
  String get couldNotLoadBookings => 'Could not load bookings';

  @override
  String get tryAgain => 'Try again';

  @override
  String get nothingMovingYet => 'Nothing moving yet';

  @override
  String get nothingMovingYetSubtitle =>
      'Your trucks, trips and live tracking will land here once you make your first booking.';

  @override
  String get myBookingsSubtitle =>
      'Manage and review your fleet transportation schedules.';

  @override
  String get export => 'Export';

  @override
  String get newBooking => 'New Booking';

  @override
  String get fromLabel => 'From:';

  @override
  String get shippingToLabel => 'Shipping to:';

  @override
  String get pickupLocationNotProvided => 'Pickup location not provided';

  @override
  String get dropOffLocationNotProvided => 'Drop-off location not provided';

  @override
  String get express => 'Express';

  @override
  String invoiceEmailMessage(Object trackingId) {
    return 'Please find attached the invoice for booking $trackingId.';
  }

  @override
  String get emailInvoice => 'Email invoice';

  @override
  String get rateBooking => 'Rate booking';

  @override
  String get review => 'Review';

  @override
  String get reviewHint => 'Tell us how the delivery went';

  @override
  String get submit => 'Submit';

  @override
  String get thanksForYourRating => 'Thanks for your rating.';

  @override
  String get raiseDispute => 'Raise dispute';

  @override
  String get billing => 'Billing';

  @override
  String get damage => 'Damage';

  @override
  String get delay => 'Delay';

  @override
  String get other => 'Other';

  @override
  String get issueType => 'Issue type';

  @override
  String get description => 'Description';

  @override
  String get disputeDescriptionHint => 'Describe the issue in a few words';

  @override
  String get disputeSubmitted => 'Dispute submitted.';

  @override
  String get cancelling => 'Cancelling...';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get liveTracking => 'Live Tracking';

  @override
  String get maps => 'Maps';

  @override
  String get signInAgainToApprove => 'Please sign in again to approve.';

  @override
  String get proofOfDeliveryApproved => 'Proof of delivery approved.';

  @override
  String get rejectProofOfDelivery => 'Reject proof of delivery?';

  @override
  String get rejectProofOfDeliveryDescription =>
      'The driver will be asked to upload new photos before the trip can be completed.';

  @override
  String get rejectPodReasonHint =>
      'e.g. Photos are blurry, doesn\'t show delivered cargo...';

  @override
  String get reject => 'Reject';

  @override
  String get signInAgainToReject => 'Please sign in again to reject.';

  @override
  String get driverAskedToReuploadPod =>
      'Asked the driver to re-upload proof of delivery.';

  @override
  String get fetchingAdvanceAmount => 'Fetching configured advance amount';

  @override
  String advanceAmountNowBalanceOnDelivery(Object amount) {
    return '$amount now, balance on delivery';
  }

  @override
  String get paymentPayNow => 'Pay Now';

  @override
  String get paymentPayNowSubtitle => 'Full amount now through secure checkout';

  @override
  String get advance => 'Advance';

  @override
  String get toPay => 'To Pay';

  @override
  String get toPaySubtitle => 'Full amount collected by the driver on delivery';

  @override
  String get toBeBilled => 'To Be Billed';

  @override
  String get toBeBilledSubtitle => 'Nothing collected now or on delivery';

  @override
  String get toBeBilledUnavailableSubtitle =>
      'Available after a driver is confirmed';

  @override
  String get chooseFuturePickupTime => 'Choose a future pickup time.';

  @override
  String get setTime => 'Set Time';

  @override
  String get bookingNumberPending => 'Booking Number: Pending';

  @override
  String bookingNumberValue(Object bookingReference) {
    return 'Booking Number: $bookingReference';
  }

  @override
  String get trackBooking => 'Track booking';

  @override
  String get goToHome => 'Go to home';

  @override
  String get driverOfferReceived => 'Driver offer received';

  @override
  String get confirmingWithDriver => 'Confirming with driver';

  @override
  String get findingNearbyTrucks => 'Finding nearby trucks';

  @override
  String get driverOfferReceivedSubtitle =>
      'Opening the live offer popup so you can accept, reject, or change fare.';

  @override
  String get confirmingWithDriverSubtitle =>
      'You accepted the offer. We are waiting for the driver to complete the handshake.';

  @override
  String driversNotifiedRadius(Object radius) {
    return 'Drivers inside $radius km have been notified. We will show the offer popup when one responds.';
  }

  @override
  String bookingLiveNotifyingDrivers(Object radius) {
    return 'Your booking is live. We are notifying drivers inside $radius km.';
  }

  @override
  String get driverResponse => 'Driver response';

  @override
  String get waitingForDriverAcceptance =>
      'Waiting for the driver to confirm your acceptance.';

  @override
  String fareChangeAmount(Object amount) {
    return 'Fare change: $amount';
  }

  @override
  String get driverResponseTimedOut => 'Driver response timed out.';

  @override
  String latestAmount(Object amount) {
    return 'Latest amount: $amount';
  }

  @override
  String get searchingLive => 'Searching live';

  @override
  String activeRequestsNearby(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active requests nearby',
      one: '1 active request nearby',
    );
    return '$_temp0';
  }

  @override
  String declinedCount(Object count) {
    return '$count declined';
  }

  @override
  String get openTracking => 'Open tracking';

  @override
  String get bookingConfirmed => 'Booking confirmed';

  @override
  String get bookingPlacedSuccessfully =>
      'Your booking has been successfully placed.';

  @override
  String get couldNotResolveMapPoint => 'Could not resolve this map point.';

  @override
  String loadingPointNumber(Object number) {
    return 'Loading point $number';
  }

  @override
  String unloadingPointNumber(Object number) {
    return 'Unloading point $number';
  }

  @override
  String get youAreHere => 'You are here';

  @override
  String get tapMapToSet => 'Tap map to set';

  @override
  String get chooseBrokerToContinue => 'Choose a broker to continue.';

  @override
  String get signInAgainToCreateBooking =>
      'Please sign in again to create a booking.';

  @override
  String get selectPickupDropOnMap =>
      'Please select pickup and drop locations on the map.';

  @override
  String get couldNotResolvePickupDropCoordinates =>
      'Could not resolve exact pickup/drop coordinates. Please choose them from suggestions or the map.';

  @override
  String get couldNotLoadBrokerOffers => 'Could not load broker offers.';

  @override
  String get acceptedWaitingForDriverConfirm =>
      'Accepted - waiting for the driver to confirm.';

  @override
  String declinedDriverStillWaiting(Object name) {
    return 'Declined $name - still waiting on the rest.';
  }

  @override
  String get enterValidAmount => 'Enter a valid amount.';

  @override
  String get fareChangeSent => 'Fare change sent.';

  @override
  String get continueAction => 'Continue';

  @override
  String get negotiate => 'Negotiate';

  @override
  String get signInAgainToContinue => 'Please sign in again to continue.';

  @override
  String get enterPickupAndDropLocations =>
      'Please enter both pickup and drop locations.';

  @override
  String get turnOnLocationServices =>
      'Turn on location services to autofill pickup.';

  @override
  String get locationPermissionNeeded =>
      'Location permission is needed to autofill pickup.';

  @override
  String get couldNotResolveCurrentAddress =>
      'Could not resolve your current address yet.';

  @override
  String get expressAvailableForIntraCity =>
      'Express delivery is available for intra-city bookings.';

  @override
  String get enterDropLocation => 'Please enter the drop location.';

  @override
  String get findTruck => 'Find Truck';

  @override
  String get brokers => 'Brokers';

  @override
  String get searchRadius => 'Search Radius';

  @override
  String get couldNotLoadBrokers => 'Could not load brokers';

  @override
  String get noBrokerNearby => 'No broker nearby';

  @override
  String get noEligibleBrokersForRoute =>
      'No eligible brokers found for this route yet.';

  @override
  String get secureCheckout => 'Secure checkout';

  @override
  String get payOnDelivery => 'Pay on delivery';

  @override
  String get noCollectionNow => 'No collection now';

  @override
  String get afterDriverConfirm => 'After driver confirm';

  @override
  String get skip => 'Skip';

  @override
  String get deliveries => 'Deliveries';

  @override
  String get refreshRequests => 'Refresh requests';

  @override
  String get goOnlineToReceiveRequests => 'Go online to receive requests';

  @override
  String get negotiationCardsAppearWhenAvailable =>
      'Negotiation cards will appear here once you are available.';

  @override
  String get pleaseSignInAgain => 'Please sign in again';

  @override
  String get activeSessionNeededForRequests =>
      'We need an active session before we can load requests.';

  @override
  String get loadingRequests => 'Loading requests';

  @override
  String get fetchingDriverRequests =>
      'Fetching driver requests from the server.';

  @override
  String get couldNotLoadRequests => 'Could not load requests';

  @override
  String get noNewDeliveries => 'No new deliveries';

  @override
  String get newClientRequestsAppearHere =>
      'New client requests will appear here when they arrive.';

  @override
  String get requestTimedOutBrokerHandoff =>
      'This request timed out for the driver. Broker handoff is active.';

  @override
  String get swipeToAccept => 'Swipe to accept';

  @override
  String get alreadyAgreedWithBroker =>
      'Already agreed with the broker - accept or decline.';

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get fullTripHistoryAppearsHere =>
      'Your full trip history will appear here.';

  @override
  String get noActiveDelivery => 'No active delivery';

  @override
  String get acceptedDeliveriesAppearLive =>
      'Accepted deliveries will appear here live.';

  @override
  String get loadingTrips => 'Loading trips...';

  @override
  String get activeDelivery => 'Active delivery';

  @override
  String get liveTripAppearsFirst => 'Your live trip appears here first';

  @override
  String get totalTrips => 'Total trips';

  @override
  String get totalEarned => 'Total earned';

  @override
  String get completed => 'Completed';

  @override
  String get addDriver => 'Add driver';

  @override
  String get removeDriverQuestion => 'Remove driver?';

  @override
  String deleteDriverFromFleet(Object name) {
    return 'This will delete $name from the broker fleet.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get signInAgainToDeleteDriver =>
      'Please sign in again to delete a driver.';

  @override
  String get driverRemoved => 'Driver removed from fleet.';

  @override
  String get reportIncident => 'Report incident';

  @override
  String get reason => 'Reason';

  @override
  String get notes => 'Notes';

  @override
  String get incidentReported => 'Incident reported successfully.';

  @override
  String get collectSettlement => 'Collect settlement';

  @override
  String get chooseSettlementMode =>
      'Choose the settlement mode for this trip.';

  @override
  String get settlementUpdated => 'Settlement updated.';

  @override
  String get updateMechanic => 'Update mechanic';

  @override
  String get mechanicName => 'Mechanic name';

  @override
  String get mechanicPhone => 'Mechanic phone';

  @override
  String get save => 'Save';

  @override
  String get mechanicDetailsUpdated => 'Mechanic details updated.';

  @override
  String get driverLocationActivityOverview =>
      'Driver location and activity overview';

  @override
  String tripId(Object id) {
    return 'Trip $id';
  }

  @override
  String get live => 'Live';

  @override
  String get paymentPending => 'Payment pending';

  @override
  String incidentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incidents',
      one: '1 incident',
    );
    return '$_temp0';
  }

  @override
  String get tripProgress => 'Trip progress';

  @override
  String get reportIssue => 'Report issue';

  @override
  String get settle => 'Settle';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get reassignDriver => 'Reassign driver';

  @override
  String currentlyAssigned(Object name) {
    return 'Currently assigned: $name';
  }

  @override
  String get reassignTo => 'Reassign to';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get reassignReasonHint =>
      'Driver unavailable, breakdown, better route fit...';

  @override
  String get reassign => 'Reassign';

  @override
  String get mechanic => 'Mechanic';

  @override
  String get resolve => 'Resolve';

  @override
  String get requestUpdated => 'Request updated.';

  @override
  String get driverRequests => 'Driver requests';

  @override
  String get noDriverRequestsYet => 'No driver requests yet.';

  @override
  String get driverReassigned => 'Driver reassigned.';

  @override
  String get tripMarkedCompleted => 'Trip marked as completed.';

  @override
  String stopMarkedCompleteWithLabel(Object label) {
    return '$label marked complete.';
  }

  @override
  String get incidentResolved => 'Incident resolved.';

  @override
  String get driverLocation => 'Driver location';

  @override
  String get tripDestination => 'Trip destination';

  @override
  String get assigned => 'Assigned';

  @override
  String get inTransit => 'In transit';

  @override
  String get tripCompleted => 'Trip completed';

  @override
  String get settled => 'Settled';

  @override
  String get brokerUpdatedPayout => 'Broker updated the payout';

  @override
  String get loading => 'Loading...';

  @override
  String get signInToLoadTripProgress => 'Sign in to load trip progress';

  @override
  String get driverLocationOnly => 'Driver location only';

  @override
  String get liveDetailsUnavailable => 'Live details unavailable';

  @override
  String get tripDestinationNotAvailable => 'Trip destination not available';

  @override
  String get vehicleTracking => 'Vehicle tracking';

  @override
  String get tripStillSyncing => 'Trip is still syncing. Please try again.';

  @override
  String get declineThisTrip => 'Decline this trip?';

  @override
  String get declineTripDescription =>
      'You will be freed from this trip and your broker can assign another driver. This cannot be undone.';

  @override
  String get keepTrip => 'Keep trip';

  @override
  String get declineTrip => 'Decline trip';

  @override
  String get tripDeclined => 'Trip declined.';

  @override
  String get confirming => 'Confirming...';

  @override
  String get slideToDeliver => 'Slide to deliver';

  @override
  String get customer => 'Customer';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get allowDisplayOverApps => 'Allow display over other apps';

  @override
  String get allowDisplayOverAppsText =>
      'This opens SSK\'s page in system Settings.\n\n1. Turn ON \"Allow display over other apps\".\n2. Press back - Maps opens automatically with the floating SSK button.\n\n(On Xiaomi/Redmi/Poco the toggle may be called \"Display pop-up windows\".)';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get couldNotOpenSettings =>
      'Could not open Settings. Open it manually: Settings > Apps > SSK > Display over other apps.';

  @override
  String get couldNotShowFloatingButton =>
      'Could not show the floating button on this device. Opening Maps anyway.';

  @override
  String get tapBubbleToReturn => 'Tap the SSK bubble over Maps to return.';

  @override
  String get navigateToDrop => 'Navigate to drop';

  @override
  String get callPolice => 'Call Police';

  @override
  String get emergency112 => 'Emergency: 112';

  @override
  String get callingPoliceSoon => 'Calling police support soon.';

  @override
  String get callAmbulance => 'Call Ambulance';

  @override
  String get emergency108 => 'Emergency: 108';

  @override
  String get callingAmbulanceSoon => 'Calling ambulance support soon.';

  @override
  String get callBroker => 'Call Broker';

  @override
  String get callingBrokerSoon => 'Calling broker soon.';

  @override
  String get reportIncidentToSupport => 'Report Incident to Support';

  @override
  String get notifySupportImmediately => 'Notify our support team immediately';

  @override
  String get viewMechanicStatus => 'View Mechanic Status';

  @override
  String get seeRepairProgress => 'See breakdown and repair progress';

  @override
  String get signInAgainToViewMechanicStatus =>
      'Please sign in again to view mechanic status.';

  @override
  String get chatUnavailableForTrip =>
      'Chat is not available for this trip yet.';

  @override
  String get customerPhoneUnavailable =>
      'Customer phone number is not available.';

  @override
  String get close => 'Close';

  @override
  String get incidentDialogSubtitle =>
      'What\'s going on? Your broker and the client will be notified right away.';

  @override
  String get addDetailsOptional => 'Add any details (optional)';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get accident => 'Accident';

  @override
  String get breakdown => 'Breakdown';

  @override
  String get trafficBlock => 'Traffic Block';

  @override
  String get medical => 'Medical';

  @override
  String incidentReportSubmitted(Object type) {
    return '$type report submitted to support.';
  }

  @override
  String get signInAgainToReportIssue =>
      'Please log in again to report the issue.';

  @override
  String get noIncidentsReported => 'No incidents reported for this trip yet.';

  @override
  String get refresh => 'Refresh';

  @override
  String get weight => 'Weight';

  @override
  String get pickupPending => 'Pickup pending';

  @override
  String get dropPending => 'Drop pending';

  @override
  String get trackingActionsSubtitle =>
      'Use the live APIs for chat, invoice, rating, payment, and disputes.';

  @override
  String get openChat => 'Open chat';

  @override
  String get openChatSubtitle => 'Message the booking thread over Socket.IO';

  @override
  String get negotiationOffers => 'Negotiation & offers';

  @override
  String get negotiationOffersSubtitle =>
      'Review driver requests and broker offers';

  @override
  String get downloadInvoice => 'Download invoice';

  @override
  String get downloadInvoiceSubtitle => 'Fetch the PDF invoice stream';

  @override
  String get emailInvoiceSubtitle => 'Send the invoice PDF by email';

  @override
  String get payBooking => 'Pay booking';

  @override
  String get openSecureCheckout => 'Open secure checkout';

  @override
  String get submitDeliveryFeedback => 'Submit delivery feedback';

  @override
  String get raiseDisputeSubtitle => 'Open a backend dispute record';

  @override
  String get messageCouldNotBeSent => 'Message could not be sent.';

  @override
  String get driverRequestAccepted => 'Driver request accepted.';

  @override
  String get driverRequestDeclined => 'Driver request declined.';

  @override
  String get offerAccepted => 'Offer accepted.';

  @override
  String get acceptedWaitingForBrokerConfirm =>
      'Accepted - waiting for the broker to confirm.';

  @override
  String get offerDeclined => 'Offer declined.';

  @override
  String get changeFare => 'Change Fare';

  @override
  String nearbyDriverOffers(Object count) {
    return 'Nearby driver offers ($count)';
  }

  @override
  String get driverConfirmedBooking => 'This driver confirmed your booking.';

  @override
  String get nearbyDriverOffersSubtitle =>
      'Every nearby driver gets their own card - accept, change fare, or decline each one separately.';

  @override
  String get noDriverOffersYet => 'No driver offers yet';

  @override
  String get driverOffersAppearHere =>
      'Once a nearby driver responds, the offers will appear here.';

  @override
  String get driverOffer => 'Driver offer';

  @override
  String get brokerOffers => 'Broker offers';

  @override
  String get brokerOffersSubtitle =>
      'Fare changes sent after the booking was broadcast.';

  @override
  String get noBrokerOffersYet => 'No broker offers yet';

  @override
  String get brokerOffersAppearHere =>
      'Once a broker responds, the offers will appear here.';

  @override
  String get confirm => 'Confirm';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get gallery => 'Gallery';

  @override
  String get brokerReqDetailRequestRejected => 'Request rejected.';

  @override
  String get brokerReqDetailFareChangeSent => 'Fare change sent.';

  @override
  String get brokerReqDetailAcceptedWaitingForTheClientToConfirm =>
      'Accepted - waiting for the client to confirm.';

  @override
  String get brokerReqDetailOfferSentToTheDriverWaitingFor =>
      'Offer sent to the driver - waiting for response.';

  @override
  String get brokerReqDetailAssignDriverTruck => 'Assign Driver & Truck';

  @override
  String brokerReqDetailBookingPickAnAvailableDriverAndTruck(Object id) {
    return 'Booking #$id - pick an available driver and truck.';
  }

  @override
  String get brokerReqDetailDriver => 'Driver';

  @override
  String get brokerReqDetailTruck => 'Truck';

  @override
  String get brokerReqDetailSelectOneIdleDriverAndOneIdle =>
      'Select one idle driver and one idle truck to continue.';

  @override
  String get brokerReqDetailCancel => 'Cancel';

  @override
  String get brokerReqDetailConfirmAssignment => 'Confirm Assignment';

  @override
  String get brokerReqDetailSelectDriver => 'Select driver';

  @override
  String get brokerReqDetailSelectTruck => 'Select truck';

  @override
  String get brokerReqDetailNegotiationAccepted => 'Negotiation accepted.';

  @override
  String get brokerReqDetailWaitingForClientConfirmation =>
      'Waiting for client confirmation';

  @override
  String get brokerReqDetailYourAcceptHasBeenSavedFareChanges =>
      'Your accept has been saved. Fare changes are locked until the client confirms or declines.';

  @override
  String get brokerReqDetailYourAcceptHasBeenSavedNoMore =>
      'Your accept has been saved. No more fare changes are available until the client responds.';

  @override
  String get brokerReqDetailYourAcceptHasBeenSavedTheRequest =>
      'Your accept has been saved. The request is locked until the client confirms or declines.';

  @override
  String get brokerReqDetailBrokerAssigned => 'Broker-assigned';

  @override
  String get brokerReqDetailAssignedDriverRequest => 'Assigned driver request';

  @override
  String get brokerReqDetailThisPriceWasAlreadyAgreedWithThe =>
      'This price was already agreed with the broker. Accept or decline only - no fare changes.';

  @override
  String get brokerReqDetailReject => 'Reject';

  @override
  String get brokerReqDetailBrokerNegotiation => 'Broker negotiation';

  @override
  String get brokerReqDetailFareAmount => 'Fare amount';

  @override
  String get brokerReqDetailChangeFare => 'Change Fare';

  @override
  String get brokerReqDetailAutoSelectedAssignment =>
      'Auto-selected assignment';

  @override
  String get brokerReqDetailNoExactMatchFoundAFallbackDriver =>
      'No exact match found — a fallback driver or truck will be used when you accept.';

  @override
  String get brokerReqDetailBookingDetails => 'Booking Details';

  @override
  String get brokerReqDetailOverview => 'Overview';

  @override
  String get brokerReqDetailRequestedOn => 'Requested on';

  @override
  String get brokerReqDetailRequestedBy => 'Requested by';

  @override
  String get brokerReqDetailLoadType => 'Load type';

  @override
  String get brokerReqDetailPayment => 'Payment';

  @override
  String get brokerReqDetailRouteInformation => 'Route Information';

  @override
  String get brokerReqDetailPickup => 'Pickup';

  @override
  String get brokerReqDetailDropOff => 'Drop-off';

  @override
  String get brokerReqDetailWeight => 'Weight';

  @override
  String get brokerReqDetailVehicle => 'Vehicle';

  @override
  String brokerReqDetailETA(Object eta) {
    return 'ETA: $eta';
  }

  @override
  String get brokerReqDetailSetFareAmount => 'Set fare amount';

  @override
  String brokerHomeDeclinedPickADifferentDriverForThis(Object name) {
    return '$name declined. Pick a different driver for this request.';
  }

  @override
  String brokerHomeConfirmedTripCreated(Object name) {
    return 'Confirmed. Trip created for $name.';
  }

  @override
  String get brokerHomeOfferSentToTheDriverWaitingFor =>
      'Offer sent to the driver - waiting for response.';

  @override
  String get brokerHomeChangeFare => 'Change fare';

  @override
  String brokerHomeBookingProposeADifferentAmount(Object id) {
    return 'Booking #$id: propose a different amount.';
  }

  @override
  String get brokerHomeEnterAmount => 'Enter amount';

  @override
  String get brokerHomeCancel => 'Cancel';

  @override
  String get brokerHomeChangeFare2 => 'Change Fare';

  @override
  String get brokerHomeSearchBookingIDLocation =>
      'Search booking ID, location...';

  @override
  String get brokerHomeBookingRequests => 'Booking Requests';

  @override
  String get brokerHomeSort => 'Sort';

  @override
  String get brokerHomeNoBookingsFound => 'No bookings found';

  @override
  String get brokerHomeCouldNotLoadBookings => 'Could not load bookings';

  @override
  String get brokerHomeReloadRequests => 'Reload requests';

  @override
  String get brokerHomeNewBookings => 'New bookings';

  @override
  String brokerHomeTo(Object pickup, Object drop) {
    return '$pickup to $drop';
  }

  @override
  String get brokerHomePickup => 'Pickup';

  @override
  String get brokerHomeDrop => 'Drop';

  @override
  String get brokerHomeDistance => 'Distance';

  @override
  String get brokerHomeWeight => 'Weight';

  @override
  String get brokerHomeClient => 'Client';

  @override
  String get brokerHomeAssignDriverTruck => 'Assign Driver & Truck';

  @override
  String get brokerHomeConfirm => 'Confirm';

  @override
  String get brokerHomeDecline => 'Decline';

  @override
  String get brokerHomeAccept => 'Accept';

  @override
  String get brokerHomeReviewRequest => 'Review request';

  @override
  String brokerHomeChooseAnIdleDriverAndTruck(Object booking) {
    return 'Choose an idle driver and truck for $booking.';
  }

  @override
  String get brokerHomeDriver => 'Driver';

  @override
  String get brokerHomeTruck => 'Truck';

  @override
  String get brokerHomeSelectOneIdleDriverAndOneIdle =>
      'Select one idle driver and one idle truck to continue.';

  @override
  String brokerHomeSelect(Object label) {
    return 'Select $label';
  }

  @override
  String get brokerHomeCouldNotLoadAssignmentOptions =>
      'Could not load assignment options';

  @override
  String get brokerHomeRetry => 'Retry';

  @override
  String get brokerHomeNEGOTIATIONHISTORY => 'NEGOTIATION HISTORY';

  @override
  String get brokerKycPleaseSignInAgainToSubmitKYC =>
      'Please sign in again to submit KYC.';

  @override
  String brokerKycIsProvidedInTheDetailsSection(Object document) {
    return '$document is provided in the details section.';
  }

  @override
  String get brokerKycPleaseSignInAgainToUploadDocuments =>
      'Please sign in again to upload documents.';

  @override
  String get brokerKycUnableToPickDocumentRightNow =>
      'Unable to pick document right now.';

  @override
  String get brokerKycChooseHowYouWantToUploadThis =>
      'Choose how you want to upload this document.';

  @override
  String get brokerKycCamera => 'Camera';

  @override
  String get brokerKycGallery => 'Gallery';

  @override
  String get brokerKycCancel => 'Cancel';

  @override
  String get brokerKycDocumentPreview => 'Document preview';

  @override
  String get brokerKycClose => 'Close';

  @override
  String get brokerKycCompleteYourKYCToVerifyYourBrokerage =>
      'Complete your KYC to verify your brokerage account.';

  @override
  String get brokerKycUploadDocuments => 'Upload Documents';

  @override
  String get brokerKycAllYourDocumentsAreVerifiedThroughDigiLocker =>
      'All your documents are verified through DigiLocker — nothing to upload.';

  @override
  String get brokerKycAadhaarAndPANVerifiedContinueToReview =>
      'Aadhaar and PAN verified. Continue to review and finish.';

  @override
  String get brokerKycThesePhotosSupportManualReviewForThe =>
      'These photos support manual review for the documents DigiLocker couldn’t confirm.';

  @override
  String get brokerKycReviewYourInformation => 'Review Your Information';

  @override
  String get brokerKycPleaseVerifyEverythingBeforeSubmitting =>
      'Please verify everything before submitting.';

  @override
  String get brokerKycBusinessInformation => 'Business Information';

  @override
  String get brokerKycPANNumber => 'PAN Number';

  @override
  String get brokerKycAadhaarNumber => 'Aadhaar Number';

  @override
  String get brokerKycGSTNumber => 'GST Number';

  @override
  String get brokerKycBankAccountNumber => 'Bank Account Number';

  @override
  String get brokerKycBusinessRegistrationNumber =>
      'Business Registration Number';

  @override
  String get brokerKycUploadedDocuments => 'Uploaded Documents';

  @override
  String get brokerKycIConfirmThatAllTheInformationProvided =>
      'I confirm that all the information provided is accurate.';

  @override
  String get brokerKycVerificationDetails => 'Verification Details';

  @override
  String get brokerKycCurrentStatus => 'Current Status';

  @override
  String get brokerKycSubmittedDate => 'Submitted Date';

  @override
  String get brokerKycSubmissionID => 'Submission ID';

  @override
  String get brokerKycReviewedAt => 'Reviewed At';

  @override
  String get brokerKycViewMyDocuments => 'View My Documents';

  @override
  String get brokerKycGoBack => 'Go Back';

  @override
  String get brokerKycMyDocuments => 'My documents';

  @override
  String get brokerKycKYCRegistration => 'KYC Registration';

  @override
  String get brokerKycVerifyYourBrokerAccount => 'Verify your broker account';

  @override
  String brokerKycSupportedFormats(Object formats) {
    return 'Supported formats: $formats';
  }

  @override
  String get brokerKycThisItemIsCoveredInTheDetails =>
      'This item is covered in the details section.';

  @override
  String get brokerActiveJobsCouldNotLoadActiveJobs =>
      'Could not load active jobs';

  @override
  String get brokerActiveJobsNoActiveJobsFound => 'No active jobs found';

  @override
  String get brokerActiveJobsAssignedAndInTransitJobsWillAppear =>
      'Assigned and in-transit jobs will appear here.';

  @override
  String get brokerActiveJobsReportAProblem => 'Report a Problem';

  @override
  String brokerActiveJobsTo(Object pickup, Object drop) {
    return '$pickup to $drop';
  }

  @override
  String get brokerActiveJobsIssueType => 'Issue Type';

  @override
  String get brokerActiveJobsDescribeWhatWentWrong =>
      'Describe what went wrong...';

  @override
  String get brokerActiveJobsCancel => 'Cancel';

  @override
  String get brokerActiveJobsDisputeRaisedOurTeamWillReviewIt =>
      'Dispute raised - our team will review it shortly.';

  @override
  String get brokerActiveJobsReassignDriver => 'Reassign Driver';

  @override
  String get brokerActiveJobsCurrentlyAssigned => 'Currently Assigned';

  @override
  String get brokerActiveJobsReassignTo => 'Reassign to';

  @override
  String get brokerActiveJobsOptionalReasonForReassignment =>
      'Optional reason for reassignment';

  @override
  String get brokerActiveJobsCanTFindTheOriginalJobRequest =>
      'Can\'t find the original job request for this booking.';

  @override
  String get brokerActiveJobsDriverReassigned => 'Driver reassigned.';

  @override
  String get brokerActiveJobsActiveJobs => 'Active Jobs';

  @override
  String brokerActiveJobsJobsCurrentlyInProgress(Object count) {
    return '$count jobs currently in progress';
  }

  @override
  String get brokerActiveJobsPickup => 'Pickup';

  @override
  String get brokerActiveJobsDrop => 'Drop';

  @override
  String get brokerActiveJobsTruck => 'Truck';

  @override
  String get brokerActiveJobsDriver => 'Driver';

  @override
  String get brokerActiveJobsTRIPPROGRESS => 'TRIP PROGRESS';

  @override
  String get brokerActiveJobsTrackLive => 'Track Live';

  @override
  String get brokerActiveJobsChat => 'Chat';

  @override
  String get addDriverPleaseSignInAgainToCreateA =>
      'Please sign in again to create a driver.';

  @override
  String get addDriverDriverProfileSavedSuccessfully =>
      'Driver profile saved successfully.';

  @override
  String addDriverHasBeenRegisteredAndAddedToYour(Object name) {
    return '$name has been registered and added to your drivers.';
  }

  @override
  String get addDriverTemporaryPassword => 'Temporary Password';

  @override
  String get addDriverPasswordCopied => 'Password copied';

  @override
  String get addDriverCopy => 'Copy';

  @override
  String get addDriverThisPasswordIsShownOnlyOnceThe =>
      'This password is shown only once — the driver can change it from their profile after logging in.';

  @override
  String get addDriverDone => 'Done';

  @override
  String get addDriverEmailAlreadyRegistered => 'Email already registered';

  @override
  String addDriverIsAlreadyTiedToADriverAccount(Object email) {
    return '$email is already tied to a driver account.';
  }

  @override
  String get addDriverKeepEditing => 'Keep editing';

  @override
  String get addDriverViewDrivers => 'View drivers';

  @override
  String get addDriverAccountDetails => 'Account Details';

  @override
  String get addDriverFullName => 'Full name';

  @override
  String get addDriverEmail => 'Email';

  @override
  String get addDriverMobileNumber => 'Mobile number';

  @override
  String get addDriverLicenseDocuments => 'License & Documents';

  @override
  String get addDriverLicenseNumber => 'License number';

  @override
  String get addDriverAadhaarNumber => 'Aadhaar number';

  @override
  String get addDriverLeaveBlankToKeepTheCurrentAadhaar =>
      'Leave blank to keep the current Aadhaar on file.';

  @override
  String get addDriverLicenseExpiry => 'License expiry';

  @override
  String get addDriverYYYYMMDD => 'YYYY-MM-DD';

  @override
  String get addDriverVehicleAssignment => 'Vehicle Assignment';

  @override
  String get addDriverAssignTruck => 'Assign truck';

  @override
  String get addDriverTruckID => 'Truck ID';

  @override
  String get addDriverEnterTruckUUIDOptional => 'Enter truck UUID (optional)';

  @override
  String get addDriverStatus => 'Status';

  @override
  String get addDriverAvailable => 'Available';

  @override
  String get addDriverOnTrip => 'On trip';

  @override
  String get addDriverOffline => 'Offline';

  @override
  String get addDriverTruckListCouldNotBeLoadedYou =>
      'Truck list could not be loaded. You can still enter a truck ID manually.';

  @override
  String get addDriverChangePhoto => 'Change Photo';

  @override
  String get brokerHistoryRemoveFromMyList => 'Remove from my list?';

  @override
  String get brokerHistoryThisOnlyRemovesItFromYourOwn =>
      'This only removes it from your own list. There\'s no undo.';

  @override
  String get brokerHistoryCancel => 'Cancel';

  @override
  String get brokerHistoryRemove => 'Remove';

  @override
  String get brokerHistoryBookingRemovedFromYourList =>
      'Booking removed from your list.';

  @override
  String get brokerHistoryCouldNotLoadJobHistory =>
      'Could not load job history';

  @override
  String get brokerHistoryNoBookingsFound => 'No bookings found';

  @override
  String get brokerHistoryCompletedAndCancelledBookingsAppearHere =>
      'Completed and cancelled bookings appear here.';

  @override
  String get brokerHistoryJobHistory => 'Job History';

  @override
  String brokerHistoryCompletedAndCancelledBookings(Object count) {
    return '$count completed and cancelled bookings';
  }

  @override
  String get brokerHistorySearchBookingsRoutesDrivers =>
      'Search bookings, routes, drivers...';

  @override
  String get brokerHistoryTotalNetEarningsFiltered =>
      'Total Net Earnings (filtered)';

  @override
  String brokerHistoryTo(Object pickup, Object drop) {
    return '$pickup to $drop';
  }

  @override
  String get brokerHistoryPickup => 'Pickup';

  @override
  String get brokerHistoryDrop => 'Drop';

  @override
  String get brokerHistoryTruck => 'Truck';

  @override
  String get brokerHistoryDriver => 'Driver';

  @override
  String get brokerHistoryViewDetails => 'View details';

  @override
  String brokerHistoryFee(Object amount) {
    return 'Fee: $amount';
  }

  @override
  String brokerHistoryNet(Object amount) {
    return 'Net: $amount';
  }

  @override
  String get brokerDriverReqDriverRequests => 'Driver requests';

  @override
  String get brokerDriverReqCouldNotLoadDriverRequests =>
      'Could not load driver requests';

  @override
  String get brokerDriverReqNegotiationCards => 'Negotiation cards';

  @override
  String get brokerDriverReqReload => 'Reload';

  @override
  String get brokerDriverReqNoDriverRequestsYet => 'No driver requests yet';

  @override
  String get brokerDriverReqWhenADriverTimesOutTheRequest =>
      'When a driver times out, the request will appear here for broker takeover.';

  @override
  String get brokerDriverReqBookingID => 'Booking ID';

  @override
  String get brokerDriverReqPickup => 'Pickup';

  @override
  String get brokerDriverReqDrop => 'Drop';

  @override
  String get brokerDriverReqAcceptedWaitingForTheClientToConfirm =>
      'Accepted - waiting for the client to confirm';

  @override
  String get brokerDriverReqConfirm => 'Confirm';

  @override
  String get brokerDriverReqDecline => 'Decline';

  @override
  String get brokerDriverReqAccept => 'Accept';

  @override
  String get brokerDriverReqAlreadyAgreedWithTheBrokerAcceptOr =>
      'Already agreed with the broker - accept or decline, no negotiation.';

  @override
  String get brokerDriverReqChangeFare => 'Change Fare';

  @override
  String get brokerDriverReqDriverTimedOutBrokerTakeoverActive =>
      'Driver timed out - broker takeover active.';

  @override
  String get brokerDriverReqBrokerAssigned => 'Broker-assigned';

  @override
  String get brokerDriverReqChangeFare2 => 'Change fare';

  @override
  String get brokerDriverReqSetFareAmount => 'Set fare amount';

  @override
  String get brokerDriverReqCancel => 'Cancel';

  @override
  String get brokerVehiclesVehicles => 'Vehicles';

  @override
  String get brokerVehiclesManageYourFleetAndTruckAvailability =>
      'Manage your fleet and truck availability';

  @override
  String get brokerVehiclesSearchVehiclesDriversOrLocation =>
      'Search vehicles, drivers or location';

  @override
  String get brokerVehiclesRemoveTruck => 'Remove Truck';

  @override
  String brokerVehiclesRemoveFromYourFleet(Object vehicle) {
    return 'Remove $vehicle from your fleet?';
  }

  @override
  String get brokerVehiclesCancel => 'Cancel';

  @override
  String get brokerVehiclesRemove => 'Remove';

  @override
  String get brokerVehiclesTruckRemoved => 'Truck removed.';

  @override
  String get brokerVehiclesYourFleet => 'Your fleet';

  @override
  String get brokerVehiclesAddTruck => 'Add truck';

  @override
  String get brokerVehiclesCouldNotLoadTrucks => 'Could not load trucks';

  @override
  String get brokerVehiclesNoMatchingVehicles => 'No matching vehicles';

  @override
  String get brokerVehiclesTryADifferentSearchOrAddA =>
      'Try a different search or add a new truck.';

  @override
  String get brokerVehiclesEdit => 'Edit';

  @override
  String get brokerVehiclesAssign => 'Assign';

  @override
  String get brokerVehiclesTrack => 'Track';

  @override
  String get brokerVehiclesHistory => 'History';

  @override
  String get addVehiclePleaseSignInAgainToAddA =>
      'Please sign in again to add a truck.';

  @override
  String get addVehiclePleaseAssignADriver => 'Please assign a driver.';

  @override
  String get addVehiclePleaseEnterAValidYear => 'Please enter a valid year.';

  @override
  String get addVehicleRegistration => 'Registration';

  @override
  String get addVehicleCapacity => 'Capacity';

  @override
  String get addVehicleAssignDriver => 'Assign driver';

  @override
  String get addVehicleMake => 'Make';

  @override
  String get addVehicleYear => 'Year';

  @override
  String get addVehicleInsuranceExpiry => 'Insurance expiry';

  @override
  String get addVehiclePickADate => 'Pick a date';

  @override
  String get addVehicleSaveTruck => 'Save truck';

  @override
  String get brokerEarningsEarnings => 'Earnings';

  @override
  String get brokerEarningsRevenueMomentumAndSettlementsAtAGlance =>
      'Revenue, momentum and settlements at a glance.';

  @override
  String get brokerEarningsFailedToLoadEarnings => 'Failed to load earnings';

  @override
  String get brokerEarningsGrossRevenue => 'Gross revenue';

  @override
  String get brokerEarningsPlatformFees => 'Platform fees';

  @override
  String get brokerEarningsRecentSettlements => 'Recent settlements';

  @override
  String get brokerEarningsSeeAll => 'See all';

  @override
  String get brokerEarningsNoSettlementsYet => 'No settlements yet';

  @override
  String get brokerEarningsCompletedSettlementsWillAppearHereWithRoute =>
      'Completed settlements will appear here with route and payout details.';

  @override
  String get brokerEarningsNETEARNINGS => 'NET EARNINGS';

  @override
  String get brokerEarningsViewSettlements => 'View settlements';

  @override
  String get brokerEarningsMonthlyMomentum => 'Monthly momentum';

  @override
  String get brokerEarningsThisMonth => 'This month';

  @override
  String get brokerEarningsLastMonth => 'Last month';

  @override
  String brokerInvoicesInvoiceFetchedFor(Object booking) {
    return 'Invoice fetched for $booking';
  }

  @override
  String brokerInvoicesInvoiceEmailedFor(Object booking) {
    return 'Invoice emailed for $booking';
  }

  @override
  String get brokerInvoicesCouldNotLoadInvoices => 'Could not load invoices';

  @override
  String get brokerInvoicesNoInvoiceReadyBookingsYet =>
      'No invoice-ready bookings yet';

  @override
  String get brokerInvoicesCompletedOrDeliveredBookingsWillAppearHere =>
      'Completed or delivered bookings will appear here.';

  @override
  String get brokerInvoicesInvoices => 'Invoices';

  @override
  String brokerInvoicesTrackingID(Object id) {
    return 'Tracking ID: $id';
  }

  @override
  String get brokerInvoicesFrom => 'From:';

  @override
  String get brokerInvoicesShippingTo => 'Shipping to:';

  @override
  String get brokerInvoicesStatus => 'Status:';

  @override
  String get brokerInvoicesFetchInvoice => 'Fetch invoice';

  @override
  String get brokerInvoicesEmailInvoice => 'Email invoice';

  @override
  String get brokerSettlementsCouldNotLoadSettlements =>
      'Could not load settlements';

  @override
  String get brokerSettlementsNoSettlementsYet => 'No settlements yet';

  @override
  String get brokerSettlementsPaidAndPendingSettlementRecordsWillAppear =>
      'Paid and pending settlement records will appear here.';

  @override
  String get brokerSettlementsNetEarnings => 'Net earnings';

  @override
  String get brokerSettlementsClose => 'Close';

  @override
  String get brokerSettlementsSettlements => 'Settlements';

  @override
  String get brokerSettlementsGross => 'Gross';

  @override
  String get brokerSettlementsPICKUP => 'PICKUP';

  @override
  String get brokerSettlementsDROP => 'DROP';

  @override
  String get addTruckPleaseSignInAgainToAddA =>
      'Please sign in again to add a truck.';

  @override
  String get addTruckChooseTheTruckTypeAndFillIn =>
      'Choose the truck type and fill in the fleet details.';

  @override
  String get addTruckSelectTruckType => 'Select truck type';

  @override
  String get addTruckRegistration => 'Registration';

  @override
  String get addTruckCapacity => 'Capacity';

  @override
  String get addTruckAssignDriverOptional => 'Assign driver (optional)';

  @override
  String get addTruckMakeOptional => 'Make (optional)';

  @override
  String get addTruckYearOptional => 'Year (optional)';

  @override
  String get addTruckInsuranceExpiry => 'Insurance expiry';

  @override
  String get addTruckPickADate => 'Pick a date';

  @override
  String get brokerTrackLiveDriverPhoneNumberIsNotAvailable =>
      'Driver phone number is not available.';

  @override
  String get brokerTrackLiveCouldNotOpenThePhoneApp =>
      'Could not open the phone app.';

  @override
  String get brokerTrackLiveTrackLive => 'Track Live';

  @override
  String get brokerTrackLiveChat => 'Chat';

  @override
  String get brokerTrackLiveCallDriver => 'Call driver';

  @override
  String get brokerTrackLiveLIVE => 'LIVE';

  @override
  String get brokerTrackLiveRoute => 'Route';

  @override
  String get brokerTrackLivePickup => 'Pickup';

  @override
  String get brokerTrackLiveDropOff => 'Drop-off';

  @override
  String get brokerTrackLiveWeight => 'Weight';

  @override
  String get brokerTrackLiveTruck => 'Truck';

  @override
  String get brokerTrackLiveTripProgress => 'Trip progress';

  @override
  String get brokerNotifCouldnTLoadYourNotifications =>
      'Couldn\'t load your notifications';

  @override
  String get brokerNotifNoNotifications => 'No notifications';

  @override
  String get brokerNotifNewAlertsWillAppearHere =>
      'New alerts will appear here.';

  @override
  String get brokerNotifNotifications => 'Notifications';

  @override
  String get brokerAnalyticsCouldNotLoadAnalytics => 'Could not load analytics';

  @override
  String get brokerAnalyticsThisMonth => 'This month';

  @override
  String get brokerAnalyticsLastMonth => 'Last month';

  @override
  String get brokerAnalyticsTripHistory => 'Trip history';

  @override
  String get brokerAnalyticsFilter => 'Filter';

  @override
  String get brokerAnalyticsNoTripHistoryYet => 'No trip history yet';

  @override
  String get brokerAnalyticsCompletedSettlementsWillAppearHereOnceTrips =>
      'Completed settlements will appear here once trips close.';

  @override
  String get brokerAnalyticsAnalytics => 'Analytics';

  @override
  String get brokerAnalyticsTrackYourEarningsAndTripHistory =>
      'Track your earnings and trip history';

  @override
  String get brokerAnalyticsTotalEarnings => 'Total earnings';

  @override
  String brokerAnalyticsNetEarnings(Object amount) {
    return 'Net earnings: ₹$amount';
  }

  @override
  String get driverDetailVehicle => 'Vehicle';

  @override
  String get driverDetailLocation => 'Location';

  @override
  String get driverDetailLicense => 'License';

  @override
  String get driverDetailOnTripSince => 'On trip since';

  @override
  String get driverDetailLiveTracking => 'Live tracking';

  @override
  String get driverDetailLiveTracking2 => 'Live Tracking';

  @override
  String get driverDetailLiveDriverPosition => 'Live driver position';

  @override
  String get driverDetailChatWithDriver => 'Chat with driver';

  @override
  String get brokerTruckAssignDriverAssignedToTruck =>
      'Driver assigned to truck.';

  @override
  String get brokerTruckAssignAssignDriver => 'Assign Driver';

  @override
  String get brokerTruckAssignTruck => 'Truck';

  @override
  String get brokerTruckAssignNoActiveDriversAvailableRightNow =>
      'No active drivers available right now.';

  @override
  String get brokerTruckAssignDriver => 'Driver';

  @override
  String get brokerTruckAssignCancel => 'Cancel';

  @override
  String get brokerTruckHistoryCouldNotLoadTripHistory =>
      'Could not load trip history';

  @override
  String get brokerTruckHistoryTruckTripsWillAppearHereOnceJobs =>
      'Truck trips will appear here once jobs are assigned.';

  @override
  String get brokerTruckHistorySearchByBookingIDRoute =>
      'Search by booking ID, route...';

  @override
  String get brokerTruckLocationCouldNotLoadTruckLocation =>
      'Could not load truck location';

  @override
  String brokerTruckLocationUpdated(Object time) {
    return 'Updated $time';
  }

  @override
  String get brokerTruckLocationLiveLocationPending => 'Live location pending';

  @override
  String get brokerTruckLocationThisTruckHasNotReportedALocation =>
      'This truck has not reported a location yet.';

  @override
  String get brokerTrackingDriverHasNotBegunNegotiation =>
      'Driver has not begun negotiation';

  @override
  String get brokerTrackingClickHereToNegotiateThisTimedOut =>
      'Click here to negotiate this timed-out request.';

  @override
  String get brokerTrackingRemainingNegotiation => 'Remaining negotiation';

  @override
  String get brokerTrackingNegotiationReady => 'Negotiation ready';

  @override
  String get brokerTrackingDrivers => 'Drivers';

  @override
  String get brokerTrackingMonitorYourDriversAndLiveTrips =>
      'Monitor your drivers and live trips';

  @override
  String get brokerTrackingSearchDriversPhoneOrVehicle =>
      'Search drivers, phone or vehicle';

  @override
  String get brokerTrackingYourDrivers => 'Your drivers';

  @override
  String get brokerTrackingChangeFareRequest => 'Change fare request';

  @override
  String get brokerTrackingAmount => 'Amount';

  @override
  String get brokerTrackingNote => 'Note';

  @override
  String get brokerTrackingCancel => 'Cancel';

  @override
  String get brokerTrackingSend => 'Send';

  @override
  String get brokerTrackingChangeFare => 'Change Fare';

  @override
  String get brokerTrackingBrokerAssignedNoFareChange =>
      'Broker-assigned - no fare change';

  @override
  String brokerTrackingSLA(Object hours) {
    return 'SLA: $hours';
  }

  @override
  String brokerTrackingDelay(Object amount) {
    return 'Delay charge: ₹$amount';
  }

  @override
  String get brokerTrackingIncidents => 'Incidents';

  @override
  String get brokerTrackingLoadingUnloadingStops => 'Loading & Unloading Stops';

  @override
  String brokerTrackingCompleteEarlierStopFirst(Object type) {
    return 'Complete the earlier $type stop first.';
  }

  @override
  String brokerTrackingMechanic(Object name) {
    return 'Mechanic: $name';
  }

  @override
  String brokerFlowLoadID(Object id) {
    return 'Load ID: $id';
  }

  @override
  String get brokerFlowPickup => 'Pickup';

  @override
  String get brokerFlowDropOff => 'Drop-off';

  @override
  String get brokerFlowReviewRequest => 'Review request';

  @override
  String get brokerFlowCapacity => 'Capacity';

  @override
  String get brokerFlowLocation => 'Location';

  @override
  String brokerFlowID(Object id) {
    return 'ID: $id';
  }

  @override
  String get brokerFlowEdit => 'Edit';

  @override
  String get brokerFlowCall => 'Call';

  @override
  String get brokerFlowRemove => 'Remove';

  @override
  String allEarningsTripCount(Object count) {
    return '$count trips';
  }

  @override
  String appNewChatBookingSuffix(Object booking) {
    return ' for booking $booking';
  }

  @override
  String appNewChatRequestFrom(Object name) {
    return 'New chat request from $name';
  }

  @override
  String appNewMessageFrom(Object name) {
    return 'New message from $name';
  }

  @override
  String brokerHomeClientAcceptedConfirm(Object amount) {
    return 'Client accepted $amount. Confirm now.';
  }

  @override
  String brokerHomeDriverChangedFare(Object name) {
    return '$name changed the fare.';
  }

  @override
  String brokerHomeDriverNoResponse(Object name) {
    return '$name did not respond.';
  }

  @override
  String brokerHomeHelloName(Object name) {
    return 'Hello, $name';
  }

  @override
  String brokerHomeNoMatchButPending(Object count) {
    return 'No exact match, but $count pending requests need attention.';
  }

  @override
  String brokerHomeOfferLive(Object amount) {
    return 'Offer live: $amount';
  }

  @override
  String brokerHomeRequestsNeedAttention(Object count) {
    return '$count requests need attention';
  }

  @override
  String brokerHomeWaitingClientResponse(Object amount) {
    return 'Waiting for client response on $amount';
  }

  @override
  String brokerHomeWaitingForDriver(Object name) {
    return 'Waiting for $name';
  }

  @override
  String clientBookingRouteDistance(Object distance) {
    return 'Route distance: $distance km';
  }

  @override
  String clientCheckoutDefaultMethod(Object method) {
    return 'Default method: $method';
  }

  @override
  String clientCheckoutDemoMode(Object description) {
    return 'Demo mode: $description';
  }

  @override
  String clientCheckoutPay(Object amount) {
    return 'Pay $amount';
  }

  @override
  String clientProceedWith(Object vehicle) {
    return 'Proceed with $vehicle';
  }

  @override
  String clientPublicDelayCharge(Object amount, Object hours) {
    return 'Delay charge: $amount for $hours';
  }

  @override
  String clientPublicExpectedDelivery(Object time, Object suffix) {
    return 'Expected delivery: $time $suffix';
  }

  @override
  String clientPublicIncidentUpdate(Object status) {
    return 'Incident update: $status';
  }

  @override
  String deliveryFlowAddMore(Object count) {
    return 'Add $count more item(s).';
  }

  @override
  String deliveryFlowImagePickerError(Object error) {
    return 'Image picker error: $error';
  }

  @override
  String deliveryFlowVideoCameraError(Object error) {
    return 'Video camera error: $error';
  }

  @override
  String driverEarningsAvgPerDelivery(Object amount) {
    return 'Avg per delivery: $amount';
  }

  @override
  String driverEarningsCompletedCount(Object count) {
    return '$count completed';
  }

  @override
  String driverPaymentRecordedAs(Object mode) {
    return 'Recorded as $mode';
  }

  @override
  String gpsAppVersion(Object version) {
    return 'App version $version';
  }

  @override
  String gpsDashboardGreeting(Object name) {
    return 'Hi, $name';
  }

  @override
  String gpsFleetMapSummary(Object count, Object online) {
    return '$count vehicles, $online online';
  }

  @override
  String gpsPageIndicator(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String gpsScreenComingNext(Object name) {
    return '$name is coming next.';
  }

  @override
  String gpsShowingEntries(Object start, Object end, Object total) {
    return 'Showing $start-$end of $total';
  }

  @override
  String gpsTimeSuffixFrom(Object time) {
    return 'from $time';
  }

  @override
  String gpsTokenEquivalent(Object amount) {
    return 'Equivalent: ₹$amount';
  }

  @override
  String gpsTokensCredit(Object count) {
    return '+$count tokens';
  }

  @override
  String gpsTokensDebit(Object count) {
    return '-$count tokens';
  }

  @override
  String gpsVehicleCachedBanner(Object time) {
    return 'Last updated $time';
  }

  @override
  String photoUploadAddMore(Object count) {
    return 'Add $count more item(s).';
  }

  @override
  String photoUploadImagePickerError(Object error) {
    return 'Image picker error: $error';
  }

  @override
  String photoUploadVideoCameraError(Object error) {
    return 'Video camera error: $error';
  }

  @override
  String sharedHaltingChargeWithHours(
    Object amount,
    Object hours,
    Object freeHours,
  ) {
    return 'Halting charge $amount applied for $hours after the free $freeHours window.';
  }

  @override
  String sharedHaltingChargeWithoutHours(Object amount, Object freeHours) {
    return 'Halting charge $amount applied after the free $freeHours window.';
  }

  @override
  String sharedHaltingExceededEstimate(Object duration, Object amount) {
    return 'Free window exceeded by $duration. Estimated charge: $amount.';
  }

  @override
  String sharedHaltingExceededNoEstimate(Object duration) {
    return 'Free window exceeded by $duration.';
  }

  @override
  String sharedHaltingNotStartedMessage(Object hours) {
    return 'Halting timer starts after the free $hours window.';
  }

  @override
  String sharedHaltingRemainingMessage(Object remaining, Object freeHours) {
    return '$remaining remaining before halting charges start after the free $freeHours window.';
  }

  @override
  String truckSearchDriverOffers(Object count) {
    return 'Driver offers ($count)';
  }

  @override
  String get allEarningsActiveMonths => 'Active months';

  @override
  String get allEarningsAvgTrip => 'Average trip';

  @override
  String get allEarningsBreakdown => 'Breakdown';

  @override
  String get allEarningsDeliveries => 'Deliveries';

  @override
  String get allEarningsEmptySubtitle => 'No earnings yet';

  @override
  String get allEarningsEmptyTitle => 'No earnings yet';

  @override
  String get allEarningsLoadFailed => 'Could not load earnings';

  @override
  String get allEarningsMonthlyTrend => 'Monthly trend';

  @override
  String get allEarningsMonths => 'Months';

  @override
  String get allEarningsNetPerMonth => 'Net per month';

  @override
  String get allEarningsPerDelivery => 'Per delivery';

  @override
  String get allEarningsTitle => 'All earnings';

  @override
  String get allEarningsTotalEarned => 'Total earned';

  @override
  String get allEarningsTripsDone => 'Trips done';

  @override
  String get appChatClientFallback => 'Client';

  @override
  String get appChatSupportFallback => 'Support';

  @override
  String get appLoginAttemptBlockedBody =>
      'For your safety, this login attempt was blocked. Please review tracking settings.';

  @override
  String get appLoginAttemptBlockedTitle => 'Login attempt blocked';

  @override
  String get appNewChatRequestTitle => 'New chat request';

  @override
  String get appOkButton => 'OK';

  @override
  String get appSignedInRetry => 'Signed in. Please try again.';

  @override
  String get appTrackingSettingsAction => 'Tracking settings';

  @override
  String get arrivedHeading => 'Heading';

  @override
  String get arrivedNextLabel => 'Next';

  @override
  String get arrivedNextUpload => 'Upload delivery photos';

  @override
  String get arrivedPreparing => 'Preparing';

  @override
  String get arrivedPreparingSub => 'Please wait while we finish preparing.';

  @override
  String get arrivedSlideSub => 'Slide to continue';

  @override
  String get arrivedSlideTitle => 'You\'re on site';

  @override
  String get arrivedStatusLabel => 'Status';

  @override
  String get arrivedStatusReady => 'Ready';

  @override
  String get arrivedSub => 'Confirm that you have reached the stop.';

  @override
  String get arrivedSwipeContinue => 'Slide to continue';

  @override
  String get arrivedTitle => 'Arrived';

  @override
  String get arrivedTripIdLabel => 'Trip ID';

  @override
  String get brokerActiveDescription =>
      'A small delay here can cost you the booking. Assign a driver quickly.';

  @override
  String get brokerActiveSubmit => 'Confirm assignment';

  @override
  String get brokerActiveSubmitting => 'Confirming...';

  @override
  String get brokerHomeClientOffered => 'You offered';

  @override
  String get brokerHomeDriverFallback => 'Driver';

  @override
  String get brokerHomeDropUnavailable => 'Drop location unavailable';

  @override
  String get brokerHomeFareChangeSent => 'Fare change sent';

  @override
  String get brokerHomeFareChangesUsed => 'Fare changes used';

  @override
  String get brokerHomeHelloPrefix => 'Hello';

  @override
  String get brokerHomeJustNow => 'Just now';

  @override
  String get brokerHomePickupUnavailable => 'Pickup location unavailable';

  @override
  String get brokerHomeRequestAccepted => 'Request accepted';

  @override
  String get brokerHomeRequestDeclined => 'Request declined';

  @override
  String get brokerHomeSendAssignment => 'Send assignment';

  @override
  String get brokerHomeSending => 'Sending...';

  @override
  String get brokerHomeTryClearingSearch => 'Try clearing your search';

  @override
  String get brokerHomeYouAcceptedWaiting =>
      'You accepted. Waiting for the client to confirm.';

  @override
  String get brokerHomeYouOffered => 'You offered';

  @override
  String get brokerKycCompleteTitle => 'KYC complete';

  @override
  String get brokerKycContinue => 'Continue';

  @override
  String get brokerKycFinish => 'Finish';

  @override
  String get brokerKycNotAvailable => 'Not available';

  @override
  String get brokerKycNotProvided => 'Not provided';

  @override
  String get brokerKycPendingReviewStatus => 'Pending review';

  @override
  String get brokerKycSubmitKyc => 'Submit KYC';

  @override
  String get brokerKycSubmittedBadge => 'Submitted';

  @override
  String get brokerKycSubmittedDesc =>
      'Your KYC was submitted and is waiting for review.';

  @override
  String get brokerKycSubmittedTitle => 'KYC submitted';

  @override
  String get brokerKycVerifiedBadge => 'Verified';

  @override
  String get brokerKycVerifiedDesc =>
      'Your KYC is verified. You can now accept bookings.';

  @override
  String get brokerKycVerifiedStatus => 'Verified';

  @override
  String get brokerKycVerifyCarefullyWarning =>
      'Please verify all information carefully. Incorrect information may delay KYC approval.';

  @override
  String get brokerReqAcceptAssign => 'Accept & assign';

  @override
  String get brokerReqAcceptedNoCard => 'Accepted';

  @override
  String get brokerReqAcceptedPickDriver =>
      'Accepted. Pick a driver to continue.';

  @override
  String get brokerReqAssignmentTitle => 'Assign driver & truck';

  @override
  String get brokerReqAutoSelectedDetails =>
      'We selected this for you. You can change it.';

  @override
  String get brokerReqAwaitingOtherSide => 'Awaiting response';

  @override
  String get brokerReqChangeFareOrReject => 'Change fare or reject';

  @override
  String get brokerReqClientAcceptedFinalize =>
      'Client accepted. Finalise the assignment.';

  @override
  String get brokerReqConfirmAssign => 'Confirm assignment';

  @override
  String get brokerReqConfirmBookingTitle => 'Confirm booking';

  @override
  String get brokerReqCustomerFallback => 'Customer';

  @override
  String get brokerReqDeclinedNoActions =>
      'Declined. No further action needed.';

  @override
  String get brokerReqFareChangeWaiting => 'Waiting for fare change response';

  @override
  String get brokerReqGeneralFallback => 'Booking';

  @override
  String get brokerReqNoDriversFound => 'No drivers found';

  @override
  String get brokerReqNoTrucksFound => 'No trucks found';

  @override
  String get brokerReqSaving => 'Saving...';

  @override
  String get brokerReqUnavailable => 'Unavailable';

  @override
  String get changePasswordAllFieldsRequired => 'All fields are required';

  @override
  String get changePasswordConfirmHint => 'Re-enter your new password';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordCurrentHint => 'Enter your current password';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordMismatch => 'The two passwords do not match';

  @override
  String get changePasswordNewHint => 'At least 8 characters';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordScreenTitle => 'Change password';

  @override
  String get changePasswordStrengthEmptyHint =>
      'Enter a password to check its strength';

  @override
  String get changePasswordStrengthFair => 'Fair';

  @override
  String get changePasswordStrengthGood => 'Good';

  @override
  String get changePasswordStrengthLowercase => 'Add a lowercase letter';

  @override
  String get changePasswordStrengthMinLength => 'Use at least 8 characters';

  @override
  String get changePasswordStrengthNumber => 'Add a number';

  @override
  String get changePasswordStrengthStrong => 'Strong';

  @override
  String get changePasswordStrengthStrongHint => 'Great password';

  @override
  String get changePasswordStrengthSymbol => 'Add a symbol';

  @override
  String get changePasswordStrengthTitle => 'Password strength';

  @override
  String get changePasswordStrengthUppercase => 'Add an uppercase letter';

  @override
  String get changePasswordStrengthWeak => 'Weak';

  @override
  String get changePasswordSubmitButton => 'Update password';

  @override
  String get changePasswordSuccessLoggedOut =>
      'Password updated. Please sign in again.';

  @override
  String get chatAssistantName => 'Support';

  @override
  String get chatClosedChip => 'Closed';

  @override
  String get chatDetailBookingTitle => 'Booking';

  @override
  String get chatDetailClientTitle => 'Client';

  @override
  String get chatDetailDirectTitle => 'Direct message';

  @override
  String get chatDirectMessageChip => 'Direct';

  @override
  String get chatDirectMessageFallback => 'Direct conversation';

  @override
  String get chatListEmpty => 'No conversations yet';

  @override
  String get chatListLoadError => 'Could not load chats';

  @override
  String get chatListRetry => 'Try again';

  @override
  String get chatListTitle => 'Chats';

  @override
  String get chatMessageFallback => 'Message';

  @override
  String get chatMessageNotSent => 'Message not sent';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatNotConnectedChip => 'Offline';

  @override
  String get chatReadReceipt => 'Read';

  @override
  String get chatThreadLoadError => 'Could not load this conversation';

  @override
  String get chatTripClosedNotice =>
      'This trip is closed. You can still read the messages.';

  @override
  String get chatTypeMessageHint => 'Type a message';

  @override
  String get chatTypingIndicator => 'Typing...';

  @override
  String get clientAddressAddTitle => 'Add address';

  @override
  String get clientAddressEditTitle => 'Edit address';

  @override
  String get clientAddressLoading => 'Loading address';

  @override
  String get clientAddressRemoved => 'Address removed';

  @override
  String get clientBookingLoadingPointHint => 'Search for the loading point';

  @override
  String get clientBookingUnloadingPointHint =>
      'Search for the unloading point';

  @override
  String get clientBookingWeightError => 'Please enter a valid weight';

  @override
  String get clientCheckoutCancel => 'Cancel';

  @override
  String get clientCheckoutChooseMethod => 'Choose a payment method';

  @override
  String get clientCheckoutEnterPin => 'Enter 4-digit UPI PIN';

  @override
  String get clientCheckoutMethodCards => 'Card';

  @override
  String get clientCheckoutMethodNetbanking => 'Netbanking';

  @override
  String get clientCheckoutMethodRecommended => 'Recommended';

  @override
  String get clientCheckoutMethodUpi => 'UPI';

  @override
  String get clientCheckoutMethodWallet => 'Wallet';

  @override
  String get clientCheckoutTestTitle => 'Test payment';

  @override
  String get clientChooseTrucks => 'Choose trucks';

  @override
  String get clientFindingBrokers => 'Finding brokers nearby';

  @override
  String get clientHomeBookAnyTruck => 'Book any truck';

  @override
  String get clientHomeLoadingHint => 'Search loading location';

  @override
  String get clientHomeUnloadingHint => 'Search unloading location';

  @override
  String get clientNotificationsAllCaughtUp => 'You\'re all caught up';

  @override
  String get clientNotificationsAllCaughtUpHint =>
      'No new notifications right now.';

  @override
  String get clientNotificationsEmpty => 'No notifications';

  @override
  String get clientNotificationsEmptyHint =>
      'Booking updates and invoice alerts will show up here.';

  @override
  String get clientNotificationsFallbackMessage =>
      'Open your booking to see the full details.';

  @override
  String get clientNotificationsFallbackTitle => 'Booking update';

  @override
  String get clientNotificationsFilterAll => 'All';

  @override
  String get clientNotificationsFilterUnread => 'Unread';

  @override
  String get clientNotificationsGotIt => 'Got it';

  @override
  String get clientNotificationsKindBooking => 'Booking';

  @override
  String get clientNotificationsKindOffer => 'Offer';

  @override
  String get clientNotificationsKindPayment => 'Payment';

  @override
  String get clientNotificationsKindUpdate => 'Update';

  @override
  String get clientNotificationsLoadError => 'Could not load notifications';

  @override
  String get clientNotificationsMarkAllRead => 'Mark all as read';

  @override
  String get clientNotificationsMarkedRead => 'Marked as read';

  @override
  String get clientNotificationsSaving => 'Saving...';

  @override
  String get clientNotificationsTitle => 'Notifications';

  @override
  String get clientNotificationsTryAgain => 'Try again';

  @override
  String get clientPaymentAddAccountInvalid => 'Enter a valid account number';

  @override
  String get clientPaymentAddAccountLabel => 'Account number';

  @override
  String get clientPaymentAddBankLabel => 'Select your bank';

  @override
  String get clientPaymentAddBankRequired => 'Select a bank';

  @override
  String get clientPaymentAddBankSearchHint => 'Search banks';

  @override
  String get clientPaymentAddBrandLabel => 'Card brand';

  @override
  String get clientPaymentAddBrandRequired => 'Enter the card brand';

  @override
  String get clientPaymentAddCardNote =>
      'We only use this to show the card on your saved methods.';

  @override
  String get clientPaymentAddDefaultOption => 'Set as default';

  @override
  String get clientPaymentAddIfscInvalid => 'Enter a valid IFSC code';

  @override
  String get clientPaymentAddIfscLabel => 'IFSC code';

  @override
  String get clientPaymentAddLast4Label => 'Last 4 digits';

  @override
  String get clientPaymentAddLast4Required => 'Enter the last 4 digits';

  @override
  String get clientPaymentAddMethod => 'Add method';

  @override
  String get clientPaymentAddNoteLabel => 'Note';

  @override
  String get clientPaymentAddPrivacyNote =>
      'Your card details are encrypted and never shared with anyone.';

  @override
  String get clientPaymentAddSaveButton => 'Save method';

  @override
  String get clientPaymentAddSignInRequired =>
      'Please sign in to add a payment method.';

  @override
  String get clientPaymentAddTileSubtitle => 'Card, UPI, netbanking or wallet';

  @override
  String get clientPaymentAddTileTitle => 'Add a payment method';

  @override
  String get clientPaymentAddTitle => 'Add payment method';

  @override
  String get clientPaymentAddTypeLabel => 'Payment type';

  @override
  String get clientPaymentAddUpiInvalid => 'Enter a valid UPI ID';

  @override
  String get clientPaymentAddUpiLabel => 'UPI ID';

  @override
  String get clientPaymentAddWalletLabel => 'Select a wallet';

  @override
  String get clientPaymentAddWalletRequired => 'Select a wallet';

  @override
  String get clientPaymentAddWalletSearchHint => 'Search wallets';

  @override
  String get clientPaymentCardSaved => 'Card saved';

  @override
  String get clientPaymentDefaultBadge => 'Default';

  @override
  String get clientPaymentDeleteTooltip => 'Delete payment method';

  @override
  String get clientPaymentEmptySubtitle =>
      'Save a card, UPI ID or bank account for faster checkout.';

  @override
  String get clientPaymentEmptyTitle => 'No payment methods';

  @override
  String get clientPaymentLoadError => 'Could not load methods';

  @override
  String get clientPaymentLoadErrorHint => 'Please try again in a moment.';

  @override
  String get clientPaymentMethodsTitle => 'Payment methods';

  @override
  String get clientPaymentRemoved => 'Payment method removed';

  @override
  String get clientPaymentRetry => 'Retry';

  @override
  String get clientPaymentSetDefault => 'Set as default';

  @override
  String get clientPaymentSignInSubtitle =>
      'Sign in to view your saved cards, UPI IDs and bank accounts.';

  @override
  String get clientPaymentSignInTitle => 'Sign in to continue';

  @override
  String get clientPaymentTypeBank => 'Bank';

  @override
  String get clientPaymentTypeCard => 'Card';

  @override
  String get clientPaymentTypeMethod => 'Payment method';

  @override
  String get clientPaymentTypeUpi => 'UPI';

  @override
  String get clientPaymentTypeWallet => 'Wallet';

  @override
  String get clientPaymentUpiFallback => 'UPI';

  @override
  String get clientPaymentWalletFallback => 'Wallet';

  @override
  String get clientPlacesSuggestionsError => 'Could not load suggestions';

  @override
  String get clientPublicAssignedDriver => 'To be assigned';

  @override
  String get clientPublicDriverLabel => 'Driver';

  @override
  String get clientPublicDropLabel => 'Drop';

  @override
  String get clientPublicExpressSuffix => 'Express';

  @override
  String get clientPublicIncidentActive => 'Incident reported';

  @override
  String get clientPublicPickupLabel => 'Pickup';

  @override
  String get clientPublicTrackingInvalidLink =>
      'This tracking link is not valid.';

  @override
  String get clientPublicTrackingUnavailable => 'Tracking unavailable';

  @override
  String get clientPublicTruckLabel => 'Truck';

  @override
  String get clientSavedAddAddress => 'Add address';

  @override
  String get clientSavedAddressesTitle => 'Saved addresses';

  @override
  String get clientSavedEmptySubtitle =>
      'Save frequent pickup and drop-off locations for faster bookings.';

  @override
  String get clientSavedEmptyTitle => 'No saved addresses yet';

  @override
  String get clientSavedLoadError => 'Could not load addresses';

  @override
  String get clientSavedLoadErrorHint => 'Please try again in a moment.';

  @override
  String get clientSavedNoMatchSubtitle =>
      'Try a different label, area, or contact name.';

  @override
  String get clientSavedNoMatchTitle => 'No matching addresses';

  @override
  String get clientSavedRetry => 'Retry';

  @override
  String get clientSavedSearchHint => 'Search saved addresses';

  @override
  String get clientSavedSignInSubtitle =>
      'Your pickup and drop-off locations stay linked to your account.';

  @override
  String get clientSavedSignInTitle => 'Sign in to view saved addresses';

  @override
  String get clientSearchRetry => 'Retry';

  @override
  String get clientSelectVehicle => 'Select a vehicle';

  @override
  String get clientTrackingGpsPending => 'Waiting for GPS';

  @override
  String get clientTrackingLivePendingSubtitle =>
      'The vehicle location will appear here as soon as it starts moving.';

  @override
  String get clientTrackingLivePendingTitle => 'Live location pending';

  @override
  String get clientTrackingLivePosition => 'Live position';

  @override
  String get clientTrackingLoading => 'Loading';

  @override
  String get clientTrackingMapEmptyHint =>
      'Live tracking will appear on the map.';

  @override
  String get clientTrackingMapLoading => 'Loading the map...';

  @override
  String get clientTrackingPayNow => 'Pay now';

  @override
  String get clientTrackingPayRemaining => 'Pay remaining';

  @override
  String get clientTrackingRateDelivery => 'Rate delivery';

  @override
  String get clientTrackingSubmitting => 'Submitting...';

  @override
  String get clientTrackingUnloading => 'Unloading';

  @override
  String get clientVehicleSelected => 'Selected';

  @override
  String get coreDigilockerAadhaarFallbackNote =>
      'DigiLocker could not read this Aadhaar. Enter the number manually.';

  @override
  String get coreDigilockerBankAccountHint => 'Bank account number';

  @override
  String get coreDigilockerBrokerIntro =>
      'Verify your PAN, Aadhaar and business documents to receive bookings.';

  @override
  String get coreDigilockerBusinessDetails => 'Business details';

  @override
  String get coreDigilockerBusinessRegHint => 'Business registration number';

  @override
  String get coreDigilockerCheckStatus => 'Check status';

  @override
  String get coreDigilockerChecking => 'Checking...';

  @override
  String get coreDigilockerDidntMatch =>
      'These details did not match your DigiLocker records.';

  @override
  String get coreDigilockerDocAadhaar => 'Aadhaar';

  @override
  String get coreDigilockerDocLicense => 'Driving licence';

  @override
  String get coreDigilockerDocPan => 'PAN card';

  @override
  String get coreDigilockerDriverIntro =>
      'Verify your PAN, Aadhaar and licence to start receiving trips.';

  @override
  String get coreDigilockerGstHint => 'GST number';

  @override
  String get coreDigilockerInfoNote =>
      'DigiLocker fetches your documents securely from the government portal.';

  @override
  String get coreDigilockerNoLoginLink =>
      'No DigiLocker login available. Please sign in and try again.';

  @override
  String get coreDigilockerNotComplete => 'Verification incomplete';

  @override
  String get coreDigilockerNotFound => 'No document found';

  @override
  String get coreDigilockerNotVerifiedYet => 'Not verified yet';

  @override
  String get coreDigilockerOpenBrowserFailed =>
      'Could not open your browser for DigiLocker.';

  @override
  String get coreDigilockerOptionalNote => 'Optional';

  @override
  String get coreDigilockerPendingRetry =>
      'Verification is still pending. Please try again in a moment.';

  @override
  String get coreDigilockerUnreachable => 'DigiLocker is unreachable right now';

  @override
  String get coreDigilockerVehicleDetails => 'Vehicle details';

  @override
  String get coreDigilockerVehicleInsuranceHint => 'Vehicle insurance number';

  @override
  String get coreDigilockerVehicleRegHint => 'Vehicle registration number';

  @override
  String get coreDigilockerVerified => 'Verified';

  @override
  String get coreDigilockerVerifyButton => 'Verify with DigiLocker';

  @override
  String get coreDigilockerVerifyLicense => 'Verify driving licence';

  @override
  String get coreDigilockerVerifyPan => 'Verify PAN';

  @override
  String get coreDigilockerWorking => 'Working...';

  @override
  String get coreKycCompleteAction => 'Complete KYC';

  @override
  String get coreKycIncompleteBody =>
      'Finish verifying your documents to book and accept trips.';

  @override
  String get coreKycIncompleteTitle => 'Complete your KYC';

  @override
  String get coreKycNotNow => 'Not now';

  @override
  String get coreKycRejectedBody =>
      'Our team could not verify your documents. Please check them and submit again.';

  @override
  String get coreKycRejectedTitle => 'KYC rejected';

  @override
  String get coreKycResubmitAction => 'Submit again';

  @override
  String get coreKycUnderReviewBody =>
      'We are reviewing your documents. This usually takes 24-48 hours.';

  @override
  String get coreKycUnderReviewTitle => 'KYC under review';

  @override
  String get coreKycViewStatusAction => 'View status';

  @override
  String get coreMapDropTitle => 'Drop';

  @override
  String get coreMapExpressLabel => 'Express';

  @override
  String get coreMapPickupTitle => 'Pickup';

  @override
  String get coreMapRouteNotFound => 'Route not found';

  @override
  String get deliveryFlowChoosePhoto => 'Choose photo';

  @override
  String get deliveryFlowCompany => 'Company';

  @override
  String get deliveryFlowContactUnavailable => 'Contact unavailable';

  @override
  String get deliveryFlowMaxItems => 'You can upload up to 5 photos.';

  @override
  String get deliveryFlowMyQr => 'My QR';

  @override
  String get deliveryFlowPersonal => 'Personal';

  @override
  String get deliveryFlowPhotosUploaded => 'Photos uploaded';

  @override
  String get deliveryFlowRecordVideo => 'Record video';

  @override
  String get deliveryFlowSignInContinue => 'Please sign in to continue.';

  @override
  String get deliveryFlowSignInUploadPhotos =>
      'Please sign in to upload photos.';

  @override
  String get deliveryFlowTakePhoto => 'Take photo';

  @override
  String get deliveryFlowVerified => 'Verified';

  @override
  String get driverEarningsCurrentBalance => 'Current balance';

  @override
  String get driverEarningsLastMonth => 'Last month';

  @override
  String get driverEarningsNoDeliveries => 'No deliveries yet';

  @override
  String get driverEarningsReadyPayout => 'Ready for payout';

  @override
  String get driverEarningsThisMonth => 'This month';

  @override
  String get driverEarningsTrips => 'Trips';

  @override
  String get driverEarningsViewAll => 'View all';

  @override
  String get driverHomeTripAccepted => 'Trip accepted';

  @override
  String get driverHomeTripDeclined => 'Trip declined';

  @override
  String get driverKycEdit => 'Edit';

  @override
  String get driverKycPickFailed =>
      'Could not open this right now. Please try again.';

  @override
  String get driverKycSignInToSubmit => 'Please sign in to submit your KYC.';

  @override
  String get driverKycSignInToUpload => 'Please sign in to upload documents.';

  @override
  String get driverKycView => 'View';

  @override
  String get driverPaymentCompany => 'Company';

  @override
  String get driverPaymentPersonal => 'Personal';

  @override
  String get driverPaymentQrUploaded => 'QR uploaded';

  @override
  String get driverPaymentSignInRecord =>
      'Please sign in to record this payment.';

  @override
  String get driverPaymentSignInUploadQr =>
      'Please sign in to upload your payment QR.';

  @override
  String get driverPaymentVerified => 'Verified';

  @override
  String get gpsAbout => 'About';

  @override
  String get gpsAboutSubtitle => 'Version, licences and app details';

  @override
  String get gpsAccountDetails => 'Account details';

  @override
  String get gpsAccountDetailsSubtitle => 'Manage your account information';

  @override
  String get gpsAccountSection => 'Account';

  @override
  String get gpsActive => 'Active';

  @override
  String get gpsAllFleet => 'Entire fleet';

  @override
  String get gpsAllVehiclesLiveMap => 'All vehicles on live map';

  @override
  String get gpsAppearance => 'Appearance';

  @override
  String get gpsAppearanceSubtitle => 'Light, dark or follow your device';

  @override
  String get gpsBackToFleet => 'Back to fleet';

  @override
  String get gpsCached => 'Cached';

  @override
  String get gpsChangePassword => 'Change password';

  @override
  String get gpsChangePasswordSubtitle => 'Update your account password';

  @override
  String get gpsCompleted => 'Completed';

  @override
  String get gpsCreateGeofence => 'Create geofence';

  @override
  String get gpsCustom => 'Custom';

  @override
  String get gpsDashboardWelcome => 'Welcome back';

  @override
  String get gpsDeducted => 'Deducted';

  @override
  String get gpsDefineZones => 'Define zones';

  @override
  String get gpsDuration => 'Duration';

  @override
  String get gpsDurationSubtitle => 'Time spent driving or idling';

  @override
  String get gpsExpired => 'Expired';

  @override
  String get gpsExpiredTokensRemoved => 'Expired tokens were removed';

  @override
  String get gpsFilter => 'Filter';

  @override
  String get gpsFilterAll => 'All';

  @override
  String get gpsFleet => 'Fleet';

  @override
  String get gpsFleetStatus => 'Fleet status';

  @override
  String get gpsFrom => 'From';

  @override
  String get gpsFuelSummary => 'Fuel summary';

  @override
  String get gpsGenerateReport => 'Generate report';

  @override
  String get gpsGeofences => 'Geofences';

  @override
  String get gpsGeofencesSubtitle => 'Automatic alerts on entry and exit';

  @override
  String get gpsHelpSupport => 'Help & support';

  @override
  String get gpsHelpSupportSubtitle => 'Get help or contact our team';

  @override
  String get gpsInvoices => 'Invoices';

  @override
  String get gpsList => 'List';

  @override
  String get gpsLiveFleetTracking => 'Live fleet tracking';

  @override
  String get gpsLiveMap => 'Live map';

  @override
  String get gpsLiveTrackingUnavailableFleet =>
      'Live tracking is unavailable for this fleet.';

  @override
  String get gpsLogout => 'Log out';

  @override
  String get gpsLogoutSubtitle => 'Sign out of this device';

  @override
  String get gpsMap => 'Map';

  @override
  String get gpsModules => 'Modules';

  @override
  String get gpsMonthlyPlan => 'Monthly plan';

  @override
  String get gpsMyFleet => 'My fleet';

  @override
  String get gpsMyVehicles => 'My vehicles';

  @override
  String get gpsMyVehiclesSubtitle => 'Devices linked to your account';

  @override
  String get gpsNavDashboard => 'Dashboard';

  @override
  String get gpsNavProfile => 'Profile';

  @override
  String get gpsNavReports => 'Reports';

  @override
  String get gpsNavVehicles => 'Vehicles';

  @override
  String get gpsNoData => 'No data';

  @override
  String get gpsNoGeofencesSubtitle =>
      'Create a geofence to get alerts when a vehicle enters or leaves a zone.';

  @override
  String get gpsNoGeofencesYet => 'No geofences yet';

  @override
  String get gpsNoMoreTransactions => 'No more transactions';

  @override
  String get gpsNotifications => 'Notifications';

  @override
  String get gpsNotificationsSubtitle => 'Alerts about your vehicles';

  @override
  String get gpsOffline => 'Offline';

  @override
  String get gpsOnline => 'Online';

  @override
  String get gpsProfileSubtitle => 'Manage your account and preferences';

  @override
  String get gpsRecentActivity => 'Recent activity';

  @override
  String get gpsReportType => 'Report type';

  @override
  String get gpsReportTypeSubtitle => 'Choose what you want to review';

  @override
  String get gpsReportsSecureNote =>
      'Reports are generated from your account data and stay private.';

  @override
  String get gpsReportsSubtitle => 'Track usage, routes and costs over time';

  @override
  String get gpsRetry => 'Try again';

  @override
  String get gpsRouteHistory => 'Route history';

  @override
  String get gpsRunning => 'Running';

  @override
  String get gpsSearchGeofences => 'Search geofences';

  @override
  String get gpsSearchTransactions => 'Search transactions';

  @override
  String get gpsSearchVehiclesHint => 'Search by number or name';

  @override
  String get gpsSelectFromFleet => 'Select from your fleet';

  @override
  String get gpsSelectVehicle => 'Select vehicle';

  @override
  String get gpsSelectVehicleOrFleet =>
      'Pick a single vehicle or the whole fleet';

  @override
  String get gpsSettings => 'Settings';

  @override
  String get gpsSettingsSubtitle => 'Configure your tracking preferences';

  @override
  String get gpsSignInForFleetDevices =>
      'Please sign in to view your fleet devices.';

  @override
  String get gpsSignInForLiveFleet => 'Please sign in to view the live fleet.';

  @override
  String get gpsSignInForVehicle => 'Please sign in to view this vehicle.';

  @override
  String get gpsStopped => 'Stopped';

  @override
  String get gpsSubscriptionPayment => 'Subscription payment';

  @override
  String get gpsThisWeek => 'This week';

  @override
  String get gpsTimeEightMinsAgo => '8 min ago';

  @override
  String get gpsTimeTwoMinsAgo => '2 min ago';

  @override
  String get gpsTo => 'To';

  @override
  String get gpsToday => 'Today';

  @override
  String get gpsTokenBalance => 'Token balance';

  @override
  String get gpsTokenExpiry => 'Token expiry';

  @override
  String get gpsTokenPurchase => 'Token purchase';

  @override
  String get gpsTokens => 'Tokens';

  @override
  String get gpsTokensAdded => 'Tokens added';

  @override
  String get gpsTotalVehicles => 'Total vehicles';

  @override
  String get gpsTotalVehiclesCenter => 'Vehicles reporting location';

  @override
  String get gpsTransactions => 'Transactions';

  @override
  String get gpsTripSummary => 'Trip summary';

  @override
  String get gpsUsageSummary => 'Usage summary';

  @override
  String get gpsVehicle => 'Vehicle';

  @override
  String get gpsVehicleLiveMap => 'Vehicle live map';

  @override
  String get gpsVehicleNotFound => 'Vehicle not found';

  @override
  String get gpsViaRazorpay => 'Via Razorpay';

  @override
  String get gpsViewAll => 'View all';

  @override
  String get gpsVsLastWeek => 'vs last week';

  @override
  String get gpsWalletBilling => 'Wallet & billing';

  @override
  String get gpsWelcomeBonus => 'Welcome bonus';

  @override
  String get gpsYesterday => 'Yesterday';

  @override
  String get historyDetailsCancel => 'Cancel';

  @override
  String get historyDetailsEmailInvoice => 'Email invoice';

  @override
  String get historyDetailsRetry => 'Try again';

  @override
  String get historyDetailsSend => 'Send';

  @override
  String get historySegmentCompleted => 'Completed';

  @override
  String get historySegmentPending => 'Pending';

  @override
  String get locationFlowAddLoading => 'Add loading point';

  @override
  String get locationFlowAddLoadingHint => 'Where should the goods be loaded?';

  @override
  String get locationFlowAddUnloading => 'Add unloading point';

  @override
  String get locationFlowAddUnloadingHint =>
      'Where should the goods be delivered?';

  @override
  String get locationFlowDropHint => 'Search the drop location';

  @override
  String get locationFlowDropSubtitle => 'Where is the goods going?';

  @override
  String get locationFlowDropTitle => 'Drop location';

  @override
  String get locationFlowFetching => 'Finding your location...';

  @override
  String get locationFlowMovePin => 'Move the pin to adjust the point';

  @override
  String get locationFlowOwnUnavailable =>
      'We could not read your current location.';

  @override
  String get locationFlowPermissionNeeded =>
      'Location permission is needed to continue.';

  @override
  String get locationFlowPickupHint => 'Search the pickup location';

  @override
  String get locationFlowPickupSubtitle => 'Where is the goods coming from?';

  @override
  String get locationFlowPickupTitle => 'Pickup location';

  @override
  String get locationFlowPinHint => 'Drag the pin to the exact spot';

  @override
  String get locationFlowPinLoading => 'Place loading pin';

  @override
  String get locationFlowPinUnloading => 'Place drop pin';

  @override
  String get locationFlowResolveCurrent =>
      'We could not determine your current location.';

  @override
  String get locationFlowResolvePoint =>
      'We could not locate that point on the map.';

  @override
  String get locationFlowSavedTitle => 'Location saved';

  @override
  String get locationFlowSuggestionsError =>
      'Could not load location suggestions';

  @override
  String get locationFlowTurnOnLocation => 'Please turn on location services.';

  @override
  String get locationFlowUseCurrent => 'Use current location';

  @override
  String get locationFlowUseCurrentPickup => 'Use my current location';

  @override
  String get manageAccountActiveLabel => 'Active';

  @override
  String get manageAccountActiveNo => 'No';

  @override
  String get manageAccountActiveYes => 'Yes';

  @override
  String get manageAccountBasicDetails => 'Basic details';

  @override
  String get manageAccountBusinessAddressLabel => 'Business address';

  @override
  String get manageAccountBusinessDetails => 'Business details';

  @override
  String get manageAccountChangePhoto => 'Change photo';

  @override
  String get manageAccountEditProfileSubtitle =>
      'Update your name, email, phone and photo';

  @override
  String get manageAccountEditProfileTitle => 'Edit profile';

  @override
  String get manageAccountEmailLabel => 'Email';

  @override
  String get manageAccountEnterEmail => 'Enter your email';

  @override
  String get manageAccountEnterName => 'Enter your name';

  @override
  String get manageAccountEnterServiceCity => 'Enter your service city';

  @override
  String get manageAccountEnterValidEmail => 'Enter a valid email address';

  @override
  String get manageAccountFullNameLabel => 'Full name';

  @override
  String get manageAccountOptionalTag => 'Optional';

  @override
  String get manageAccountPhoneLabel => 'Phone';

  @override
  String get manageAccountProfileUpdated => 'Profile Updated';

  @override
  String get manageAccountSaveChanges => 'Save changes';

  @override
  String get manageAccountServiceCityLabel => 'Service city';

  @override
  String get manageAccountYourNameFallback => 'Your name';

  @override
  String get negotiationAccept => 'Accept';

  @override
  String get negotiationBack => 'Back';

  @override
  String get negotiationBrokerConfirmBody =>
      'Waiting for the broker to confirm the new fare.';

  @override
  String get negotiationBrokerConfirmTitle => 'Confirming with broker';

  @override
  String get negotiationBrokerOfferBody =>
      'The broker has sent a revised fare. Review it below.';

  @override
  String get negotiationBrokerOfferLabel => 'Broker\'s offer';

  @override
  String get negotiationBrokerOfferTitle => 'New offer from broker';

  @override
  String get negotiationConfirm => 'Confirm';

  @override
  String get negotiationDecline => 'Decline';

  @override
  String get negotiationDriverAcceptedTitle => 'Driver accepted';

  @override
  String get negotiationDriverConfirmBody =>
      'Waiting for the driver to confirm the new fare.';

  @override
  String get negotiationDriverConfirmNowTitle => 'Confirm with driver';

  @override
  String get negotiationDriverFallback => 'Driver';

  @override
  String get negotiationDriverResponseBody =>
      'The driver has responded to your fare change.';

  @override
  String get negotiationDriverResponseTitle => 'Driver responded';

  @override
  String get negotiationFareChangeBody =>
      'We have sent your new fare. Waiting for a response.';

  @override
  String get negotiationFareChangeTitle => 'Fare change sent';

  @override
  String get negotiationHandshakeProgress =>
      'Both sides are confirming the new fare';

  @override
  String get negotiationOfferCaption => 'Fare for this booking';

  @override
  String get negotiationOfferSentBody =>
      'Your offer has been sent. Waiting for the other side.';

  @override
  String get negotiationOfferSentTitle => 'Offer sent';

  @override
  String get negotiationPillActionNeeded => 'Action needed';

  @override
  String get negotiationPillLiveOffer => 'Live offer';

  @override
  String get negotiationPillNewCounter => 'New counter offer';

  @override
  String get negotiationPillWithBroker => 'With broker';

  @override
  String get negotiationWaitingBrokerBody =>
      'We have sent your fare. Waiting for the broker to respond.';

  @override
  String get negotiationWaitingBrokerTitle => 'Waiting for broker';

  @override
  String get negotiationWaitingDriverBody =>
      'We have sent the new fare to the driver.';

  @override
  String get negotiationWaitingDriverTitle => 'Waiting for driver';

  @override
  String get onboardingFastSubtitle =>
      'Payments, invoices, and updates stay in one place.';

  @override
  String get onboardingFastTitle => 'Fast settlements';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSafeSubtitle =>
      'Book verified trucks and drivers with confidence.';

  @override
  String get onboardingSafeTitle => 'Safe bookings';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingTrackingSubtitle =>
      'Track every shipment from pickup to delivery.';

  @override
  String get onboardingTrackingTitle => 'Live tracking';

  @override
  String get orderAcceptedAssignedTitle => 'Trip assigned';

  @override
  String get orderAcceptedOfferUnavailable =>
      'This offer is no longer available.';

  @override
  String get orderAcceptedRequestTitle => 'New request';

  @override
  String get orderAcceptedRequestUpdated =>
      'This request was updated. Pull down to refresh.';

  @override
  String get orderAcceptedSignInContinue => 'Please sign in to continue.';

  @override
  String get photoUploadChoosePhoto => 'Choose photo';

  @override
  String get photoUploadMaxItems => 'You can upload up to 5 photos.';

  @override
  String get photoUploadRecordVideo => 'Record video';

  @override
  String get photoUploadSignInUpload => 'Please sign in to upload photos.';

  @override
  String get photoUploadTakePhoto => 'Take photo';

  @override
  String get podWaitingCouldNotComplete => 'Could not complete';

  @override
  String get podWaitingFinishing => 'Finishing up...';

  @override
  String get podWaitingNewPhotosFallback => 'New delivery photos';

  @override
  String get podWaitingPhotosUp => 'Uploading photos...';

  @override
  String get podWaitingRejectedTitle => 'Proof of delivery rejected';

  @override
  String get podWaitingTitle => 'Proof of delivery';

  @override
  String get podWaitingTryAgain => 'Try again';

  @override
  String get podWaitingUploadNew => 'Upload new photos';

  @override
  String get podWaitingWaitingReview => 'Waiting for review';

  @override
  String get sessionExpiredEmailHint => 'you@example.com';

  @override
  String get sessionExpiredEmailLabel => 'Email';

  @override
  String get sessionExpiredEnterEmailPassword =>
      'Enter your email and password to continue.';

  @override
  String get sessionExpiredPasswordHint => 'Enter your password';

  @override
  String get sessionExpiredPasswordLabel => 'Password';

  @override
  String get sessionExpiredSignInButton => 'Sign in';

  @override
  String get sessionExpiredSubtitle =>
      'Sign in again to pick up where you left off.';

  @override
  String get sessionExpiredTitle => 'Session expired';

  @override
  String get sharedExpressLabel => 'Express';

  @override
  String get sharedHaltingChargeApplied => 'Halting charge applied';

  @override
  String get sharedHaltingExceededTitle => 'Free time exceeded';

  @override
  String get sharedHaltingFreeWindowTitle => 'Free waiting time';

  @override
  String get sharedHaltingRemainingTitle => 'Time remaining';

  @override
  String get signupAccountCreated => 'Your account has been created.';

  @override
  String get signupAgreeTerms => 'I agree to the Terms and Privacy Policy';

  @override
  String get signupAllFieldsRequired => 'All fields are required';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account?';

  @override
  String get signupBackToLogin => 'Back to login';

  @override
  String get signupCreateAccount => 'Create account';

  @override
  String get signupEmailHint => 'you@example.com';

  @override
  String get signupEmailLabel => 'Email';

  @override
  String get signupFullNameHint => 'Enter your full name';

  @override
  String get signupFullNameLabel => 'Full name';

  @override
  String get signupLoginAction => 'Log in';

  @override
  String get signupPasswordHelper => 'Use at least 8 characters';

  @override
  String get signupPasswordHint => 'At least 8 characters';

  @override
  String get signupPasswordLabel => 'Password';

  @override
  String get signupPhoneHint => '10-digit mobile number';

  @override
  String get signupPhoneLabel => 'Phone';

  @override
  String get signupSubtitle => 'Create your account to start booking';

  @override
  String get signupTermsRequired => 'Please accept the terms to continue.';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get thankYouBackToTrips => 'Back to trips';

  @override
  String get thankYouDeliveryComplete => 'Delivery complete';

  @override
  String get thankYouForCompleting => 'for completing this delivery';

  @override
  String get thankYouPaid => 'Paid';

  @override
  String get thankYouTripCompleted => 'Trip completed';

  @override
  String get tripSummaryCargo => 'Cargo';

  @override
  String get tripSummaryDelivered => 'Delivered';

  @override
  String get tripSummaryInProgress => 'In progress';

  @override
  String get tripSummaryLocationUnavailable => 'Location unavailable';

  @override
  String get truckSearchAllDeclinedHint =>
      'Nearby drivers declined. Try widening your search radius.';

  @override
  String get truckSearchBack => 'Back';

  @override
  String get truckSearchCancel => 'Cancel search';

  @override
  String get truckSearchCloseTooltip => 'Close';

  @override
  String get truckSearchConfirmTurn => 'Confirming your acceptance';

  @override
  String get truckSearchConfirmed => 'Confirmed';

  @override
  String get truckSearchDriverFallback => 'Driver';

  @override
  String get truckSearchFindingDrivers => 'Finding drivers';

  @override
  String get truckSearchFindingNearby => 'Looking for drivers near your pickup';

  @override
  String get truckSearchGoBack => 'Go back';

  @override
  String get truckSearchKeepSearching => 'Keep searching';

  @override
  String get truckSearchNewFare => 'New fare received';

  @override
  String get truckSearchNoDriverAccepted => 'No driver accepted yet';

  @override
  String get truckSearchNoResponse => 'No response';

  @override
  String get truckSearchNotifyingDrivers => 'Notifying drivers nearby';

  @override
  String get truckSearchRetry => 'Try again';

  @override
  String get truckSearchSearching => 'Searching';

  @override
  String get truckSearchWaitingConfirm => 'Waiting for confirmation';

  @override
  String get truckSearchWaitingResponse => 'Waiting for responses';

  @override
  String get negotiationContinuePrice => 'Continue price';

  @override
  String get negotiationCancel => 'Cancel';

  @override
  String get negotiationSend => 'Send';

  @override
  String get negotiationReject => 'Reject';

  @override
  String get negotiationChangeFare => 'Change fare';

  @override
  String negotiationReviewPriceFor(Object truck) {
    return 'Review price for $truck';
  }

  @override
  String get negotiationOfferPrice => 'Offer price';

  @override
  String get driverKycReviewYourInformation => 'Review Your Information';

  @override
  String get driverKycPleaseVerifyEverythingBeforeSubmitting =>
      'Please verify everything before submitting.';

  @override
  String get driverKycDriverInformation => 'Driver Information';

  @override
  String get driverKycPANNumber => 'PAN Number';

  @override
  String get driverKycDateOfBirth => 'Date of Birth';

  @override
  String get driverKycLicenseNumber => 'License Number';

  @override
  String get driverKycAadhaarNumber => 'Aadhaar Number';

  @override
  String get driverKycVehicleRegistrationNumber =>
      'Vehicle Registration Number';

  @override
  String get driverKycVehicleInsuranceNumber => 'Vehicle Insurance Number';

  @override
  String get driverKycNotProvided => 'Not provided';

  @override
  String get driverKycUploadedDocuments => 'Uploaded Documents';

  @override
  String get driverKycVerificationDetails => 'Verification Details';

  @override
  String get driverKycCurrentStatus => 'Current Status';

  @override
  String get driverKycSubmittedDate => 'Submitted Date';

  @override
  String get driverKycSubmissionID => 'Submission ID';

  @override
  String get driverKycReviewedAt => 'Reviewed At';

  @override
  String get driverKycNotAvailable => 'Not available';

  @override
  String get driverKycDrivingLicense => 'Driving License';

  @override
  String get driverKycVehicleRegShort => 'Vehicle Reg.';

  @override
  String get driverKycInsurance => 'Insurance';

  @override
  String get driverKycChooseHowYouWantToUploadThisDocument =>
      'Choose how you want to upload this document.';

  @override
  String get driverKycCamera => 'Camera';

  @override
  String get driverKycGallery => 'Gallery';

  @override
  String get driverKycCancel => 'Cancel';

  @override
  String get driverKycDocumentPreview => 'Document preview';

  @override
  String get driverKycUploadedFile => 'Uploaded file';

  @override
  String get driverKycUpload => 'Upload';

  @override
  String get driverKycClose => 'Close';

  @override
  String get driverKycStepDetails => 'Details';

  @override
  String get driverKycStepDocuments => 'Documents';

  @override
  String get driverKycStepReview => 'Review';

  @override
  String get driverKycStepSubmit => 'Submit';

  @override
  String get driverKycVerifiedTitle => 'KYC Verified';

  @override
  String get driverKycVerifiedSubtitle =>
      'Your driver account is verified and active.';

  @override
  String get driverKycVerifiedBadge => 'VERIFIED';

  @override
  String get driverKycRejectedTitle => 'KYC Rejected';

  @override
  String get driverKycRejectedSubtitle =>
      'Review the reason below and resubmit your documents.';

  @override
  String get driverKycRejectedBadge => 'REJECTED';

  @override
  String get driverKycUnderReviewTitle => 'KYC Under Review';

  @override
  String get driverKycUnderReviewSubtitle =>
      'Documents submitted successfully. Review usually takes 24-48 hours.';

  @override
  String get driverKycSubmittedBadge => 'SUBMITTED';

  @override
  String get driverKycCompleteTitle => 'Complete Driver KYC';

  @override
  String get driverKycCompleteSubtitle =>
      'Submit your identity and vehicle documents for verification.';

  @override
  String get driverKycPendingBadge => 'PENDING';

  @override
  String get driverKycPanCard => 'PAN Card';

  @override
  String get driverKycAadhaarCard => 'Aadhaar Card';

  @override
  String get driverKycUploaded => 'Uploaded';

  @override
  String get driverKycRequired => 'Required';

  @override
  String driverKycSupportedFormats(Object formats) {
    return 'Supported formats: $formats';
  }

  @override
  String get driverKycMaxSize10Mb => 'Max 10 MB';

  @override
  String driverKycDocumentPhoto(Object document) {
    return '$document Photo';
  }

  @override
  String get driverKycNotUploaded => 'Not uploaded';

  @override
  String get driverKycWaitingForUpload => 'Waiting for upload';

  @override
  String get clientSavedAddNewAddress => 'Add New Address';

  @override
  String get clientSavedPickupOrDropoffLocation =>
      'Pickup or Drop-off Location';

  @override
  String get clientSavedAddressNameRequired =>
      'Give this address a name, such as Home or Warehouse.';

  @override
  String get clientSavedAddressRequired =>
      'Search and select an address from Google Maps.';

  @override
  String clientSavedPinnedLocation(Object latitude, Object longitude) {
    return 'Pinned location ($latitude, $longitude)';
  }

  @override
  String get clientSavedLabelHint => 'Home, Office, Warehouse 2';

  @override
  String get clientSavedUseCurrent => 'Use current';

  @override
  String get clientSavedSearchOrTapMap => 'Search, or tap the map...';

  @override
  String get clientSavedFloorHint => '3rd Floor, Flat 402, Gate 2';

  @override
  String get clientSavedOnSiteContact => 'On-site Contact';

  @override
  String get clientSavedOptional => '(optional)';

  @override
  String get clientSavedContactNameHint => 'Contact name';

  @override
  String get clientSavedUse => 'Use';

  @override
  String get historyDetailsTo => 'To';

  @override
  String get historyDetailsEmailHint => 'recipient@example.com';

  @override
  String get historyDetailsBookingTime => 'Booking time';

  @override
  String get historyDetailsExpectedDelivery => 'Expected delivery';

  @override
  String get historyDetailsDeliveredOn => 'Delivered on';

  @override
  String get historyDetailsDistanceTravelled => 'Distance travelled';

  @override
  String get historyDetailsSaving => 'Saving...';

  @override
  String get historyDetailsInvoice => 'Invoice';

  @override
  String get historyDetailsSending => 'Sending...';

  @override
  String get historyDetailsEmail => 'Email';

  @override
  String get historyDetailsNotify => 'Notify';

  @override
  String deliveryFlowShowThisToCollect(Object amount) {
    return 'Show this to collect $amount';
  }

  @override
  String deliveryFlowScanToPayViaUpi(Object amount) {
    return 'Scan to pay $amount via any UPI app';
  }

  @override
  String get deliveryFlowAddUpiIdForQr =>
      'Add your UPI ID in Profile to show a scannable payment QR here next time.';

  @override
  String get deliveryFlowPaymentReceivedViaUpi => 'Payment Received via UPI';

  @override
  String get deliveryFlowRecording => 'Recording...';

  @override
  String get deliveryFlowCollectCash => 'Collect Cash';

  @override
  String get deliveryFlowPaymentVerifiedByRazorpay =>
      'Payment verified by Razorpay';

  @override
  String get deliveryFlowQrGenerationFailed =>
      'Couldn\'t generate the verified QR code - collect via UPI ID or cash instead.';

  @override
  String get deliveryFlowRazorpayAutoConfirms =>
      'Auto-confirms the moment Razorpay verifies the payment';

  @override
  String get negotiationAcceptedWaitingDriverConfirm =>
      'Accepted - waiting for the driver to confirm.';

  @override
  String get loadingPoint => 'Loading point';

  @override
  String get unloadingPoint => 'Unloading point';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  String get emailRecipientHint => 'recipient@example.com';

  @override
  String get addMoreDetailOptional => 'Add more detail (optional)';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get brokerStatusAccepted => 'Accepted';

  @override
  String get brokerStatusAcceptedBookingConfirmed =>
      'Accepted - booking confirmed';

  @override
  String get brokerStatusFareChanged => 'Fare changed';

  @override
  String get brokerStatusFareChangedWaiting =>
      'Fare changed - waiting for the next response';

  @override
  String get brokerStatusAwaitingConfirmation => 'Awaiting confirmation';

  @override
  String get brokerStatusWaitingOtherSideConfirm =>
      'Waiting for the other side to confirm.';

  @override
  String get brokerStatusDeclined => 'Declined';

  @override
  String get brokerStatusDeclinedUnavailable =>
      'Declined - no longer available';

  @override
  String get brokerStatusPending => 'Pending';

  @override
  String get brokerStatusReviewRequest => 'Review request';

  @override
  String get brokerStatusCancelled => 'Cancelled';

  @override
  String get brokerReqAcceptedAssignDriverTruck =>
      'This request has been accepted. Assign a driver and truck.';

  @override
  String get brokerReqFareChangeWaitingClient =>
      'Fare change sent. Waiting for the client to respond.';

  @override
  String get brokerReqCancelledNoActions =>
      'This booking has been cancelled. No further broker actions are available.';

  @override
  String get brokerReqPendingAction =>
      'This request is still waiting for action.';

  @override
  String get brokerSettlementsFee => 'Fee';

  @override
  String get brokerSettlementsNet => 'Net';

  @override
  String get pickupLocation => 'Pickup location';

  @override
  String get dropLocation => 'Drop location';

  @override
  String get vehicleSmallTruck => 'Small truck';

  @override
  String get vehicleMediumTruck => 'Medium truck';

  @override
  String get vehicleBigTruck => 'Big truck';

  @override
  String get vehicleTruckPooling => 'Truck pooling';

  @override
  String get historyDetailsTripDetails => 'Trip details';

  @override
  String get historyDetailsEarnings => 'Earnings';

  @override
  String get historyDetailsOpenInMaps => 'Open in Maps';

  @override
  String get historyDetailsMissingBookingId => 'Missing booking id.';

  @override
  String get historyDetailsSignInToView =>
      'Please sign in again to view delivery details.';

  @override
  String get historyDetailsLoadFailed => 'Unable to load delivery details.';

  @override
  String get historyDetailsSignInToDownload =>
      'Please sign in again to download the invoice.';

  @override
  String get historyDetailsSignInToEmail =>
      'Please sign in again to email the invoice.';

  @override
  String get historyDetailsSignInToNotify =>
      'Please sign in again to notify the client.';

  @override
  String historyDetailsEmailBody(Object bookingRef) {
    return 'Please find attached the invoice for booking $bookingRef.';
  }

  @override
  String get historyDetailsPreviousDriver => 'Previous driver';

  @override
  String get historyDetailsNewDriver => 'New driver';

  @override
  String historyDetailsDriverChanged(Object count) {
    return 'Driver changed ($count)';
  }

  @override
  String deliveryDetailsStopLabel(Object stop) {
    return '$stop point';
  }

  @override
  String get deliveryDetailsStopsTitle => 'Loading & unloading stops';

  @override
  String get deliveryDetailsConfirmDropReached =>
      'Confirm when you have reached the drop point.';

  @override
  String get deliveryDetailsLoadingEllipsis => 'Loading...';

  @override
  String get deliveryDetailsEnterPickupCode => 'Enter pickup code';

  @override
  String get deliveryDetailsConfirmPickup => 'Confirm pickup';

  @override
  String get deliveryDetailsOpenPickupInMaps => 'Open pickup in Google Maps';

  @override
  String get deliveryDetailsOpenDropInMaps => 'Open drop in Google Maps';

  @override
  String get deliveryDetailsDropLocationMissing => 'Drop location not provided';

  @override
  String get deliveryDetailsSignInToContinue =>
      'Please sign in again to continue.';

  @override
  String get driverKycUploadDocumentsTitle => 'Upload documents';

  @override
  String get driverKycUploadDocumentsSubtitle =>
      'Upload clear photos of the following documents.';

  @override
  String get driverKycVerifyIdentityTitle => 'Verify your identity';

  @override
  String get driverKycRequiredBadge => 'Required';

  @override
  String get driverKycNoActiveSession => 'No active session found.';

  @override
  String get driverKycConfirmAccuracy =>
      'Please confirm that all information is accurate.';

  @override
  String get driverKycSubmittedDocuments => 'Submitted documents';

  @override
  String get driverKycVerifyCarefully =>
      'Please verify all information carefully. Incorrect information may delay KYC approval.';

  @override
  String get driverKycSubmitForReview => 'Submit for review';

  @override
  String get driverKycSourceLabelSubmittedUrl => 'Submitted URL';

  @override
  String get addVehicleInsuranceExpiryHelp => 'Select insurance expiry date';

  @override
  String get addVehicleEditTruckTitle => 'Edit truck';

  @override
  String get addVehicleAddTruckTitle => 'Add truck';

  @override
  String get addVehicleEditTruckSubtitle =>
      'Update the truck details and save the changes.';

  @override
  String get addVehicleAddTruckSubtitle =>
      'Choose the truck type and fill in the fleet details.';

  @override
  String get addVehicleErrRegistration => 'Enter registration number';

  @override
  String get addVehicleErrCapacity => 'Enter capacity';

  @override
  String get addVehicleErrSelectDriver => 'Select a driver';

  @override
  String get addVehicleErrMake => 'Enter truck make';

  @override
  String get addVehicleErrYear => 'Enter a valid year';

  @override
  String get addVehicleErrInsuranceExpiry => 'Enter insurance expiry date';

  @override
  String get addVehicleUpdateTruck => 'Update truck';

  @override
  String get addDriverEditTitle => 'Edit driver';

  @override
  String get addDriverAddTitle => 'Add driver';

  @override
  String get addDriverEditSubtitle => 'Update the driver account';

  @override
  String get addDriverAddSubtitle => 'Add a new driver to your fleet';

  @override
  String get addDriverUpdateAction => 'Update driver';

  @override
  String get addDriverAddPhotoTitle => 'Add driver photo';

  @override
  String get addDriverErrName => 'Enter full name';

  @override
  String get addDriverErrEmail => 'Enter email';

  @override
  String get addDriverEmailHelper =>
      'Enter a valid email address — the driver logs in with email + password.';

  @override
  String get addDriverErrMobile => 'Enter mobile number';

  @override
  String get addDriverMobileHelper => 'Enter a valid 10-digit phone number.';

  @override
  String get addDriverErrLicense => 'Enter license number';

  @override
  String get brokerNotificationsRetry => 'Retry';

  @override
  String get brokerNotificationsEmptyTitle => 'No notifications yet';

  @override
  String get brokerNotificationsGenericTitle => 'Notification';

  @override
  String get brokerNotificationsToday => 'Today';

  @override
  String get brokerNotificationsYesterday => 'Yesterday';

  @override
  String get brokerNotificationsEarlier => 'Earlier';

  @override
  String get brokerNotificationsViewDetails => 'View details';

  @override
  String get brokerNotificationsViewTrip => 'View trip';

  @override
  String get brokerNotificationsOpenChat => 'Open chat';

  @override
  String get clientSavedSearchHintField => 'Search saved addresses...';

  @override
  String get clientSavedTooltipOpenMap => 'Open map picker';

  @override
  String get clientSavedTooltipSetDefault => 'Set as default';

  @override
  String get clientSavedTooltipEdit => 'Edit';

  @override
  String get clientSavedTooltipRemove => 'Remove';

  @override
  String get clientSavedDropoffTag => 'Drop-off';

  @override
  String get clientSavedPickupTag => 'Pickup';

  @override
  String get clientSavedErrorLoadOne => 'Could not load this address';

  @override
  String get clientSavedBackToAddresses => 'Back to saved addresses';

  @override
  String get clientSavedSaveChanges => 'Save changes';

  @override
  String get clientSavedSaveAddress => 'Save address';

  @override
  String get clientSavedMapPickerHint =>
      'Search, tap the map, or drag the pin once it is placed.';

  @override
  String get clientSavedCurrentLocationError =>
      'Could not get your current location.';

  @override
  String get clientSavedSignInToSave =>
      'Please sign in again to save this address.';

  @override
  String get clientBookingStepNext => 'Next';

  @override
  String get clientBookingStepContinue => 'Continue';

  @override
  String get clientBookingChooseTrucks => 'Choose trucks';

  @override
  String get clientBookingChooseTrucksSubtitle =>
      'Select truck type and search radius';

  @override
  String get clientBookingCancelling => 'Cancelling...';

  @override
  String get clientBookingCancelSearch => 'Cancel search';

  @override
  String get clientBookingEnterLoading => 'Enter loading location';

  @override
  String get clientBookingEnterUnloading => 'Enter unloading location';

  @override
  String get clientBookingConfirmToPay => 'Confirm to pay';

  @override
  String get clientBookingConfirmBilling => 'Confirm billing';

  @override
  String get clientBookingChoosePayment => 'Choose payment';

  @override
  String get clientBookingNoDriverInWindow =>
      'No driver found within the search window';

  @override
  String get clientBookingBookNowTooltip => 'Book now';

  @override
  String get checkoutStatusBookingConfirmedTitle => 'Booking confirmed';

  @override
  String get checkoutStatusBookingConfirmedMessage =>
      'Your booking has been successfully placed.';

  @override
  String get clientNegotiationRefreshBrokerOfferFailed =>
      'Could not refresh the live broker offer.';

  @override
  String get clientNegotiationRefreshRequestFailed =>
      'Could not refresh the live request.';

  @override
  String get clientNegotiationRefreshDriverOfferFailed =>
      'Could not refresh the live driver offer.';

  @override
  String get clientTrackingProofLoadFailed => 'Could not load delivery proof.';

  @override
  String get clientTrackingVideoPlayFailed => 'Could not play delivery video.';

  @override
  String get clientTrackingCancelTitle => 'Cancel this booking?';

  @override
  String get clientTrackingYesCancel => 'Yes, cancel';

  @override
  String get clientTrackingChatLoadFailed => 'Could not load this chat.';

  @override
  String get clientTrackingNegotiationLoadFailed =>
      'Could not load negotiation data.';

  @override
  String get clientTrackingConfirmedDriver => 'Confirmed driver';

  @override
  String get clientTrackingConfirmed => 'Confirmed';

  @override
  String get clientTrackingNoLongerAvailable => 'No longer available';

  @override
  String get clientBookingRemoveStopTooltip => 'Remove stop';

  @override
  String get clientTrackingLiveLocationLabel => 'Live location';

  @override
  String get clientTrackingLocationPendingTitle => 'Location pending';

  @override
  String get locationFlowSelectOnMap => 'Select on map';

  @override
  String get brokerFlowVehicleIdleLocation => 'Location';

  @override
  String get brokerFlowVehicleHeadingTo => 'Heading to';

  @override
  String get brokerFlowVehicleLastKnown => 'Last known';

  @override
  String get brokerFlowNoVehicleAssigned => 'No vehicle assigned';

  @override
  String get brokerFlowCtaViewMap => 'View map';

  @override
  String get brokerFlowCtaViewDetails => 'View details';

  @override
  String get brokerFlowLastSeenUnavailable => 'Not available';

  @override
  String get coreDigilockerAadhaarMaskHint => 'XXXX XXXX XXXX';

  @override
  String get coreDigilockerPanMaskHint => 'ABCDE1234F';

  @override
  String get coreDigilockerVehicleRegMaskHint => 'MH-2020123456789';

  @override
  String get coreDigilockerDateMaskHint => 'YYYY-MM-DD';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusRouteUnavailable => 'Route unavailable';

  @override
  String get historyDetailsInvoiceDownloaded =>
      'Invoice downloaded successfully.';

  @override
  String historyDetailsInvoiceDownloadedBytes(Object size) {
    return 'Invoice downloaded ($size bytes).';
  }

  @override
  String historyDetailsEmailSubject(Object bookingRef) {
    return 'Invoice for booking $bookingRef';
  }

  @override
  String get historyDetailsInvoiceEmailed => 'Invoice emailed successfully.';

  @override
  String get historyDetailsClientNotified => 'Client notified successfully.';

  @override
  String get timePeriodAm => 'AM';

  @override
  String get timePeriodPm => 'PM';

  @override
  String get addDriverCreateAccountSubtitle => 'Create a driver account';

  @override
  String brokerNotificationsMinsAgo(Object minutes) {
    return '${minutes}m';
  }

  @override
  String get brokerNotifRetryAction => 'Retry';

  @override
  String get brokerNotifEmptySubtitle => 'No notifications yet';

  @override
  String brokerNotifUnreadCount(Object count) {
    return '$count unread';
  }

  @override
  String brokerNotifTotalCount(Object count) {
    return '$count notifications';
  }

  @override
  String bookingRadiusKm(Object radius) {
    return '$radius km';
  }

  @override
  String get bookingBookNowTooltip => 'Book now';

  @override
  String get savedAddressCouldNotLoad => 'Could not load this address';

  @override
  String get savedAddressMapPickerTooltip => 'Open map picker';

  @override
  String get savedAddressSetDefaultTooltip => 'Set default';

  @override
  String get savedAddressEditTooltip => 'Edit';

  @override
  String get savedAddressRemoveTooltip => 'Remove';

  @override
  String get savedAddressDropoffLabel => 'Drop-off';

  @override
  String get savedAddressPickupLabel => 'Pickup';

  @override
  String get trackingAssignedDriver => 'Assigned driver';

  @override
  String get trackingPackageInformation => 'Package information';

  @override
  String get trackingDeliveryTypeLabel => 'Delivery Type:';

  @override
  String get trackingExpressDelivery => 'Express delivery';

  @override
  String get trackingStandardDelivery => 'Standard delivery';

  @override
  String get trackingPackageWeightLabel => 'Package weight:';

  @override
  String get trackingDriverNotAssigned => 'Driver not assigned';

  @override
  String get trackingPickupCodeTitle => 'Pickup Code';

  @override
  String get trackingPickupVerifiedBadge => 'Verified';

  @override
  String get trackingPickupConfirmedText => 'Pickup confirmed with your code.';

  @override
  String get trackingPickupCodeShareHint =>
      'Share this with your driver when they arrive to confirm pickup.';

  @override
  String get trackingLiveBadge => 'Live';

  @override
  String get trackingTimelineTitle => 'Shipment Timeline';

  @override
  String get trackingPodTitle => 'Proof of delivery';

  @override
  String get trackingPodApprovalPrompt =>
      'Does this look right? Approve to let the driver close out the trip, or reject to ask for new photos.';

  @override
  String get trackingPodApproving => 'Approving...';

  @override
  String get trackingPodApprove => 'Approve';

  @override
  String get trackingPodApproved => 'Approved';

  @override
  String trackingPodRejectionWithReason(Object reason) {
    return 'You asked the driver to re-upload: \"$reason.\" Waiting for new photos.';
  }

  @override
  String get trackingPodRejection =>
      'You asked the driver to re-upload. Waiting for new photos.';

  @override
  String get trackingPodLoadFailed => 'Could not load delivery proof.';

  @override
  String get trackingPodPlayFailed => 'Could not play delivery video.';

  @override
  String get bookingScheduled => 'Booking scheduled';

  @override
  String get bookingScheduledNotifyMessage =>
      'We will notify drivers or brokers closer to your pickup time.';

  @override
  String get checkoutOpeningActivity => 'Opening activity';

  @override
  String get checkoutBookLater => 'Book later';

  @override
  String get checkoutWhereIsYourDrop => 'Where is your Drop ?';

  @override
  String get weightStepAddLocation => 'Add location';

  @override
  String get weightStepTapToAddDetails => 'Tap + to add details';

  @override
  String get deliveryDetailsLoadingPoint => 'Loading Point';

  @override
  String get deliveryDetailsUnloadingPoint => 'Unloading Point';

  @override
  String get deliveryDetailsStartTripToPickup => 'Start Trip to Pickup';

  @override
  String get deliveryDetailsReachedPickup => 'I\'ve Reached Pickup';

  @override
  String get deliveryDetailsStartDelivery => 'Start Delivery';

  @override
  String get deliveryDetailsMarkAsDelivered => 'Mark as Delivered';

  @override
  String get driverKycVerificationCompleteTitle => 'KYC Verification Complete';

  @override
  String get driverKycSubmittedSuccessTitle => 'KYC Submitted Successfully';

  @override
  String get driverKycVerifiedBadgeUpper => 'VERIFIED';

  @override
  String get driverKycSubmittedBadgeUpper => 'SUBMITTED';

  @override
  String get driverKycVerifiedDescription =>
      'Your KYC has been verified. Your driver account is now active.';

  @override
  String get driverKycSubmittedDescription =>
      'Your KYC has been successfully submitted. Our verification team will review your documents. This usually takes 24-48 hours.';

  @override
  String get vehicleOption3Wheeler => '3 Wheeler';

  @override
  String get vehicleOptionTataAce => 'Tata Ace';

  @override
  String get vehicleOptionPickup8ft => 'Pickup 8ft';

  @override
  String get vehicleOptionPickup10ft => 'Pickup 10ft';

  @override
  String get vehicleOption14ftTruck => '14ft Truck';

  @override
  String get vehicleOption17ftTruck => '17ft Truck';

  @override
  String get vehicleOption19ftTruck => '19ft Truck';

  @override
  String get vehicleOption22ftTruck => '22ft Truck';

  @override
  String get vehiclePriceShared => 'Shared';

  @override
  String get vehiclePriceOnRequest => 'On request';

  @override
  String vehiclePriceWithToll(Object baseFare, Object toll) {
    return '$baseFare + toll $toll';
  }

  @override
  String get pickupOtpVerifiedTitle => 'Pickup verified';

  @override
  String get pickupOtpCodeTitle => 'Pickup code';

  @override
  String get pickupOtpVerifiedMessage => 'Pickup verified with your code';

  @override
  String get pickupOtpShareMessage =>
      'Share this code with your driver when they arrive to confirm pickup';

  @override
  String get trackingTimelineBookingCreated => 'Booking created';

  @override
  String get trackingTimelineVehicleAssigned => 'Vehicle assigned';

  @override
  String get trackingTimelineDriverAssigned => 'Driver assigned';

  @override
  String get trackingTimelineCompletedSuccessfully => 'Completed successfully';

  @override
  String get trackingTimelineWaitingForAssignment => 'Waiting for assignment';

  @override
  String get trackingTimelineBookingCancelled => 'Booking was cancelled';

  @override
  String get locationArcPickUpFrom => 'Pick up from';

  @override
  String packageCardTrackingId(Object trackingId) {
    return '#Tracking ID: $trackingId';
  }

  @override
  String get tripTypeChooseTitle => 'Choose trip type';

  @override
  String get tripTypeFullTruck => 'Full truck';

  @override
  String get tripTypePartTruck => 'Part truck';

  @override
  String get tripTypeFullTruckHelper => 'Dedicated truck for one shipment';

  @override
  String get tripTypePartTruckHelper => 'Share capacity and optimize cost';

  @override
  String get locationFlowSavedAddress => 'Saved address';

  @override
  String get locationFlowSetPickupLocation => 'Set pickup location';

  @override
  String get locationFlowSetDropLocation => 'Set drop-off location';

  @override
  String get locationFlowFindingAddress => 'Finding address...';

  @override
  String get locationFlowUseThisPickup => 'Use this pickup';

  @override
  String get locationFlowUseThisDrop => 'Use this drop-off';

  @override
  String get clientBookingAvailableTruck => 'Available truck';

  @override
  String get clientBookingLocationValidationFailed =>
      'These pickup/drop locations are not valid for this trip';

  @override
  String get clientBookingStepLocation => 'Location';

  @override
  String get clientBookingStepWeight => 'Weight';

  @override
  String get clientBookingStepPayment => 'Payment';

  @override
  String get clientBookingStepWaiting => 'Waiting';

  @override
  String get clientBookingFindingBrokers => 'Finding brokers';

  @override
  String get clientBookingScanningBrokerOffers =>
      'Scanning for broker offers on this route.';

  @override
  String clientBookingNegotiateWith(Object broker) {
    return 'Negotiate with $broker';
  }

  @override
  String get clientBookingChooseTrucksTitle => 'Choose Trucks';

  @override
  String get clientBookingPickBrokerForRoute => 'Pick a broker for this route';

  @override
  String get clientBookingLocating => 'Locating...';

  @override
  String get clientBookingMaterialWeight => 'Material weight';

  @override
  String clientBookingBookLaterAt(Object time) {
    return 'Book later: $time';
  }

  @override
  String clientBookingFreeHaltingNote(Object hours, Object rate) {
    return 'Free halting: ${hours}h, then $rate/hr.';
  }

  @override
  String get clientBookingFetchingAdvance => 'Fetching advance';

  @override
  String get clientBookingAdvanceUnavailable => 'Advance unavailable';

  @override
  String clientBookingAdvanceAmountNow(Object amount) {
    return '$amount now';
  }

  @override
  String get clientBookingPayAdvance => 'Pay Advance';

  @override
  String get clientBookingPaySecurely => 'Pay Securely';

  @override
  String get clientBookingCheckoutMapNote =>
      'Map stays live while you finish checkout.';

  @override
  String get clientDeliveryBookingFallback => 'Booking';

  @override
  String get clientDeliveryTruckFallback => 'Truck';

  @override
  String get clientPublicTimelineBookingCreated => 'Booking created';

  @override
  String get clientPublicTimelineVehicleAssigned => 'Vehicle assigned';

  @override
  String get clientPublicTimelineDropLocation => 'Drop-off location';

  @override
  String get clientPublicTimelineCompletedSuccessfully =>
      'Completed successfully';

  @override
  String get clientSavedAddressUpdated => 'Address updated.';

  @override
  String get clientSavedAddressSaved => 'Address saved.';

  @override
  String get clientSavedLocationServicesOff =>
      'Location services are turned off.';

  @override
  String get clientSavedLocationPermissionRequired =>
      'Location permission is required.';

  @override
  String get clientSavedLoadErrorSubtitle =>
      'Go back to saved addresses and try editing it again.';

  @override
  String get clientSavedTypeLabel => 'Type';

  @override
  String get clientSavedNameLabel => 'Name';

  @override
  String get clientSavedAddressLabel => 'Address';

  @override
  String clientSavedCityValue(Object city) {
    return 'City: $city';
  }

  @override
  String get clientSavedFloorUnitLabel => 'Floor / Unit';

  @override
  String get clientSavedTapMapForExactSpot =>
      'Tap the map to choose an exact spot';

  @override
  String get clientSavedDefaultBadge => 'Default';

  @override
  String trackingPodFilesPosted(Object count) {
    return '$count file(s) posted by driver';
  }

  @override
  String get trackingDriverPending => 'Driver pending';

  @override
  String get trackingTruckNotAssigned => 'Truck not assigned';

  @override
  String trackingCrewHandoff(Object from, Object to) {
    return '$from -> $to';
  }

  @override
  String trackingDriverChangedCount(Object count) {
    return 'Driver changed ($count)';
  }

  @override
  String get trackingCancelWhyHint => 'Tell us why — it helps us do better.';

  @override
  String get trackingKeepBooking => 'Keep booking';

  @override
  String get trackingBookingActions => 'Booking actions';

  @override
  String get trackingBookingChat => 'Booking chat';

  @override
  String get trackingChatSocketHint => 'Thread updates over REST + Socket.IO';

  @override
  String get trackingChatNoMessages => 'No messages yet.';

  @override
  String get trackingChatEmptyMessage => 'Message';

  @override
  String get trackingChatRead => 'Read';

  @override
  String get trackingChatTyping => 'Typing...';

  @override
  String get trackingChangeDriverFare => 'Change driver fare';

  @override
  String trackingCurrentOffer(Object amount) {
    return 'Current offer: $amount';
  }

  @override
  String trackingYourFareChange(Object amount) {
    return 'Your fare change: $amount';
  }

  @override
  String get trackingNegotiationOffers => 'Negotiation & offers';

  @override
  String get trackingNegotiationOffersSubtitle =>
      'Driver requests and broker offers from the client flow.';

  @override
  String get trackingNegotiationLoadFailed =>
      'Could not load negotiation data.';

  @override
  String get trackingBrokerOffer => 'Broker offer';

  @override
  String get trackingBrokerOfferReceived => 'Broker offer received';

  @override
  String get trackingYourTurn => 'Your turn';

  @override
  String get trackingWaitingBrokerConfirmation =>
      'Waiting for broker confirmation';

  @override
  String get trackingWaitingBrokerResponse => 'Waiting for broker response';

  @override
  String get trackingWaitingDriverConfirmation =>
      'Waiting for driver confirmation';

  @override
  String get trackingWaitingDriverResponse => 'Waiting for driver response';

  @override
  String get trackingConfirmed => 'Confirmed';

  @override
  String get trackingDirectTruckRequest => 'Direct truck request';

  @override
  String trackingNegotiationHistoryCount(Object count) {
    return 'Negotiation history ($count)';
  }

  @override
  String get brokerFlowDropOffUnavailable => 'Drop-off location unavailable';

  @override
  String brokerFlowTripWithStatus(Object status) {
    return 'Trip $status';
  }

  @override
  String get brokerFlowActiveOnTrip => 'Active on trip';

  @override
  String brokerFlowActiveOnBooking(Object bookingRef) {
    return 'Active on Booking $bookingRef';
  }

  @override
  String get brokerFlowIdleAwaitingAssignment => 'Idle - Awaiting Assignment';

  @override
  String get brokerFlowVehicleIdle => 'Idle';

  @override
  String get brokerFlowOnTrip => 'On Trip';

  @override
  String get brokerFlowMaintenance => 'Maintenance';

  @override
  String get brokerFlowRecentlyCompleted => 'Recently completed';

  @override
  String brokerFlowSinceAgo(Object value) {
    return '$value ago';
  }

  @override
  String get brokerFlowReassigning => 'Reassigning...';

  @override
  String get brokerActiveJobsNotAssigned => 'Not Assigned';

  @override
  String get brokerActiveJobsBreakdownReported => 'Breakdown Reported';

  @override
  String get brokerActiveJobsIssueReported => 'Issue Reported';

  @override
  String get brokerActiveJobsRouteDistancePending => 'Route distance pending';

  @override
  String brokerActiveJobsRouteKm(Object distance) {
    return '$distance km route';
  }

  @override
  String get brokerActiveJobsStepEnRoute => 'En Route';

  @override
  String get brokerActiveJobsStepPickedUp => 'Picked Up';

  @override
  String get brokerActiveJobsStepInTransit => 'In Transit';

  @override
  String get brokerActiveJobsIssueDamagedGoods => 'Damaged Goods';

  @override
  String get brokerActiveJobsIssuePaymentDelay => 'Payment Delay';

  @override
  String get brokerActiveJobsIssueCancellationFee => 'Cancellation Fee';

  @override
  String get brokerActiveJobsIssueRouteDispute => 'Route Dispute';

  @override
  String get brokerActiveJobsIssueLateDelivery => 'Late Delivery';

  @override
  String get brokerActiveJobsIssueFuelSurcharge => 'Fuel Surcharge';

  @override
  String get brokerActiveJobsIssueWrongItems => 'Wrong Items';

  @override
  String get brokerActiveJobsIssueWeightDiscrepancy => 'Weight Discrepancy';

  @override
  String get brokerPickupLocationNotAvailable =>
      'Pickup location not available';

  @override
  String get brokerDropLocationNotAvailable => 'Drop location not available';

  @override
  String get brokerTruckHistoryNoTripsMatchSearch =>
      'No trips match your search';

  @override
  String get brokerTruckHistoryDriverPending => 'Driver pending';

  @override
  String get brokerTruckHistoryDistancePending => 'Distance pending';

  @override
  String get brokerTruckHistoryEarningsPending => 'Earnings pending';

  @override
  String brokerTrackingAssignedTo(Object plate) {
    return 'Assigned to $plate';
  }

  @override
  String get brokerTrackingTimedOutNegotiation => 'Timed-out negotiation';

  @override
  String get brokerTrackingOpenToContinueNegotiation =>
      'Open to continue negotiation.';

  @override
  String get brokerTrackingNoDriversYet => 'No drivers yet';

  @override
  String brokerTrackingNoDriversMatch(Object query) {
    return 'No drivers match \"$query\"';
  }

  @override
  String get brokerTrackingCreateDriverFromPlus =>
      'Create a driver from the + button to start tracking.';

  @override
  String get brokerTrackingTryDifferentQuery =>
      'Try a different name, phone or vehicle number.';

  @override
  String get brokerTrackingNoActiveTripIncidentData =>
      'No active trip incident data for this driver.';

  @override
  String get brokerTrackingNoIncidentsYet => 'No incidents reported yet.';

  @override
  String get brokerTrackingIncident => 'Incident';

  @override
  String get brokerTrackingDestinationNotAvailable =>
      'Destination not available';

  @override
  String get addTruckAddedSuccessfully => 'Truck added successfully.';

  @override
  String get addTruckUpdatedSuccessfully => 'Truck updated successfully.';

  @override
  String get addTruckEditTruck => 'Edit Truck';

  @override
  String get addTruckAddTruck => 'Add Truck';

  @override
  String get addTruckErrRegistrationLooksInvalid =>
      'Registration looks invalid, e.g. MH-12-AB-1234.';

  @override
  String get brokerHomeTheDriver => 'The driver';

  @override
  String get brokerNotificationsMarkAllRead => 'Mark all read';

  @override
  String get brokerNotificationsTabOps => 'Ops';

  @override
  String get brokerNotificationsTabSystem => 'System';

  @override
  String get brokerNotificationsTabMoney => 'Money';

  @override
  String get brokerVehiclesRowType => 'Type';

  @override
  String get brokerVehiclesRowInsurance => 'Insurance';

  @override
  String get brokerEarningsAcrossAllSettledTrips => 'Across all settled trips';

  @override
  String get brokerEarningsAcrossAllSettledTripsVsLastMonth =>
      'Across all settled trips • vs last month';

  @override
  String get brokerEarningsFlatVsLastMonth =>
      'Flat vs last month — steady performance.';

  @override
  String brokerEarningsUpVsLastMonth(Object change) {
    return 'Up $change% vs last month — keep the momentum.';
  }

  @override
  String brokerEarningsDownVsLastMonth(Object change) {
    return 'Down $change% vs last month.';
  }

  @override
  String get brokerEarningsSettlementPending => 'Settlement pending';

  @override
  String get brokerReqDetailAutoSelectedDriver => 'Auto-selected driver';

  @override
  String get brokerReqDetailAutoSelectedTruck => 'Auto-selected truck';

  @override
  String brokerTruckLocationDriverLabel(Object name) {
    return 'Driver: $name';
  }

  @override
  String get brokerDriverRequestsAccepted => 'Request accepted.';

  @override
  String get brokerDriverRequestsDeclined => 'Request declined.';

  @override
  String get brokerDriverRequestsTimedOut => 'Timed out';

  @override
  String get driverDetailNotOnTrip => 'Not on trip';

  @override
  String get driverDetailAwaitingLiveLocation => 'Awaiting live location';

  @override
  String get brokerTruckAssignAssigning => 'Assigning...';

  @override
  String get driverTripToday => 'Today';

  @override
  String get driverEarningsRecent => 'Recent';

  @override
  String get driverRiderAllTripsTitle => 'All Trips';

  @override
  String get driverRiderAllTripsSubtitle =>
      'Latest activity and completed deliveries';

  @override
  String get driverRiderRecentlyCompleted => 'Recently completed deliveries';

  @override
  String get driverRiderPendingDeliveries =>
      'Pending deliveries and settlements';

  @override
  String get driverRiderViewAll => 'View all';

  @override
  String get driverRiderNoDeliveriesDoneYet =>
      'No deliveries done yet, start working';

  @override
  String get driverRiderNoLatestTripYet => 'No latest trip yet';

  @override
  String get driverRiderToday => 'Today';

  @override
  String get driverRiderYesterday => 'Yesterday';

  @override
  String driverRiderTripCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$_temp0';
  }

  @override
  String get driverRiderToLabel => 'To:';

  @override
  String get driverRiderStatusLabel => 'Status:';

  @override
  String get driverRiderFromLocationUnavailable => 'From location unavailable';

  @override
  String get driverRiderToLocationUnavailable => 'To location unavailable';

  @override
  String get driverRiderLocatingPickup => 'Locating pickup…';

  @override
  String get driverRiderLocatingDropoff => 'Locating drop-off…';

  @override
  String get driverRiderViewDetails => 'View Details';

  @override
  String get driverHomeOffline => 'Offline';

  @override
  String get driverHomeOnline => 'Online';

  @override
  String get driverHomeToggleOffline => 'Toggle offline';

  @override
  String get driverHomeToggleOnline => 'Toggle online';

  @override
  String get driverHomeCantGoOffline =>
      'Can\'t go offline while you have an active trip';

  @override
  String get driverHomeCannotGoOfflineSnack =>
      'You cannot go offline while a trip is active.';

  @override
  String get driverHomeActiveTripLocksOnline =>
      'Active trip in progress. Online mode stays locked until the trip is completed.';

  @override
  String get driverHomeMoreRequests => 'More requests';

  @override
  String get driverHomeDeliveryId => 'Delivery ID';

  @override
  String get driverHomeBrokerHandoffActive => 'Broker handoff active';

  @override
  String get driverHomeClientCountered =>
      'Client countered. Open the request to respond.';

  @override
  String get driverHomeWaitingForClientResponse =>
      'Waiting for the client response';

  @override
  String get driverHomeClientAccepted =>
      'Client accepted. Open the request to confirm.';

  @override
  String get driverHomeWaitingForClientConfirmation =>
      'Waiting for client confirmation';

  @override
  String get driverHomeNegotiationUnavailable => 'Negotiation unavailable';

  @override
  String get driverHomeClientRequest => 'Client request';

  @override
  String get driverHomeBrokerAssignedNotice =>
      'Broker-assigned - accept or decline, no negotiation.';

  @override
  String driverHomeLocationFallback(Object label) {
    return '$label location';
  }

  @override
  String get driverOrderClientAcceptedRequest => 'Client accepted the request';

  @override
  String get driverOrderClientAcceptedBody =>
      'The client accepted your offer. Please confirm to finalize the booking or reject to decline it.';

  @override
  String get driverOrderBookingSyncing => 'Booking is still syncing.';

  @override
  String get driverOrderOpeningTripWhenReady =>
      'We are opening the active trip view as soon as the trip is ready.';

  @override
  String get driverOrderCheckingApis =>
      'We check the request, booking, and trip APIs every 5 seconds.';

  @override
  String get driverOrderCheckNow => 'Check now';

  @override
  String get driverOrderBookingFinalized => 'Booking finalized';

  @override
  String get driverOrderOpeningActiveTrip => 'Opening the active trip view.';

  @override
  String get driverOrderYourOffer => 'Your offer';

  @override
  String driverOrderBaseAmount(Object amount) {
    return 'Base $amount';
  }

  @override
  String get driverOrderClientAcceptedYourRequest =>
      'Client accepted your request';

  @override
  String get driverOrderConfirmOrDeclinePrompt =>
      'Confirm or decline from the prompt that appeared above.';

  @override
  String get driverOrderAcceptedWaitingClient =>
      'Accepted - waiting for the client to confirm.';

  @override
  String get driverOrderRealtimeUpdates => 'We update this in real time.';

  @override
  String get driverOrderFareChangeSent =>
      'Fare change sent. Waiting for client response...';

  @override
  String get driverOrderUnlockAfterClientAccepts =>
      'We will unlock the tracking button once the client accepts the offer.';

  @override
  String get driverOrderFareChangesUsedUp =>
      'You have used your fare changes - accept or decline instead.';

  @override
  String get driverOrderBrokerTakeover => 'Broker takeover';

  @override
  String get driverOrderLocked => 'Locked';

  @override
  String get driverOrderAnyMomentNow => 'Any moment now';

  @override
  String get driverOrderHandedOverToBroker => 'Handed over to broker';

  @override
  String get driverOrderFinalizingTrip => 'Finalizing the trip';

  @override
  String get driverOrderSetYourFareChange => 'Set your fare change';

  @override
  String get driverOrderNegotiatingWithClient => 'Negotiating with the client';

  @override
  String get driverOrderHandedOver => 'Handed over';

  @override
  String get driverOrderHandoff => 'Handoff';

  @override
  String get driverOrderBrokerAssignedTrip => 'Broker-assigned trip';

  @override
  String get driverOrderAlreadyAgreedWithBroker =>
      'Already agreed with the broker - accept or decline, no fare changes.';

  @override
  String get driverOrderFixedPrice => 'Fixed price';

  @override
  String get driverOrderAgreedAmount => 'AGREED AMOUNT';

  @override
  String get driverOrderAssignedTripBody =>
      'This trip was assigned by the broker at the agreed amount. You can decline it if you are not available.';

  @override
  String get driverOrderBrokerControlsRequest =>
      'Broker controls this request now - waiting for new leads.';

  @override
  String get driverOrderBaseOffer => 'BASE OFFER';

  @override
  String get driverOrderBrokerHandling => 'Broker handling';

  @override
  String get driverOrderClientResponded => 'Client responded';

  @override
  String get driverOrderFareWindow => 'Fare window';

  @override
  String get driverOrderAwaitingResponse => 'Awaiting response';

  @override
  String get deliveryDetailsTripStartedHeadingToPickup =>
      'Trip started. Heading to pickup.';

  @override
  String get deliveryDetailsPickupMarkedStartDelivery =>
      'Pickup marked. Start delivery next.';

  @override
  String get deliveryDetailsNowInTransit => 'Delivery is now in transit.';

  @override
  String get deliveryDetailsMarkedAsDelivered =>
      'Delivery marked as delivered.';

  @override
  String deliveryDetailsCompleteLoadingStopsFirst(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Complete $count loading stops first',
      one: 'Complete 1 loading stop first',
    );
    return '$_temp0';
  }

  @override
  String deliveryDetailsCompleteUnloadingStopsFirst(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Complete $count unloading stops first',
      one: 'Complete 1 unloading stop first',
    );
    return '$_temp0';
  }

  @override
  String get deliveryDetailsOnRoute => 'On route';

  @override
  String get deliveryDetailsActiveBadge => 'Active';

  @override
  String get deliveryDetailsUseActionToAdvance =>
      'Use the action below to advance the trip.';

  @override
  String get deliveryDetailsCurrentStatus => 'Current status';

  @override
  String get deliveryDetailsSyncingTrip => 'Syncing trip...';

  @override
  String get deliveryDetailsDecliningEllipsis => 'Declining...';

  @override
  String get deliveryDetailsTripFallbackLabel => 'Trip';

  @override
  String get deliveryDetailsEmergencyAssistance => 'Emergency Assistance';

  @override
  String get deliveryDetailsNavigateToPickup => 'Navigate to pickup';

  @override
  String get deliveryDetailsAskCustomerForCode =>
      'Ask the customer to share their 4-digit code';

  @override
  String get deliveryDetailsDelayCharge => 'Delivery delay charge';

  @override
  String get deliveryDetailsSla => 'Delivery SLA';

  @override
  String deliveryDetailsDelayChargeBody(Object amount, Object hours) {
    return '$amount for ${hours}h over the expected delivery time.';
  }

  @override
  String deliveryDetailsExpectedWithin(Object hours) {
    return 'Expected delivery within ~${hours}h.';
  }

  @override
  String get deliveryDetailsBookingChat => 'Booking chat';

  @override
  String get deliveryDetailsMechanicStatus => 'Mechanic Status';

  @override
  String get deliveryDetailsLiveIncidentUpdates =>
      'Live incident updates for this trip.';

  @override
  String get deliveryDetailsIncident => 'Incident';

  @override
  String deliveryDetailsMechanicLine(Object name) {
    return 'Mechanic: $name';
  }

  @override
  String get deliveryDetailsPendingAssignment => 'Pending assignment';

  @override
  String deliveryDetailsPhoneLine(Object phone) {
    return 'Phone: $phone';
  }

  @override
  String deliveryDetailsStatusLine(Object status) {
    return 'Status: $status';
  }

  @override
  String get deliveryDetailsRequestedLabel => 'requested';

  @override
  String get driverKycVerifiedSnack =>
      'You\'re verified - full access unlocked.';

  @override
  String get driverKycSubmittedForReviewSnack => 'KYC submitted for review.';

  @override
  String get driverKycConfirmAccuracyDeclaration =>
      'I confirm that all the information provided is accurate.';

  @override
  String get driverKycVerifyIdentity => 'Verify Your Identity';

  @override
  String get driverKycFinish => 'Finish';

  @override
  String get driverKycResubmitForReview => 'Resubmit for Review';

  @override
  String get driverKycDriverKycTitle => 'Driver KYC';

  @override
  String get chatCurrentUserSenderName => 'You';

  @override
  String clientNotificationsTimeMinutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String clientNotificationsTimeHoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String clientNotificationsTimeDaysAgo(Object days) {
    return '${days}d ago';
  }

  @override
  String get negotiationYourFare => 'Your fare';

  @override
  String get negotiationFareChangesExhausted =>
      'You have used your fare changes — accept or decline instead.';

  @override
  String get negotiationWaitingDriverAcceptedTitle =>
      'Driver accepted the request';

  @override
  String get negotiationWaitingDriverTurnToConfirmTitle =>
      'Driver accepted - your turn to confirm';

  @override
  String get negotiationWaitingDriverConfirmationTitle =>
      'Waiting for driver confirmation';

  @override
  String get negotiationWaitingFareChangeReceivedTitle =>
      'Fare change received';

  @override
  String get negotiationWaitingDriverResponseTypeTitle =>
      'Waiting for driver response';

  @override
  String get negotiationWaitingDriverAcceptedBody =>
      'The driver accepted your request. You can confirm the booking and continue to payment.';

  @override
  String get negotiationWaitingDriverCommittedBody =>
      'The driver already committed. Confirm or decline to finish the handshake.';

  @override
  String get negotiationWaitingDriverYourConfirmBody =>
      'You already confirmed this offer. We are waiting for the driver to confirm now.';

  @override
  String get negotiationWaitingDriverChangedFareBody =>
      'The driver changed the fare. Review it here and respond instantly.';

  @override
  String get negotiationWaitingDriverTimedOutBody =>
      'The driver did not respond in time. The broker can step in now.';

  @override
  String get negotiationWaitingDriverLiveBody =>
      'Your request is live. We will update this popup as soon as the truck responds.';

  @override
  String negotiationBookingReference(Object bookingNumber) {
    return 'Booking #$bookingNumber';
  }

  @override
  String get negotiationLiveUpdatesAppearHere =>
      'Live updates will appear here.';

  @override
  String negotiationCurrentAmount(Object amount) {
    return 'Current amount: $amount';
  }

  @override
  String negotiationHistoryCount(Object count) {
    return 'Negotiation history ($count)';
  }

  @override
  String negotiationHistoryEntryOffered(Object amount, Object displayBy) {
    return '$displayBy offered ₹$amount';
  }

  @override
  String get negotiationWaitingLiveFareChange =>
      'Waiting for a live fare change...';

  @override
  String get negotiationPickPayment =>
      'Pick how this freight booking should be settled. Advance uses the latest admin-configured amount.';

  @override
  String get negotiationRazorpayCheckoutNote =>
      'Razorpay checkout will show the available payment methods before you pay.';

  @override
  String get negotiationConfirmPaymentStage => 'Confirm payment stage';

  @override
  String get negotiationContinueToSecureCheckout =>
      'Continue to secure checkout';

  @override
  String get negotiationWaitingNextDriverUpdate =>
      'Waiting for the next driver update...';

  @override
  String get negotiationUseSliderHint =>
      'Use the slider to set the amount you want to continue with.';

  @override
  String get negotiationDragToSetPrice => 'Drag to set your price';

  @override
  String get brokerSettlementsGrossAmount => 'Gross amount';

  @override
  String get brokerSettlementsPlatformFee => 'Platform fee';

  @override
  String get brokerSettlementsRoutePending => 'Route pending';

  @override
  String get brokerTrackLiveStepEnRoute => 'En Route';

  @override
  String get brokerTrackLiveStepPickedUp => 'Picked Up';

  @override
  String get brokerTrackLiveStepInTransit => 'In Transit';

  @override
  String get addDriverSharedSeparately => 'Shared separately';

  @override
  String get addDriverAadhaarMustBe12Digits => 'Aadhaar must be 12 digits';

  @override
  String get addDriverUseAValidDate => 'Use a valid date';

  @override
  String get addDriverLicenseExpiryCannotBeInThePast =>
      'License expiry cannot be in the past.';

  @override
  String get addDriverTapToUpdateTheDriverPhoto =>
      'Tap to update the driver photo';

  @override
  String get addDriverTapTheCameraToAddADriverPhoto =>
      'Tap the camera to add a driver photo';

  @override
  String get addVehicleTruckAddedSuccessfully => 'Truck added successfully.';

  @override
  String get addVehicleTruckUpdatedSuccessfully =>
      'Truck updated successfully.';

  @override
  String get addVehicleUseYyyyMmdd => 'Use YYYY-MM-DD';

  @override
  String get brokerKycInDetails => 'In details';

  @override
  String get brokerKycIncludedInDetails => 'Included in details';

  @override
  String get brokerKycSubmittedUrl => 'Submitted URL';

  @override
  String get brokerKycNoActiveSessionFound => 'No active session found.';

  @override
  String get brokerKycPleaseConfirmAllInformationIsAccurate =>
      'Please confirm that all information is accurate.';

  @override
  String get brokerKycYouAreVerified =>
      'You\'re verified - full access unlocked.';

  @override
  String get brokerKycSubmittedForReview => 'KYC submitted for review.';

  @override
  String get driverTrackingSignInAgainBeforeEnablingLocation =>
      'Please sign in again before enabling location sharing.';

  @override
  String get driverTrackingEnableLocationServices =>
      'Enable location services on the device to share live tracking.';

  @override
  String get driverTrackingLocationPermissionRequired =>
      'Location permission is required for live driver tracking.';

  @override
  String get driverTrackingLocationPermissionDeniedForever =>
      'Location permission is permanently denied. Open app settings to enable it.';

  @override
  String get driverTrackingUnableToStartLiveTracking =>
      'Unable to start live tracking on this device.';

  @override
  String get driverTrackingSignInAgainBeforeRefreshingLocation =>
      'Please sign in again before refreshing location.';

  @override
  String get negotiationWindowAnyMomentNow =>
      'Any moment now - waiting for the server handoff.';

  @override
  String negotiationWindowRemaining(Object countdown, Object label) {
    return '$label $countdown remaining';
  }

  @override
  String get brokerActiveJobActiveJob => 'Active job';

  @override
  String get brokerActiveJobDriverPending => 'Driver pending';

  @override
  String get brokerActiveJobLoadPending => 'Load details pending';

  @override
  String get brokerActiveJobAssigned => 'Assigned';

  @override
  String get brokerActiveJobDriverAssigned => 'Driver assigned';

  @override
  String get brokerActiveJobEnRoutePickup => 'En Route Pickup';

  @override
  String get brokerActiveJobDriverHeadingToPickup => 'Driver heading to pickup';

  @override
  String get brokerActiveJobPickedUp => 'Picked Up';

  @override
  String get brokerActiveJobShipmentPickedUp => 'Shipment picked up';

  @override
  String get brokerActiveJobInTransit => 'In Transit';

  @override
  String get brokerActiveJobShipmentOnRoad => 'Shipment on the road';

  @override
  String get brokerActiveJobDelivered => 'Delivered';

  @override
  String get brokerActiveJobDropCompleted => 'Drop completed';

  @override
  String get brokerFlowRequestReceived => 'Request received';

  @override
  String get brokerFlowBrokerInbox => 'Broker inbox';

  @override
  String get brokerFlowAssignmentPending => 'Assignment pending';

  @override
  String get brokerFlowVehicleAssignmentPending => 'Vehicle assignment pending';

  @override
  String get brokerFlowAwaitingPickup => 'Awaiting pickup';

  @override
  String get brokerFlowDriverRequestSent => 'Driver request sent';

  @override
  String get brokerFlowBrokerNegotiation => 'Broker negotiation';

  @override
  String get driverNavDestinationUnavailable =>
      'Destination is not available for this trip yet.';

  @override
  String get driverNavPickupDropUnavailable =>
      'Pickup or drop details are not available yet.';

  @override
  String get driverNavMapsUnavailable =>
      'Could not open Google Maps on this device.';

  @override
  String get vehicleOptionPartLoad => 'Part load';

  @override
  String get paymentStatusFailed => 'Failed';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get paymentStatusPartiallyPaid => 'Partially paid';

  @override
  String get paymentStatusPendingFallback => 'Pending';
}
