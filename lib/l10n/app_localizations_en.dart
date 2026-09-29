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
}
