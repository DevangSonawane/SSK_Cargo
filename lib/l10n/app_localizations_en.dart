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
  String get allEarningsActiveMonths => 'Active Months';

  @override
  String get allEarningsAvgTrip => 'Avg Trip';

  @override
  String get allEarningsBreakdown => 'Breakdown';

  @override
  String get allEarningsDeliveries => 'Deliveries';

  @override
  String get allEarningsEmptySubtitle => 'Empty Subtitle';

  @override
  String get allEarningsEmptyTitle => 'Empty Title';

  @override
  String get allEarningsLoadFailed => 'Load Failed';

  @override
  String get allEarningsMonthlyTrend => 'Monthly Trend';

  @override
  String get allEarningsMonths => 'Months';

  @override
  String get allEarningsNetPerMonth => 'Net Per Month';

  @override
  String get allEarningsPerDelivery => 'Per Delivery';

  @override
  String get allEarningsTitle => 'Title';

  @override
  String get allEarningsTotalEarned => 'Total Earned';

  @override
  String get allEarningsTripsDone => 'Trips Done';

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
  String get arrivedNextLabel => 'Next Label';

  @override
  String get arrivedNextUpload => 'Next Upload';

  @override
  String get arrivedPreparing => 'Preparing';

  @override
  String get arrivedPreparingSub => 'Preparing Sub';

  @override
  String get arrivedSlideSub => 'Slide Sub';

  @override
  String get arrivedSlideTitle => 'Slide Title';

  @override
  String get arrivedStatusLabel => 'Status Label';

  @override
  String get arrivedStatusReady => 'Status Ready';

  @override
  String get arrivedSub => 'Sub';

  @override
  String get arrivedSwipeContinue => 'Swipe Continue';

  @override
  String get arrivedTitle => 'Title';

  @override
  String get arrivedTripIdLabel => 'Trip ID Label';

  @override
  String get brokerActiveDescription => 'Broker Active Description';

  @override
  String get brokerActiveSubmit => 'Broker Active Submit';

  @override
  String get brokerActiveSubmitting => 'Broker Active Submitting';

  @override
  String get brokerHomeClientOffered => 'Client Offered';

  @override
  String get brokerHomeDriverFallback => 'Driver Fallback';

  @override
  String get brokerHomeDropUnavailable => 'Drop Unavailable';

  @override
  String get brokerHomeFareChangeSent => 'Fare Change Sent';

  @override
  String get brokerHomeFareChangesUsed => 'Fare Changes Used';

  @override
  String get brokerHomeHelloPrefix => 'Hello Prefix';

  @override
  String get brokerHomeJustNow => 'Just Now';

  @override
  String get brokerHomePickupUnavailable => 'Pickup Unavailable';

  @override
  String get brokerHomeRequestAccepted => 'Request Accepted';

  @override
  String get brokerHomeRequestDeclined => 'Request Declined';

  @override
  String get brokerHomeSendAssignment => 'Send Assignment';

  @override
  String get brokerHomeSending => 'Sending';

  @override
  String get brokerHomeTryClearingSearch => 'Try Clearing Search';

  @override
  String get brokerHomeYouAcceptedWaiting => 'You Accepted Waiting';

  @override
  String get brokerHomeYouOffered => 'You Offered';

  @override
  String get brokerKycCompleteTitle => 'Complete Title';

  @override
  String get brokerKycContinue => 'Continue';

  @override
  String get brokerKycFinish => 'Finish';

  @override
  String get brokerKycNotAvailable => 'Not Available';

  @override
  String get brokerKycNotProvided => 'Not Provided';

  @override
  String get brokerKycPendingReviewStatus => 'Pending Review Status';

  @override
  String get brokerKycSubmitKyc => 'Submit KYC';

  @override
  String get brokerKycSubmittedBadge => 'Submitted Badge';

  @override
  String get brokerKycSubmittedDesc => 'Submitted Desc';

  @override
  String get brokerKycSubmittedTitle => 'Submitted Title';

  @override
  String get brokerKycVerifiedBadge => 'Verified Badge';

  @override
  String get brokerKycVerifiedDesc => 'Verified Desc';

  @override
  String get brokerKycVerifiedStatus => 'Verified Status';

  @override
  String get brokerKycVerifyCarefullyWarning => 'Verify Carefully Warning';

  @override
  String get brokerReqAcceptAssign => 'Accept Assign';

  @override
  String get brokerReqAcceptedNoCard => 'Accepted No Card';

  @override
  String get brokerReqAcceptedPickDriver => 'Accepted Pick Driver';

  @override
  String get brokerReqAssignmentTitle => 'Assignment Title';

  @override
  String get brokerReqAutoSelectedDetails => 'Auto Selected Details';

  @override
  String get brokerReqAwaitingOtherSide => 'Awaiting Other Side';

  @override
  String get brokerReqChangeFareOrReject => 'Change Fare or Reject';

  @override
  String get brokerReqClientAcceptedFinalize => 'Client Accepted Finalize';

  @override
  String get brokerReqConfirmAssign => 'Confirm Assign';

  @override
  String get brokerReqConfirmBookingTitle => 'Confirm Booking Title';

  @override
  String get brokerReqCustomerFallback => 'Customer Fallback';

  @override
  String get brokerReqDeclinedNoActions => 'Declined No Actions';

  @override
  String get brokerReqFareChangeWaiting => 'Fare Change Waiting';

  @override
  String get brokerReqGeneralFallback => 'General Fallback';

  @override
  String get brokerReqNoDriversFound => 'No Drivers Found';

  @override
  String get brokerReqNoTrucksFound => 'No Trucks Found';

  @override
  String get brokerReqSaving => 'Saving';

  @override
  String get brokerReqUnavailable => 'Unavailable';

  @override
  String get changePasswordAllFieldsRequired => 'All Fields Required';

  @override
  String get changePasswordConfirmHint => 'Confirm Hint';

  @override
  String get changePasswordConfirmLabel => 'Confirm Label';

  @override
  String get changePasswordCurrentHint => 'Current Hint';

  @override
  String get changePasswordCurrentLabel => 'Current Label';

  @override
  String get changePasswordMismatch => 'Mismatch';

  @override
  String get changePasswordNewHint => 'New Hint';

  @override
  String get changePasswordNewLabel => 'New Label';

  @override
  String get changePasswordScreenTitle => 'Screen Title';

  @override
  String get changePasswordStrengthEmptyHint => 'Strength Empty Hint';

  @override
  String get changePasswordStrengthFair => 'Strength Fair';

  @override
  String get changePasswordStrengthGood => 'Strength Good';

  @override
  String get changePasswordStrengthLowercase => 'Strength Lowercase';

  @override
  String get changePasswordStrengthMinLength => 'Strength Min Length';

  @override
  String get changePasswordStrengthNumber => 'Strength Number';

  @override
  String get changePasswordStrengthStrong => 'Strength Strong';

  @override
  String get changePasswordStrengthStrongHint => 'Strength Strong Hint';

  @override
  String get changePasswordStrengthSymbol => 'Strength Symbol';

  @override
  String get changePasswordStrengthTitle => 'Strength Title';

  @override
  String get changePasswordStrengthUppercase => 'Strength Uppercase';

  @override
  String get changePasswordStrengthWeak => 'Strength Weak';

  @override
  String get changePasswordSubmitButton => 'Submit Button';

  @override
  String get changePasswordSuccessLoggedOut => 'Success Logged Out';

  @override
  String get chatAssistantName => 'Assistant Name';

  @override
  String get chatClosedChip => 'Closed Chip';

  @override
  String get chatDetailBookingTitle => 'Detail Booking Title';

  @override
  String get chatDetailClientTitle => 'Detail Client Title';

  @override
  String get chatDetailDirectTitle => 'Detail Direct Title';

  @override
  String get chatDirectMessageChip => 'Direct Message Chip';

  @override
  String get chatDirectMessageFallback => 'Direct Message Fallback';

  @override
  String get chatListEmpty => 'List Empty';

  @override
  String get chatListLoadError => 'List Load Error';

  @override
  String get chatListRetry => 'List Retry';

  @override
  String get chatListTitle => 'List Title';

  @override
  String get chatMessageFallback => 'Message Fallback';

  @override
  String get chatMessageNotSent => 'Message Not Sent';

  @override
  String get chatNoMessagesYet => 'No Messages Yet';

  @override
  String get chatNotConnectedChip => 'Not Connected Chip';

  @override
  String get chatReadReceipt => 'Read Receipt';

  @override
  String get chatThreadLoadError => 'Thread Load Error';

  @override
  String get chatTripClosedNotice => 'Trip Closed Notice';

  @override
  String get chatTypeMessageHint => 'Type Message Hint';

  @override
  String get chatTypingIndicator => 'Typing Indicator';

  @override
  String get clientAddressAddTitle => 'Add address';

  @override
  String get clientAddressEditTitle => 'Edit address';

  @override
  String get clientAddressLoading => 'Loading address';

  @override
  String get clientAddressRemoved => 'Address removed';

  @override
  String get clientBookingLoadingPointHint => 'Loading Point Hint';

  @override
  String get clientBookingUnloadingPointHint => 'Unloading Point Hint';

  @override
  String get clientBookingWeightError => 'Weight Error';

  @override
  String get clientCheckoutCancel => 'Cancel';

  @override
  String get clientCheckoutChooseMethod => 'Choose Method';

  @override
  String get clientCheckoutEnterPin => 'Enter Pin';

  @override
  String get clientCheckoutMethodCards => 'Method Cards';

  @override
  String get clientCheckoutMethodNetbanking => 'Method Netbanking';

  @override
  String get clientCheckoutMethodRecommended => 'Method Recommended';

  @override
  String get clientCheckoutMethodUpi => 'Method UPI';

  @override
  String get clientCheckoutMethodWallet => 'Method Wallet';

  @override
  String get clientCheckoutTestTitle => 'Test Title';

  @override
  String get clientChooseTrucks => 'Client Choose Trucks';

  @override
  String get clientFindingBrokers => 'Client Finding Brokers';

  @override
  String get clientHomeBookAnyTruck => 'Book Any Truck';

  @override
  String get clientHomeLoadingHint => 'Loading Hint';

  @override
  String get clientHomeUnloadingHint => 'Unloading Hint';

  @override
  String get clientNotificationsAllCaughtUp => 'All Caught Up';

  @override
  String get clientNotificationsAllCaughtUpHint => 'All Caught Up Hint';

  @override
  String get clientNotificationsEmpty => 'Empty';

  @override
  String get clientNotificationsEmptyHint => 'Empty Hint';

  @override
  String get clientNotificationsFallbackMessage => 'Fallback Message';

  @override
  String get clientNotificationsFallbackTitle => 'Fallback Title';

  @override
  String get clientNotificationsFilterAll => 'Filter All';

  @override
  String get clientNotificationsFilterUnread => 'Filter Unread';

  @override
  String get clientNotificationsGotIt => 'Got It';

  @override
  String get clientNotificationsKindBooking => 'Kind Booking';

  @override
  String get clientNotificationsKindOffer => 'Kind Offer';

  @override
  String get clientNotificationsKindPayment => 'Kind Payment';

  @override
  String get clientNotificationsKindUpdate => 'Kind Update';

  @override
  String get clientNotificationsLoadError => 'Load Error';

  @override
  String get clientNotificationsMarkAllRead => 'Mark All Read';

  @override
  String get clientNotificationsMarkedRead => 'Marked Read';

  @override
  String get clientNotificationsSaving => 'Saving';

  @override
  String get clientNotificationsTitle => 'Title';

  @override
  String get clientNotificationsTryAgain => 'Try Again';

  @override
  String get clientPaymentAddAccountInvalid => 'Account Invalid';

  @override
  String get clientPaymentAddAccountLabel => 'Account Label';

  @override
  String get clientPaymentAddBankLabel => 'Bank Label';

  @override
  String get clientPaymentAddBankRequired => 'Bank Required';

  @override
  String get clientPaymentAddBankSearchHint => 'Bank Search Hint';

  @override
  String get clientPaymentAddBrandLabel => 'Brand Label';

  @override
  String get clientPaymentAddBrandRequired => 'Brand Required';

  @override
  String get clientPaymentAddCardNote => 'Card Note';

  @override
  String get clientPaymentAddDefaultOption => 'Default Option';

  @override
  String get clientPaymentAddIfscInvalid => 'IFSC Invalid';

  @override
  String get clientPaymentAddIfscLabel => 'IFSC Label';

  @override
  String get clientPaymentAddLast4Label => 'Last4 Label';

  @override
  String get clientPaymentAddLast4Required => 'Last4 Required';

  @override
  String get clientPaymentAddMethod => 'Method';

  @override
  String get clientPaymentAddNoteLabel => 'Note Label';

  @override
  String get clientPaymentAddPrivacyNote => 'Privacy Note';

  @override
  String get clientPaymentAddSaveButton => 'Save Button';

  @override
  String get clientPaymentAddSignInRequired => 'Sign In Required';

  @override
  String get clientPaymentAddTileSubtitle => 'Tile Subtitle';

  @override
  String get clientPaymentAddTileTitle => 'Tile Title';

  @override
  String get clientPaymentAddTitle => 'Title';

  @override
  String get clientPaymentAddTypeLabel => 'Type Label';

  @override
  String get clientPaymentAddUpiInvalid => 'UPI Invalid';

  @override
  String get clientPaymentAddUpiLabel => 'UPI Label';

  @override
  String get clientPaymentAddWalletLabel => 'Wallet Label';

  @override
  String get clientPaymentAddWalletRequired => 'Wallet Required';

  @override
  String get clientPaymentAddWalletSearchHint => 'Wallet Search Hint';

  @override
  String get clientPaymentCardSaved => 'Card Saved';

  @override
  String get clientPaymentDefaultBadge => 'Default Badge';

  @override
  String get clientPaymentDeleteTooltip => 'Delete tooltip';

  @override
  String get clientPaymentEmptySubtitle => 'Empty Subtitle';

  @override
  String get clientPaymentEmptyTitle => 'Empty Title';

  @override
  String get clientPaymentLoadError => 'Load Error';

  @override
  String get clientPaymentLoadErrorHint => 'Load Error Hint';

  @override
  String get clientPaymentMethodsTitle => 'Methods Title';

  @override
  String get clientPaymentRemoved => 'Removed';

  @override
  String get clientPaymentRetry => 'Retry';

  @override
  String get clientPaymentSetDefault => 'Set Default';

  @override
  String get clientPaymentSignInSubtitle => 'Sign In Subtitle';

  @override
  String get clientPaymentSignInTitle => 'Sign In Title';

  @override
  String get clientPaymentTypeBank => 'Type Bank';

  @override
  String get clientPaymentTypeCard => 'Type Card';

  @override
  String get clientPaymentTypeMethod => 'Type Method';

  @override
  String get clientPaymentTypeUpi => 'Type UPI';

  @override
  String get clientPaymentTypeWallet => 'Type Wallet';

  @override
  String get clientPaymentUpiFallback => 'UPI Fallback';

  @override
  String get clientPaymentWalletFallback => 'Wallet Fallback';

  @override
  String get clientPlacesSuggestionsError => 'Suggestions Error';

  @override
  String get clientPublicAssignedDriver => 'Assigned Driver';

  @override
  String get clientPublicDriverLabel => 'Driver Label';

  @override
  String get clientPublicDropLabel => 'Drop Label';

  @override
  String get clientPublicExpressSuffix => 'Express Suffix';

  @override
  String get clientPublicIncidentActive => 'Incident Active';

  @override
  String get clientPublicPickupLabel => 'Pickup Label';

  @override
  String get clientPublicTrackingInvalidLink => 'Tracking Invalid Link';

  @override
  String get clientPublicTrackingUnavailable => 'Tracking Unavailable';

  @override
  String get clientPublicTruckLabel => 'Truck Label';

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
  String get clientSelectVehicle => 'Client Select Vehicle';

  @override
  String get clientTrackingGpsPending => 'Gps Pending';

  @override
  String get clientTrackingLivePendingSubtitle => 'Live Pending Subtitle';

  @override
  String get clientTrackingLivePendingTitle => 'Live Pending Title';

  @override
  String get clientTrackingLivePosition => 'Live Position';

  @override
  String get clientTrackingLoading => 'Loading';

  @override
  String get clientTrackingMapEmptyHint => 'Map Empty Hint';

  @override
  String get clientTrackingMapLoading => 'Map Loading';

  @override
  String get clientTrackingPayNow => 'Pay Now';

  @override
  String get clientTrackingPayRemaining => 'Pay Remaining';

  @override
  String get clientTrackingRateDelivery => 'Rate Delivery';

  @override
  String get clientTrackingSubmitting => 'Submitting';

  @override
  String get clientTrackingUnloading => 'Unloading';

  @override
  String get clientVehicleSelected => 'Selected';

  @override
  String get coreDigilockerAadhaarFallbackNote => 'Aadhaar Fallback Note';

  @override
  String get coreDigilockerBankAccountHint => 'Bank Account Hint';

  @override
  String get coreDigilockerBrokerIntro => 'Broker Intro';

  @override
  String get coreDigilockerBusinessDetails => 'Business Details';

  @override
  String get coreDigilockerBusinessRegHint => 'Business Reg Hint';

  @override
  String get coreDigilockerCheckStatus => 'Check Status';

  @override
  String get coreDigilockerChecking => 'Checking';

  @override
  String get coreDigilockerDidntMatch => 'Didnt Match';

  @override
  String get coreDigilockerDocAadhaar => 'Doc Aadhaar';

  @override
  String get coreDigilockerDocLicense => 'Doc License';

  @override
  String get coreDigilockerDocPan => 'Doc PAN';

  @override
  String get coreDigilockerDriverIntro => 'Driver Intro';

  @override
  String get coreDigilockerGstHint => 'GST Hint';

  @override
  String get coreDigilockerInfoNote => 'Info Note';

  @override
  String get coreDigilockerNoLoginLink => 'No Login Link';

  @override
  String get coreDigilockerNotComplete => 'Not Complete';

  @override
  String get coreDigilockerNotFound => 'Not Found';

  @override
  String get coreDigilockerNotVerifiedYet => 'Not Verified Yet';

  @override
  String get coreDigilockerOpenBrowserFailed => 'Open Browser Failed';

  @override
  String get coreDigilockerOptionalNote => 'Optional Note';

  @override
  String get coreDigilockerPendingRetry => 'Pending Retry';

  @override
  String get coreDigilockerUnreachable => 'Unreachable';

  @override
  String get coreDigilockerVehicleDetails => 'Vehicle Details';

  @override
  String get coreDigilockerVehicleInsuranceHint => 'Vehicle Insurance Hint';

  @override
  String get coreDigilockerVehicleRegHint => 'Vehicle Reg Hint';

  @override
  String get coreDigilockerVerified => 'Verified';

  @override
  String get coreDigilockerVerifyButton => 'Verify Button';

  @override
  String get coreDigilockerVerifyLicense => 'Verify License';

  @override
  String get coreDigilockerVerifyPan => 'Verify PAN';

  @override
  String get coreDigilockerWorking => 'Working';

  @override
  String get coreKycCompleteAction => 'Complete Action';

  @override
  String get coreKycIncompleteBody => 'Incomplete Body';

  @override
  String get coreKycIncompleteTitle => 'Incomplete Title';

  @override
  String get coreKycNotNow => 'Not Now';

  @override
  String get coreKycRejectedBody => 'Rejected Body';

  @override
  String get coreKycRejectedTitle => 'Rejected Title';

  @override
  String get coreKycResubmitAction => 'Resubmit Action';

  @override
  String get coreKycUnderReviewBody => 'Under Review Body';

  @override
  String get coreKycUnderReviewTitle => 'Under Review Title';

  @override
  String get coreKycViewStatusAction => 'View Status Action';

  @override
  String get coreMapDropTitle => 'Drop Title';

  @override
  String get coreMapExpressLabel => 'Express Label';

  @override
  String get coreMapPickupTitle => 'Pickup Title';

  @override
  String get coreMapRouteNotFound => 'Route Not Found';

  @override
  String get deliveryFlowChoosePhoto => 'Choose Photo';

  @override
  String get deliveryFlowCompany => 'Company';

  @override
  String get deliveryFlowContactUnavailable => 'Contact Unavailable';

  @override
  String get deliveryFlowMaxItems => 'Max Items';

  @override
  String get deliveryFlowMyQr => 'My QR';

  @override
  String get deliveryFlowPersonal => 'Personal';

  @override
  String get deliveryFlowPhotosUploaded => 'Photos Uploaded';

  @override
  String get deliveryFlowRecordVideo => 'Record Video';

  @override
  String get deliveryFlowSignInContinue => 'Sign In Continue';

  @override
  String get deliveryFlowSignInUploadPhotos => 'Sign In Upload Photos';

  @override
  String get deliveryFlowTakePhoto => 'Take Photo';

  @override
  String get deliveryFlowVerified => 'Verified';

  @override
  String get driverEarningsCurrentBalance => 'Current Balance';

  @override
  String get driverEarningsLastMonth => 'Last Month';

  @override
  String get driverEarningsNoDeliveries => 'No Deliveries';

  @override
  String get driverEarningsReadyPayout => 'Ready Payout';

  @override
  String get driverEarningsThisMonth => 'This Month';

  @override
  String get driverEarningsTrips => 'Trips';

  @override
  String get driverEarningsViewAll => 'View All';

  @override
  String get driverHomeTripAccepted => 'Trip Accepted';

  @override
  String get driverHomeTripDeclined => 'Trip Declined';

  @override
  String get driverKycEdit => 'Edit';

  @override
  String get driverKycPickFailed => 'Pick Failed';

  @override
  String get driverKycSignInToSubmit => 'Sign In to Submit';

  @override
  String get driverKycSignInToUpload => 'Sign In to Upload';

  @override
  String get driverKycView => 'View';

  @override
  String get driverPaymentCompany => 'Company';

  @override
  String get driverPaymentPersonal => 'Personal';

  @override
  String get driverPaymentQrUploaded => 'QR Uploaded';

  @override
  String get driverPaymentSignInRecord => 'Sign In Record';

  @override
  String get driverPaymentSignInUploadQr => 'Sign In Upload QR';

  @override
  String get driverPaymentVerified => 'Verified';

  @override
  String get gpsAbout => 'About';

  @override
  String get gpsAboutSubtitle => 'About Subtitle';

  @override
  String get gpsAccountDetails => 'Account Details';

  @override
  String get gpsAccountDetailsSubtitle => 'Account Details Subtitle';

  @override
  String get gpsAccountSection => 'Account';

  @override
  String get gpsActive => 'Active';

  @override
  String get gpsAllFleet => 'All Fleet';

  @override
  String get gpsAllVehiclesLiveMap => 'All Vehicles Live Map';

  @override
  String get gpsAppearance => 'Appearance';

  @override
  String get gpsAppearanceSubtitle => 'Appearance Subtitle';

  @override
  String get gpsBackToFleet => 'Back to Fleet';

  @override
  String get gpsCached => 'Cached';

  @override
  String get gpsChangePassword => 'Change Password';

  @override
  String get gpsChangePasswordSubtitle => 'Change Password Subtitle';

  @override
  String get gpsCompleted => 'Completed';

  @override
  String get gpsCreateGeofence => 'Create Geofence';

  @override
  String get gpsCustom => 'Custom';

  @override
  String get gpsDashboardWelcome => 'Dashboard Welcome';

  @override
  String get gpsDeducted => 'Deducted';

  @override
  String get gpsDefineZones => 'Define Zones';

  @override
  String get gpsDuration => 'Duration';

  @override
  String get gpsDurationSubtitle => 'Duration Subtitle';

  @override
  String get gpsExpired => 'Expired';

  @override
  String get gpsExpiredTokensRemoved => 'Expired tokens Removed';

  @override
  String get gpsFilter => 'Filter';

  @override
  String get gpsFilterAll => 'Filter All';

  @override
  String get gpsFleet => 'Fleet';

  @override
  String get gpsFleetStatus => 'Fleet Status';

  @override
  String get gpsFrom => 'From';

  @override
  String get gpsFuelSummary => 'Fuel Summary';

  @override
  String get gpsGenerateReport => 'Generate Report';

  @override
  String get gpsGeofences => 'Geofences';

  @override
  String get gpsGeofencesSubtitle => 'Geofences Subtitle';

  @override
  String get gpsHelpSupport => 'Help Support';

  @override
  String get gpsHelpSupportSubtitle => 'Help Support Subtitle';

  @override
  String get gpsInvoices => 'Invoices';

  @override
  String get gpsList => 'List';

  @override
  String get gpsLiveFleetTracking => 'Live Fleet Tracking';

  @override
  String get gpsLiveMap => 'Live map';

  @override
  String get gpsLiveTrackingUnavailableFleet =>
      'Live Tracking Unavailable Fleet';

  @override
  String get gpsLogout => 'Logout';

  @override
  String get gpsLogoutSubtitle => 'Logout Subtitle';

  @override
  String get gpsMap => 'Map';

  @override
  String get gpsModules => 'Modules';

  @override
  String get gpsMonthlyPlan => 'Monthly Plan';

  @override
  String get gpsMyFleet => 'My fleet';

  @override
  String get gpsMyVehicles => 'My Vehicles';

  @override
  String get gpsMyVehiclesSubtitle => 'My Vehicles Subtitle';

  @override
  String get gpsNavDashboard => 'Dashboard';

  @override
  String get gpsNavProfile => 'Profile';

  @override
  String get gpsNavReports => 'Reports';

  @override
  String get gpsNavVehicles => 'Vehicles';

  @override
  String get gpsNoData => 'No Data';

  @override
  String get gpsNoGeofencesSubtitle => 'No Geofences Subtitle';

  @override
  String get gpsNoGeofencesYet => 'No Geofences Yet';

  @override
  String get gpsNoMoreTransactions => 'No More Transactions';

  @override
  String get gpsNotifications => 'Notifications';

  @override
  String get gpsNotificationsSubtitle => 'Notifications Subtitle';

  @override
  String get gpsOffline => 'Offline';

  @override
  String get gpsOnline => 'Online';

  @override
  String get gpsProfileSubtitle => 'Profile Subtitle';

  @override
  String get gpsRecentActivity => 'Recent Activity';

  @override
  String get gpsReportType => 'Report Type';

  @override
  String get gpsReportTypeSubtitle => 'Report Type Subtitle';

  @override
  String get gpsReportsSecureNote => 'Reports Secure Note';

  @override
  String get gpsReportsSubtitle => 'Reports Subtitle';

  @override
  String get gpsRetry => 'Retry';

  @override
  String get gpsRouteHistory => 'Route History';

  @override
  String get gpsRunning => 'Running';

  @override
  String get gpsSearchGeofences => 'Search Geofences';

  @override
  String get gpsSearchTransactions => 'Search Transactions';

  @override
  String get gpsSearchVehiclesHint => 'Search Vehicles Hint';

  @override
  String get gpsSelectFromFleet => 'Select From Fleet';

  @override
  String get gpsSelectVehicle => 'Select Vehicle';

  @override
  String get gpsSelectVehicleOrFleet => 'Select Vehicle or Fleet';

  @override
  String get gpsSettings => 'Settings';

  @override
  String get gpsSettingsSubtitle => 'Settings Subtitle';

  @override
  String get gpsSignInForFleetDevices => 'Sign In For Fleet Devices';

  @override
  String get gpsSignInForLiveFleet => 'Sign In For Live Fleet';

  @override
  String get gpsSignInForVehicle => 'Sign In For Vehicle';

  @override
  String get gpsStopped => 'Stopped';

  @override
  String get gpsSubscriptionPayment => 'Subscription Payment';

  @override
  String get gpsThisWeek => 'This Week';

  @override
  String get gpsTimeEightMinsAgo => 'Time Eight Mins Ago';

  @override
  String get gpsTimeTwoMinsAgo => 'Time Two Mins Ago';

  @override
  String get gpsTo => 'To';

  @override
  String get gpsToday => 'Today';

  @override
  String get gpsTokenBalance => 'Token Balance';

  @override
  String get gpsTokenExpiry => 'Token Expiry';

  @override
  String get gpsTokenPurchase => 'Token Purchase';

  @override
  String get gpsTokens => 'Tokens';

  @override
  String get gpsTokensAdded => 'Tokens Added';

  @override
  String get gpsTotalVehicles => 'Total Vehicles';

  @override
  String get gpsTotalVehiclesCenter => 'Total Vehicles Center';

  @override
  String get gpsTransactions => 'Transactions';

  @override
  String get gpsTripSummary => 'Trip Summary';

  @override
  String get gpsUsageSummary => 'Usage Summary';

  @override
  String get gpsVehicle => 'Vehicle';

  @override
  String get gpsVehicleLiveMap => 'Vehicle Live Map';

  @override
  String get gpsVehicleNotFound => 'Vehicle Not Found';

  @override
  String get gpsViaRazorpay => 'Via Razorpay';

  @override
  String get gpsViewAll => 'View All';

  @override
  String get gpsVsLastWeek => 'Vs Last Week';

  @override
  String get gpsWalletBilling => 'Wallet & billing';

  @override
  String get gpsWelcomeBonus => 'Welcome Bonus';

  @override
  String get gpsYesterday => 'Yesterday';

  @override
  String get historyDetailsCancel => 'Cancel';

  @override
  String get historyDetailsEmailInvoice => 'Email Invoice';

  @override
  String get historyDetailsRetry => 'Retry';

  @override
  String get historyDetailsSend => 'Send';

  @override
  String get historySegmentCompleted => 'Completed';

  @override
  String get historySegmentPending => 'Pending';

  @override
  String get locationFlowAddLoading => 'Add Loading';

  @override
  String get locationFlowAddLoadingHint => 'Add Loading Hint';

  @override
  String get locationFlowAddUnloading => 'Add Unloading';

  @override
  String get locationFlowAddUnloadingHint => 'Add Unloading Hint';

  @override
  String get locationFlowDropHint => 'Drop Hint';

  @override
  String get locationFlowDropSubtitle => 'Drop Subtitle';

  @override
  String get locationFlowDropTitle => 'Drop Title';

  @override
  String get locationFlowFetching => 'Fetching';

  @override
  String get locationFlowMovePin => 'Move Pin';

  @override
  String get locationFlowOwnUnavailable => 'Own Unavailable';

  @override
  String get locationFlowPermissionNeeded => 'Permission Needed';

  @override
  String get locationFlowPickupHint => 'Pickup Hint';

  @override
  String get locationFlowPickupSubtitle => 'Pickup Subtitle';

  @override
  String get locationFlowPickupTitle => 'Pickup Title';

  @override
  String get locationFlowPinHint => 'Pin Hint';

  @override
  String get locationFlowPinLoading => 'Pin Loading';

  @override
  String get locationFlowPinUnloading => 'Pin Unloading';

  @override
  String get locationFlowResolveCurrent => 'Resolve Current';

  @override
  String get locationFlowResolvePoint => 'Resolve Point';

  @override
  String get locationFlowSavedTitle => 'Saved Title';

  @override
  String get locationFlowSuggestionsError => 'Suggestions Error';

  @override
  String get locationFlowTurnOnLocation => 'Turn On Location';

  @override
  String get locationFlowUseCurrent => 'Use Current';

  @override
  String get locationFlowUseCurrentPickup => 'Use Current Pickup';

  @override
  String get manageAccountActiveLabel => 'Active Label';

  @override
  String get manageAccountActiveNo => 'Active No';

  @override
  String get manageAccountActiveYes => 'Active Yes';

  @override
  String get manageAccountBasicDetails => 'Basic Details';

  @override
  String get manageAccountBusinessAddressLabel => 'Business Address Label';

  @override
  String get manageAccountBusinessDetails => 'Business Details';

  @override
  String get manageAccountChangePhoto => 'Change Photo';

  @override
  String get manageAccountEditProfileSubtitle => 'Edit Profile Subtitle';

  @override
  String get manageAccountEditProfileTitle => 'Edit Profile Title';

  @override
  String get manageAccountEmailLabel => 'Email Label';

  @override
  String get manageAccountEnterEmail => 'Enter Email';

  @override
  String get manageAccountEnterName => 'Enter Name';

  @override
  String get manageAccountEnterServiceCity => 'Enter Service City';

  @override
  String get manageAccountEnterValidEmail => 'Enter Valid Email';

  @override
  String get manageAccountFullNameLabel => 'Full Name Label';

  @override
  String get manageAccountOptionalTag => 'Optional Tag';

  @override
  String get manageAccountPhoneLabel => 'Phone Label';

  @override
  String get manageAccountProfileUpdated => 'Profile Updated';

  @override
  String get manageAccountSaveChanges => 'Save Changes';

  @override
  String get manageAccountServiceCityLabel => 'Service City Label';

  @override
  String get manageAccountYourNameFallback => 'Your Name Fallback';

  @override
  String get negotiationAccept => 'Accept';

  @override
  String get negotiationBack => 'Back';

  @override
  String get negotiationBrokerConfirmBody => 'Broker Confirm Body';

  @override
  String get negotiationBrokerConfirmTitle => 'Broker Confirm Title';

  @override
  String get negotiationBrokerOfferBody => 'Broker Offer Body';

  @override
  String get negotiationBrokerOfferLabel => 'Broker Offer Label';

  @override
  String get negotiationBrokerOfferTitle => 'Broker Offer Title';

  @override
  String get negotiationConfirm => 'Confirm';

  @override
  String get negotiationDecline => 'Decline';

  @override
  String get negotiationDriverAcceptedTitle => 'Driver Accepted Title';

  @override
  String get negotiationDriverConfirmBody => 'Driver Confirm Body';

  @override
  String get negotiationDriverConfirmNowTitle => 'Driver Confirm Now Title';

  @override
  String get negotiationDriverFallback => 'Driver Fallback';

  @override
  String get negotiationDriverResponseBody => 'Driver Response Body';

  @override
  String get negotiationDriverResponseTitle => 'Driver Response Title';

  @override
  String get negotiationFareChangeBody => 'Fare Change Body';

  @override
  String get negotiationFareChangeTitle => 'Fare Change Title';

  @override
  String get negotiationHandshakeProgress => 'Handshake Progress';

  @override
  String get negotiationOfferCaption => 'Offer Caption';

  @override
  String get negotiationOfferSentBody => 'Offer Sent Body';

  @override
  String get negotiationOfferSentTitle => 'Offer Sent Title';

  @override
  String get negotiationPillActionNeeded => 'Pill Action Needed';

  @override
  String get negotiationPillLiveOffer => 'Pill Live Offer';

  @override
  String get negotiationPillNewCounter => 'Pill New Counter';

  @override
  String get negotiationPillWithBroker => 'Pill With Broker';

  @override
  String get negotiationWaitingBrokerBody => 'Waiting Broker Body';

  @override
  String get negotiationWaitingBrokerTitle => 'Waiting Broker Title';

  @override
  String get negotiationWaitingDriverBody => 'Waiting Driver Body';

  @override
  String get negotiationWaitingDriverTitle => 'Waiting Driver Title';

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
  String get orderAcceptedAssignedTitle => 'Assigned Title';

  @override
  String get orderAcceptedOfferUnavailable => 'Offer Unavailable';

  @override
  String get orderAcceptedRequestTitle => 'Request Title';

  @override
  String get orderAcceptedRequestUpdated => 'Request Updated';

  @override
  String get orderAcceptedSignInContinue => 'Sign In Continue';

  @override
  String get photoUploadChoosePhoto => 'Choose Photo';

  @override
  String get photoUploadMaxItems => 'Max Items';

  @override
  String get photoUploadRecordVideo => 'Record Video';

  @override
  String get photoUploadSignInUpload => 'Sign In Upload';

  @override
  String get photoUploadTakePhoto => 'Take Photo';

  @override
  String get podWaitingCouldNotComplete => 'Could Not Complete';

  @override
  String get podWaitingFinishing => 'Finishing';

  @override
  String get podWaitingNewPhotosFallback => 'New Photos Fallback';

  @override
  String get podWaitingPhotosUp => 'Photos Up';

  @override
  String get podWaitingRejectedTitle => 'Rejected Title';

  @override
  String get podWaitingTitle => 'Title';

  @override
  String get podWaitingTryAgain => 'Try Again';

  @override
  String get podWaitingUploadNew => 'Upload New';

  @override
  String get podWaitingWaitingReview => 'Waiting Review';

  @override
  String get sessionExpiredEmailHint => 'Email Hint';

  @override
  String get sessionExpiredEmailLabel => 'Email Label';

  @override
  String get sessionExpiredEnterEmailPassword => 'Enter Email Password';

  @override
  String get sessionExpiredPasswordHint => 'Password Hint';

  @override
  String get sessionExpiredPasswordLabel => 'Password Label';

  @override
  String get sessionExpiredSignInButton => 'Sign In Button';

  @override
  String get sessionExpiredSubtitle => 'Subtitle';

  @override
  String get sessionExpiredTitle => 'Title';

  @override
  String get sharedExpressLabel => 'Express';

  @override
  String get sharedHaltingChargeApplied => 'Charge Applied';

  @override
  String get sharedHaltingExceededTitle => 'Exceeded Title';

  @override
  String get sharedHaltingFreeWindowTitle => 'Free Window Title';

  @override
  String get sharedHaltingRemainingTitle => 'Remaining Title';

  @override
  String get signupAccountCreated => 'Account Created';

  @override
  String get signupAgreeTerms => 'Agree Terms';

  @override
  String get signupAllFieldsRequired => 'All Fields Required';

  @override
  String get signupAlreadyHaveAccount => 'Already Have Account';

  @override
  String get signupBackToLogin => 'Back to Login';

  @override
  String get signupCreateAccount => 'Create Account';

  @override
  String get signupEmailHint => 'Email Hint';

  @override
  String get signupEmailLabel => 'Email Label';

  @override
  String get signupFullNameHint => 'Full Name Hint';

  @override
  String get signupFullNameLabel => 'Full Name Label';

  @override
  String get signupLoginAction => 'Login Action';

  @override
  String get signupPasswordHelper => 'Password Helper';

  @override
  String get signupPasswordHint => 'Password Hint';

  @override
  String get signupPasswordLabel => 'Password Label';

  @override
  String get signupPhoneHint => 'Phone Hint';

  @override
  String get signupPhoneLabel => 'Phone Label';

  @override
  String get signupSubtitle => 'Subtitle';

  @override
  String get signupTermsRequired => 'Terms Required';

  @override
  String get signupTitle => 'Title';

  @override
  String get thankYouBackToTrips => 'Back to Trips';

  @override
  String get thankYouDeliveryComplete => 'Delivery Complete';

  @override
  String get thankYouForCompleting => 'For Completing';

  @override
  String get thankYouPaid => 'Paid';

  @override
  String get thankYouTripCompleted => 'Trip Completed';

  @override
  String get tripSummaryCargo => 'Cargo';

  @override
  String get tripSummaryDelivered => 'Delivered';

  @override
  String get tripSummaryInProgress => 'In Progress';

  @override
  String get tripSummaryLocationUnavailable => 'Location Unavailable';

  @override
  String get truckSearchAllDeclinedHint => 'All Declined Hint';

  @override
  String get truckSearchBack => 'Back';

  @override
  String get truckSearchCancel => 'Cancel';

  @override
  String get truckSearchCloseTooltip => 'Close tooltip';

  @override
  String get truckSearchConfirmTurn => 'Confirm Turn';

  @override
  String get truckSearchConfirmed => 'Confirmed';

  @override
  String get truckSearchDriverFallback => 'Driver Fallback';

  @override
  String get truckSearchFindingDrivers => 'Finding Drivers';

  @override
  String get truckSearchFindingNearby => 'Finding Nearby';

  @override
  String get truckSearchGoBack => 'Go Back';

  @override
  String get truckSearchKeepSearching => 'Keep Searching';

  @override
  String get truckSearchNewFare => 'New Fare';

  @override
  String get truckSearchNoDriverAccepted => 'No Driver Accepted';

  @override
  String get truckSearchNoResponse => 'No Response';

  @override
  String get truckSearchNotifyingDrivers => 'Notifying Drivers';

  @override
  String get truckSearchRetry => 'Retry';

  @override
  String get truckSearchSearching => 'Searching';

  @override
  String get truckSearchWaitingConfirm => 'Waiting Confirm';

  @override
  String get truckSearchWaitingResponse => 'Waiting Response';

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
}
