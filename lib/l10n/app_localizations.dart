import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for this device'**
  String get languageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app looks on this device'**
  String get appearanceSubtitle;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @chatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View conversations from all your bookings'**
  String get chatsSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @clientNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review booking updates and invoice alerts'**
  String get clientNotificationsSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the password for this account'**
  String get changePasswordSubtitle;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage account'**
  String get manageAccount;

  /// No description provided for @manageAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name, email, phone, and photo'**
  String get manageAccountSubtitle;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @savedAddressesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage pickup and drop locations'**
  String get savedAddressesSubtitle;

  /// No description provided for @monthlyVehicleHiring.
  ///
  /// In en, this message translates to:
  /// **'Monthly Vehicle Hiring'**
  String get monthlyVehicleHiring;

  /// No description provided for @monthlyVehicleHiringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hire a truck on a monthly basis'**
  String get monthlyVehicleHiringSubtitle;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @financeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices, settlements, and earnings insights.'**
  String get financeSubtitle;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @invoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review bookings and invoice actions'**
  String get invoicesSubtitle;

  /// No description provided for @settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlements;

  /// No description provided for @settlementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View payouts and settlement status'**
  String get settlementsSubtitle;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track this month vs last month'**
  String get analyticsSubtitle;

  /// No description provided for @brokerNotificationsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open your notification inbox.'**
  String get brokerNotificationsSectionSubtitle;

  /// No description provided for @brokerNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open your notification inbox'**
  String get brokerNotificationsSubtitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @manageAccountTitleCase.
  ///
  /// In en, this message translates to:
  /// **'Manage Account'**
  String get manageAccountTitleCase;

  /// No description provided for @driverManageAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile details, security, and preferences'**
  String get driverManageAccountSubtitle;

  /// No description provided for @kycRegistration.
  ///
  /// In en, this message translates to:
  /// **'KYC Registration'**
  String get kycRegistration;

  /// No description provided for @checkingVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking verification status'**
  String get checkingVerificationStatus;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @completeDriverVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete your driver verification'**
  String get completeDriverVerification;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @driverEarningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trip payouts and completed delivery earnings'**
  String get driverEarningsSubtitle;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @openingChat.
  ///
  /// In en, this message translates to:
  /// **'Opening chat...'**
  String get openingChat;

  /// No description provided for @messageMyBroker.
  ///
  /// In en, this message translates to:
  /// **'Message My Broker'**
  String get messageMyBroker;

  /// No description provided for @messageMyBrokerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open your direct broker conversation'**
  String get messageMyBrokerSubtitle;

  /// No description provided for @allChats.
  ///
  /// In en, this message translates to:
  /// **'All Chats'**
  String get allChats;

  /// No description provided for @allChatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View every driver conversation'**
  String get allChatsSubtitle;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePasswordTitleCase.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitleCase;

  /// No description provided for @driverChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your sign-in credentials'**
  String get driverChangePasswordSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from this device'**
  String get logoutSubtitle;

  /// No description provided for @driverAccount.
  ///
  /// In en, this message translates to:
  /// **'Driver account'**
  String get driverAccount;

  /// No description provided for @noAccountConnected.
  ///
  /// In en, this message translates to:
  /// **'No account connected'**
  String get noAccountConnected;

  /// No description provided for @kycPending.
  ///
  /// In en, this message translates to:
  /// **'KYC Pending'**
  String get kycPending;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @enterEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter both email and password.'**
  String get enterEmailAndPassword;

  /// No description provided for @googleNoIdToken.
  ///
  /// In en, this message translates to:
  /// **'Google did not return an ID token.'**
  String get googleNoIdToken;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get googleSignInCancelled;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.'**
  String get googleSignInFailed;

  /// No description provided for @couldNotOpenRegistration.
  ///
  /// In en, this message translates to:
  /// **'Could not open registration link.'**
  String get couldNotOpenRegistration;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @appleSignInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in is coming soon.'**
  String get appleSignInComingSoon;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @registerAsBrokerDriver.
  ///
  /// In en, this message translates to:
  /// **'Register as Broker/Driver'**
  String get registerAsBrokerDriver;

  /// No description provided for @newEnquiry.
  ///
  /// In en, this message translates to:
  /// **'New Enquiry'**
  String get newEnquiry;

  /// No description provided for @signInToManageEnquiries.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage enquiries'**
  String get signInToManageEnquiries;

  /// No description provided for @signInToManageEnquiriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need an active client session before we can load monthly hiring requests.'**
  String get signInToManageEnquiriesSubtitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @couldNotLoadEnquiries.
  ///
  /// In en, this message translates to:
  /// **'Could not load enquiries'**
  String get couldNotLoadEnquiries;

  /// No description provided for @couldNotLoadEnquiriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh or try again in a moment.'**
  String get couldNotLoadEnquiriesSubtitle;

  /// No description provided for @noEnquiriesYet.
  ///
  /// In en, this message translates to:
  /// **'No enquiries yet'**
  String get noEnquiriesYet;

  /// No description provided for @noEnquiriesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us where and for how long you need a truck, and our team will follow up.'**
  String get noEnquiriesYetSubtitle;

  /// No description provided for @noEnquiriesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No enquiries match your search'**
  String get noEnquiriesMatchSearch;

  /// No description provided for @noEnquiriesMatchSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another location, truck type, or status.'**
  String get noEnquiriesMatchSearchSubtitle;

  /// No description provided for @searchMonthlyEnquiries.
  ///
  /// In en, this message translates to:
  /// **'Search monthly enquiries...'**
  String get searchMonthlyEnquiries;

  /// No description provided for @monthlyTruckHiring.
  ///
  /// In en, this message translates to:
  /// **'Monthly Truck Hiring'**
  String get monthlyTruckHiring;

  /// No description provided for @contacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get contacted;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @perKm.
  ///
  /// In en, this message translates to:
  /// **'Per KM'**
  String get perKm;

  /// No description provided for @fixedRate.
  ///
  /// In en, this message translates to:
  /// **'Fixed Rate'**
  String get fixedRate;

  /// No description provided for @locationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Location not specified'**
  String get locationNotSpecified;

  /// No description provided for @submittedRecently.
  ///
  /// In en, this message translates to:
  /// **'Submitted recently'**
  String get submittedRecently;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String submittedOn(Object date);

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @monthlyHiringFormIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you need — our team will get back to you with options.'**
  String get monthlyHiringFormIntro;

  /// No description provided for @locationRoute.
  ///
  /// In en, this message translates to:
  /// **'Location / Route'**
  String get locationRoute;

  /// No description provided for @monthlyHiringLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pune, or Pune to Mumbai corridor'**
  String get monthlyHiringLocationHint;

  /// No description provided for @truckCategory.
  ///
  /// In en, this message translates to:
  /// **'Truck Category'**
  String get truckCategory;

  /// No description provided for @anyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get anyCategory;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get selectStartDate;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get selectEndDate;

  /// No description provided for @pricingPreference.
  ///
  /// In en, this message translates to:
  /// **'Pricing Preference'**
  String get pricingPreference;

  /// No description provided for @perKmRate.
  ///
  /// In en, this message translates to:
  /// **'Per KM Rate'**
  String get perKmRate;

  /// No description provided for @budgetPerKmOptional.
  ///
  /// In en, this message translates to:
  /// **'Budget (₹ per km) (optional)'**
  String get budgetPerKmOptional;

  /// No description provided for @monthlyBudgetOptional.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget (₹) (optional)'**
  String get monthlyBudgetOptional;

  /// No description provided for @expectedBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Your expected budget'**
  String get expectedBudgetHint;

  /// No description provided for @additionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Details (optional)'**
  String get additionalDetailsOptional;

  /// No description provided for @monthlyHiringDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Anything else that would help — cargo type, expected daily runs, etc.'**
  String get monthlyHiringDetailsHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submitEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Submit Enquiry'**
  String get submitEnquiry;

  /// No description provided for @monthlyHiringLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please tell us where you need the vehicle'**
  String get monthlyHiringLocationRequired;

  /// No description provided for @monthlyHiringDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select both a start and end date'**
  String get monthlyHiringDatesRequired;

  /// No description provided for @monthlyHiringEndDateAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be after the start date'**
  String get monthlyHiringEndDateAfterStart;

  /// No description provided for @signInAgainToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to submit.'**
  String get signInAgainToSubmit;

  /// No description provided for @validBudgetRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid budget amount'**
  String get validBudgetRequired;

  /// No description provided for @enquirySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Enquiry submitted — our team will get in touch soon'**
  String get enquirySubmitted;

  /// No description provided for @driverPhoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Driver phone number is not available.'**
  String get driverPhoneUnavailable;

  /// No description provided for @couldNotOpenPhoneApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app.'**
  String get couldNotOpenPhoneApp;

  /// No description provided for @signInAgainToCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to cancel this booking.'**
  String get signInAgainToCancelBooking;

  /// No description provided for @cancelledByClient.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by client'**
  String get cancelledByClient;

  /// No description provided for @bookingCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled successfully.'**
  String get bookingCancelledSuccessfully;

  /// No description provided for @paymentAmountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Payment amount is unavailable.'**
  String get paymentAmountUnavailable;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment?'**
  String get continueToPayment;

  /// No description provided for @paymentCheckoutMessage.
  ///
  /// In en, this message translates to:
  /// **'This will open secure checkout for ₹{amount}.'**
  String paymentCheckoutMessage(Object amount);

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @bookingPaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Booking payment'**
  String get bookingPaymentDescription;

  /// No description provided for @paymentCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment completed successfully.'**
  String get paymentCompletedSuccessfully;

  /// No description provided for @signInAgainToShareTracking.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to share tracking.'**
  String get signInAgainToShareTracking;

  /// No description provided for @trackingLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tracking link is unavailable.'**
  String get trackingLinkUnavailable;

  /// No description provided for @trackYourShipment.
  ///
  /// In en, this message translates to:
  /// **'Track your shipment'**
  String get trackYourShipment;

  /// No description provided for @trackingShareText.
  ///
  /// In en, this message translates to:
  /// **'Track {trackingId} ({fromLocation} to {toLocation})\n{shareUrl}'**
  String trackingShareText(
    Object trackingId,
    Object fromLocation,
    Object toLocation,
    Object shareUrl,
  );

  /// No description provided for @trackingLinkReadyToShare.
  ///
  /// In en, this message translates to:
  /// **'Tracking link is ready to share.'**
  String get trackingLinkReadyToShare;

  /// No description provided for @trackingLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Tracking link copied to clipboard.'**
  String get trackingLinkCopied;

  /// No description provided for @invoiceFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Invoice file is empty.'**
  String get invoiceFileEmpty;

  /// No description provided for @invoiceDownloadedTo.
  ///
  /// In en, this message translates to:
  /// **'Invoice downloaded to {path}.'**
  String invoiceDownloadedTo(Object path);

  /// No description provided for @invoiceReadyToSaveOrShare.
  ///
  /// In en, this message translates to:
  /// **'Invoice ready to save or share.'**
  String get invoiceReadyToSaveOrShare;

  /// No description provided for @invoiceDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download invoice. Please restart the app and try again.'**
  String get invoiceDownloadFailed;

  /// No description provided for @invoiceDownloadFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to download invoice. Please try again.'**
  String get invoiceDownloadFailedTryAgain;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @shipments.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get shipments;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon.'**
  String get featureComingSoon;

  /// No description provided for @sskVersion.
  ///
  /// In en, this message translates to:
  /// **'SSK Logistics v1.0.0'**
  String get sskVersion;

  /// No description provided for @appearanceLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Liquid glass light mode'**
  String get appearanceLightSubtitle;

  /// No description provided for @appearanceDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Liquid glass dark mode'**
  String get appearanceDarkSubtitle;

  /// No description provided for @liquidGlassAppearance.
  ///
  /// In en, this message translates to:
  /// **'Liquid glass appearance'**
  String get liquidGlassAppearance;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @retryAccountStats.
  ///
  /// In en, this message translates to:
  /// **'Retry account stats'**
  String get retryAccountStats;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @activeShipments.
  ///
  /// In en, this message translates to:
  /// **'Active Shipments'**
  String get activeShipments;

  /// No description provided for @lifetimeValue.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Value'**
  String get lifetimeValue;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @brokerAccount.
  ///
  /// In en, this message translates to:
  /// **'Broker account'**
  String get brokerAccount;

  /// No description provided for @noEmailConnected.
  ///
  /// In en, this message translates to:
  /// **'No email connected'**
  String get noEmailConnected;

  /// No description provided for @standardPlan.
  ///
  /// In en, this message translates to:
  /// **'Standard Plan'**
  String get standardPlan;

  /// No description provided for @brokerEarningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue and settlement performance'**
  String get brokerEarningsSubtitle;

  /// No description provided for @completeBrokerVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete your broker verification'**
  String get completeBrokerVerification;

  /// No description provided for @brokerHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support for account or trip issues'**
  String get brokerHelpSubtitle;

  /// No description provided for @removeFromMyList.
  ///
  /// In en, this message translates to:
  /// **'Remove from my list?'**
  String get removeFromMyList;

  /// No description provided for @removeFromMyListDescription.
  ///
  /// In en, this message translates to:
  /// **'This only removes it from your own list. There\'s no undo.'**
  String get removeFromMyListDescription;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @bookingRemovedFromList.
  ///
  /// In en, this message translates to:
  /// **'Booking removed from your list.'**
  String get bookingRemovedFromList;

  /// No description provided for @invoiceForBooking.
  ///
  /// In en, this message translates to:
  /// **'Invoice for booking {trackingId}'**
  String invoiceForBooking(Object trackingId);

  /// No description provided for @invoiceEmailDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Please find attached the invoice for booking {bookingRef}.'**
  String invoiceEmailDefaultMessage(Object bookingRef);

  /// No description provided for @invoiceEmailedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice emailed successfully.'**
  String get invoiceEmailedSuccessfully;

  /// No description provided for @clientNotifiedInvoiceShared.
  ///
  /// In en, this message translates to:
  /// **'Client notified — invoice shared to their portal.'**
  String get clientNotifiedInvoiceShared;

  /// No description provided for @stopMarkedComplete.
  ///
  /// In en, this message translates to:
  /// **'Stop marked complete.'**
  String get stopMarkedComplete;

  /// No description provided for @forceTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Force trip status?'**
  String get forceTripStatus;

  /// No description provided for @forceTripStatusDescription.
  ///
  /// In en, this message translates to:
  /// **'This moves the trip to \"{status}\" on the driver\'s behalf. Use only if the driver is unreachable.'**
  String forceTripStatusDescription(Object status);

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @tripStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trip status updated.'**
  String get tripStatusUpdated;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded.'**
  String get paymentRecorded;

  /// No description provided for @tripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get tripNotFound;

  /// No description provided for @couldNotLoadJobDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load job details'**
  String get couldNotLoadJobDetails;

  /// No description provided for @completeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Complete Delivery'**
  String get completeDelivery;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @emailAction.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailAction;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @notify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get notify;

  /// No description provided for @removing.
  ///
  /// In en, this message translates to:
  /// **'Removing...'**
  String get removing;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @truck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truck;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @cargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get cargo;

  /// No description provided for @earningsPayment.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Payment'**
  String get earningsPayment;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @timeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time Taken'**
  String get timeTaken;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @routeTo.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String routeTo(Object from, Object to);

  /// No description provided for @driverTakeoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver unreachable? Take over this trip'**
  String get driverTakeoverTitle;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @driverTakeoverDescription.
  ///
  /// In en, this message translates to:
  /// **'Use this only if the driver\'s phone is dead, their app crashed, or they\'ve lost signal. Actions happen directly on the driver\'s behalf.'**
  String get driverTakeoverDescription;

  /// No description provided for @retryLoadingTrip.
  ///
  /// In en, this message translates to:
  /// **'Retry loading trip'**
  String get retryLoadingTrip;

  /// No description provided for @loadingUnloadingStops.
  ///
  /// In en, this message translates to:
  /// **'LOADING & UNLOADING STOPS'**
  String get loadingUnloadingStops;

  /// No description provided for @forceStatus.
  ///
  /// In en, this message translates to:
  /// **'FORCE STATUS'**
  String get forceStatus;

  /// No description provided for @applying.
  ///
  /// In en, this message translates to:
  /// **'Applying...'**
  String get applying;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @markLoaded.
  ///
  /// In en, this message translates to:
  /// **'Mark Loaded'**
  String get markLoaded;

  /// No description provided for @markUnloaded.
  ///
  /// In en, this message translates to:
  /// **'Mark Unloaded'**
  String get markUnloaded;

  /// No description provided for @loadingUnloadingStopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading & Unloading Stops'**
  String get loadingUnloadingStopsTitle;

  /// No description provided for @proofOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Proof of Delivery'**
  String get proofOfDelivery;

  /// No description provided for @awaitingClientReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting client review'**
  String get awaitingClientReview;

  /// No description provided for @clientApproved.
  ///
  /// In en, this message translates to:
  /// **'Client approved'**
  String get clientApproved;

  /// No description provided for @clientRejectedReuploading.
  ///
  /// In en, this message translates to:
  /// **'Client rejected — driver re-uploading'**
  String get clientRejectedReuploading;

  /// No description provided for @sendInvoiceByEmail.
  ///
  /// In en, this message translates to:
  /// **'Send invoice by email'**
  String get sendInvoiceByEmail;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @reassignmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Reassignment History'**
  String get reassignmentHistory;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @reassignedBy.
  ///
  /// In en, this message translates to:
  /// **'By {name} · {date}'**
  String reassignedBy(Object name, Object date);

  /// No description provided for @locationPending.
  ///
  /// In en, this message translates to:
  /// **'Location pending'**
  String get locationPending;

  /// No description provided for @includedHaltingCharge.
  ///
  /// In en, this message translates to:
  /// **'Incl. halting ({hours}h): {amount}'**
  String includedHaltingCharge(Object hours, Object amount);

  /// No description provided for @includedDelayCharge.
  ///
  /// In en, this message translates to:
  /// **'Incl. delay ({hours}h): {amount}'**
  String includedDelayCharge(Object hours, Object amount);

  /// No description provided for @clientReason.
  ///
  /// In en, this message translates to:
  /// **'Client\'s reason: {reason}'**
  String clientReason(Object reason);

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navNewBooking.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get navNewBooking;

  /// No description provided for @navActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get navActive;

  /// No description provided for @navVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get navVehicles;

  /// No description provided for @navTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get navTracking;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navNewTravel.
  ///
  /// In en, this message translates to:
  /// **'New travel'**
  String get navNewTravel;

  /// No description provided for @navEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// No description provided for @broker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get broker;

  /// No description provided for @goodMorningName.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorningName(Object name);

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(Object name);

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @newBookingsWaiting.
  ///
  /// In en, this message translates to:
  /// **'New bookings waiting for you'**
  String get newBookingsWaiting;

  /// No description provided for @jobsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Jobs currently in progress'**
  String get jobsInProgress;

  /// No description provided for @manageFleetAtGlance.
  ///
  /// In en, this message translates to:
  /// **'Manage your fleet at a glance'**
  String get manageFleetAtGlance;

  /// No description provided for @monitorDriverMovement.
  ///
  /// In en, this message translates to:
  /// **'Monitor driver movement'**
  String get monitorDriverMovement;

  /// No description provided for @reviewRecentBookings.
  ///
  /// In en, this message translates to:
  /// **'Review recent bookings'**
  String get reviewRecentBookings;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drop;

  /// No description provided for @dropOff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get dropOff;

  /// No description provided for @truckType.
  ///
  /// In en, this message translates to:
  /// **'Truck Type'**
  String get truckType;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @bookingsCsvCopied.
  ///
  /// In en, this message translates to:
  /// **'Bookings CSV copied to clipboard.'**
  String get bookingsCsvCopied;

  /// No description provided for @signInToViewBookings.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view bookings'**
  String get signInToViewBookings;

  /// No description provided for @signInToViewBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need an active client session before we can load your activity feed.'**
  String get signInToViewBookingsSubtitle;

  /// No description provided for @couldNotLoadBookings.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings'**
  String get couldNotLoadBookings;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @nothingMovingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing moving yet'**
  String get nothingMovingYet;

  /// No description provided for @nothingMovingYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your trucks, trips and live tracking will land here once you make your first booking.'**
  String get nothingMovingYetSubtitle;

  /// No description provided for @myBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage and review your fleet transportation schedules.'**
  String get myBookingsSubtitle;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @newBooking.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get newBooking;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get fromLabel;

  /// No description provided for @shippingToLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping to:'**
  String get shippingToLabel;

  /// No description provided for @pickupLocationNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Pickup location not provided'**
  String get pickupLocationNotProvided;

  /// No description provided for @dropOffLocationNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Drop-off location not provided'**
  String get dropOffLocationNotProvided;

  /// No description provided for @express.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get express;

  /// No description provided for @invoiceEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Please find attached the invoice for booking {trackingId}.'**
  String invoiceEmailMessage(Object trackingId);

  /// No description provided for @emailInvoice.
  ///
  /// In en, this message translates to:
  /// **'Email invoice'**
  String get emailInvoice;

  /// No description provided for @rateBooking.
  ///
  /// In en, this message translates to:
  /// **'Rate booking'**
  String get rateBooking;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us how the delivery went'**
  String get reviewHint;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @thanksForYourRating.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your rating.'**
  String get thanksForYourRating;

  /// No description provided for @raiseDispute.
  ///
  /// In en, this message translates to:
  /// **'Raise dispute'**
  String get raiseDispute;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @damage.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get damage;

  /// No description provided for @delay.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get delay;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @issueType.
  ///
  /// In en, this message translates to:
  /// **'Issue type'**
  String get issueType;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @disputeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in a few words'**
  String get disputeDescriptionHint;

  /// No description provided for @disputeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted.'**
  String get disputeSubmitted;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancelling;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @maps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get maps;

  /// No description provided for @signInAgainToApprove.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to approve.'**
  String get signInAgainToApprove;

  /// No description provided for @proofOfDeliveryApproved.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery approved.'**
  String get proofOfDeliveryApproved;

  /// No description provided for @rejectProofOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Reject proof of delivery?'**
  String get rejectProofOfDelivery;

  /// No description provided for @rejectProofOfDeliveryDescription.
  ///
  /// In en, this message translates to:
  /// **'The driver will be asked to upload new photos before the trip can be completed.'**
  String get rejectProofOfDeliveryDescription;

  /// No description provided for @rejectPodReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Photos are blurry, doesn\'t show delivered cargo...'**
  String get rejectPodReasonHint;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @signInAgainToReject.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to reject.'**
  String get signInAgainToReject;

  /// No description provided for @driverAskedToReuploadPod.
  ///
  /// In en, this message translates to:
  /// **'Asked the driver to re-upload proof of delivery.'**
  String get driverAskedToReuploadPod;

  /// No description provided for @fetchingAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Fetching configured advance amount'**
  String get fetchingAdvanceAmount;

  /// No description provided for @advanceAmountNowBalanceOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'{amount} now, balance on delivery'**
  String advanceAmountNowBalanceOnDelivery(Object amount);

  /// No description provided for @paymentPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get paymentPayNow;

  /// No description provided for @paymentPayNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full amount now through secure checkout'**
  String get paymentPayNowSubtitle;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To Pay'**
  String get toPay;

  /// No description provided for @toPaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full amount collected by the driver on delivery'**
  String get toPaySubtitle;

  /// No description provided for @toBeBilled.
  ///
  /// In en, this message translates to:
  /// **'To Be Billed'**
  String get toBeBilled;

  /// No description provided for @toBeBilledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing collected now or on delivery'**
  String get toBeBilledSubtitle;

  /// No description provided for @toBeBilledUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available after a driver is confirmed'**
  String get toBeBilledUnavailableSubtitle;

  /// No description provided for @chooseFuturePickupTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a future pickup time.'**
  String get chooseFuturePickupTime;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get setTime;

  /// No description provided for @bookingNumberPending.
  ///
  /// In en, this message translates to:
  /// **'Booking Number: Pending'**
  String get bookingNumberPending;

  /// No description provided for @bookingNumberValue.
  ///
  /// In en, this message translates to:
  /// **'Booking Number: {bookingReference}'**
  String bookingNumberValue(Object bookingReference);

  /// No description provided for @trackBooking.
  ///
  /// In en, this message translates to:
  /// **'Track booking'**
  String get trackBooking;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get goToHome;

  /// No description provided for @driverOfferReceived.
  ///
  /// In en, this message translates to:
  /// **'Driver offer received'**
  String get driverOfferReceived;

  /// No description provided for @confirmingWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Confirming with driver'**
  String get confirmingWithDriver;

  /// No description provided for @findingNearbyTrucks.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby trucks'**
  String get findingNearbyTrucks;

  /// No description provided for @driverOfferReceivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opening the live offer popup so you can accept, reject, or change fare.'**
  String get driverOfferReceivedSubtitle;

  /// No description provided for @confirmingWithDriverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You accepted the offer. We are waiting for the driver to complete the handshake.'**
  String get confirmingWithDriverSubtitle;

  /// No description provided for @driversNotifiedRadius.
  ///
  /// In en, this message translates to:
  /// **'Drivers inside {radius} km have been notified. We will show the offer popup when one responds.'**
  String driversNotifiedRadius(Object radius);

  /// No description provided for @bookingLiveNotifyingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Your booking is live. We are notifying drivers inside {radius} km.'**
  String bookingLiveNotifyingDrivers(Object radius);

  /// No description provided for @driverResponse.
  ///
  /// In en, this message translates to:
  /// **'Driver response'**
  String get driverResponse;

  /// No description provided for @waitingForDriverAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver to confirm your acceptance.'**
  String get waitingForDriverAcceptance;

  /// No description provided for @fareChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'Fare change: {amount}'**
  String fareChangeAmount(Object amount);

  /// No description provided for @driverResponseTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Driver response timed out.'**
  String get driverResponseTimedOut;

  /// No description provided for @latestAmount.
  ///
  /// In en, this message translates to:
  /// **'Latest amount: {amount}'**
  String latestAmount(Object amount);

  /// No description provided for @searchingLive.
  ///
  /// In en, this message translates to:
  /// **'Searching live'**
  String get searchingLive;

  /// No description provided for @activeRequestsNearby.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active request nearby} other{{count} active requests nearby}}'**
  String activeRequestsNearby(num count);

  /// No description provided for @declinedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} declined'**
  String declinedCount(Object count);

  /// No description provided for @openTracking.
  ///
  /// In en, this message translates to:
  /// **'Open tracking'**
  String get openTracking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your booking has been successfully placed.'**
  String get bookingPlacedSuccessfully;

  /// No description provided for @couldNotResolveMapPoint.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve this map point.'**
  String get couldNotResolveMapPoint;

  /// No description provided for @loadingPointNumber.
  ///
  /// In en, this message translates to:
  /// **'Loading point {number}'**
  String loadingPointNumber(Object number);

  /// No description provided for @unloadingPointNumber.
  ///
  /// In en, this message translates to:
  /// **'Unloading point {number}'**
  String unloadingPointNumber(Object number);

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @tapMapToSet.
  ///
  /// In en, this message translates to:
  /// **'Tap map to set'**
  String get tapMapToSet;

  /// No description provided for @chooseBrokerToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose a broker to continue.'**
  String get chooseBrokerToContinue;

  /// No description provided for @signInAgainToCreateBooking.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to create a booking.'**
  String get signInAgainToCreateBooking;

  /// No description provided for @selectPickupDropOnMap.
  ///
  /// In en, this message translates to:
  /// **'Please select pickup and drop locations on the map.'**
  String get selectPickupDropOnMap;

  /// No description provided for @couldNotResolvePickupDropCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve exact pickup/drop coordinates. Please choose them from suggestions or the map.'**
  String get couldNotResolvePickupDropCoordinates;

  /// No description provided for @couldNotLoadBrokerOffers.
  ///
  /// In en, this message translates to:
  /// **'Could not load broker offers.'**
  String get couldNotLoadBrokerOffers;

  /// No description provided for @acceptedWaitingForDriverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accepted - waiting for the driver to confirm.'**
  String get acceptedWaitingForDriverConfirm;

  /// No description provided for @declinedDriverStillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Declined {name} - still waiting on the rest.'**
  String declinedDriverStillWaiting(Object name);

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @fareChangeSent.
  ///
  /// In en, this message translates to:
  /// **'Fare change sent.'**
  String get fareChangeSent;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @negotiate.
  ///
  /// In en, this message translates to:
  /// **'Negotiate'**
  String get negotiate;

  /// No description provided for @signInAgainToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get signInAgainToContinue;

  /// No description provided for @enterPickupAndDropLocations.
  ///
  /// In en, this message translates to:
  /// **'Please enter both pickup and drop locations.'**
  String get enterPickupAndDropLocations;

  /// No description provided for @turnOnLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to autofill pickup.'**
  String get turnOnLocationServices;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to autofill pickup.'**
  String get locationPermissionNeeded;

  /// No description provided for @couldNotResolveCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve your current address yet.'**
  String get couldNotResolveCurrentAddress;

  /// No description provided for @expressAvailableForIntraCity.
  ///
  /// In en, this message translates to:
  /// **'Express delivery is available for intra-city bookings.'**
  String get expressAvailableForIntraCity;

  /// No description provided for @enterDropLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter the drop location.'**
  String get enterDropLocation;

  /// No description provided for @findTruck.
  ///
  /// In en, this message translates to:
  /// **'Find Truck'**
  String get findTruck;

  /// No description provided for @brokers.
  ///
  /// In en, this message translates to:
  /// **'Brokers'**
  String get brokers;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadius;

  /// No description provided for @couldNotLoadBrokers.
  ///
  /// In en, this message translates to:
  /// **'Could not load brokers'**
  String get couldNotLoadBrokers;

  /// No description provided for @noBrokerNearby.
  ///
  /// In en, this message translates to:
  /// **'No broker nearby'**
  String get noBrokerNearby;

  /// No description provided for @noEligibleBrokersForRoute.
  ///
  /// In en, this message translates to:
  /// **'No eligible brokers found for this route yet.'**
  String get noEligibleBrokersForRoute;

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout'**
  String get secureCheckout;

  /// No description provided for @payOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pay on delivery'**
  String get payOnDelivery;

  /// No description provided for @noCollectionNow.
  ///
  /// In en, this message translates to:
  /// **'No collection now'**
  String get noCollectionNow;

  /// No description provided for @afterDriverConfirm.
  ///
  /// In en, this message translates to:
  /// **'After driver confirm'**
  String get afterDriverConfirm;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @refreshRequests.
  ///
  /// In en, this message translates to:
  /// **'Refresh requests'**
  String get refreshRequests;

  /// No description provided for @goOnlineToReceiveRequests.
  ///
  /// In en, this message translates to:
  /// **'Go online to receive requests'**
  String get goOnlineToReceiveRequests;

  /// No description provided for @negotiationCardsAppearWhenAvailable.
  ///
  /// In en, this message translates to:
  /// **'Negotiation cards will appear here once you are available.'**
  String get negotiationCardsAppearWhenAvailable;

  /// No description provided for @pleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get pleaseSignInAgain;

  /// No description provided for @activeSessionNeededForRequests.
  ///
  /// In en, this message translates to:
  /// **'We need an active session before we can load requests.'**
  String get activeSessionNeededForRequests;

  /// No description provided for @loadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Loading requests'**
  String get loadingRequests;

  /// No description provided for @fetchingDriverRequests.
  ///
  /// In en, this message translates to:
  /// **'Fetching driver requests from the server.'**
  String get fetchingDriverRequests;

  /// No description provided for @couldNotLoadRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests'**
  String get couldNotLoadRequests;

  /// No description provided for @noNewDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No new deliveries'**
  String get noNewDeliveries;

  /// No description provided for @newClientRequestsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'New client requests will appear here when they arrive.'**
  String get newClientRequestsAppearHere;

  /// No description provided for @requestTimedOutBrokerHandoff.
  ///
  /// In en, this message translates to:
  /// **'This request timed out for the driver. Broker handoff is active.'**
  String get requestTimedOutBrokerHandoff;

  /// No description provided for @swipeToAccept.
  ///
  /// In en, this message translates to:
  /// **'Swipe to accept'**
  String get swipeToAccept;

  /// No description provided for @alreadyAgreedWithBroker.
  ///
  /// In en, this message translates to:
  /// **'Already agreed with the broker - accept or decline.'**
  String get alreadyAgreedWithBroker;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @fullTripHistoryAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Your full trip history will appear here.'**
  String get fullTripHistoryAppearsHere;

  /// No description provided for @noActiveDelivery.
  ///
  /// In en, this message translates to:
  /// **'No active delivery'**
  String get noActiveDelivery;

  /// No description provided for @acceptedDeliveriesAppearLive.
  ///
  /// In en, this message translates to:
  /// **'Accepted deliveries will appear here live.'**
  String get acceptedDeliveriesAppearLive;

  /// No description provided for @loadingTrips.
  ///
  /// In en, this message translates to:
  /// **'Loading trips...'**
  String get loadingTrips;

  /// No description provided for @activeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Active delivery'**
  String get activeDelivery;

  /// No description provided for @liveTripAppearsFirst.
  ///
  /// In en, this message translates to:
  /// **'Your live trip appears here first'**
  String get liveTripAppearsFirst;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total trips'**
  String get totalTrips;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get totalEarned;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @addDriver.
  ///
  /// In en, this message translates to:
  /// **'Add driver'**
  String get addDriver;

  /// No description provided for @removeDriverQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove driver?'**
  String get removeDriverQuestion;

  /// No description provided for @deleteDriverFromFleet.
  ///
  /// In en, this message translates to:
  /// **'This will delete {name} from the broker fleet.'**
  String deleteDriverFromFleet(Object name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @signInAgainToDeleteDriver.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to delete a driver.'**
  String get signInAgainToDeleteDriver;

  /// No description provided for @driverRemoved.
  ///
  /// In en, this message translates to:
  /// **'Driver removed from fleet.'**
  String get driverRemoved;

  /// No description provided for @reportIncident.
  ///
  /// In en, this message translates to:
  /// **'Report incident'**
  String get reportIncident;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @incidentReported.
  ///
  /// In en, this message translates to:
  /// **'Incident reported successfully.'**
  String get incidentReported;

  /// No description provided for @collectSettlement.
  ///
  /// In en, this message translates to:
  /// **'Collect settlement'**
  String get collectSettlement;

  /// No description provided for @chooseSettlementMode.
  ///
  /// In en, this message translates to:
  /// **'Choose the settlement mode for this trip.'**
  String get chooseSettlementMode;

  /// No description provided for @settlementUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settlement updated.'**
  String get settlementUpdated;

  /// No description provided for @updateMechanic.
  ///
  /// In en, this message translates to:
  /// **'Update mechanic'**
  String get updateMechanic;

  /// No description provided for @mechanicName.
  ///
  /// In en, this message translates to:
  /// **'Mechanic name'**
  String get mechanicName;

  /// No description provided for @mechanicPhone.
  ///
  /// In en, this message translates to:
  /// **'Mechanic phone'**
  String get mechanicPhone;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @mechanicDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mechanic details updated.'**
  String get mechanicDetailsUpdated;

  /// No description provided for @driverLocationActivityOverview.
  ///
  /// In en, this message translates to:
  /// **'Driver location and activity overview'**
  String get driverLocationActivityOverview;

  /// No description provided for @tripId.
  ///
  /// In en, this message translates to:
  /// **'Trip {id}'**
  String tripId(Object id);

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPending;

  /// No description provided for @incidentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 incident} other{{count} incidents}}'**
  String incidentsCount(num count);

  /// No description provided for @tripProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip progress'**
  String get tripProgress;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssue;

  /// No description provided for @settle.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get settle;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @reassignDriver.
  ///
  /// In en, this message translates to:
  /// **'Reassign driver'**
  String get reassignDriver;

  /// No description provided for @currentlyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Currently assigned: {name}'**
  String currentlyAssigned(Object name);

  /// No description provided for @reassignTo.
  ///
  /// In en, this message translates to:
  /// **'Reassign to'**
  String get reassignTo;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @reassignReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Driver unavailable, breakdown, better route fit...'**
  String get reassignReasonHint;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @mechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get mechanic;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @requestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Request updated.'**
  String get requestUpdated;

  /// No description provided for @driverRequests.
  ///
  /// In en, this message translates to:
  /// **'Driver requests'**
  String get driverRequests;

  /// No description provided for @noDriverRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No driver requests yet.'**
  String get noDriverRequestsYet;

  /// No description provided for @driverReassigned.
  ///
  /// In en, this message translates to:
  /// **'Driver reassigned.'**
  String get driverReassigned;

  /// No description provided for @tripMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip marked as completed.'**
  String get tripMarkedCompleted;

  /// No description provided for @stopMarkedCompleteWithLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} marked complete.'**
  String stopMarkedCompleteWithLabel(Object label);

  /// No description provided for @incidentResolved.
  ///
  /// In en, this message translates to:
  /// **'Incident resolved.'**
  String get incidentResolved;

  /// No description provided for @driverLocation.
  ///
  /// In en, this message translates to:
  /// **'Driver location'**
  String get driverLocation;

  /// No description provided for @tripDestination.
  ///
  /// In en, this message translates to:
  /// **'Trip destination'**
  String get tripDestination;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get inTransit;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get tripCompleted;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @brokerUpdatedPayout.
  ///
  /// In en, this message translates to:
  /// **'Broker updated the payout'**
  String get brokerUpdatedPayout;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @signInToLoadTripProgress.
  ///
  /// In en, this message translates to:
  /// **'Sign in to load trip progress'**
  String get signInToLoadTripProgress;

  /// No description provided for @driverLocationOnly.
  ///
  /// In en, this message translates to:
  /// **'Driver location only'**
  String get driverLocationOnly;

  /// No description provided for @liveDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live details unavailable'**
  String get liveDetailsUnavailable;

  /// No description provided for @tripDestinationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Trip destination not available'**
  String get tripDestinationNotAvailable;

  /// No description provided for @vehicleTracking.
  ///
  /// In en, this message translates to:
  /// **'Vehicle tracking'**
  String get vehicleTracking;

  /// No description provided for @tripStillSyncing.
  ///
  /// In en, this message translates to:
  /// **'Trip is still syncing. Please try again.'**
  String get tripStillSyncing;

  /// No description provided for @declineThisTrip.
  ///
  /// In en, this message translates to:
  /// **'Decline this trip?'**
  String get declineThisTrip;

  /// No description provided for @declineTripDescription.
  ///
  /// In en, this message translates to:
  /// **'You will be freed from this trip and your broker can assign another driver. This cannot be undone.'**
  String get declineTripDescription;

  /// No description provided for @keepTrip.
  ///
  /// In en, this message translates to:
  /// **'Keep trip'**
  String get keepTrip;

  /// No description provided for @declineTrip.
  ///
  /// In en, this message translates to:
  /// **'Decline trip'**
  String get declineTrip;

  /// No description provided for @tripDeclined.
  ///
  /// In en, this message translates to:
  /// **'Trip declined.'**
  String get tripDeclined;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming...'**
  String get confirming;

  /// No description provided for @slideToDeliver.
  ///
  /// In en, this message translates to:
  /// **'Slide to deliver'**
  String get slideToDeliver;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @allowDisplayOverApps.
  ///
  /// In en, this message translates to:
  /// **'Allow display over other apps'**
  String get allowDisplayOverApps;

  /// No description provided for @allowDisplayOverAppsText.
  ///
  /// In en, this message translates to:
  /// **'This opens SSK\'s page in system Settings.\n\n1. Turn ON \"Allow display over other apps\".\n2. Press back - Maps opens automatically with the floating SSK button.\n\n(On Xiaomi/Redmi/Poco the toggle may be called \"Display pop-up windows\".)'**
  String get allowDisplayOverAppsText;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @couldNotOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not open Settings. Open it manually: Settings > Apps > SSK > Display over other apps.'**
  String get couldNotOpenSettings;

  /// No description provided for @couldNotShowFloatingButton.
  ///
  /// In en, this message translates to:
  /// **'Could not show the floating button on this device. Opening Maps anyway.'**
  String get couldNotShowFloatingButton;

  /// No description provided for @tapBubbleToReturn.
  ///
  /// In en, this message translates to:
  /// **'Tap the SSK bubble over Maps to return.'**
  String get tapBubbleToReturn;

  /// No description provided for @navigateToDrop.
  ///
  /// In en, this message translates to:
  /// **'Navigate to drop'**
  String get navigateToDrop;

  /// No description provided for @callPolice.
  ///
  /// In en, this message translates to:
  /// **'Call Police'**
  String get callPolice;

  /// No description provided for @emergency112.
  ///
  /// In en, this message translates to:
  /// **'Emergency: 112'**
  String get emergency112;

  /// No description provided for @callingPoliceSoon.
  ///
  /// In en, this message translates to:
  /// **'Calling police support soon.'**
  String get callingPoliceSoon;

  /// No description provided for @callAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Call Ambulance'**
  String get callAmbulance;

  /// No description provided for @emergency108.
  ///
  /// In en, this message translates to:
  /// **'Emergency: 108'**
  String get emergency108;

  /// No description provided for @callingAmbulanceSoon.
  ///
  /// In en, this message translates to:
  /// **'Calling ambulance support soon.'**
  String get callingAmbulanceSoon;

  /// No description provided for @callBroker.
  ///
  /// In en, this message translates to:
  /// **'Call Broker'**
  String get callBroker;

  /// No description provided for @callingBrokerSoon.
  ///
  /// In en, this message translates to:
  /// **'Calling broker soon.'**
  String get callingBrokerSoon;

  /// No description provided for @reportIncidentToSupport.
  ///
  /// In en, this message translates to:
  /// **'Report Incident to Support'**
  String get reportIncidentToSupport;

  /// No description provided for @notifySupportImmediately.
  ///
  /// In en, this message translates to:
  /// **'Notify our support team immediately'**
  String get notifySupportImmediately;

  /// No description provided for @viewMechanicStatus.
  ///
  /// In en, this message translates to:
  /// **'View Mechanic Status'**
  String get viewMechanicStatus;

  /// No description provided for @seeRepairProgress.
  ///
  /// In en, this message translates to:
  /// **'See breakdown and repair progress'**
  String get seeRepairProgress;

  /// No description provided for @signInAgainToViewMechanicStatus.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to view mechanic status.'**
  String get signInAgainToViewMechanicStatus;

  /// No description provided for @chatUnavailableForTrip.
  ///
  /// In en, this message translates to:
  /// **'Chat is not available for this trip yet.'**
  String get chatUnavailableForTrip;

  /// No description provided for @customerPhoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Customer phone number is not available.'**
  String get customerPhoneUnavailable;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @incidentDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s going on? Your broker and the client will be notified right away.'**
  String get incidentDialogSubtitle;

  /// No description provided for @addDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Add any details (optional)'**
  String get addDetailsOptional;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @accident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get accident;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @trafficBlock.
  ///
  /// In en, this message translates to:
  /// **'Traffic Block'**
  String get trafficBlock;

  /// No description provided for @medical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get medical;

  /// No description provided for @incidentReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{type} report submitted to support.'**
  String incidentReportSubmitted(Object type);

  /// No description provided for @signInAgainToReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to report the issue.'**
  String get signInAgainToReportIssue;

  /// No description provided for @noIncidentsReported.
  ///
  /// In en, this message translates to:
  /// **'No incidents reported for this trip yet.'**
  String get noIncidentsReported;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @pickupPending.
  ///
  /// In en, this message translates to:
  /// **'Pickup pending'**
  String get pickupPending;

  /// No description provided for @dropPending.
  ///
  /// In en, this message translates to:
  /// **'Drop pending'**
  String get dropPending;

  /// No description provided for @trackingActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the live APIs for chat, invoice, rating, payment, and disputes.'**
  String get trackingActionsSubtitle;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get openChat;

  /// No description provided for @openChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Message the booking thread over Socket.IO'**
  String get openChatSubtitle;

  /// No description provided for @negotiationOffers.
  ///
  /// In en, this message translates to:
  /// **'Negotiation & offers'**
  String get negotiationOffers;

  /// No description provided for @negotiationOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review driver requests and broker offers'**
  String get negotiationOffersSubtitle;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download invoice'**
  String get downloadInvoice;

  /// No description provided for @downloadInvoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch the PDF invoice stream'**
  String get downloadInvoiceSubtitle;

  /// No description provided for @emailInvoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send the invoice PDF by email'**
  String get emailInvoiceSubtitle;

  /// No description provided for @payBooking.
  ///
  /// In en, this message translates to:
  /// **'Pay booking'**
  String get payBooking;

  /// No description provided for @openSecureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Open secure checkout'**
  String get openSecureCheckout;

  /// No description provided for @submitDeliveryFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit delivery feedback'**
  String get submitDeliveryFeedback;

  /// No description provided for @raiseDisputeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a backend dispute record'**
  String get raiseDisputeSubtitle;

  /// No description provided for @messageCouldNotBeSent.
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent.'**
  String get messageCouldNotBeSent;

  /// No description provided for @driverRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Driver request accepted.'**
  String get driverRequestAccepted;

  /// No description provided for @driverRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Driver request declined.'**
  String get driverRequestDeclined;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted.'**
  String get offerAccepted;

  /// No description provided for @acceptedWaitingForBrokerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accepted - waiting for the broker to confirm.'**
  String get acceptedWaitingForBrokerConfirm;

  /// No description provided for @offerDeclined.
  ///
  /// In en, this message translates to:
  /// **'Offer declined.'**
  String get offerDeclined;

  /// No description provided for @changeFare.
  ///
  /// In en, this message translates to:
  /// **'Change Fare'**
  String get changeFare;

  /// No description provided for @nearbyDriverOffers.
  ///
  /// In en, this message translates to:
  /// **'Nearby driver offers ({count})'**
  String nearbyDriverOffers(Object count);

  /// No description provided for @driverConfirmedBooking.
  ///
  /// In en, this message translates to:
  /// **'This driver confirmed your booking.'**
  String get driverConfirmedBooking;

  /// No description provided for @nearbyDriverOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every nearby driver gets their own card - accept, change fare, or decline each one separately.'**
  String get nearbyDriverOffersSubtitle;

  /// No description provided for @noDriverOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No driver offers yet'**
  String get noDriverOffersYet;

  /// No description provided for @driverOffersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Once a nearby driver responds, the offers will appear here.'**
  String get driverOffersAppearHere;

  /// No description provided for @driverOffer.
  ///
  /// In en, this message translates to:
  /// **'Driver offer'**
  String get driverOffer;

  /// No description provided for @brokerOffers.
  ///
  /// In en, this message translates to:
  /// **'Broker offers'**
  String get brokerOffers;

  /// No description provided for @brokerOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fare changes sent after the booking was broadcast.'**
  String get brokerOffersSubtitle;

  /// No description provided for @noBrokerOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No broker offers yet'**
  String get noBrokerOffersYet;

  /// No description provided for @brokerOffersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Once a broker responds, the offers will appear here.'**
  String get brokerOffersAppearHere;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @brokerReqDetailRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected.'**
  String get brokerReqDetailRequestRejected;

  /// No description provided for @brokerReqDetailFareChangeSent.
  ///
  /// In en, this message translates to:
  /// **'Fare change sent.'**
  String get brokerReqDetailFareChangeSent;

  /// No description provided for @brokerReqDetailAcceptedWaitingForTheClientToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accepted - waiting for the client to confirm.'**
  String get brokerReqDetailAcceptedWaitingForTheClientToConfirm;

  /// No description provided for @brokerReqDetailOfferSentToTheDriverWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Offer sent to the driver - waiting for response.'**
  String get brokerReqDetailOfferSentToTheDriverWaitingFor;

  /// No description provided for @brokerReqDetailAssignDriverTruck.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver & Truck'**
  String get brokerReqDetailAssignDriverTruck;

  /// No description provided for @brokerReqDetailBookingPickAnAvailableDriverAndTruck.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id} - pick an available driver and truck.'**
  String brokerReqDetailBookingPickAnAvailableDriverAndTruck(Object id);

  /// No description provided for @brokerReqDetailDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get brokerReqDetailDriver;

  /// No description provided for @brokerReqDetailTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get brokerReqDetailTruck;

  /// No description provided for @brokerReqDetailSelectOneIdleDriverAndOneIdle.
  ///
  /// In en, this message translates to:
  /// **'Select one idle driver and one idle truck to continue.'**
  String get brokerReqDetailSelectOneIdleDriverAndOneIdle;

  /// No description provided for @brokerReqDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerReqDetailCancel;

  /// No description provided for @brokerReqDetailConfirmAssignment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Assignment'**
  String get brokerReqDetailConfirmAssignment;

  /// No description provided for @brokerReqDetailSelectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select driver'**
  String get brokerReqDetailSelectDriver;

  /// No description provided for @brokerReqDetailSelectTruck.
  ///
  /// In en, this message translates to:
  /// **'Select truck'**
  String get brokerReqDetailSelectTruck;

  /// No description provided for @brokerReqDetailNegotiationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Negotiation accepted.'**
  String get brokerReqDetailNegotiationAccepted;

  /// No description provided for @brokerReqDetailWaitingForClientConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client confirmation'**
  String get brokerReqDetailWaitingForClientConfirmation;

  /// No description provided for @brokerReqDetailYourAcceptHasBeenSavedFareChanges.
  ///
  /// In en, this message translates to:
  /// **'Your accept has been saved. Fare changes are locked until the client confirms or declines.'**
  String get brokerReqDetailYourAcceptHasBeenSavedFareChanges;

  /// No description provided for @brokerReqDetailYourAcceptHasBeenSavedNoMore.
  ///
  /// In en, this message translates to:
  /// **'Your accept has been saved. No more fare changes are available until the client responds.'**
  String get brokerReqDetailYourAcceptHasBeenSavedNoMore;

  /// No description provided for @brokerReqDetailYourAcceptHasBeenSavedTheRequest.
  ///
  /// In en, this message translates to:
  /// **'Your accept has been saved. The request is locked until the client confirms or declines.'**
  String get brokerReqDetailYourAcceptHasBeenSavedTheRequest;

  /// No description provided for @brokerReqDetailBrokerAssigned.
  ///
  /// In en, this message translates to:
  /// **'Broker-assigned'**
  String get brokerReqDetailBrokerAssigned;

  /// No description provided for @brokerReqDetailAssignedDriverRequest.
  ///
  /// In en, this message translates to:
  /// **'Assigned driver request'**
  String get brokerReqDetailAssignedDriverRequest;

  /// No description provided for @brokerReqDetailThisPriceWasAlreadyAgreedWithThe.
  ///
  /// In en, this message translates to:
  /// **'This price was already agreed with the broker. Accept or decline only - no fare changes.'**
  String get brokerReqDetailThisPriceWasAlreadyAgreedWithThe;

  /// No description provided for @brokerReqDetailReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get brokerReqDetailReject;

  /// No description provided for @brokerReqDetailBrokerNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Broker negotiation'**
  String get brokerReqDetailBrokerNegotiation;

  /// No description provided for @brokerReqDetailFareAmount.
  ///
  /// In en, this message translates to:
  /// **'Fare amount'**
  String get brokerReqDetailFareAmount;

  /// No description provided for @brokerReqDetailChangeFare.
  ///
  /// In en, this message translates to:
  /// **'Change Fare'**
  String get brokerReqDetailChangeFare;

  /// No description provided for @brokerReqDetailAutoSelectedAssignment.
  ///
  /// In en, this message translates to:
  /// **'Auto-selected assignment'**
  String get brokerReqDetailAutoSelectedAssignment;

  /// No description provided for @brokerReqDetailNoExactMatchFoundAFallbackDriver.
  ///
  /// In en, this message translates to:
  /// **'No exact match found — a fallback driver or truck will be used when you accept.'**
  String get brokerReqDetailNoExactMatchFoundAFallbackDriver;

  /// No description provided for @brokerReqDetailBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get brokerReqDetailBookingDetails;

  /// No description provided for @brokerReqDetailOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get brokerReqDetailOverview;

  /// No description provided for @brokerReqDetailRequestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested on'**
  String get brokerReqDetailRequestedOn;

  /// No description provided for @brokerReqDetailRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get brokerReqDetailRequestedBy;

  /// No description provided for @brokerReqDetailLoadType.
  ///
  /// In en, this message translates to:
  /// **'Load type'**
  String get brokerReqDetailLoadType;

  /// No description provided for @brokerReqDetailPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get brokerReqDetailPayment;

  /// No description provided for @brokerReqDetailRouteInformation.
  ///
  /// In en, this message translates to:
  /// **'Route Information'**
  String get brokerReqDetailRouteInformation;

  /// No description provided for @brokerReqDetailPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerReqDetailPickup;

  /// No description provided for @brokerReqDetailDropOff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get brokerReqDetailDropOff;

  /// No description provided for @brokerReqDetailWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get brokerReqDetailWeight;

  /// No description provided for @brokerReqDetailVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get brokerReqDetailVehicle;

  /// No description provided for @brokerReqDetailETA.
  ///
  /// In en, this message translates to:
  /// **'ETA: {eta}'**
  String brokerReqDetailETA(Object eta);

  /// No description provided for @brokerReqDetailSetFareAmount.
  ///
  /// In en, this message translates to:
  /// **'Set fare amount'**
  String get brokerReqDetailSetFareAmount;

  /// No description provided for @brokerHomeDeclinedPickADifferentDriverForThis.
  ///
  /// In en, this message translates to:
  /// **'{name} declined. Pick a different driver for this request.'**
  String brokerHomeDeclinedPickADifferentDriverForThis(Object name);

  /// No description provided for @brokerHomeConfirmedTripCreated.
  ///
  /// In en, this message translates to:
  /// **'Confirmed. Trip created for {name}.'**
  String brokerHomeConfirmedTripCreated(Object name);

  /// No description provided for @brokerHomeOfferSentToTheDriverWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Offer sent to the driver - waiting for response.'**
  String get brokerHomeOfferSentToTheDriverWaitingFor;

  /// No description provided for @brokerHomeChangeFare.
  ///
  /// In en, this message translates to:
  /// **'Change fare'**
  String get brokerHomeChangeFare;

  /// No description provided for @brokerHomeBookingProposeADifferentAmount.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id}: propose a different amount.'**
  String brokerHomeBookingProposeADifferentAmount(Object id);

  /// No description provided for @brokerHomeEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get brokerHomeEnterAmount;

  /// No description provided for @brokerHomeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerHomeCancel;

  /// No description provided for @brokerHomeChangeFare2.
  ///
  /// In en, this message translates to:
  /// **'Change Fare'**
  String get brokerHomeChangeFare2;

  /// No description provided for @brokerHomeSearchBookingIDLocation.
  ///
  /// In en, this message translates to:
  /// **'Search booking ID, location...'**
  String get brokerHomeSearchBookingIDLocation;

  /// No description provided for @brokerHomeBookingRequests.
  ///
  /// In en, this message translates to:
  /// **'Booking Requests'**
  String get brokerHomeBookingRequests;

  /// No description provided for @brokerHomeSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get brokerHomeSort;

  /// No description provided for @brokerHomeNoBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get brokerHomeNoBookingsFound;

  /// No description provided for @brokerHomeCouldNotLoadBookings.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings'**
  String get brokerHomeCouldNotLoadBookings;

  /// No description provided for @brokerHomeReloadRequests.
  ///
  /// In en, this message translates to:
  /// **'Reload requests'**
  String get brokerHomeReloadRequests;

  /// No description provided for @brokerHomeNewBookings.
  ///
  /// In en, this message translates to:
  /// **'New bookings'**
  String get brokerHomeNewBookings;

  /// No description provided for @brokerHomeTo.
  ///
  /// In en, this message translates to:
  /// **'{pickup} to {drop}'**
  String brokerHomeTo(Object pickup, Object drop);

  /// No description provided for @brokerHomePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerHomePickup;

  /// No description provided for @brokerHomeDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get brokerHomeDrop;

  /// No description provided for @brokerHomeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get brokerHomeDistance;

  /// No description provided for @brokerHomeWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get brokerHomeWeight;

  /// No description provided for @brokerHomeClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get brokerHomeClient;

  /// No description provided for @brokerHomeAssignDriverTruck.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver & Truck'**
  String get brokerHomeAssignDriverTruck;

  /// No description provided for @brokerHomeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get brokerHomeConfirm;

  /// No description provided for @brokerHomeDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get brokerHomeDecline;

  /// No description provided for @brokerHomeAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get brokerHomeAccept;

  /// No description provided for @brokerHomeReviewRequest.
  ///
  /// In en, this message translates to:
  /// **'Review request'**
  String get brokerHomeReviewRequest;

  /// No description provided for @brokerHomeChooseAnIdleDriverAndTruck.
  ///
  /// In en, this message translates to:
  /// **'Choose an idle driver and truck for {booking}.'**
  String brokerHomeChooseAnIdleDriverAndTruck(Object booking);

  /// No description provided for @brokerHomeDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get brokerHomeDriver;

  /// No description provided for @brokerHomeTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get brokerHomeTruck;

  /// No description provided for @brokerHomeSelectOneIdleDriverAndOneIdle.
  ///
  /// In en, this message translates to:
  /// **'Select one idle driver and one idle truck to continue.'**
  String get brokerHomeSelectOneIdleDriverAndOneIdle;

  /// No description provided for @brokerHomeSelect.
  ///
  /// In en, this message translates to:
  /// **'Select {label}'**
  String brokerHomeSelect(Object label);

  /// No description provided for @brokerHomeCouldNotLoadAssignmentOptions.
  ///
  /// In en, this message translates to:
  /// **'Could not load assignment options'**
  String get brokerHomeCouldNotLoadAssignmentOptions;

  /// No description provided for @brokerHomeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get brokerHomeRetry;

  /// No description provided for @brokerHomeNEGOTIATIONHISTORY.
  ///
  /// In en, this message translates to:
  /// **'NEGOTIATION HISTORY'**
  String get brokerHomeNEGOTIATIONHISTORY;

  /// No description provided for @brokerKycPleaseSignInAgainToSubmitKYC.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to submit KYC.'**
  String get brokerKycPleaseSignInAgainToSubmitKYC;

  /// No description provided for @brokerKycIsProvidedInTheDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'{document} is provided in the details section.'**
  String brokerKycIsProvidedInTheDetailsSection(Object document);

  /// No description provided for @brokerKycPleaseSignInAgainToUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to upload documents.'**
  String get brokerKycPleaseSignInAgainToUploadDocuments;

  /// No description provided for @brokerKycUnableToPickDocumentRightNow.
  ///
  /// In en, this message translates to:
  /// **'Unable to pick document right now.'**
  String get brokerKycUnableToPickDocumentRightNow;

  /// No description provided for @brokerKycChooseHowYouWantToUploadThis.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to upload this document.'**
  String get brokerKycChooseHowYouWantToUploadThis;

  /// No description provided for @brokerKycCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get brokerKycCamera;

  /// No description provided for @brokerKycGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get brokerKycGallery;

  /// No description provided for @brokerKycCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerKycCancel;

  /// No description provided for @brokerKycDocumentPreview.
  ///
  /// In en, this message translates to:
  /// **'Document preview'**
  String get brokerKycDocumentPreview;

  /// No description provided for @brokerKycClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get brokerKycClose;

  /// No description provided for @brokerKycCompleteYourKYCToVerifyYourBrokerage.
  ///
  /// In en, this message translates to:
  /// **'Complete your KYC to verify your brokerage account.'**
  String get brokerKycCompleteYourKYCToVerifyYourBrokerage;

  /// No description provided for @brokerKycUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get brokerKycUploadDocuments;

  /// No description provided for @brokerKycAllYourDocumentsAreVerifiedThroughDigiLocker.
  ///
  /// In en, this message translates to:
  /// **'All your documents are verified through DigiLocker — nothing to upload.'**
  String get brokerKycAllYourDocumentsAreVerifiedThroughDigiLocker;

  /// No description provided for @brokerKycAadhaarAndPANVerifiedContinueToReview.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar and PAN verified. Continue to review and finish.'**
  String get brokerKycAadhaarAndPANVerifiedContinueToReview;

  /// No description provided for @brokerKycThesePhotosSupportManualReviewForThe.
  ///
  /// In en, this message translates to:
  /// **'These photos support manual review for the documents DigiLocker couldn’t confirm.'**
  String get brokerKycThesePhotosSupportManualReviewForThe;

  /// No description provided for @brokerKycReviewYourInformation.
  ///
  /// In en, this message translates to:
  /// **'Review Your Information'**
  String get brokerKycReviewYourInformation;

  /// No description provided for @brokerKycPleaseVerifyEverythingBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Please verify everything before submitting.'**
  String get brokerKycPleaseVerifyEverythingBeforeSubmitting;

  /// No description provided for @brokerKycBusinessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get brokerKycBusinessInformation;

  /// No description provided for @brokerKycPANNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get brokerKycPANNumber;

  /// No description provided for @brokerKycAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get brokerKycAadhaarNumber;

  /// No description provided for @brokerKycGSTNumber.
  ///
  /// In en, this message translates to:
  /// **'GST Number'**
  String get brokerKycGSTNumber;

  /// No description provided for @brokerKycBankAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Number'**
  String get brokerKycBankAccountNumber;

  /// No description provided for @brokerKycBusinessRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Business Registration Number'**
  String get brokerKycBusinessRegistrationNumber;

  /// No description provided for @brokerKycUploadedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Documents'**
  String get brokerKycUploadedDocuments;

  /// No description provided for @brokerKycIConfirmThatAllTheInformationProvided.
  ///
  /// In en, this message translates to:
  /// **'I confirm that all the information provided is accurate.'**
  String get brokerKycIConfirmThatAllTheInformationProvided;

  /// No description provided for @brokerKycVerificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Verification Details'**
  String get brokerKycVerificationDetails;

  /// No description provided for @brokerKycCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get brokerKycCurrentStatus;

  /// No description provided for @brokerKycSubmittedDate.
  ///
  /// In en, this message translates to:
  /// **'Submitted Date'**
  String get brokerKycSubmittedDate;

  /// No description provided for @brokerKycSubmissionID.
  ///
  /// In en, this message translates to:
  /// **'Submission ID'**
  String get brokerKycSubmissionID;

  /// No description provided for @brokerKycReviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed At'**
  String get brokerKycReviewedAt;

  /// No description provided for @brokerKycViewMyDocuments.
  ///
  /// In en, this message translates to:
  /// **'View My Documents'**
  String get brokerKycViewMyDocuments;

  /// No description provided for @brokerKycGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get brokerKycGoBack;

  /// No description provided for @brokerKycMyDocuments.
  ///
  /// In en, this message translates to:
  /// **'My documents'**
  String get brokerKycMyDocuments;

  /// No description provided for @brokerKycKYCRegistration.
  ///
  /// In en, this message translates to:
  /// **'KYC Registration'**
  String get brokerKycKYCRegistration;

  /// No description provided for @brokerKycVerifyYourBrokerAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify your broker account'**
  String get brokerKycVerifyYourBrokerAccount;

  /// No description provided for @brokerKycSupportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: {formats}'**
  String brokerKycSupportedFormats(Object formats);

  /// No description provided for @brokerKycThisItemIsCoveredInTheDetails.
  ///
  /// In en, this message translates to:
  /// **'This item is covered in the details section.'**
  String get brokerKycThisItemIsCoveredInTheDetails;

  /// No description provided for @brokerActiveJobsCouldNotLoadActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Could not load active jobs'**
  String get brokerActiveJobsCouldNotLoadActiveJobs;

  /// No description provided for @brokerActiveJobsNoActiveJobsFound.
  ///
  /// In en, this message translates to:
  /// **'No active jobs found'**
  String get brokerActiveJobsNoActiveJobsFound;

  /// No description provided for @brokerActiveJobsAssignedAndInTransitJobsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Assigned and in-transit jobs will appear here.'**
  String get brokerActiveJobsAssignedAndInTransitJobsWillAppear;

  /// No description provided for @brokerActiveJobsReportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get brokerActiveJobsReportAProblem;

  /// No description provided for @brokerActiveJobsTo.
  ///
  /// In en, this message translates to:
  /// **'{pickup} to {drop}'**
  String brokerActiveJobsTo(Object pickup, Object drop);

  /// No description provided for @brokerActiveJobsIssueType.
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get brokerActiveJobsIssueType;

  /// No description provided for @brokerActiveJobsDescribeWhatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Describe what went wrong...'**
  String get brokerActiveJobsDescribeWhatWentWrong;

  /// No description provided for @brokerActiveJobsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerActiveJobsCancel;

  /// No description provided for @brokerActiveJobsDisputeRaisedOurTeamWillReviewIt.
  ///
  /// In en, this message translates to:
  /// **'Dispute raised - our team will review it shortly.'**
  String get brokerActiveJobsDisputeRaisedOurTeamWillReviewIt;

  /// No description provided for @brokerActiveJobsReassignDriver.
  ///
  /// In en, this message translates to:
  /// **'Reassign Driver'**
  String get brokerActiveJobsReassignDriver;

  /// No description provided for @brokerActiveJobsCurrentlyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Currently Assigned'**
  String get brokerActiveJobsCurrentlyAssigned;

  /// No description provided for @brokerActiveJobsReassignTo.
  ///
  /// In en, this message translates to:
  /// **'Reassign to'**
  String get brokerActiveJobsReassignTo;

  /// No description provided for @brokerActiveJobsOptionalReasonForReassignment.
  ///
  /// In en, this message translates to:
  /// **'Optional reason for reassignment'**
  String get brokerActiveJobsOptionalReasonForReassignment;

  /// No description provided for @brokerActiveJobsCanTFindTheOriginalJobRequest.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find the original job request for this booking.'**
  String get brokerActiveJobsCanTFindTheOriginalJobRequest;

  /// No description provided for @brokerActiveJobsDriverReassigned.
  ///
  /// In en, this message translates to:
  /// **'Driver reassigned.'**
  String get brokerActiveJobsDriverReassigned;

  /// No description provided for @brokerActiveJobsActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get brokerActiveJobsActiveJobs;

  /// No description provided for @brokerActiveJobsJobsCurrentlyInProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs currently in progress'**
  String brokerActiveJobsJobsCurrentlyInProgress(Object count);

  /// No description provided for @brokerActiveJobsPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerActiveJobsPickup;

  /// No description provided for @brokerActiveJobsDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get brokerActiveJobsDrop;

  /// No description provided for @brokerActiveJobsTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get brokerActiveJobsTruck;

  /// No description provided for @brokerActiveJobsDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get brokerActiveJobsDriver;

  /// No description provided for @brokerActiveJobsTRIPPROGRESS.
  ///
  /// In en, this message translates to:
  /// **'TRIP PROGRESS'**
  String get brokerActiveJobsTRIPPROGRESS;

  /// No description provided for @brokerActiveJobsTrackLive.
  ///
  /// In en, this message translates to:
  /// **'Track Live'**
  String get brokerActiveJobsTrackLive;

  /// No description provided for @brokerActiveJobsChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get brokerActiveJobsChat;

  /// No description provided for @addDriverPleaseSignInAgainToCreateA.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to create a driver.'**
  String get addDriverPleaseSignInAgainToCreateA;

  /// No description provided for @addDriverDriverProfileSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Driver profile saved successfully.'**
  String get addDriverDriverProfileSavedSuccessfully;

  /// No description provided for @addDriverHasBeenRegisteredAndAddedToYour.
  ///
  /// In en, this message translates to:
  /// **'{name} has been registered and added to your drivers.'**
  String addDriverHasBeenRegisteredAndAddedToYour(Object name);

  /// No description provided for @addDriverTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary Password'**
  String get addDriverTemporaryPassword;

  /// No description provided for @addDriverPasswordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get addDriverPasswordCopied;

  /// No description provided for @addDriverCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get addDriverCopy;

  /// No description provided for @addDriverThisPasswordIsShownOnlyOnceThe.
  ///
  /// In en, this message translates to:
  /// **'This password is shown only once — the driver can change it from their profile after logging in.'**
  String get addDriverThisPasswordIsShownOnlyOnceThe;

  /// No description provided for @addDriverDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get addDriverDone;

  /// No description provided for @addDriverEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get addDriverEmailAlreadyRegistered;

  /// No description provided for @addDriverIsAlreadyTiedToADriverAccount.
  ///
  /// In en, this message translates to:
  /// **'{email} is already tied to a driver account.'**
  String addDriverIsAlreadyTiedToADriverAccount(Object email);

  /// No description provided for @addDriverKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get addDriverKeepEditing;

  /// No description provided for @addDriverViewDrivers.
  ///
  /// In en, this message translates to:
  /// **'View drivers'**
  String get addDriverViewDrivers;

  /// No description provided for @addDriverAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get addDriverAccountDetails;

  /// No description provided for @addDriverFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get addDriverFullName;

  /// No description provided for @addDriverEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get addDriverEmail;

  /// No description provided for @addDriverMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get addDriverMobileNumber;

  /// No description provided for @addDriverLicenseDocuments.
  ///
  /// In en, this message translates to:
  /// **'License & Documents'**
  String get addDriverLicenseDocuments;

  /// No description provided for @addDriverLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get addDriverLicenseNumber;

  /// No description provided for @addDriverAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get addDriverAadhaarNumber;

  /// No description provided for @addDriverLeaveBlankToKeepTheCurrentAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the current Aadhaar on file.'**
  String get addDriverLeaveBlankToKeepTheCurrentAadhaar;

  /// No description provided for @addDriverLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'License expiry'**
  String get addDriverLicenseExpiry;

  /// No description provided for @addDriverYYYYMMDD.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get addDriverYYYYMMDD;

  /// No description provided for @addDriverVehicleAssignment.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Assignment'**
  String get addDriverVehicleAssignment;

  /// No description provided for @addDriverAssignTruck.
  ///
  /// In en, this message translates to:
  /// **'Assign truck'**
  String get addDriverAssignTruck;

  /// No description provided for @addDriverTruckID.
  ///
  /// In en, this message translates to:
  /// **'Truck ID'**
  String get addDriverTruckID;

  /// No description provided for @addDriverEnterTruckUUIDOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter truck UUID (optional)'**
  String get addDriverEnterTruckUUIDOptional;

  /// No description provided for @addDriverStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get addDriverStatus;

  /// No description provided for @addDriverAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get addDriverAvailable;

  /// No description provided for @addDriverOnTrip.
  ///
  /// In en, this message translates to:
  /// **'On trip'**
  String get addDriverOnTrip;

  /// No description provided for @addDriverOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get addDriverOffline;

  /// No description provided for @addDriverTruckListCouldNotBeLoadedYou.
  ///
  /// In en, this message translates to:
  /// **'Truck list could not be loaded. You can still enter a truck ID manually.'**
  String get addDriverTruckListCouldNotBeLoadedYou;

  /// No description provided for @addDriverChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get addDriverChangePhoto;

  /// No description provided for @brokerHistoryRemoveFromMyList.
  ///
  /// In en, this message translates to:
  /// **'Remove from my list?'**
  String get brokerHistoryRemoveFromMyList;

  /// No description provided for @brokerHistoryThisOnlyRemovesItFromYourOwn.
  ///
  /// In en, this message translates to:
  /// **'This only removes it from your own list. There\'s no undo.'**
  String get brokerHistoryThisOnlyRemovesItFromYourOwn;

  /// No description provided for @brokerHistoryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerHistoryCancel;

  /// No description provided for @brokerHistoryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get brokerHistoryRemove;

  /// No description provided for @brokerHistoryBookingRemovedFromYourList.
  ///
  /// In en, this message translates to:
  /// **'Booking removed from your list.'**
  String get brokerHistoryBookingRemovedFromYourList;

  /// No description provided for @brokerHistoryCouldNotLoadJobHistory.
  ///
  /// In en, this message translates to:
  /// **'Could not load job history'**
  String get brokerHistoryCouldNotLoadJobHistory;

  /// No description provided for @brokerHistoryNoBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get brokerHistoryNoBookingsFound;

  /// No description provided for @brokerHistoryCompletedAndCancelledBookingsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled bookings appear here.'**
  String get brokerHistoryCompletedAndCancelledBookingsAppearHere;

  /// No description provided for @brokerHistoryJobHistory.
  ///
  /// In en, this message translates to:
  /// **'Job History'**
  String get brokerHistoryJobHistory;

  /// No description provided for @brokerHistoryCompletedAndCancelledBookings.
  ///
  /// In en, this message translates to:
  /// **'{count} completed and cancelled bookings'**
  String brokerHistoryCompletedAndCancelledBookings(Object count);

  /// No description provided for @brokerHistorySearchBookingsRoutesDrivers.
  ///
  /// In en, this message translates to:
  /// **'Search bookings, routes, drivers...'**
  String get brokerHistorySearchBookingsRoutesDrivers;

  /// No description provided for @brokerHistoryTotalNetEarningsFiltered.
  ///
  /// In en, this message translates to:
  /// **'Total Net Earnings (filtered)'**
  String get brokerHistoryTotalNetEarningsFiltered;

  /// No description provided for @brokerHistoryTo.
  ///
  /// In en, this message translates to:
  /// **'{pickup} to {drop}'**
  String brokerHistoryTo(Object pickup, Object drop);

  /// No description provided for @brokerHistoryPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerHistoryPickup;

  /// No description provided for @brokerHistoryDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get brokerHistoryDrop;

  /// No description provided for @brokerHistoryTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get brokerHistoryTruck;

  /// No description provided for @brokerHistoryDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get brokerHistoryDriver;

  /// No description provided for @brokerHistoryViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get brokerHistoryViewDetails;

  /// No description provided for @brokerHistoryFee.
  ///
  /// In en, this message translates to:
  /// **'Fee: {amount}'**
  String brokerHistoryFee(Object amount);

  /// No description provided for @brokerHistoryNet.
  ///
  /// In en, this message translates to:
  /// **'Net: {amount}'**
  String brokerHistoryNet(Object amount);

  /// No description provided for @brokerDriverReqDriverRequests.
  ///
  /// In en, this message translates to:
  /// **'Driver requests'**
  String get brokerDriverReqDriverRequests;

  /// No description provided for @brokerDriverReqCouldNotLoadDriverRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load driver requests'**
  String get brokerDriverReqCouldNotLoadDriverRequests;

  /// No description provided for @brokerDriverReqNegotiationCards.
  ///
  /// In en, this message translates to:
  /// **'Negotiation cards'**
  String get brokerDriverReqNegotiationCards;

  /// No description provided for @brokerDriverReqReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get brokerDriverReqReload;

  /// No description provided for @brokerDriverReqNoDriverRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No driver requests yet'**
  String get brokerDriverReqNoDriverRequestsYet;

  /// No description provided for @brokerDriverReqWhenADriverTimesOutTheRequest.
  ///
  /// In en, this message translates to:
  /// **'When a driver times out, the request will appear here for broker takeover.'**
  String get brokerDriverReqWhenADriverTimesOutTheRequest;

  /// No description provided for @brokerDriverReqBookingID.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get brokerDriverReqBookingID;

  /// No description provided for @brokerDriverReqPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerDriverReqPickup;

  /// No description provided for @brokerDriverReqDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get brokerDriverReqDrop;

  /// No description provided for @brokerDriverReqAcceptedWaitingForTheClientToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accepted - waiting for the client to confirm'**
  String get brokerDriverReqAcceptedWaitingForTheClientToConfirm;

  /// No description provided for @brokerDriverReqConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get brokerDriverReqConfirm;

  /// No description provided for @brokerDriverReqDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get brokerDriverReqDecline;

  /// No description provided for @brokerDriverReqAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get brokerDriverReqAccept;

  /// No description provided for @brokerDriverReqAlreadyAgreedWithTheBrokerAcceptOr.
  ///
  /// In en, this message translates to:
  /// **'Already agreed with the broker - accept or decline, no negotiation.'**
  String get brokerDriverReqAlreadyAgreedWithTheBrokerAcceptOr;

  /// No description provided for @brokerDriverReqChangeFare.
  ///
  /// In en, this message translates to:
  /// **'Change Fare'**
  String get brokerDriverReqChangeFare;

  /// No description provided for @brokerDriverReqDriverTimedOutBrokerTakeoverActive.
  ///
  /// In en, this message translates to:
  /// **'Driver timed out - broker takeover active.'**
  String get brokerDriverReqDriverTimedOutBrokerTakeoverActive;

  /// No description provided for @brokerDriverReqBrokerAssigned.
  ///
  /// In en, this message translates to:
  /// **'Broker-assigned'**
  String get brokerDriverReqBrokerAssigned;

  /// No description provided for @brokerDriverReqChangeFare2.
  ///
  /// In en, this message translates to:
  /// **'Change fare'**
  String get brokerDriverReqChangeFare2;

  /// No description provided for @brokerDriverReqSetFareAmount.
  ///
  /// In en, this message translates to:
  /// **'Set fare amount'**
  String get brokerDriverReqSetFareAmount;

  /// No description provided for @brokerDriverReqCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerDriverReqCancel;

  /// No description provided for @brokerVehiclesVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get brokerVehiclesVehicles;

  /// No description provided for @brokerVehiclesManageYourFleetAndTruckAvailability.
  ///
  /// In en, this message translates to:
  /// **'Manage your fleet and truck availability'**
  String get brokerVehiclesManageYourFleetAndTruckAvailability;

  /// No description provided for @brokerVehiclesSearchVehiclesDriversOrLocation.
  ///
  /// In en, this message translates to:
  /// **'Search vehicles, drivers or location'**
  String get brokerVehiclesSearchVehiclesDriversOrLocation;

  /// No description provided for @brokerVehiclesRemoveTruck.
  ///
  /// In en, this message translates to:
  /// **'Remove Truck'**
  String get brokerVehiclesRemoveTruck;

  /// No description provided for @brokerVehiclesRemoveFromYourFleet.
  ///
  /// In en, this message translates to:
  /// **'Remove {vehicle} from your fleet?'**
  String brokerVehiclesRemoveFromYourFleet(Object vehicle);

  /// No description provided for @brokerVehiclesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerVehiclesCancel;

  /// No description provided for @brokerVehiclesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get brokerVehiclesRemove;

  /// No description provided for @brokerVehiclesTruckRemoved.
  ///
  /// In en, this message translates to:
  /// **'Truck removed.'**
  String get brokerVehiclesTruckRemoved;

  /// No description provided for @brokerVehiclesYourFleet.
  ///
  /// In en, this message translates to:
  /// **'Your fleet'**
  String get brokerVehiclesYourFleet;

  /// No description provided for @brokerVehiclesAddTruck.
  ///
  /// In en, this message translates to:
  /// **'Add truck'**
  String get brokerVehiclesAddTruck;

  /// No description provided for @brokerVehiclesCouldNotLoadTrucks.
  ///
  /// In en, this message translates to:
  /// **'Could not load trucks'**
  String get brokerVehiclesCouldNotLoadTrucks;

  /// No description provided for @brokerVehiclesNoMatchingVehicles.
  ///
  /// In en, this message translates to:
  /// **'No matching vehicles'**
  String get brokerVehiclesNoMatchingVehicles;

  /// No description provided for @brokerVehiclesTryADifferentSearchOrAddA.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or add a new truck.'**
  String get brokerVehiclesTryADifferentSearchOrAddA;

  /// No description provided for @brokerVehiclesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get brokerVehiclesEdit;

  /// No description provided for @brokerVehiclesAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get brokerVehiclesAssign;

  /// No description provided for @brokerVehiclesTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get brokerVehiclesTrack;

  /// No description provided for @brokerVehiclesHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get brokerVehiclesHistory;

  /// No description provided for @addVehiclePleaseSignInAgainToAddA.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to add a truck.'**
  String get addVehiclePleaseSignInAgainToAddA;

  /// No description provided for @addVehiclePleaseAssignADriver.
  ///
  /// In en, this message translates to:
  /// **'Please assign a driver.'**
  String get addVehiclePleaseAssignADriver;

  /// No description provided for @addVehiclePleaseEnterAValidYear.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid year.'**
  String get addVehiclePleaseEnterAValidYear;

  /// No description provided for @addVehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get addVehicleRegistration;

  /// No description provided for @addVehicleCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get addVehicleCapacity;

  /// No description provided for @addVehicleAssignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign driver'**
  String get addVehicleAssignDriver;

  /// No description provided for @addVehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get addVehicleMake;

  /// No description provided for @addVehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get addVehicleYear;

  /// No description provided for @addVehicleInsuranceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Insurance expiry'**
  String get addVehicleInsuranceExpiry;

  /// No description provided for @addVehiclePickADate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get addVehiclePickADate;

  /// No description provided for @addVehicleSaveTruck.
  ///
  /// In en, this message translates to:
  /// **'Save truck'**
  String get addVehicleSaveTruck;

  /// No description provided for @brokerEarningsEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get brokerEarningsEarnings;

  /// No description provided for @brokerEarningsRevenueMomentumAndSettlementsAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Revenue, momentum and settlements at a glance.'**
  String get brokerEarningsRevenueMomentumAndSettlementsAtAGlance;

  /// No description provided for @brokerEarningsFailedToLoadEarnings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load earnings'**
  String get brokerEarningsFailedToLoadEarnings;

  /// No description provided for @brokerEarningsGrossRevenue.
  ///
  /// In en, this message translates to:
  /// **'Gross revenue'**
  String get brokerEarningsGrossRevenue;

  /// No description provided for @brokerEarningsPlatformFees.
  ///
  /// In en, this message translates to:
  /// **'Platform fees'**
  String get brokerEarningsPlatformFees;

  /// No description provided for @brokerEarningsRecentSettlements.
  ///
  /// In en, this message translates to:
  /// **'Recent settlements'**
  String get brokerEarningsRecentSettlements;

  /// No description provided for @brokerEarningsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get brokerEarningsSeeAll;

  /// No description provided for @brokerEarningsNoSettlementsYet.
  ///
  /// In en, this message translates to:
  /// **'No settlements yet'**
  String get brokerEarningsNoSettlementsYet;

  /// No description provided for @brokerEarningsCompletedSettlementsWillAppearHereWithRoute.
  ///
  /// In en, this message translates to:
  /// **'Completed settlements will appear here with route and payout details.'**
  String get brokerEarningsCompletedSettlementsWillAppearHereWithRoute;

  /// No description provided for @brokerEarningsNETEARNINGS.
  ///
  /// In en, this message translates to:
  /// **'NET EARNINGS'**
  String get brokerEarningsNETEARNINGS;

  /// No description provided for @brokerEarningsViewSettlements.
  ///
  /// In en, this message translates to:
  /// **'View settlements'**
  String get brokerEarningsViewSettlements;

  /// No description provided for @brokerEarningsMonthlyMomentum.
  ///
  /// In en, this message translates to:
  /// **'Monthly momentum'**
  String get brokerEarningsMonthlyMomentum;

  /// No description provided for @brokerEarningsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get brokerEarningsThisMonth;

  /// No description provided for @brokerEarningsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get brokerEarningsLastMonth;

  /// No description provided for @brokerInvoicesInvoiceFetchedFor.
  ///
  /// In en, this message translates to:
  /// **'Invoice fetched for {booking}'**
  String brokerInvoicesInvoiceFetchedFor(Object booking);

  /// No description provided for @brokerInvoicesInvoiceEmailedFor.
  ///
  /// In en, this message translates to:
  /// **'Invoice emailed for {booking}'**
  String brokerInvoicesInvoiceEmailedFor(Object booking);

  /// No description provided for @brokerInvoicesCouldNotLoadInvoices.
  ///
  /// In en, this message translates to:
  /// **'Could not load invoices'**
  String get brokerInvoicesCouldNotLoadInvoices;

  /// No description provided for @brokerInvoicesNoInvoiceReadyBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No invoice-ready bookings yet'**
  String get brokerInvoicesNoInvoiceReadyBookingsYet;

  /// No description provided for @brokerInvoicesCompletedOrDeliveredBookingsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Completed or delivered bookings will appear here.'**
  String get brokerInvoicesCompletedOrDeliveredBookingsWillAppearHere;

  /// No description provided for @brokerInvoicesInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get brokerInvoicesInvoices;

  /// No description provided for @brokerInvoicesTrackingID.
  ///
  /// In en, this message translates to:
  /// **'Tracking ID: {id}'**
  String brokerInvoicesTrackingID(Object id);

  /// No description provided for @brokerInvoicesFrom.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get brokerInvoicesFrom;

  /// No description provided for @brokerInvoicesShippingTo.
  ///
  /// In en, this message translates to:
  /// **'Shipping to:'**
  String get brokerInvoicesShippingTo;

  /// No description provided for @brokerInvoicesStatus.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get brokerInvoicesStatus;

  /// No description provided for @brokerInvoicesFetchInvoice.
  ///
  /// In en, this message translates to:
  /// **'Fetch invoice'**
  String get brokerInvoicesFetchInvoice;

  /// No description provided for @brokerInvoicesEmailInvoice.
  ///
  /// In en, this message translates to:
  /// **'Email invoice'**
  String get brokerInvoicesEmailInvoice;

  /// No description provided for @brokerSettlementsCouldNotLoadSettlements.
  ///
  /// In en, this message translates to:
  /// **'Could not load settlements'**
  String get brokerSettlementsCouldNotLoadSettlements;

  /// No description provided for @brokerSettlementsNoSettlementsYet.
  ///
  /// In en, this message translates to:
  /// **'No settlements yet'**
  String get brokerSettlementsNoSettlementsYet;

  /// No description provided for @brokerSettlementsPaidAndPendingSettlementRecordsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Paid and pending settlement records will appear here.'**
  String get brokerSettlementsPaidAndPendingSettlementRecordsWillAppear;

  /// No description provided for @brokerSettlementsNetEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net earnings'**
  String get brokerSettlementsNetEarnings;

  /// No description provided for @brokerSettlementsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get brokerSettlementsClose;

  /// No description provided for @brokerSettlementsSettlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get brokerSettlementsSettlements;

  /// No description provided for @brokerSettlementsGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get brokerSettlementsGross;

  /// No description provided for @brokerSettlementsPICKUP.
  ///
  /// In en, this message translates to:
  /// **'PICKUP'**
  String get brokerSettlementsPICKUP;

  /// No description provided for @brokerSettlementsDROP.
  ///
  /// In en, this message translates to:
  /// **'DROP'**
  String get brokerSettlementsDROP;

  /// No description provided for @addTruckPleaseSignInAgainToAddA.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to add a truck.'**
  String get addTruckPleaseSignInAgainToAddA;

  /// No description provided for @addTruckChooseTheTruckTypeAndFillIn.
  ///
  /// In en, this message translates to:
  /// **'Choose the truck type and fill in the fleet details.'**
  String get addTruckChooseTheTruckTypeAndFillIn;

  /// No description provided for @addTruckSelectTruckType.
  ///
  /// In en, this message translates to:
  /// **'Select truck type'**
  String get addTruckSelectTruckType;

  /// No description provided for @addTruckRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get addTruckRegistration;

  /// No description provided for @addTruckCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get addTruckCapacity;

  /// No description provided for @addTruckAssignDriverOptional.
  ///
  /// In en, this message translates to:
  /// **'Assign driver (optional)'**
  String get addTruckAssignDriverOptional;

  /// No description provided for @addTruckMakeOptional.
  ///
  /// In en, this message translates to:
  /// **'Make (optional)'**
  String get addTruckMakeOptional;

  /// No description provided for @addTruckYearOptional.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get addTruckYearOptional;

  /// No description provided for @addTruckInsuranceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Insurance expiry'**
  String get addTruckInsuranceExpiry;

  /// No description provided for @addTruckPickADate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get addTruckPickADate;

  /// No description provided for @brokerTrackLiveDriverPhoneNumberIsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Driver phone number is not available.'**
  String get brokerTrackLiveDriverPhoneNumberIsNotAvailable;

  /// No description provided for @brokerTrackLiveCouldNotOpenThePhoneApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app.'**
  String get brokerTrackLiveCouldNotOpenThePhoneApp;

  /// No description provided for @brokerTrackLiveTrackLive.
  ///
  /// In en, this message translates to:
  /// **'Track Live'**
  String get brokerTrackLiveTrackLive;

  /// No description provided for @brokerTrackLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get brokerTrackLiveChat;

  /// No description provided for @brokerTrackLiveCallDriver.
  ///
  /// In en, this message translates to:
  /// **'Call driver'**
  String get brokerTrackLiveCallDriver;

  /// No description provided for @brokerTrackLiveLIVE.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get brokerTrackLiveLIVE;

  /// No description provided for @brokerTrackLiveRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get brokerTrackLiveRoute;

  /// No description provided for @brokerTrackLivePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerTrackLivePickup;

  /// No description provided for @brokerTrackLiveDropOff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get brokerTrackLiveDropOff;

  /// No description provided for @brokerTrackLiveWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get brokerTrackLiveWeight;

  /// No description provided for @brokerTrackLiveTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get brokerTrackLiveTruck;

  /// No description provided for @brokerTrackLiveTripProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip progress'**
  String get brokerTrackLiveTripProgress;

  /// No description provided for @brokerNotifCouldnTLoadYourNotifications.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your notifications'**
  String get brokerNotifCouldnTLoadYourNotifications;

  /// No description provided for @brokerNotifNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get brokerNotifNoNotifications;

  /// No description provided for @brokerNotifNewAlertsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'New alerts will appear here.'**
  String get brokerNotifNewAlertsWillAppearHere;

  /// No description provided for @brokerNotifNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get brokerNotifNotifications;

  /// No description provided for @brokerAnalyticsCouldNotLoadAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Could not load analytics'**
  String get brokerAnalyticsCouldNotLoadAnalytics;

  /// No description provided for @brokerAnalyticsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get brokerAnalyticsThisMonth;

  /// No description provided for @brokerAnalyticsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get brokerAnalyticsLastMonth;

  /// No description provided for @brokerAnalyticsTripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get brokerAnalyticsTripHistory;

  /// No description provided for @brokerAnalyticsFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get brokerAnalyticsFilter;

  /// No description provided for @brokerAnalyticsNoTripHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No trip history yet'**
  String get brokerAnalyticsNoTripHistoryYet;

  /// No description provided for @brokerAnalyticsCompletedSettlementsWillAppearHereOnceTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed settlements will appear here once trips close.'**
  String get brokerAnalyticsCompletedSettlementsWillAppearHereOnceTrips;

  /// No description provided for @brokerAnalyticsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get brokerAnalyticsAnalytics;

  /// No description provided for @brokerAnalyticsTrackYourEarningsAndTripHistory.
  ///
  /// In en, this message translates to:
  /// **'Track your earnings and trip history'**
  String get brokerAnalyticsTrackYourEarningsAndTripHistory;

  /// No description provided for @brokerAnalyticsTotalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total earnings'**
  String get brokerAnalyticsTotalEarnings;

  /// No description provided for @brokerAnalyticsNetEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net earnings: ₹{amount}'**
  String brokerAnalyticsNetEarnings(Object amount);

  /// No description provided for @driverDetailVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get driverDetailVehicle;

  /// No description provided for @driverDetailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get driverDetailLocation;

  /// No description provided for @driverDetailLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get driverDetailLicense;

  /// No description provided for @driverDetailOnTripSince.
  ///
  /// In en, this message translates to:
  /// **'On trip since'**
  String get driverDetailOnTripSince;

  /// No description provided for @driverDetailLiveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get driverDetailLiveTracking;

  /// No description provided for @driverDetailLiveTracking2.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get driverDetailLiveTracking2;

  /// No description provided for @driverDetailLiveDriverPosition.
  ///
  /// In en, this message translates to:
  /// **'Live driver position'**
  String get driverDetailLiveDriverPosition;

  /// No description provided for @driverDetailChatWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Chat with driver'**
  String get driverDetailChatWithDriver;

  /// No description provided for @brokerTruckAssignDriverAssignedToTruck.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned to truck.'**
  String get brokerTruckAssignDriverAssignedToTruck;

  /// No description provided for @brokerTruckAssignAssignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get brokerTruckAssignAssignDriver;

  /// No description provided for @brokerTruckAssignTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get brokerTruckAssignTruck;

  /// No description provided for @brokerTruckAssignNoActiveDriversAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No active drivers available right now.'**
  String get brokerTruckAssignNoActiveDriversAvailableRightNow;

  /// No description provided for @brokerTruckAssignDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get brokerTruckAssignDriver;

  /// No description provided for @brokerTruckAssignCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerTruckAssignCancel;

  /// No description provided for @brokerTruckHistoryCouldNotLoadTripHistory.
  ///
  /// In en, this message translates to:
  /// **'Could not load trip history'**
  String get brokerTruckHistoryCouldNotLoadTripHistory;

  /// No description provided for @brokerTruckHistoryTruckTripsWillAppearHereOnceJobs.
  ///
  /// In en, this message translates to:
  /// **'Truck trips will appear here once jobs are assigned.'**
  String get brokerTruckHistoryTruckTripsWillAppearHereOnceJobs;

  /// No description provided for @brokerTruckHistorySearchByBookingIDRoute.
  ///
  /// In en, this message translates to:
  /// **'Search by booking ID, route...'**
  String get brokerTruckHistorySearchByBookingIDRoute;

  /// No description provided for @brokerTruckLocationCouldNotLoadTruckLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not load truck location'**
  String get brokerTruckLocationCouldNotLoadTruckLocation;

  /// No description provided for @brokerTruckLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String brokerTruckLocationUpdated(Object time);

  /// No description provided for @brokerTruckLocationLiveLocationPending.
  ///
  /// In en, this message translates to:
  /// **'Live location pending'**
  String get brokerTruckLocationLiveLocationPending;

  /// No description provided for @brokerTruckLocationThisTruckHasNotReportedALocation.
  ///
  /// In en, this message translates to:
  /// **'This truck has not reported a location yet.'**
  String get brokerTruckLocationThisTruckHasNotReportedALocation;

  /// No description provided for @brokerTrackingDriverHasNotBegunNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Driver has not begun negotiation'**
  String get brokerTrackingDriverHasNotBegunNegotiation;

  /// No description provided for @brokerTrackingClickHereToNegotiateThisTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Click here to negotiate this timed-out request.'**
  String get brokerTrackingClickHereToNegotiateThisTimedOut;

  /// No description provided for @brokerTrackingRemainingNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Remaining negotiation'**
  String get brokerTrackingRemainingNegotiation;

  /// No description provided for @brokerTrackingNegotiationReady.
  ///
  /// In en, this message translates to:
  /// **'Negotiation ready'**
  String get brokerTrackingNegotiationReady;

  /// No description provided for @brokerTrackingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get brokerTrackingDrivers;

  /// No description provided for @brokerTrackingMonitorYourDriversAndLiveTrips.
  ///
  /// In en, this message translates to:
  /// **'Monitor your drivers and live trips'**
  String get brokerTrackingMonitorYourDriversAndLiveTrips;

  /// No description provided for @brokerTrackingSearchDriversPhoneOrVehicle.
  ///
  /// In en, this message translates to:
  /// **'Search drivers, phone or vehicle'**
  String get brokerTrackingSearchDriversPhoneOrVehicle;

  /// No description provided for @brokerTrackingYourDrivers.
  ///
  /// In en, this message translates to:
  /// **'Your drivers'**
  String get brokerTrackingYourDrivers;

  /// No description provided for @brokerTrackingChangeFareRequest.
  ///
  /// In en, this message translates to:
  /// **'Change fare request'**
  String get brokerTrackingChangeFareRequest;

  /// No description provided for @brokerTrackingAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get brokerTrackingAmount;

  /// No description provided for @brokerTrackingNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get brokerTrackingNote;

  /// No description provided for @brokerTrackingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brokerTrackingCancel;

  /// No description provided for @brokerTrackingSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get brokerTrackingSend;

  /// No description provided for @brokerTrackingChangeFare.
  ///
  /// In en, this message translates to:
  /// **'Change Fare'**
  String get brokerTrackingChangeFare;

  /// No description provided for @brokerTrackingBrokerAssignedNoFareChange.
  ///
  /// In en, this message translates to:
  /// **'Broker-assigned - no fare change'**
  String get brokerTrackingBrokerAssignedNoFareChange;

  /// No description provided for @brokerTrackingSLA.
  ///
  /// In en, this message translates to:
  /// **'SLA: {hours}'**
  String brokerTrackingSLA(Object hours);

  /// No description provided for @brokerTrackingDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay charge: ₹{amount}'**
  String brokerTrackingDelay(Object amount);

  /// No description provided for @brokerTrackingIncidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get brokerTrackingIncidents;

  /// No description provided for @brokerTrackingLoadingUnloadingStops.
  ///
  /// In en, this message translates to:
  /// **'Loading & Unloading Stops'**
  String get brokerTrackingLoadingUnloadingStops;

  /// No description provided for @brokerTrackingCompleteEarlierStopFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete the earlier {type} stop first.'**
  String brokerTrackingCompleteEarlierStopFirst(Object type);

  /// No description provided for @brokerTrackingMechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic: {name}'**
  String brokerTrackingMechanic(Object name);

  /// No description provided for @brokerFlowLoadID.
  ///
  /// In en, this message translates to:
  /// **'Load ID: {id}'**
  String brokerFlowLoadID(Object id);

  /// No description provided for @brokerFlowPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerFlowPickup;

  /// No description provided for @brokerFlowDropOff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get brokerFlowDropOff;

  /// No description provided for @brokerFlowReviewRequest.
  ///
  /// In en, this message translates to:
  /// **'Review request'**
  String get brokerFlowReviewRequest;

  /// No description provided for @brokerFlowCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get brokerFlowCapacity;

  /// No description provided for @brokerFlowLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get brokerFlowLocation;

  /// No description provided for @brokerFlowID.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String brokerFlowID(Object id);

  /// No description provided for @brokerFlowEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get brokerFlowEdit;

  /// No description provided for @brokerFlowCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get brokerFlowCall;

  /// No description provided for @brokerFlowRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get brokerFlowRemove;

  /// No description provided for @allEarningsTripCount.
  ///
  /// In en, this message translates to:
  /// **'{count} trips'**
  String allEarningsTripCount(Object count);

  /// No description provided for @appNewChatBookingSuffix.
  ///
  /// In en, this message translates to:
  /// **' for booking {booking}'**
  String appNewChatBookingSuffix(Object booking);

  /// No description provided for @appNewChatRequestFrom.
  ///
  /// In en, this message translates to:
  /// **'New chat request from {name}'**
  String appNewChatRequestFrom(Object name);

  /// No description provided for @appNewMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'New message from {name}'**
  String appNewMessageFrom(Object name);

  /// No description provided for @brokerHomeClientAcceptedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Client accepted {amount}. Confirm now.'**
  String brokerHomeClientAcceptedConfirm(Object amount);

  /// No description provided for @brokerHomeDriverChangedFare.
  ///
  /// In en, this message translates to:
  /// **'{name} changed the fare.'**
  String brokerHomeDriverChangedFare(Object name);

  /// No description provided for @brokerHomeDriverNoResponse.
  ///
  /// In en, this message translates to:
  /// **'{name} did not respond.'**
  String brokerHomeDriverNoResponse(Object name);

  /// No description provided for @brokerHomeHelloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String brokerHomeHelloName(Object name);

  /// No description provided for @brokerHomeNoMatchButPending.
  ///
  /// In en, this message translates to:
  /// **'No exact match, but {count} pending requests need attention.'**
  String brokerHomeNoMatchButPending(Object count);

  /// No description provided for @brokerHomeOfferLive.
  ///
  /// In en, this message translates to:
  /// **'Offer live: {amount}'**
  String brokerHomeOfferLive(Object amount);

  /// No description provided for @brokerHomeRequestsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} requests need attention'**
  String brokerHomeRequestsNeedAttention(Object count);

  /// No description provided for @brokerHomeWaitingClientResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client response on {amount}'**
  String brokerHomeWaitingClientResponse(Object amount);

  /// No description provided for @brokerHomeWaitingForDriver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String brokerHomeWaitingForDriver(Object name);

  /// No description provided for @clientBookingRouteDistance.
  ///
  /// In en, this message translates to:
  /// **'Route distance: {distance} km'**
  String clientBookingRouteDistance(Object distance);

  /// No description provided for @clientCheckoutDefaultMethod.
  ///
  /// In en, this message translates to:
  /// **'Default method: {method}'**
  String clientCheckoutDefaultMethod(Object method);

  /// No description provided for @clientCheckoutDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: {description}'**
  String clientCheckoutDemoMode(Object description);

  /// No description provided for @clientCheckoutPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String clientCheckoutPay(Object amount);

  /// No description provided for @clientProceedWith.
  ///
  /// In en, this message translates to:
  /// **'Proceed with {vehicle}'**
  String clientProceedWith(Object vehicle);

  /// No description provided for @clientPublicDelayCharge.
  ///
  /// In en, this message translates to:
  /// **'Delay charge: {amount} for {hours}'**
  String clientPublicDelayCharge(Object amount, Object hours);

  /// No description provided for @clientPublicExpectedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery: {time} {suffix}'**
  String clientPublicExpectedDelivery(Object time, Object suffix);

  /// No description provided for @clientPublicIncidentUpdate.
  ///
  /// In en, this message translates to:
  /// **'Incident update: {status}'**
  String clientPublicIncidentUpdate(Object status);

  /// No description provided for @deliveryFlowAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add {count} more item(s).'**
  String deliveryFlowAddMore(Object count);

  /// No description provided for @deliveryFlowImagePickerError.
  ///
  /// In en, this message translates to:
  /// **'Image picker error: {error}'**
  String deliveryFlowImagePickerError(Object error);

  /// No description provided for @deliveryFlowVideoCameraError.
  ///
  /// In en, this message translates to:
  /// **'Video camera error: {error}'**
  String deliveryFlowVideoCameraError(Object error);

  /// No description provided for @driverEarningsAvgPerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Avg per delivery: {amount}'**
  String driverEarningsAvgPerDelivery(Object amount);

  /// No description provided for @driverEarningsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String driverEarningsCompletedCount(Object count);

  /// No description provided for @driverPaymentRecordedAs.
  ///
  /// In en, this message translates to:
  /// **'Recorded as {mode}'**
  String driverPaymentRecordedAs(Object mode);

  /// No description provided for @gpsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version {version}'**
  String gpsAppVersion(Object version);

  /// No description provided for @gpsDashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String gpsDashboardGreeting(Object name);

  /// No description provided for @gpsFleetMapSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} vehicles, {online} online'**
  String gpsFleetMapSummary(Object count, Object online);

  /// No description provided for @gpsPageIndicator.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String gpsPageIndicator(Object current, Object total);

  /// No description provided for @gpsScreenComingNext.
  ///
  /// In en, this message translates to:
  /// **'{name} is coming next.'**
  String gpsScreenComingNext(Object name);

  /// No description provided for @gpsShowingEntries.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}-{end} of {total}'**
  String gpsShowingEntries(Object start, Object end, Object total);

  /// No description provided for @gpsTimeSuffixFrom.
  ///
  /// In en, this message translates to:
  /// **'from {time}'**
  String gpsTimeSuffixFrom(Object time);

  /// No description provided for @gpsTokenEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Equivalent: ₹{amount}'**
  String gpsTokenEquivalent(Object amount);

  /// No description provided for @gpsTokensCredit.
  ///
  /// In en, this message translates to:
  /// **'+{count} tokens'**
  String gpsTokensCredit(Object count);

  /// No description provided for @gpsTokensDebit.
  ///
  /// In en, this message translates to:
  /// **'-{count} tokens'**
  String gpsTokensDebit(Object count);

  /// No description provided for @gpsVehicleCachedBanner.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}'**
  String gpsVehicleCachedBanner(Object time);

  /// No description provided for @photoUploadAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add {count} more item(s).'**
  String photoUploadAddMore(Object count);

  /// No description provided for @photoUploadImagePickerError.
  ///
  /// In en, this message translates to:
  /// **'Image picker error: {error}'**
  String photoUploadImagePickerError(Object error);

  /// No description provided for @photoUploadVideoCameraError.
  ///
  /// In en, this message translates to:
  /// **'Video camera error: {error}'**
  String photoUploadVideoCameraError(Object error);

  /// No description provided for @sharedHaltingChargeWithHours.
  ///
  /// In en, this message translates to:
  /// **'Halting charge {amount} applied for {hours} after the free {freeHours} window.'**
  String sharedHaltingChargeWithHours(
    Object amount,
    Object hours,
    Object freeHours,
  );

  /// No description provided for @sharedHaltingChargeWithoutHours.
  ///
  /// In en, this message translates to:
  /// **'Halting charge {amount} applied after the free {freeHours} window.'**
  String sharedHaltingChargeWithoutHours(Object amount, Object freeHours);

  /// No description provided for @sharedHaltingExceededEstimate.
  ///
  /// In en, this message translates to:
  /// **'Free window exceeded by {duration}. Estimated charge: {amount}.'**
  String sharedHaltingExceededEstimate(Object duration, Object amount);

  /// No description provided for @sharedHaltingExceededNoEstimate.
  ///
  /// In en, this message translates to:
  /// **'Free window exceeded by {duration}.'**
  String sharedHaltingExceededNoEstimate(Object duration);

  /// No description provided for @sharedHaltingNotStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Halting timer starts after the free {hours} window.'**
  String sharedHaltingNotStartedMessage(Object hours);

  /// No description provided for @sharedHaltingRemainingMessage.
  ///
  /// In en, this message translates to:
  /// **'{remaining} remaining before halting charges start after the free {freeHours} window.'**
  String sharedHaltingRemainingMessage(Object remaining, Object freeHours);

  /// No description provided for @truckSearchDriverOffers.
  ///
  /// In en, this message translates to:
  /// **'Driver offers ({count})'**
  String truckSearchDriverOffers(Object count);

  /// No description provided for @allEarningsActiveMonths.
  ///
  /// In en, this message translates to:
  /// **'Active months'**
  String get allEarningsActiveMonths;

  /// No description provided for @allEarningsAvgTrip.
  ///
  /// In en, this message translates to:
  /// **'Average trip'**
  String get allEarningsAvgTrip;

  /// No description provided for @allEarningsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get allEarningsBreakdown;

  /// No description provided for @allEarningsDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get allEarningsDeliveries;

  /// No description provided for @allEarningsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get allEarningsEmptySubtitle;

  /// No description provided for @allEarningsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get allEarningsEmptyTitle;

  /// No description provided for @allEarningsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load earnings'**
  String get allEarningsLoadFailed;

  /// No description provided for @allEarningsMonthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend'**
  String get allEarningsMonthlyTrend;

  /// No description provided for @allEarningsMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get allEarningsMonths;

  /// No description provided for @allEarningsNetPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Net per month'**
  String get allEarningsNetPerMonth;

  /// No description provided for @allEarningsPerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Per delivery'**
  String get allEarningsPerDelivery;

  /// No description provided for @allEarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'All earnings'**
  String get allEarningsTitle;

  /// No description provided for @allEarningsTotalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get allEarningsTotalEarned;

  /// No description provided for @allEarningsTripsDone.
  ///
  /// In en, this message translates to:
  /// **'Trips done'**
  String get allEarningsTripsDone;

  /// No description provided for @appChatClientFallback.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get appChatClientFallback;

  /// No description provided for @appChatSupportFallback.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get appChatSupportFallback;

  /// No description provided for @appLoginAttemptBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'For your safety, this login attempt was blocked. Please review tracking settings.'**
  String get appLoginAttemptBlockedBody;

  /// No description provided for @appLoginAttemptBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Login attempt blocked'**
  String get appLoginAttemptBlockedTitle;

  /// No description provided for @appNewChatRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New chat request'**
  String get appNewChatRequestTitle;

  /// No description provided for @appOkButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get appOkButton;

  /// No description provided for @appSignedInRetry.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Please try again.'**
  String get appSignedInRetry;

  /// No description provided for @appTrackingSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Tracking settings'**
  String get appTrackingSettingsAction;

  /// No description provided for @arrivedHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get arrivedHeading;

  /// No description provided for @arrivedNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get arrivedNextLabel;

  /// No description provided for @arrivedNextUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload delivery photos'**
  String get arrivedNextUpload;

  /// No description provided for @arrivedPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get arrivedPreparing;

  /// No description provided for @arrivedPreparingSub.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we finish preparing.'**
  String get arrivedPreparingSub;

  /// No description provided for @arrivedSlideSub.
  ///
  /// In en, this message translates to:
  /// **'Slide to continue'**
  String get arrivedSlideSub;

  /// No description provided for @arrivedSlideTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on site'**
  String get arrivedSlideTitle;

  /// No description provided for @arrivedStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get arrivedStatusLabel;

  /// No description provided for @arrivedStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get arrivedStatusReady;

  /// No description provided for @arrivedSub.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you have reached the stop.'**
  String get arrivedSub;

  /// No description provided for @arrivedSwipeContinue.
  ///
  /// In en, this message translates to:
  /// **'Slide to continue'**
  String get arrivedSwipeContinue;

  /// No description provided for @arrivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrivedTitle;

  /// No description provided for @arrivedTripIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip ID'**
  String get arrivedTripIdLabel;

  /// No description provided for @brokerActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'A small delay here can cost you the booking. Assign a driver quickly.'**
  String get brokerActiveDescription;

  /// No description provided for @brokerActiveSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm assignment'**
  String get brokerActiveSubmit;

  /// No description provided for @brokerActiveSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Confirming...'**
  String get brokerActiveSubmitting;

  /// No description provided for @brokerHomeClientOffered.
  ///
  /// In en, this message translates to:
  /// **'You offered'**
  String get brokerHomeClientOffered;

  /// No description provided for @brokerHomeDriverFallback.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get brokerHomeDriverFallback;

  /// No description provided for @brokerHomeDropUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Drop location unavailable'**
  String get brokerHomeDropUnavailable;

  /// No description provided for @brokerHomeFareChangeSent.
  ///
  /// In en, this message translates to:
  /// **'Fare change sent'**
  String get brokerHomeFareChangeSent;

  /// No description provided for @brokerHomeFareChangesUsed.
  ///
  /// In en, this message translates to:
  /// **'Fare changes used'**
  String get brokerHomeFareChangesUsed;

  /// No description provided for @brokerHomeHelloPrefix.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get brokerHomeHelloPrefix;

  /// No description provided for @brokerHomeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get brokerHomeJustNow;

  /// No description provided for @brokerHomePickupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pickup location unavailable'**
  String get brokerHomePickupUnavailable;

  /// No description provided for @brokerHomeRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get brokerHomeRequestAccepted;

  /// No description provided for @brokerHomeRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get brokerHomeRequestDeclined;

  /// No description provided for @brokerHomeSendAssignment.
  ///
  /// In en, this message translates to:
  /// **'Send assignment'**
  String get brokerHomeSendAssignment;

  /// No description provided for @brokerHomeSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get brokerHomeSending;

  /// No description provided for @brokerHomeTryClearingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your search'**
  String get brokerHomeTryClearingSearch;

  /// No description provided for @brokerHomeYouAcceptedWaiting.
  ///
  /// In en, this message translates to:
  /// **'You accepted. Waiting for the client to confirm.'**
  String get brokerHomeYouAcceptedWaiting;

  /// No description provided for @brokerHomeYouOffered.
  ///
  /// In en, this message translates to:
  /// **'You offered'**
  String get brokerHomeYouOffered;

  /// No description provided for @brokerKycCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC complete'**
  String get brokerKycCompleteTitle;

  /// No description provided for @brokerKycContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get brokerKycContinue;

  /// No description provided for @brokerKycFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get brokerKycFinish;

  /// No description provided for @brokerKycNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get brokerKycNotAvailable;

  /// No description provided for @brokerKycNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get brokerKycNotProvided;

  /// No description provided for @brokerKycPendingReviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get brokerKycPendingReviewStatus;

  /// No description provided for @brokerKycSubmitKyc.
  ///
  /// In en, this message translates to:
  /// **'Submit KYC'**
  String get brokerKycSubmitKyc;

  /// No description provided for @brokerKycSubmittedBadge.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get brokerKycSubmittedBadge;

  /// No description provided for @brokerKycSubmittedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your KYC was submitted and is waiting for review.'**
  String get brokerKycSubmittedDesc;

  /// No description provided for @brokerKycSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC submitted'**
  String get brokerKycSubmittedTitle;

  /// No description provided for @brokerKycVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get brokerKycVerifiedBadge;

  /// No description provided for @brokerKycVerifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your KYC is verified. You can now accept bookings.'**
  String get brokerKycVerifiedDesc;

  /// No description provided for @brokerKycVerifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get brokerKycVerifiedStatus;

  /// No description provided for @brokerKycVerifyCarefullyWarning.
  ///
  /// In en, this message translates to:
  /// **'Please verify all information carefully. Incorrect information may delay KYC approval.'**
  String get brokerKycVerifyCarefullyWarning;

  /// No description provided for @brokerReqAcceptAssign.
  ///
  /// In en, this message translates to:
  /// **'Accept & assign'**
  String get brokerReqAcceptAssign;

  /// No description provided for @brokerReqAcceptedNoCard.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get brokerReqAcceptedNoCard;

  /// No description provided for @brokerReqAcceptedPickDriver.
  ///
  /// In en, this message translates to:
  /// **'Accepted. Pick a driver to continue.'**
  String get brokerReqAcceptedPickDriver;

  /// No description provided for @brokerReqAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign driver & truck'**
  String get brokerReqAssignmentTitle;

  /// No description provided for @brokerReqAutoSelectedDetails.
  ///
  /// In en, this message translates to:
  /// **'We selected this for you. You can change it.'**
  String get brokerReqAutoSelectedDetails;

  /// No description provided for @brokerReqAwaitingOtherSide.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get brokerReqAwaitingOtherSide;

  /// No description provided for @brokerReqChangeFareOrReject.
  ///
  /// In en, this message translates to:
  /// **'Change fare or reject'**
  String get brokerReqChangeFareOrReject;

  /// No description provided for @brokerReqClientAcceptedFinalize.
  ///
  /// In en, this message translates to:
  /// **'Client accepted. Finalise the assignment.'**
  String get brokerReqClientAcceptedFinalize;

  /// No description provided for @brokerReqConfirmAssign.
  ///
  /// In en, this message translates to:
  /// **'Confirm assignment'**
  String get brokerReqConfirmAssign;

  /// No description provided for @brokerReqConfirmBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get brokerReqConfirmBookingTitle;

  /// No description provided for @brokerReqCustomerFallback.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get brokerReqCustomerFallback;

  /// No description provided for @brokerReqDeclinedNoActions.
  ///
  /// In en, this message translates to:
  /// **'Declined. No further action needed.'**
  String get brokerReqDeclinedNoActions;

  /// No description provided for @brokerReqFareChangeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for fare change response'**
  String get brokerReqFareChangeWaiting;

  /// No description provided for @brokerReqGeneralFallback.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get brokerReqGeneralFallback;

  /// No description provided for @brokerReqNoDriversFound.
  ///
  /// In en, this message translates to:
  /// **'No drivers found'**
  String get brokerReqNoDriversFound;

  /// No description provided for @brokerReqNoTrucksFound.
  ///
  /// In en, this message translates to:
  /// **'No trucks found'**
  String get brokerReqNoTrucksFound;

  /// No description provided for @brokerReqSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get brokerReqSaving;

  /// No description provided for @brokerReqUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get brokerReqUnavailable;

  /// No description provided for @changePasswordAllFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get changePasswordAllFieldsRequired;

  /// No description provided for @changePasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get changePasswordConfirmHint;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get changePasswordCurrentHint;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordNewHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get changePasswordNewHint;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordScreenTitle;

  /// No description provided for @changePasswordStrengthEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a password to check its strength'**
  String get changePasswordStrengthEmptyHint;

  /// No description provided for @changePasswordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get changePasswordStrengthFair;

  /// No description provided for @changePasswordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get changePasswordStrengthGood;

  /// No description provided for @changePasswordStrengthLowercase.
  ///
  /// In en, this message translates to:
  /// **'Add a lowercase letter'**
  String get changePasswordStrengthLowercase;

  /// No description provided for @changePasswordStrengthMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get changePasswordStrengthMinLength;

  /// No description provided for @changePasswordStrengthNumber.
  ///
  /// In en, this message translates to:
  /// **'Add a number'**
  String get changePasswordStrengthNumber;

  /// No description provided for @changePasswordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get changePasswordStrengthStrong;

  /// No description provided for @changePasswordStrengthStrongHint.
  ///
  /// In en, this message translates to:
  /// **'Great password'**
  String get changePasswordStrengthStrongHint;

  /// No description provided for @changePasswordStrengthSymbol.
  ///
  /// In en, this message translates to:
  /// **'Add a symbol'**
  String get changePasswordStrengthSymbol;

  /// No description provided for @changePasswordStrengthTitle.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get changePasswordStrengthTitle;

  /// No description provided for @changePasswordStrengthUppercase.
  ///
  /// In en, this message translates to:
  /// **'Add an uppercase letter'**
  String get changePasswordStrengthUppercase;

  /// No description provided for @changePasswordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get changePasswordStrengthWeak;

  /// No description provided for @changePasswordSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordSubmitButton;

  /// No description provided for @changePasswordSuccessLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please sign in again.'**
  String get changePasswordSuccessLoggedOut;

  /// No description provided for @chatAssistantName.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatAssistantName;

  /// No description provided for @chatClosedChip.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get chatClosedChip;

  /// No description provided for @chatDetailBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get chatDetailBookingTitle;

  /// No description provided for @chatDetailClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get chatDetailClientTitle;

  /// No description provided for @chatDetailDirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get chatDetailDirectTitle;

  /// No description provided for @chatDirectMessageChip.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get chatDirectMessageChip;

  /// No description provided for @chatDirectMessageFallback.
  ///
  /// In en, this message translates to:
  /// **'Direct conversation'**
  String get chatDirectMessageFallback;

  /// No description provided for @chatListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatListEmpty;

  /// No description provided for @chatListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load chats'**
  String get chatListLoadError;

  /// No description provided for @chatListRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get chatListRetry;

  /// No description provided for @chatListTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatListTitle;

  /// No description provided for @chatMessageFallback.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessageFallback;

  /// No description provided for @chatMessageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Message not sent'**
  String get chatMessageNotSent;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesYet;

  /// No description provided for @chatNotConnectedChip.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chatNotConnectedChip;

  /// No description provided for @chatReadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatReadReceipt;

  /// No description provided for @chatThreadLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this conversation'**
  String get chatThreadLoadError;

  /// No description provided for @chatTripClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This trip is closed. You can still read the messages.'**
  String get chatTripClosedNotice;

  /// No description provided for @chatTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatTypeMessageHint;

  /// No description provided for @chatTypingIndicator.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get chatTypingIndicator;

  /// No description provided for @clientAddressAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get clientAddressAddTitle;

  /// No description provided for @clientAddressEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get clientAddressEditTitle;

  /// No description provided for @clientAddressLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading address'**
  String get clientAddressLoading;

  /// No description provided for @clientAddressRemoved.
  ///
  /// In en, this message translates to:
  /// **'Address removed'**
  String get clientAddressRemoved;

  /// No description provided for @clientBookingLoadingPointHint.
  ///
  /// In en, this message translates to:
  /// **'Search for the loading point'**
  String get clientBookingLoadingPointHint;

  /// No description provided for @clientBookingUnloadingPointHint.
  ///
  /// In en, this message translates to:
  /// **'Search for the unloading point'**
  String get clientBookingUnloadingPointHint;

  /// No description provided for @clientBookingWeightError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get clientBookingWeightError;

  /// No description provided for @clientCheckoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get clientCheckoutCancel;

  /// No description provided for @clientCheckoutChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment method'**
  String get clientCheckoutChooseMethod;

  /// No description provided for @clientCheckoutEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-digit UPI PIN'**
  String get clientCheckoutEnterPin;

  /// No description provided for @clientCheckoutMethodCards.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get clientCheckoutMethodCards;

  /// No description provided for @clientCheckoutMethodNetbanking.
  ///
  /// In en, this message translates to:
  /// **'Netbanking'**
  String get clientCheckoutMethodNetbanking;

  /// No description provided for @clientCheckoutMethodRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get clientCheckoutMethodRecommended;

  /// No description provided for @clientCheckoutMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get clientCheckoutMethodUpi;

  /// No description provided for @clientCheckoutMethodWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get clientCheckoutMethodWallet;

  /// No description provided for @clientCheckoutTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test payment'**
  String get clientCheckoutTestTitle;

  /// No description provided for @clientChooseTrucks.
  ///
  /// In en, this message translates to:
  /// **'Choose trucks'**
  String get clientChooseTrucks;

  /// No description provided for @clientFindingBrokers.
  ///
  /// In en, this message translates to:
  /// **'Finding brokers nearby'**
  String get clientFindingBrokers;

  /// No description provided for @clientHomeBookAnyTruck.
  ///
  /// In en, this message translates to:
  /// **'Book any truck'**
  String get clientHomeBookAnyTruck;

  /// No description provided for @clientHomeLoadingHint.
  ///
  /// In en, this message translates to:
  /// **'Search loading location'**
  String get clientHomeLoadingHint;

  /// No description provided for @clientHomeUnloadingHint.
  ///
  /// In en, this message translates to:
  /// **'Search unloading location'**
  String get clientHomeUnloadingHint;

  /// No description provided for @clientNotificationsAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get clientNotificationsAllCaughtUp;

  /// No description provided for @clientNotificationsAllCaughtUpHint.
  ///
  /// In en, this message translates to:
  /// **'No new notifications right now.'**
  String get clientNotificationsAllCaughtUpHint;

  /// No description provided for @clientNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get clientNotificationsEmpty;

  /// No description provided for @clientNotificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Booking updates and invoice alerts will show up here.'**
  String get clientNotificationsEmptyHint;

  /// No description provided for @clientNotificationsFallbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Open your booking to see the full details.'**
  String get clientNotificationsFallbackMessage;

  /// No description provided for @clientNotificationsFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking update'**
  String get clientNotificationsFallbackTitle;

  /// No description provided for @clientNotificationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clientNotificationsFilterAll;

  /// No description provided for @clientNotificationsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get clientNotificationsFilterUnread;

  /// No description provided for @clientNotificationsGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get clientNotificationsGotIt;

  /// No description provided for @clientNotificationsKindBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get clientNotificationsKindBooking;

  /// No description provided for @clientNotificationsKindOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get clientNotificationsKindOffer;

  /// No description provided for @clientNotificationsKindPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get clientNotificationsKindPayment;

  /// No description provided for @clientNotificationsKindUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get clientNotificationsKindUpdate;

  /// No description provided for @clientNotificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get clientNotificationsLoadError;

  /// No description provided for @clientNotificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get clientNotificationsMarkAllRead;

  /// No description provided for @clientNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'Marked as read'**
  String get clientNotificationsMarkedRead;

  /// No description provided for @clientNotificationsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get clientNotificationsSaving;

  /// No description provided for @clientNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get clientNotificationsTitle;

  /// No description provided for @clientNotificationsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get clientNotificationsTryAgain;

  /// No description provided for @clientPaymentAddAccountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid account number'**
  String get clientPaymentAddAccountInvalid;

  /// No description provided for @clientPaymentAddAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get clientPaymentAddAccountLabel;

  /// No description provided for @clientPaymentAddBankLabel.
  ///
  /// In en, this message translates to:
  /// **'Select your bank'**
  String get clientPaymentAddBankLabel;

  /// No description provided for @clientPaymentAddBankRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a bank'**
  String get clientPaymentAddBankRequired;

  /// No description provided for @clientPaymentAddBankSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search banks'**
  String get clientPaymentAddBankSearchHint;

  /// No description provided for @clientPaymentAddBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Card brand'**
  String get clientPaymentAddBrandLabel;

  /// No description provided for @clientPaymentAddBrandRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the card brand'**
  String get clientPaymentAddBrandRequired;

  /// No description provided for @clientPaymentAddCardNote.
  ///
  /// In en, this message translates to:
  /// **'We only use this to show the card on your saved methods.'**
  String get clientPaymentAddCardNote;

  /// No description provided for @clientPaymentAddDefaultOption.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get clientPaymentAddDefaultOption;

  /// No description provided for @clientPaymentAddIfscInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IFSC code'**
  String get clientPaymentAddIfscInvalid;

  /// No description provided for @clientPaymentAddIfscLabel.
  ///
  /// In en, this message translates to:
  /// **'IFSC code'**
  String get clientPaymentAddIfscLabel;

  /// No description provided for @clientPaymentAddLast4Label.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits'**
  String get clientPaymentAddLast4Label;

  /// No description provided for @clientPaymentAddLast4Required.
  ///
  /// In en, this message translates to:
  /// **'Enter the last 4 digits'**
  String get clientPaymentAddLast4Required;

  /// No description provided for @clientPaymentAddMethod.
  ///
  /// In en, this message translates to:
  /// **'Add method'**
  String get clientPaymentAddMethod;

  /// No description provided for @clientPaymentAddNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get clientPaymentAddNoteLabel;

  /// No description provided for @clientPaymentAddPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your card details are encrypted and never shared with anyone.'**
  String get clientPaymentAddPrivacyNote;

  /// No description provided for @clientPaymentAddSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save method'**
  String get clientPaymentAddSaveButton;

  /// No description provided for @clientPaymentAddSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to add a payment method.'**
  String get clientPaymentAddSignInRequired;

  /// No description provided for @clientPaymentAddTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Card, UPI, netbanking or wallet'**
  String get clientPaymentAddTileSubtitle;

  /// No description provided for @clientPaymentAddTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a payment method'**
  String get clientPaymentAddTileTitle;

  /// No description provided for @clientPaymentAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add payment method'**
  String get clientPaymentAddTitle;

  /// No description provided for @clientPaymentAddTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment type'**
  String get clientPaymentAddTypeLabel;

  /// No description provided for @clientPaymentAddUpiInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid UPI ID'**
  String get clientPaymentAddUpiInvalid;

  /// No description provided for @clientPaymentAddUpiLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get clientPaymentAddUpiLabel;

  /// No description provided for @clientPaymentAddWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Select a wallet'**
  String get clientPaymentAddWalletLabel;

  /// No description provided for @clientPaymentAddWalletRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a wallet'**
  String get clientPaymentAddWalletRequired;

  /// No description provided for @clientPaymentAddWalletSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search wallets'**
  String get clientPaymentAddWalletSearchHint;

  /// No description provided for @clientPaymentCardSaved.
  ///
  /// In en, this message translates to:
  /// **'Card saved'**
  String get clientPaymentCardSaved;

  /// No description provided for @clientPaymentDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get clientPaymentDefaultBadge;

  /// No description provided for @clientPaymentDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete payment method'**
  String get clientPaymentDeleteTooltip;

  /// No description provided for @clientPaymentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a card, UPI ID or bank account for faster checkout.'**
  String get clientPaymentEmptySubtitle;

  /// No description provided for @clientPaymentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No payment methods'**
  String get clientPaymentEmptyTitle;

  /// No description provided for @clientPaymentLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load methods'**
  String get clientPaymentLoadError;

  /// No description provided for @clientPaymentLoadErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get clientPaymentLoadErrorHint;

  /// No description provided for @clientPaymentMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get clientPaymentMethodsTitle;

  /// No description provided for @clientPaymentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Payment method removed'**
  String get clientPaymentRemoved;

  /// No description provided for @clientPaymentRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientPaymentRetry;

  /// No description provided for @clientPaymentSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get clientPaymentSetDefault;

  /// No description provided for @clientPaymentSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your saved cards, UPI IDs and bank accounts.'**
  String get clientPaymentSignInSubtitle;

  /// No description provided for @clientPaymentSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get clientPaymentSignInTitle;

  /// No description provided for @clientPaymentTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get clientPaymentTypeBank;

  /// No description provided for @clientPaymentTypeCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get clientPaymentTypeCard;

  /// No description provided for @clientPaymentTypeMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get clientPaymentTypeMethod;

  /// No description provided for @clientPaymentTypeUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get clientPaymentTypeUpi;

  /// No description provided for @clientPaymentTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get clientPaymentTypeWallet;

  /// No description provided for @clientPaymentUpiFallback.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get clientPaymentUpiFallback;

  /// No description provided for @clientPaymentWalletFallback.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get clientPaymentWalletFallback;

  /// No description provided for @clientPlacesSuggestionsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load suggestions'**
  String get clientPlacesSuggestionsError;

  /// No description provided for @clientPublicAssignedDriver.
  ///
  /// In en, this message translates to:
  /// **'To be assigned'**
  String get clientPublicAssignedDriver;

  /// No description provided for @clientPublicDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get clientPublicDriverLabel;

  /// No description provided for @clientPublicDropLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get clientPublicDropLabel;

  /// No description provided for @clientPublicExpressSuffix.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get clientPublicExpressSuffix;

  /// No description provided for @clientPublicIncidentActive.
  ///
  /// In en, this message translates to:
  /// **'Incident reported'**
  String get clientPublicIncidentActive;

  /// No description provided for @clientPublicPickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get clientPublicPickupLabel;

  /// No description provided for @clientPublicTrackingInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'This tracking link is not valid.'**
  String get clientPublicTrackingInvalidLink;

  /// No description provided for @clientPublicTrackingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tracking unavailable'**
  String get clientPublicTrackingUnavailable;

  /// No description provided for @clientPublicTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get clientPublicTruckLabel;

  /// No description provided for @clientSavedAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get clientSavedAddAddress;

  /// No description provided for @clientSavedAddressesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get clientSavedAddressesTitle;

  /// No description provided for @clientSavedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save frequent pickup and drop-off locations for faster bookings.'**
  String get clientSavedEmptySubtitle;

  /// No description provided for @clientSavedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet'**
  String get clientSavedEmptyTitle;

  /// No description provided for @clientSavedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load addresses'**
  String get clientSavedLoadError;

  /// No description provided for @clientSavedLoadErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get clientSavedLoadErrorHint;

  /// No description provided for @clientSavedNoMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different label, area, or contact name.'**
  String get clientSavedNoMatchSubtitle;

  /// No description provided for @clientSavedNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching addresses'**
  String get clientSavedNoMatchTitle;

  /// No description provided for @clientSavedRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientSavedRetry;

  /// No description provided for @clientSavedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search saved addresses'**
  String get clientSavedSearchHint;

  /// No description provided for @clientSavedSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your pickup and drop-off locations stay linked to your account.'**
  String get clientSavedSignInSubtitle;

  /// No description provided for @clientSavedSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view saved addresses'**
  String get clientSavedSignInTitle;

  /// No description provided for @clientSearchRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientSearchRetry;

  /// No description provided for @clientSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select a vehicle'**
  String get clientSelectVehicle;

  /// No description provided for @clientTrackingGpsPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS'**
  String get clientTrackingGpsPending;

  /// No description provided for @clientTrackingLivePendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The vehicle location will appear here as soon as it starts moving.'**
  String get clientTrackingLivePendingSubtitle;

  /// No description provided for @clientTrackingLivePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Live location pending'**
  String get clientTrackingLivePendingTitle;

  /// No description provided for @clientTrackingLivePosition.
  ///
  /// In en, this message translates to:
  /// **'Live position'**
  String get clientTrackingLivePosition;

  /// No description provided for @clientTrackingLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get clientTrackingLoading;

  /// No description provided for @clientTrackingMapEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Live tracking will appear on the map.'**
  String get clientTrackingMapEmptyHint;

  /// No description provided for @clientTrackingMapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the map...'**
  String get clientTrackingMapLoading;

  /// No description provided for @clientTrackingPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get clientTrackingPayNow;

  /// No description provided for @clientTrackingPayRemaining.
  ///
  /// In en, this message translates to:
  /// **'Pay remaining'**
  String get clientTrackingPayRemaining;

  /// No description provided for @clientTrackingRateDelivery.
  ///
  /// In en, this message translates to:
  /// **'Rate delivery'**
  String get clientTrackingRateDelivery;

  /// No description provided for @clientTrackingSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get clientTrackingSubmitting;

  /// No description provided for @clientTrackingUnloading.
  ///
  /// In en, this message translates to:
  /// **'Unloading'**
  String get clientTrackingUnloading;

  /// No description provided for @clientVehicleSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get clientVehicleSelected;

  /// No description provided for @coreDigilockerAadhaarFallbackNote.
  ///
  /// In en, this message translates to:
  /// **'DigiLocker could not read this Aadhaar. Enter the number manually.'**
  String get coreDigilockerAadhaarFallbackNote;

  /// No description provided for @coreDigilockerBankAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Bank account number'**
  String get coreDigilockerBankAccountHint;

  /// No description provided for @coreDigilockerBrokerIntro.
  ///
  /// In en, this message translates to:
  /// **'Verify your PAN, Aadhaar and business documents to receive bookings.'**
  String get coreDigilockerBrokerIntro;

  /// No description provided for @coreDigilockerBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get coreDigilockerBusinessDetails;

  /// No description provided for @coreDigilockerBusinessRegHint.
  ///
  /// In en, this message translates to:
  /// **'Business registration number'**
  String get coreDigilockerBusinessRegHint;

  /// No description provided for @coreDigilockerCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Check status'**
  String get coreDigilockerCheckStatus;

  /// No description provided for @coreDigilockerChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get coreDigilockerChecking;

  /// No description provided for @coreDigilockerDidntMatch.
  ///
  /// In en, this message translates to:
  /// **'These details did not match your DigiLocker records.'**
  String get coreDigilockerDidntMatch;

  /// No description provided for @coreDigilockerDocAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar'**
  String get coreDigilockerDocAadhaar;

  /// No description provided for @coreDigilockerDocLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get coreDigilockerDocLicense;

  /// No description provided for @coreDigilockerDocPan.
  ///
  /// In en, this message translates to:
  /// **'PAN card'**
  String get coreDigilockerDocPan;

  /// No description provided for @coreDigilockerDriverIntro.
  ///
  /// In en, this message translates to:
  /// **'Verify your PAN, Aadhaar and licence to start receiving trips.'**
  String get coreDigilockerDriverIntro;

  /// No description provided for @coreDigilockerGstHint.
  ///
  /// In en, this message translates to:
  /// **'GST number'**
  String get coreDigilockerGstHint;

  /// No description provided for @coreDigilockerInfoNote.
  ///
  /// In en, this message translates to:
  /// **'DigiLocker fetches your documents securely from the government portal.'**
  String get coreDigilockerInfoNote;

  /// No description provided for @coreDigilockerNoLoginLink.
  ///
  /// In en, this message translates to:
  /// **'No DigiLocker login available. Please sign in and try again.'**
  String get coreDigilockerNoLoginLink;

  /// No description provided for @coreDigilockerNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Verification incomplete'**
  String get coreDigilockerNotComplete;

  /// No description provided for @coreDigilockerNotFound.
  ///
  /// In en, this message translates to:
  /// **'No document found'**
  String get coreDigilockerNotFound;

  /// No description provided for @coreDigilockerNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get coreDigilockerNotVerifiedYet;

  /// No description provided for @coreDigilockerOpenBrowserFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open your browser for DigiLocker.'**
  String get coreDigilockerOpenBrowserFailed;

  /// No description provided for @coreDigilockerOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get coreDigilockerOptionalNote;

  /// No description provided for @coreDigilockerPendingRetry.
  ///
  /// In en, this message translates to:
  /// **'Verification is still pending. Please try again in a moment.'**
  String get coreDigilockerPendingRetry;

  /// No description provided for @coreDigilockerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'DigiLocker is unreachable right now'**
  String get coreDigilockerUnreachable;

  /// No description provided for @coreDigilockerVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get coreDigilockerVehicleDetails;

  /// No description provided for @coreDigilockerVehicleInsuranceHint.
  ///
  /// In en, this message translates to:
  /// **'Vehicle insurance number'**
  String get coreDigilockerVehicleInsuranceHint;

  /// No description provided for @coreDigilockerVehicleRegHint.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration number'**
  String get coreDigilockerVehicleRegHint;

  /// No description provided for @coreDigilockerVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get coreDigilockerVerified;

  /// No description provided for @coreDigilockerVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify with DigiLocker'**
  String get coreDigilockerVerifyButton;

  /// No description provided for @coreDigilockerVerifyLicense.
  ///
  /// In en, this message translates to:
  /// **'Verify driving licence'**
  String get coreDigilockerVerifyLicense;

  /// No description provided for @coreDigilockerVerifyPan.
  ///
  /// In en, this message translates to:
  /// **'Verify PAN'**
  String get coreDigilockerVerifyPan;

  /// No description provided for @coreDigilockerWorking.
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get coreDigilockerWorking;

  /// No description provided for @coreKycCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete KYC'**
  String get coreKycCompleteAction;

  /// No description provided for @coreKycIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Finish verifying your documents to book and accept trips.'**
  String get coreKycIncompleteBody;

  /// No description provided for @coreKycIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your KYC'**
  String get coreKycIncompleteTitle;

  /// No description provided for @coreKycNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get coreKycNotNow;

  /// No description provided for @coreKycRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Our team could not verify your documents. Please check them and submit again.'**
  String get coreKycRejectedBody;

  /// No description provided for @coreKycRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC rejected'**
  String get coreKycRejectedTitle;

  /// No description provided for @coreKycResubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit again'**
  String get coreKycResubmitAction;

  /// No description provided for @coreKycUnderReviewBody.
  ///
  /// In en, this message translates to:
  /// **'We are reviewing your documents. This usually takes 24-48 hours.'**
  String get coreKycUnderReviewBody;

  /// No description provided for @coreKycUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC under review'**
  String get coreKycUnderReviewTitle;

  /// No description provided for @coreKycViewStatusAction.
  ///
  /// In en, this message translates to:
  /// **'View status'**
  String get coreKycViewStatusAction;

  /// No description provided for @coreMapDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get coreMapDropTitle;

  /// No description provided for @coreMapExpressLabel.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get coreMapExpressLabel;

  /// No description provided for @coreMapPickupTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get coreMapPickupTitle;

  /// No description provided for @coreMapRouteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get coreMapRouteNotFound;

  /// No description provided for @deliveryFlowChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get deliveryFlowChoosePhoto;

  /// No description provided for @deliveryFlowCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get deliveryFlowCompany;

  /// No description provided for @deliveryFlowContactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact unavailable'**
  String get deliveryFlowContactUnavailable;

  /// No description provided for @deliveryFlowMaxItems.
  ///
  /// In en, this message translates to:
  /// **'You can upload up to 5 photos.'**
  String get deliveryFlowMaxItems;

  /// No description provided for @deliveryFlowMyQr.
  ///
  /// In en, this message translates to:
  /// **'My QR'**
  String get deliveryFlowMyQr;

  /// No description provided for @deliveryFlowPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get deliveryFlowPersonal;

  /// No description provided for @deliveryFlowPhotosUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photos uploaded'**
  String get deliveryFlowPhotosUploaded;

  /// No description provided for @deliveryFlowRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get deliveryFlowRecordVideo;

  /// No description provided for @deliveryFlowSignInContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get deliveryFlowSignInContinue;

  /// No description provided for @deliveryFlowSignInUploadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to upload photos.'**
  String get deliveryFlowSignInUploadPhotos;

  /// No description provided for @deliveryFlowTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get deliveryFlowTakePhoto;

  /// No description provided for @deliveryFlowVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get deliveryFlowVerified;

  /// No description provided for @driverEarningsCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get driverEarningsCurrentBalance;

  /// No description provided for @driverEarningsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get driverEarningsLastMonth;

  /// No description provided for @driverEarningsNoDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No deliveries yet'**
  String get driverEarningsNoDeliveries;

  /// No description provided for @driverEarningsReadyPayout.
  ///
  /// In en, this message translates to:
  /// **'Ready for payout'**
  String get driverEarningsReadyPayout;

  /// No description provided for @driverEarningsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get driverEarningsThisMonth;

  /// No description provided for @driverEarningsTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get driverEarningsTrips;

  /// No description provided for @driverEarningsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get driverEarningsViewAll;

  /// No description provided for @driverHomeTripAccepted.
  ///
  /// In en, this message translates to:
  /// **'Trip accepted'**
  String get driverHomeTripAccepted;

  /// No description provided for @driverHomeTripDeclined.
  ///
  /// In en, this message translates to:
  /// **'Trip declined'**
  String get driverHomeTripDeclined;

  /// No description provided for @driverKycEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get driverKycEdit;

  /// No description provided for @driverKycPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this right now. Please try again.'**
  String get driverKycPickFailed;

  /// No description provided for @driverKycSignInToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to submit your KYC.'**
  String get driverKycSignInToSubmit;

  /// No description provided for @driverKycSignInToUpload.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to upload documents.'**
  String get driverKycSignInToUpload;

  /// No description provided for @driverKycView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get driverKycView;

  /// No description provided for @driverPaymentCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get driverPaymentCompany;

  /// No description provided for @driverPaymentPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get driverPaymentPersonal;

  /// No description provided for @driverPaymentQrUploaded.
  ///
  /// In en, this message translates to:
  /// **'QR uploaded'**
  String get driverPaymentQrUploaded;

  /// No description provided for @driverPaymentSignInRecord.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to record this payment.'**
  String get driverPaymentSignInRecord;

  /// No description provided for @driverPaymentSignInUploadQr.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to upload your payment QR.'**
  String get driverPaymentSignInUploadQr;

  /// No description provided for @driverPaymentVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get driverPaymentVerified;

  /// No description provided for @gpsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get gpsAbout;

  /// No description provided for @gpsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, licences and app details'**
  String get gpsAboutSubtitle;

  /// No description provided for @gpsAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get gpsAccountDetails;

  /// No description provided for @gpsAccountDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account information'**
  String get gpsAccountDetailsSubtitle;

  /// No description provided for @gpsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get gpsAccountSection;

  /// No description provided for @gpsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get gpsActive;

  /// No description provided for @gpsAllFleet.
  ///
  /// In en, this message translates to:
  /// **'Entire fleet'**
  String get gpsAllFleet;

  /// No description provided for @gpsAllVehiclesLiveMap.
  ///
  /// In en, this message translates to:
  /// **'All vehicles on live map'**
  String get gpsAllVehiclesLiveMap;

  /// No description provided for @gpsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get gpsAppearance;

  /// No description provided for @gpsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, dark or follow your device'**
  String get gpsAppearanceSubtitle;

  /// No description provided for @gpsBackToFleet.
  ///
  /// In en, this message translates to:
  /// **'Back to fleet'**
  String get gpsBackToFleet;

  /// No description provided for @gpsCached.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get gpsCached;

  /// No description provided for @gpsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get gpsChangePassword;

  /// No description provided for @gpsChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get gpsChangePasswordSubtitle;

  /// No description provided for @gpsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get gpsCompleted;

  /// No description provided for @gpsCreateGeofence.
  ///
  /// In en, this message translates to:
  /// **'Create geofence'**
  String get gpsCreateGeofence;

  /// No description provided for @gpsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get gpsCustom;

  /// No description provided for @gpsDashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get gpsDashboardWelcome;

  /// No description provided for @gpsDeducted.
  ///
  /// In en, this message translates to:
  /// **'Deducted'**
  String get gpsDeducted;

  /// No description provided for @gpsDefineZones.
  ///
  /// In en, this message translates to:
  /// **'Define zones'**
  String get gpsDefineZones;

  /// No description provided for @gpsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get gpsDuration;

  /// No description provided for @gpsDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time spent driving or idling'**
  String get gpsDurationSubtitle;

  /// No description provided for @gpsExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get gpsExpired;

  /// No description provided for @gpsExpiredTokensRemoved.
  ///
  /// In en, this message translates to:
  /// **'Expired tokens were removed'**
  String get gpsExpiredTokensRemoved;

  /// No description provided for @gpsFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get gpsFilter;

  /// No description provided for @gpsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gpsFilterAll;

  /// No description provided for @gpsFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get gpsFleet;

  /// No description provided for @gpsFleetStatus.
  ///
  /// In en, this message translates to:
  /// **'Fleet status'**
  String get gpsFleetStatus;

  /// No description provided for @gpsFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get gpsFrom;

  /// No description provided for @gpsFuelSummary.
  ///
  /// In en, this message translates to:
  /// **'Fuel summary'**
  String get gpsFuelSummary;

  /// No description provided for @gpsGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get gpsGenerateReport;

  /// No description provided for @gpsGeofences.
  ///
  /// In en, this message translates to:
  /// **'Geofences'**
  String get gpsGeofences;

  /// No description provided for @gpsGeofencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic alerts on entry and exit'**
  String get gpsGeofencesSubtitle;

  /// No description provided for @gpsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get gpsHelpSupport;

  /// No description provided for @gpsHelpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help or contact our team'**
  String get gpsHelpSupportSubtitle;

  /// No description provided for @gpsInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get gpsInvoices;

  /// No description provided for @gpsList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get gpsList;

  /// No description provided for @gpsLiveFleetTracking.
  ///
  /// In en, this message translates to:
  /// **'Live fleet tracking'**
  String get gpsLiveFleetTracking;

  /// No description provided for @gpsLiveMap.
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get gpsLiveMap;

  /// No description provided for @gpsLiveTrackingUnavailableFleet.
  ///
  /// In en, this message translates to:
  /// **'Live tracking is unavailable for this fleet.'**
  String get gpsLiveTrackingUnavailableFleet;

  /// No description provided for @gpsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get gpsLogout;

  /// No description provided for @gpsLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get gpsLogoutSubtitle;

  /// No description provided for @gpsMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get gpsMap;

  /// No description provided for @gpsModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get gpsModules;

  /// No description provided for @gpsMonthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly plan'**
  String get gpsMonthlyPlan;

  /// No description provided for @gpsMyFleet.
  ///
  /// In en, this message translates to:
  /// **'My fleet'**
  String get gpsMyFleet;

  /// No description provided for @gpsMyVehicles.
  ///
  /// In en, this message translates to:
  /// **'My vehicles'**
  String get gpsMyVehicles;

  /// No description provided for @gpsMyVehiclesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Devices linked to your account'**
  String get gpsMyVehiclesSubtitle;

  /// No description provided for @gpsNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get gpsNavDashboard;

  /// No description provided for @gpsNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get gpsNavProfile;

  /// No description provided for @gpsNavReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get gpsNavReports;

  /// No description provided for @gpsNavVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get gpsNavVehicles;

  /// No description provided for @gpsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get gpsNoData;

  /// No description provided for @gpsNoGeofencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a geofence to get alerts when a vehicle enters or leaves a zone.'**
  String get gpsNoGeofencesSubtitle;

  /// No description provided for @gpsNoGeofencesYet.
  ///
  /// In en, this message translates to:
  /// **'No geofences yet'**
  String get gpsNoGeofencesYet;

  /// No description provided for @gpsNoMoreTransactions.
  ///
  /// In en, this message translates to:
  /// **'No more transactions'**
  String get gpsNoMoreTransactions;

  /// No description provided for @gpsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get gpsNotifications;

  /// No description provided for @gpsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts about your vehicles'**
  String get gpsNotificationsSubtitle;

  /// No description provided for @gpsOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get gpsOffline;

  /// No description provided for @gpsOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get gpsOnline;

  /// No description provided for @gpsProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and preferences'**
  String get gpsProfileSubtitle;

  /// No description provided for @gpsRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get gpsRecentActivity;

  /// No description provided for @gpsReportType.
  ///
  /// In en, this message translates to:
  /// **'Report type'**
  String get gpsReportType;

  /// No description provided for @gpsReportTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to review'**
  String get gpsReportTypeSubtitle;

  /// No description provided for @gpsReportsSecureNote.
  ///
  /// In en, this message translates to:
  /// **'Reports are generated from your account data and stay private.'**
  String get gpsReportsSecureNote;

  /// No description provided for @gpsReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track usage, routes and costs over time'**
  String get gpsReportsSubtitle;

  /// No description provided for @gpsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gpsRetry;

  /// No description provided for @gpsRouteHistory.
  ///
  /// In en, this message translates to:
  /// **'Route history'**
  String get gpsRouteHistory;

  /// No description provided for @gpsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get gpsRunning;

  /// No description provided for @gpsSearchGeofences.
  ///
  /// In en, this message translates to:
  /// **'Search geofences'**
  String get gpsSearchGeofences;

  /// No description provided for @gpsSearchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get gpsSearchTransactions;

  /// No description provided for @gpsSearchVehiclesHint.
  ///
  /// In en, this message translates to:
  /// **'Search by number or name'**
  String get gpsSearchVehiclesHint;

  /// No description provided for @gpsSelectFromFleet.
  ///
  /// In en, this message translates to:
  /// **'Select from your fleet'**
  String get gpsSelectFromFleet;

  /// No description provided for @gpsSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get gpsSelectVehicle;

  /// No description provided for @gpsSelectVehicleOrFleet.
  ///
  /// In en, this message translates to:
  /// **'Pick a single vehicle or the whole fleet'**
  String get gpsSelectVehicleOrFleet;

  /// No description provided for @gpsSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get gpsSettings;

  /// No description provided for @gpsSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your tracking preferences'**
  String get gpsSettingsSubtitle;

  /// No description provided for @gpsSignInForFleetDevices.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your fleet devices.'**
  String get gpsSignInForFleetDevices;

  /// No description provided for @gpsSignInForLiveFleet.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view the live fleet.'**
  String get gpsSignInForLiveFleet;

  /// No description provided for @gpsSignInForVehicle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view this vehicle.'**
  String get gpsSignInForVehicle;

  /// No description provided for @gpsStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get gpsStopped;

  /// No description provided for @gpsSubscriptionPayment.
  ///
  /// In en, this message translates to:
  /// **'Subscription payment'**
  String get gpsSubscriptionPayment;

  /// No description provided for @gpsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get gpsThisWeek;

  /// No description provided for @gpsTimeEightMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'8 min ago'**
  String get gpsTimeEightMinsAgo;

  /// No description provided for @gpsTimeTwoMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'2 min ago'**
  String get gpsTimeTwoMinsAgo;

  /// No description provided for @gpsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get gpsTo;

  /// No description provided for @gpsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get gpsToday;

  /// No description provided for @gpsTokenBalance.
  ///
  /// In en, this message translates to:
  /// **'Token balance'**
  String get gpsTokenBalance;

  /// No description provided for @gpsTokenExpiry.
  ///
  /// In en, this message translates to:
  /// **'Token expiry'**
  String get gpsTokenExpiry;

  /// No description provided for @gpsTokenPurchase.
  ///
  /// In en, this message translates to:
  /// **'Token purchase'**
  String get gpsTokenPurchase;

  /// No description provided for @gpsTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get gpsTokens;

  /// No description provided for @gpsTokensAdded.
  ///
  /// In en, this message translates to:
  /// **'Tokens added'**
  String get gpsTokensAdded;

  /// No description provided for @gpsTotalVehicles.
  ///
  /// In en, this message translates to:
  /// **'Total vehicles'**
  String get gpsTotalVehicles;

  /// No description provided for @gpsTotalVehiclesCenter.
  ///
  /// In en, this message translates to:
  /// **'Vehicles reporting location'**
  String get gpsTotalVehiclesCenter;

  /// No description provided for @gpsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get gpsTransactions;

  /// No description provided for @gpsTripSummary.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get gpsTripSummary;

  /// No description provided for @gpsUsageSummary.
  ///
  /// In en, this message translates to:
  /// **'Usage summary'**
  String get gpsUsageSummary;

  /// No description provided for @gpsVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get gpsVehicle;

  /// No description provided for @gpsVehicleLiveMap.
  ///
  /// In en, this message translates to:
  /// **'Vehicle live map'**
  String get gpsVehicleLiveMap;

  /// No description provided for @gpsVehicleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not found'**
  String get gpsVehicleNotFound;

  /// No description provided for @gpsViaRazorpay.
  ///
  /// In en, this message translates to:
  /// **'Via Razorpay'**
  String get gpsViaRazorpay;

  /// No description provided for @gpsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get gpsViewAll;

  /// No description provided for @gpsVsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get gpsVsLastWeek;

  /// No description provided for @gpsWalletBilling.
  ///
  /// In en, this message translates to:
  /// **'Wallet & billing'**
  String get gpsWalletBilling;

  /// No description provided for @gpsWelcomeBonus.
  ///
  /// In en, this message translates to:
  /// **'Welcome bonus'**
  String get gpsWelcomeBonus;

  /// No description provided for @gpsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get gpsYesterday;

  /// No description provided for @historyDetailsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get historyDetailsCancel;

  /// No description provided for @historyDetailsEmailInvoice.
  ///
  /// In en, this message translates to:
  /// **'Email invoice'**
  String get historyDetailsEmailInvoice;

  /// No description provided for @historyDetailsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get historyDetailsRetry;

  /// No description provided for @historyDetailsSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get historyDetailsSend;

  /// No description provided for @historySegmentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get historySegmentCompleted;

  /// No description provided for @historySegmentPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get historySegmentPending;

  /// No description provided for @locationFlowAddLoading.
  ///
  /// In en, this message translates to:
  /// **'Add loading point'**
  String get locationFlowAddLoading;

  /// No description provided for @locationFlowAddLoadingHint.
  ///
  /// In en, this message translates to:
  /// **'Where should the goods be loaded?'**
  String get locationFlowAddLoadingHint;

  /// No description provided for @locationFlowAddUnloading.
  ///
  /// In en, this message translates to:
  /// **'Add unloading point'**
  String get locationFlowAddUnloading;

  /// No description provided for @locationFlowAddUnloadingHint.
  ///
  /// In en, this message translates to:
  /// **'Where should the goods be delivered?'**
  String get locationFlowAddUnloadingHint;

  /// No description provided for @locationFlowDropHint.
  ///
  /// In en, this message translates to:
  /// **'Search the drop location'**
  String get locationFlowDropHint;

  /// No description provided for @locationFlowDropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where is the goods going?'**
  String get locationFlowDropSubtitle;

  /// No description provided for @locationFlowDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop location'**
  String get locationFlowDropTitle;

  /// No description provided for @locationFlowFetching.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get locationFlowFetching;

  /// No description provided for @locationFlowMovePin.
  ///
  /// In en, this message translates to:
  /// **'Move the pin to adjust the point'**
  String get locationFlowMovePin;

  /// No description provided for @locationFlowOwnUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not read your current location.'**
  String get locationFlowOwnUnavailable;

  /// No description provided for @locationFlowPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to continue.'**
  String get locationFlowPermissionNeeded;

  /// No description provided for @locationFlowPickupHint.
  ///
  /// In en, this message translates to:
  /// **'Search the pickup location'**
  String get locationFlowPickupHint;

  /// No description provided for @locationFlowPickupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where is the goods coming from?'**
  String get locationFlowPickupSubtitle;

  /// No description provided for @locationFlowPickupTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get locationFlowPickupTitle;

  /// No description provided for @locationFlowPinHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the pin to the exact spot'**
  String get locationFlowPinHint;

  /// No description provided for @locationFlowPinLoading.
  ///
  /// In en, this message translates to:
  /// **'Place loading pin'**
  String get locationFlowPinLoading;

  /// No description provided for @locationFlowPinUnloading.
  ///
  /// In en, this message translates to:
  /// **'Place drop pin'**
  String get locationFlowPinUnloading;

  /// No description provided for @locationFlowResolveCurrent.
  ///
  /// In en, this message translates to:
  /// **'We could not determine your current location.'**
  String get locationFlowResolveCurrent;

  /// No description provided for @locationFlowResolvePoint.
  ///
  /// In en, this message translates to:
  /// **'We could not locate that point on the map.'**
  String get locationFlowResolvePoint;

  /// No description provided for @locationFlowSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location saved'**
  String get locationFlowSavedTitle;

  /// No description provided for @locationFlowSuggestionsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load location suggestions'**
  String get locationFlowSuggestionsError;

  /// No description provided for @locationFlowTurnOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Please turn on location services.'**
  String get locationFlowTurnOnLocation;

  /// No description provided for @locationFlowUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get locationFlowUseCurrent;

  /// No description provided for @locationFlowUseCurrentPickup.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locationFlowUseCurrentPickup;

  /// No description provided for @manageAccountActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get manageAccountActiveLabel;

  /// No description provided for @manageAccountActiveNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get manageAccountActiveNo;

  /// No description provided for @manageAccountActiveYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get manageAccountActiveYes;

  /// No description provided for @manageAccountBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic details'**
  String get manageAccountBasicDetails;

  /// No description provided for @manageAccountBusinessAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get manageAccountBusinessAddressLabel;

  /// No description provided for @manageAccountBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get manageAccountBusinessDetails;

  /// No description provided for @manageAccountChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get manageAccountChangePhoto;

  /// No description provided for @manageAccountEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name, email, phone and photo'**
  String get manageAccountEditProfileSubtitle;

  /// No description provided for @manageAccountEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get manageAccountEditProfileTitle;

  /// No description provided for @manageAccountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get manageAccountEmailLabel;

  /// No description provided for @manageAccountEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get manageAccountEnterEmail;

  /// No description provided for @manageAccountEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get manageAccountEnterName;

  /// No description provided for @manageAccountEnterServiceCity.
  ///
  /// In en, this message translates to:
  /// **'Enter your service city'**
  String get manageAccountEnterServiceCity;

  /// No description provided for @manageAccountEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get manageAccountEnterValidEmail;

  /// No description provided for @manageAccountFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get manageAccountFullNameLabel;

  /// No description provided for @manageAccountOptionalTag.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get manageAccountOptionalTag;

  /// No description provided for @manageAccountPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get manageAccountPhoneLabel;

  /// No description provided for @manageAccountProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated'**
  String get manageAccountProfileUpdated;

  /// No description provided for @manageAccountSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get manageAccountSaveChanges;

  /// No description provided for @manageAccountServiceCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Service city'**
  String get manageAccountServiceCityLabel;

  /// No description provided for @manageAccountYourNameFallback.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get manageAccountYourNameFallback;

  /// No description provided for @negotiationAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get negotiationAccept;

  /// No description provided for @negotiationBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get negotiationBack;

  /// No description provided for @negotiationBrokerConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the broker to confirm the new fare.'**
  String get negotiationBrokerConfirmBody;

  /// No description provided for @negotiationBrokerConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirming with broker'**
  String get negotiationBrokerConfirmTitle;

  /// No description provided for @negotiationBrokerOfferBody.
  ///
  /// In en, this message translates to:
  /// **'The broker has sent a revised fare. Review it below.'**
  String get negotiationBrokerOfferBody;

  /// No description provided for @negotiationBrokerOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Broker\'s offer'**
  String get negotiationBrokerOfferLabel;

  /// No description provided for @negotiationBrokerOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'New offer from broker'**
  String get negotiationBrokerOfferTitle;

  /// No description provided for @negotiationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get negotiationConfirm;

  /// No description provided for @negotiationDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get negotiationDecline;

  /// No description provided for @negotiationDriverAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted'**
  String get negotiationDriverAcceptedTitle;

  /// No description provided for @negotiationDriverConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver to confirm the new fare.'**
  String get negotiationDriverConfirmBody;

  /// No description provided for @negotiationDriverConfirmNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm with driver'**
  String get negotiationDriverConfirmNowTitle;

  /// No description provided for @negotiationDriverFallback.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get negotiationDriverFallback;

  /// No description provided for @negotiationDriverResponseBody.
  ///
  /// In en, this message translates to:
  /// **'The driver has responded to your fare change.'**
  String get negotiationDriverResponseBody;

  /// No description provided for @negotiationDriverResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver responded'**
  String get negotiationDriverResponseTitle;

  /// No description provided for @negotiationFareChangeBody.
  ///
  /// In en, this message translates to:
  /// **'We have sent your new fare. Waiting for a response.'**
  String get negotiationFareChangeBody;

  /// No description provided for @negotiationFareChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare change sent'**
  String get negotiationFareChangeTitle;

  /// No description provided for @negotiationHandshakeProgress.
  ///
  /// In en, this message translates to:
  /// **'Both sides are confirming the new fare'**
  String get negotiationHandshakeProgress;

  /// No description provided for @negotiationOfferCaption.
  ///
  /// In en, this message translates to:
  /// **'Fare for this booking'**
  String get negotiationOfferCaption;

  /// No description provided for @negotiationOfferSentBody.
  ///
  /// In en, this message translates to:
  /// **'Your offer has been sent. Waiting for the other side.'**
  String get negotiationOfferSentBody;

  /// No description provided for @negotiationOfferSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer sent'**
  String get negotiationOfferSentTitle;

  /// No description provided for @negotiationPillActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get negotiationPillActionNeeded;

  /// No description provided for @negotiationPillLiveOffer.
  ///
  /// In en, this message translates to:
  /// **'Live offer'**
  String get negotiationPillLiveOffer;

  /// No description provided for @negotiationPillNewCounter.
  ///
  /// In en, this message translates to:
  /// **'New counter offer'**
  String get negotiationPillNewCounter;

  /// No description provided for @negotiationPillWithBroker.
  ///
  /// In en, this message translates to:
  /// **'With broker'**
  String get negotiationPillWithBroker;

  /// No description provided for @negotiationWaitingBrokerBody.
  ///
  /// In en, this message translates to:
  /// **'We have sent your fare. Waiting for the broker to respond.'**
  String get negotiationWaitingBrokerBody;

  /// No description provided for @negotiationWaitingBrokerTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for broker'**
  String get negotiationWaitingBrokerTitle;

  /// No description provided for @negotiationWaitingDriverBody.
  ///
  /// In en, this message translates to:
  /// **'We have sent the new fare to the driver.'**
  String get negotiationWaitingDriverBody;

  /// No description provided for @negotiationWaitingDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver'**
  String get negotiationWaitingDriverTitle;

  /// No description provided for @onboardingFastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payments, invoices, and updates stay in one place.'**
  String get onboardingFastSubtitle;

  /// No description provided for @onboardingFastTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast settlements'**
  String get onboardingFastTitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSafeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book verified trucks and drivers with confidence.'**
  String get onboardingSafeSubtitle;

  /// No description provided for @onboardingSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe bookings'**
  String get onboardingSafeTitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track every shipment from pickup to delivery.'**
  String get onboardingTrackingSubtitle;

  /// No description provided for @onboardingTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get onboardingTrackingTitle;

  /// No description provided for @orderAcceptedAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip assigned'**
  String get orderAcceptedAssignedTitle;

  /// No description provided for @orderAcceptedOfferUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This offer is no longer available.'**
  String get orderAcceptedOfferUnavailable;

  /// No description provided for @orderAcceptedRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get orderAcceptedRequestTitle;

  /// No description provided for @orderAcceptedRequestUpdated.
  ///
  /// In en, this message translates to:
  /// **'This request was updated. Pull down to refresh.'**
  String get orderAcceptedRequestUpdated;

  /// No description provided for @orderAcceptedSignInContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get orderAcceptedSignInContinue;

  /// No description provided for @photoUploadChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get photoUploadChoosePhoto;

  /// No description provided for @photoUploadMaxItems.
  ///
  /// In en, this message translates to:
  /// **'You can upload up to 5 photos.'**
  String get photoUploadMaxItems;

  /// No description provided for @photoUploadRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get photoUploadRecordVideo;

  /// No description provided for @photoUploadSignInUpload.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to upload photos.'**
  String get photoUploadSignInUpload;

  /// No description provided for @photoUploadTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get photoUploadTakePhoto;

  /// No description provided for @podWaitingCouldNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Could not complete'**
  String get podWaitingCouldNotComplete;

  /// No description provided for @podWaitingFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing up...'**
  String get podWaitingFinishing;

  /// No description provided for @podWaitingNewPhotosFallback.
  ///
  /// In en, this message translates to:
  /// **'New delivery photos'**
  String get podWaitingNewPhotosFallback;

  /// No description provided for @podWaitingPhotosUp.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos...'**
  String get podWaitingPhotosUp;

  /// No description provided for @podWaitingRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery rejected'**
  String get podWaitingRejectedTitle;

  /// No description provided for @podWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery'**
  String get podWaitingTitle;

  /// No description provided for @podWaitingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get podWaitingTryAgain;

  /// No description provided for @podWaitingUploadNew.
  ///
  /// In en, this message translates to:
  /// **'Upload new photos'**
  String get podWaitingUploadNew;

  /// No description provided for @podWaitingWaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get podWaitingWaitingReview;

  /// No description provided for @sessionExpiredEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get sessionExpiredEmailHint;

  /// No description provided for @sessionExpiredEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get sessionExpiredEmailLabel;

  /// No description provided for @sessionExpiredEnterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to continue.'**
  String get sessionExpiredEnterEmailPassword;

  /// No description provided for @sessionExpiredPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get sessionExpiredPasswordHint;

  /// No description provided for @sessionExpiredPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get sessionExpiredPasswordLabel;

  /// No description provided for @sessionExpiredSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sessionExpiredSignInButton;

  /// No description provided for @sessionExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to pick up where you left off.'**
  String get sessionExpiredSubtitle;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpiredTitle;

  /// No description provided for @sharedExpressLabel.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get sharedExpressLabel;

  /// No description provided for @sharedHaltingChargeApplied.
  ///
  /// In en, this message translates to:
  /// **'Halting charge applied'**
  String get sharedHaltingChargeApplied;

  /// No description provided for @sharedHaltingExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'Free time exceeded'**
  String get sharedHaltingExceededTitle;

  /// No description provided for @sharedHaltingFreeWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Free waiting time'**
  String get sharedHaltingFreeWindowTitle;

  /// No description provided for @sharedHaltingRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get sharedHaltingRemainingTitle;

  /// No description provided for @signupAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created.'**
  String get signupAccountCreated;

  /// No description provided for @signupAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms and Privacy Policy'**
  String get signupAgreeTerms;

  /// No description provided for @signupAllFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get signupAllFieldsRequired;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get signupBackToLogin;

  /// No description provided for @signupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupCreateAccount;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get signupEmailHint;

  /// No description provided for @signupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmailLabel;

  /// No description provided for @signupFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get signupFullNameHint;

  /// No description provided for @signupFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get signupFullNameLabel;

  /// No description provided for @signupLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get signupLoginAction;

  /// No description provided for @signupPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get signupPasswordHelper;

  /// No description provided for @signupPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get signupPasswordHint;

  /// No description provided for @signupPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPasswordLabel;

  /// No description provided for @signupPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get signupPhoneHint;

  /// No description provided for @signupPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get signupPhoneLabel;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start booking'**
  String get signupSubtitle;

  /// No description provided for @signupTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms to continue.'**
  String get signupTermsRequired;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// No description provided for @thankYouBackToTrips.
  ///
  /// In en, this message translates to:
  /// **'Back to trips'**
  String get thankYouBackToTrips;

  /// No description provided for @thankYouDeliveryComplete.
  ///
  /// In en, this message translates to:
  /// **'Delivery complete'**
  String get thankYouDeliveryComplete;

  /// No description provided for @thankYouForCompleting.
  ///
  /// In en, this message translates to:
  /// **'for completing this delivery'**
  String get thankYouForCompleting;

  /// No description provided for @thankYouPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get thankYouPaid;

  /// No description provided for @thankYouTripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get thankYouTripCompleted;

  /// No description provided for @tripSummaryCargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get tripSummaryCargo;

  /// No description provided for @tripSummaryDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get tripSummaryDelivered;

  /// No description provided for @tripSummaryInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tripSummaryInProgress;

  /// No description provided for @tripSummaryLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get tripSummaryLocationUnavailable;

  /// No description provided for @truckSearchAllDeclinedHint.
  ///
  /// In en, this message translates to:
  /// **'Nearby drivers declined. Try widening your search radius.'**
  String get truckSearchAllDeclinedHint;

  /// No description provided for @truckSearchBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get truckSearchBack;

  /// No description provided for @truckSearchCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel search'**
  String get truckSearchCancel;

  /// No description provided for @truckSearchCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get truckSearchCloseTooltip;

  /// No description provided for @truckSearchConfirmTurn.
  ///
  /// In en, this message translates to:
  /// **'Confirming your acceptance'**
  String get truckSearchConfirmTurn;

  /// No description provided for @truckSearchConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get truckSearchConfirmed;

  /// No description provided for @truckSearchDriverFallback.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get truckSearchDriverFallback;

  /// No description provided for @truckSearchFindingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Finding drivers'**
  String get truckSearchFindingDrivers;

  /// No description provided for @truckSearchFindingNearby.
  ///
  /// In en, this message translates to:
  /// **'Looking for drivers near your pickup'**
  String get truckSearchFindingNearby;

  /// No description provided for @truckSearchGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get truckSearchGoBack;

  /// No description provided for @truckSearchKeepSearching.
  ///
  /// In en, this message translates to:
  /// **'Keep searching'**
  String get truckSearchKeepSearching;

  /// No description provided for @truckSearchNewFare.
  ///
  /// In en, this message translates to:
  /// **'New fare received'**
  String get truckSearchNewFare;

  /// No description provided for @truckSearchNoDriverAccepted.
  ///
  /// In en, this message translates to:
  /// **'No driver accepted yet'**
  String get truckSearchNoDriverAccepted;

  /// No description provided for @truckSearchNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No response'**
  String get truckSearchNoResponse;

  /// No description provided for @truckSearchNotifyingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Notifying drivers nearby'**
  String get truckSearchNotifyingDrivers;

  /// No description provided for @truckSearchRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get truckSearchRetry;

  /// No description provided for @truckSearchSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get truckSearchSearching;

  /// No description provided for @truckSearchWaitingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get truckSearchWaitingConfirm;

  /// No description provided for @truckSearchWaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for responses'**
  String get truckSearchWaitingResponse;

  /// No description provided for @negotiationContinuePrice.
  ///
  /// In en, this message translates to:
  /// **'Continue price'**
  String get negotiationContinuePrice;

  /// No description provided for @negotiationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get negotiationCancel;

  /// No description provided for @negotiationSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get negotiationSend;

  /// No description provided for @negotiationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get negotiationReject;

  /// No description provided for @negotiationChangeFare.
  ///
  /// In en, this message translates to:
  /// **'Change fare'**
  String get negotiationChangeFare;

  /// No description provided for @negotiationReviewPriceFor.
  ///
  /// In en, this message translates to:
  /// **'Review price for {truck}'**
  String negotiationReviewPriceFor(Object truck);

  /// No description provided for @negotiationOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'Offer price'**
  String get negotiationOfferPrice;

  /// No description provided for @driverKycReviewYourInformation.
  ///
  /// In en, this message translates to:
  /// **'Review Your Information'**
  String get driverKycReviewYourInformation;

  /// No description provided for @driverKycPleaseVerifyEverythingBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Please verify everything before submitting.'**
  String get driverKycPleaseVerifyEverythingBeforeSubmitting;

  /// No description provided for @driverKycDriverInformation.
  ///
  /// In en, this message translates to:
  /// **'Driver Information'**
  String get driverKycDriverInformation;

  /// No description provided for @driverKycPANNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get driverKycPANNumber;

  /// No description provided for @driverKycDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get driverKycDateOfBirth;

  /// No description provided for @driverKycLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get driverKycLicenseNumber;

  /// No description provided for @driverKycAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get driverKycAadhaarNumber;

  /// No description provided for @driverKycVehicleRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration Number'**
  String get driverKycVehicleRegistrationNumber;

  /// No description provided for @driverKycVehicleInsuranceNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Insurance Number'**
  String get driverKycVehicleInsuranceNumber;

  /// No description provided for @driverKycNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get driverKycNotProvided;

  /// No description provided for @driverKycUploadedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Documents'**
  String get driverKycUploadedDocuments;

  /// No description provided for @driverKycVerificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Verification Details'**
  String get driverKycVerificationDetails;

  /// No description provided for @driverKycCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get driverKycCurrentStatus;

  /// No description provided for @driverKycSubmittedDate.
  ///
  /// In en, this message translates to:
  /// **'Submitted Date'**
  String get driverKycSubmittedDate;

  /// No description provided for @driverKycSubmissionID.
  ///
  /// In en, this message translates to:
  /// **'Submission ID'**
  String get driverKycSubmissionID;

  /// No description provided for @driverKycReviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed At'**
  String get driverKycReviewedAt;

  /// No description provided for @driverKycNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get driverKycNotAvailable;

  /// No description provided for @driverKycDrivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get driverKycDrivingLicense;

  /// No description provided for @driverKycVehicleRegShort.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Reg.'**
  String get driverKycVehicleRegShort;

  /// No description provided for @driverKycInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get driverKycInsurance;

  /// No description provided for @driverKycChooseHowYouWantToUploadThisDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to upload this document.'**
  String get driverKycChooseHowYouWantToUploadThisDocument;

  /// No description provided for @driverKycCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get driverKycCamera;

  /// No description provided for @driverKycGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get driverKycGallery;

  /// No description provided for @driverKycCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get driverKycCancel;

  /// No description provided for @driverKycDocumentPreview.
  ///
  /// In en, this message translates to:
  /// **'Document preview'**
  String get driverKycDocumentPreview;

  /// No description provided for @driverKycUploadedFile.
  ///
  /// In en, this message translates to:
  /// **'Uploaded file'**
  String get driverKycUploadedFile;

  /// No description provided for @driverKycUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get driverKycUpload;

  /// No description provided for @driverKycClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get driverKycClose;

  /// No description provided for @driverKycStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get driverKycStepDetails;

  /// No description provided for @driverKycStepDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get driverKycStepDocuments;

  /// No description provided for @driverKycStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get driverKycStepReview;

  /// No description provided for @driverKycStepSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get driverKycStepSubmit;

  /// No description provided for @driverKycVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Verified'**
  String get driverKycVerifiedTitle;

  /// No description provided for @driverKycVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your driver account is verified and active.'**
  String get driverKycVerifiedSubtitle;

  /// No description provided for @driverKycVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get driverKycVerifiedBadge;

  /// No description provided for @driverKycRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Rejected'**
  String get driverKycRejectedTitle;

  /// No description provided for @driverKycRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the reason below and resubmit your documents.'**
  String get driverKycRejectedSubtitle;

  /// No description provided for @driverKycRejectedBadge.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get driverKycRejectedBadge;

  /// No description provided for @driverKycUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Under Review'**
  String get driverKycUnderReviewTitle;

  /// No description provided for @driverKycUnderReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted successfully. Review usually takes 24-48 hours.'**
  String get driverKycUnderReviewSubtitle;

  /// No description provided for @driverKycSubmittedBadge.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED'**
  String get driverKycSubmittedBadge;

  /// No description provided for @driverKycCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Driver KYC'**
  String get driverKycCompleteTitle;

  /// No description provided for @driverKycCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your identity and vehicle documents for verification.'**
  String get driverKycCompleteSubtitle;

  /// No description provided for @driverKycPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get driverKycPendingBadge;

  /// No description provided for @driverKycPanCard.
  ///
  /// In en, this message translates to:
  /// **'PAN Card'**
  String get driverKycPanCard;

  /// No description provided for @driverKycAadhaarCard.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card'**
  String get driverKycAadhaarCard;

  /// No description provided for @driverKycUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get driverKycUploaded;

  /// No description provided for @driverKycRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get driverKycRequired;

  /// No description provided for @driverKycSupportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: {formats}'**
  String driverKycSupportedFormats(Object formats);

  /// No description provided for @driverKycMaxSize10Mb.
  ///
  /// In en, this message translates to:
  /// **'Max 10 MB'**
  String get driverKycMaxSize10Mb;

  /// No description provided for @driverKycDocumentPhoto.
  ///
  /// In en, this message translates to:
  /// **'{document} Photo'**
  String driverKycDocumentPhoto(Object document);

  /// No description provided for @driverKycNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get driverKycNotUploaded;

  /// No description provided for @driverKycWaitingForUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting for upload'**
  String get driverKycWaitingForUpload;

  /// No description provided for @clientSavedAddNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get clientSavedAddNewAddress;

  /// No description provided for @clientSavedPickupOrDropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup or Drop-off Location'**
  String get clientSavedPickupOrDropoffLocation;

  /// No description provided for @clientSavedAddressNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give this address a name, such as Home or Warehouse.'**
  String get clientSavedAddressNameRequired;

  /// No description provided for @clientSavedAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Search and select an address from Google Maps.'**
  String get clientSavedAddressRequired;

  /// No description provided for @clientSavedPinnedLocation.
  ///
  /// In en, this message translates to:
  /// **'Pinned location ({latitude}, {longitude})'**
  String clientSavedPinnedLocation(Object latitude, Object longitude);

  /// No description provided for @clientSavedLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Home, Office, Warehouse 2'**
  String get clientSavedLabelHint;

  /// No description provided for @clientSavedUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use current'**
  String get clientSavedUseCurrent;

  /// No description provided for @clientSavedSearchOrTapMap.
  ///
  /// In en, this message translates to:
  /// **'Search, or tap the map...'**
  String get clientSavedSearchOrTapMap;

  /// No description provided for @clientSavedFloorHint.
  ///
  /// In en, this message translates to:
  /// **'3rd Floor, Flat 402, Gate 2'**
  String get clientSavedFloorHint;

  /// No description provided for @clientSavedOnSiteContact.
  ///
  /// In en, this message translates to:
  /// **'On-site Contact'**
  String get clientSavedOnSiteContact;

  /// No description provided for @clientSavedOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get clientSavedOptional;

  /// No description provided for @clientSavedContactNameHint.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get clientSavedContactNameHint;

  /// No description provided for @clientSavedUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get clientSavedUse;

  /// No description provided for @historyDetailsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get historyDetailsTo;

  /// No description provided for @historyDetailsEmailHint.
  ///
  /// In en, this message translates to:
  /// **'recipient@example.com'**
  String get historyDetailsEmailHint;

  /// No description provided for @historyDetailsBookingTime.
  ///
  /// In en, this message translates to:
  /// **'Booking time'**
  String get historyDetailsBookingTime;

  /// No description provided for @historyDetailsExpectedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery'**
  String get historyDetailsExpectedDelivery;

  /// No description provided for @historyDetailsDeliveredOn.
  ///
  /// In en, this message translates to:
  /// **'Delivered on'**
  String get historyDetailsDeliveredOn;

  /// No description provided for @historyDetailsDistanceTravelled.
  ///
  /// In en, this message translates to:
  /// **'Distance travelled'**
  String get historyDetailsDistanceTravelled;

  /// No description provided for @historyDetailsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get historyDetailsSaving;

  /// No description provided for @historyDetailsInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get historyDetailsInvoice;

  /// No description provided for @historyDetailsSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get historyDetailsSending;

  /// No description provided for @historyDetailsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get historyDetailsEmail;

  /// No description provided for @historyDetailsNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get historyDetailsNotify;

  /// No description provided for @deliveryFlowShowThisToCollect.
  ///
  /// In en, this message translates to:
  /// **'Show this to collect {amount}'**
  String deliveryFlowShowThisToCollect(Object amount);

  /// No description provided for @deliveryFlowScanToPayViaUpi.
  ///
  /// In en, this message translates to:
  /// **'Scan to pay {amount} via any UPI app'**
  String deliveryFlowScanToPayViaUpi(Object amount);

  /// No description provided for @deliveryFlowAddUpiIdForQr.
  ///
  /// In en, this message translates to:
  /// **'Add your UPI ID in Profile to show a scannable payment QR here next time.'**
  String get deliveryFlowAddUpiIdForQr;

  /// No description provided for @deliveryFlowPaymentReceivedViaUpi.
  ///
  /// In en, this message translates to:
  /// **'Payment Received via UPI'**
  String get deliveryFlowPaymentReceivedViaUpi;

  /// No description provided for @deliveryFlowRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get deliveryFlowRecording;

  /// No description provided for @deliveryFlowCollectCash.
  ///
  /// In en, this message translates to:
  /// **'Collect Cash'**
  String get deliveryFlowCollectCash;

  /// No description provided for @deliveryFlowPaymentVerifiedByRazorpay.
  ///
  /// In en, this message translates to:
  /// **'Payment verified by Razorpay'**
  String get deliveryFlowPaymentVerifiedByRazorpay;

  /// No description provided for @deliveryFlowQrGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate the verified QR code - collect via UPI ID or cash instead.'**
  String get deliveryFlowQrGenerationFailed;

  /// No description provided for @deliveryFlowRazorpayAutoConfirms.
  ///
  /// In en, this message translates to:
  /// **'Auto-confirms the moment Razorpay verifies the payment'**
  String get deliveryFlowRazorpayAutoConfirms;

  /// No description provided for @negotiationAcceptedWaitingDriverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accepted - waiting for the driver to confirm.'**
  String get negotiationAcceptedWaitingDriverConfirm;

  /// No description provided for @loadingPoint.
  ///
  /// In en, this message translates to:
  /// **'Loading point'**
  String get loadingPoint;

  /// No description provided for @unloadingPoint.
  ///
  /// In en, this message translates to:
  /// **'Unloading point'**
  String get unloadingPoint;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @emailRecipientHint.
  ///
  /// In en, this message translates to:
  /// **'recipient@example.com'**
  String get emailRecipientHint;

  /// No description provided for @addMoreDetailOptional.
  ///
  /// In en, this message translates to:
  /// **'Add more detail (optional)'**
  String get addMoreDetailOptional;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @brokerStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get brokerStatusAccepted;

  /// No description provided for @brokerStatusAcceptedBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Accepted - booking confirmed'**
  String get brokerStatusAcceptedBookingConfirmed;

  /// No description provided for @brokerStatusFareChanged.
  ///
  /// In en, this message translates to:
  /// **'Fare changed'**
  String get brokerStatusFareChanged;

  /// No description provided for @brokerStatusFareChangedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Fare changed - waiting for the next response'**
  String get brokerStatusFareChangedWaiting;

  /// No description provided for @brokerStatusAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get brokerStatusAwaitingConfirmation;

  /// No description provided for @brokerStatusWaitingOtherSideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other side to confirm.'**
  String get brokerStatusWaitingOtherSideConfirm;

  /// No description provided for @brokerStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get brokerStatusDeclined;

  /// No description provided for @brokerStatusDeclinedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Declined - no longer available'**
  String get brokerStatusDeclinedUnavailable;

  /// No description provided for @brokerStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get brokerStatusPending;

  /// No description provided for @brokerStatusReviewRequest.
  ///
  /// In en, this message translates to:
  /// **'Review request'**
  String get brokerStatusReviewRequest;

  /// No description provided for @brokerStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get brokerStatusCancelled;

  /// No description provided for @brokerReqAcceptedAssignDriverTruck.
  ///
  /// In en, this message translates to:
  /// **'This request has been accepted. Assign a driver and truck.'**
  String get brokerReqAcceptedAssignDriverTruck;

  /// No description provided for @brokerReqFareChangeWaitingClient.
  ///
  /// In en, this message translates to:
  /// **'Fare change sent. Waiting for the client to respond.'**
  String get brokerReqFareChangeWaitingClient;

  /// No description provided for @brokerReqCancelledNoActions.
  ///
  /// In en, this message translates to:
  /// **'This booking has been cancelled. No further broker actions are available.'**
  String get brokerReqCancelledNoActions;

  /// No description provided for @brokerReqPendingAction.
  ///
  /// In en, this message translates to:
  /// **'This request is still waiting for action.'**
  String get brokerReqPendingAction;

  /// No description provided for @brokerSettlementsFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get brokerSettlementsFee;

  /// No description provided for @brokerSettlementsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get brokerSettlementsNet;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @dropLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop location'**
  String get dropLocation;

  /// No description provided for @vehicleSmallTruck.
  ///
  /// In en, this message translates to:
  /// **'Small truck'**
  String get vehicleSmallTruck;

  /// No description provided for @vehicleMediumTruck.
  ///
  /// In en, this message translates to:
  /// **'Medium truck'**
  String get vehicleMediumTruck;

  /// No description provided for @vehicleBigTruck.
  ///
  /// In en, this message translates to:
  /// **'Big truck'**
  String get vehicleBigTruck;

  /// No description provided for @vehicleTruckPooling.
  ///
  /// In en, this message translates to:
  /// **'Truck pooling'**
  String get vehicleTruckPooling;

  /// No description provided for @historyDetailsTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get historyDetailsTripDetails;

  /// No description provided for @historyDetailsEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get historyDetailsEarnings;

  /// No description provided for @historyDetailsOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get historyDetailsOpenInMaps;

  /// No description provided for @historyDetailsMissingBookingId.
  ///
  /// In en, this message translates to:
  /// **'Missing booking id.'**
  String get historyDetailsMissingBookingId;

  /// No description provided for @historyDetailsSignInToView.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to view delivery details.'**
  String get historyDetailsSignInToView;

  /// No description provided for @historyDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load delivery details.'**
  String get historyDetailsLoadFailed;

  /// No description provided for @historyDetailsSignInToDownload.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to download the invoice.'**
  String get historyDetailsSignInToDownload;

  /// No description provided for @historyDetailsSignInToEmail.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to email the invoice.'**
  String get historyDetailsSignInToEmail;

  /// No description provided for @historyDetailsSignInToNotify.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to notify the client.'**
  String get historyDetailsSignInToNotify;

  /// No description provided for @historyDetailsEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Please find attached the invoice for booking {bookingRef}.'**
  String historyDetailsEmailBody(Object bookingRef);

  /// No description provided for @historyDetailsPreviousDriver.
  ///
  /// In en, this message translates to:
  /// **'Previous driver'**
  String get historyDetailsPreviousDriver;

  /// No description provided for @historyDetailsNewDriver.
  ///
  /// In en, this message translates to:
  /// **'New driver'**
  String get historyDetailsNewDriver;

  /// No description provided for @historyDetailsDriverChanged.
  ///
  /// In en, this message translates to:
  /// **'Driver changed ({count})'**
  String historyDetailsDriverChanged(Object count);

  /// No description provided for @deliveryDetailsStopLabel.
  ///
  /// In en, this message translates to:
  /// **'{stop} point'**
  String deliveryDetailsStopLabel(Object stop);

  /// No description provided for @deliveryDetailsStopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading & unloading stops'**
  String get deliveryDetailsStopsTitle;

  /// No description provided for @deliveryDetailsConfirmDropReached.
  ///
  /// In en, this message translates to:
  /// **'Confirm when you have reached the drop point.'**
  String get deliveryDetailsConfirmDropReached;

  /// No description provided for @deliveryDetailsLoadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get deliveryDetailsLoadingEllipsis;

  /// No description provided for @deliveryDetailsEnterPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter pickup code'**
  String get deliveryDetailsEnterPickupCode;

  /// No description provided for @deliveryDetailsConfirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Confirm pickup'**
  String get deliveryDetailsConfirmPickup;

  /// No description provided for @deliveryDetailsOpenPickupInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open pickup in Google Maps'**
  String get deliveryDetailsOpenPickupInMaps;

  /// No description provided for @deliveryDetailsOpenDropInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open drop in Google Maps'**
  String get deliveryDetailsOpenDropInMaps;

  /// No description provided for @deliveryDetailsDropLocationMissing.
  ///
  /// In en, this message translates to:
  /// **'Drop location not provided'**
  String get deliveryDetailsDropLocationMissing;

  /// No description provided for @deliveryDetailsSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get deliveryDetailsSignInToContinue;

  /// No description provided for @driverKycUploadDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get driverKycUploadDocumentsTitle;

  /// No description provided for @driverKycUploadDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload clear photos of the following documents.'**
  String get driverKycUploadDocumentsSubtitle;

  /// No description provided for @driverKycVerifyIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get driverKycVerifyIdentityTitle;

  /// No description provided for @driverKycRequiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get driverKycRequiredBadge;

  /// No description provided for @driverKycNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session found.'**
  String get driverKycNoActiveSession;

  /// No description provided for @driverKycConfirmAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that all information is accurate.'**
  String get driverKycConfirmAccuracy;

  /// No description provided for @driverKycSubmittedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Submitted documents'**
  String get driverKycSubmittedDocuments;

  /// No description provided for @driverKycVerifyCarefully.
  ///
  /// In en, this message translates to:
  /// **'Please verify all information carefully. Incorrect information may delay KYC approval.'**
  String get driverKycVerifyCarefully;

  /// No description provided for @driverKycSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get driverKycSubmitForReview;

  /// No description provided for @driverKycSourceLabelSubmittedUrl.
  ///
  /// In en, this message translates to:
  /// **'Submitted URL'**
  String get driverKycSourceLabelSubmittedUrl;

  /// No description provided for @addVehicleInsuranceExpiryHelp.
  ///
  /// In en, this message translates to:
  /// **'Select insurance expiry date'**
  String get addVehicleInsuranceExpiryHelp;

  /// No description provided for @addVehicleEditTruckTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit truck'**
  String get addVehicleEditTruckTitle;

  /// No description provided for @addVehicleAddTruckTitle.
  ///
  /// In en, this message translates to:
  /// **'Add truck'**
  String get addVehicleAddTruckTitle;

  /// No description provided for @addVehicleEditTruckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the truck details and save the changes.'**
  String get addVehicleEditTruckSubtitle;

  /// No description provided for @addVehicleAddTruckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the truck type and fill in the fleet details.'**
  String get addVehicleAddTruckSubtitle;

  /// No description provided for @addVehicleErrRegistration.
  ///
  /// In en, this message translates to:
  /// **'Enter registration number'**
  String get addVehicleErrRegistration;

  /// No description provided for @addVehicleErrCapacity.
  ///
  /// In en, this message translates to:
  /// **'Enter capacity'**
  String get addVehicleErrCapacity;

  /// No description provided for @addVehicleErrSelectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select a driver'**
  String get addVehicleErrSelectDriver;

  /// No description provided for @addVehicleErrMake.
  ///
  /// In en, this message translates to:
  /// **'Enter truck make'**
  String get addVehicleErrMake;

  /// No description provided for @addVehicleErrYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid year'**
  String get addVehicleErrYear;

  /// No description provided for @addVehicleErrInsuranceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Enter insurance expiry date'**
  String get addVehicleErrInsuranceExpiry;

  /// No description provided for @addVehicleUpdateTruck.
  ///
  /// In en, this message translates to:
  /// **'Update truck'**
  String get addVehicleUpdateTruck;

  /// No description provided for @addDriverEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit driver'**
  String get addDriverEditTitle;

  /// No description provided for @addDriverAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add driver'**
  String get addDriverAddTitle;

  /// No description provided for @addDriverEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the driver account'**
  String get addDriverEditSubtitle;

  /// No description provided for @addDriverAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new driver to your fleet'**
  String get addDriverAddSubtitle;

  /// No description provided for @addDriverUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update driver'**
  String get addDriverUpdateAction;

  /// No description provided for @addDriverAddPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add driver photo'**
  String get addDriverAddPhotoTitle;

  /// No description provided for @addDriverErrName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get addDriverErrName;

  /// No description provided for @addDriverErrEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get addDriverErrEmail;

  /// No description provided for @addDriverEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address — the driver logs in with email + password.'**
  String get addDriverEmailHelper;

  /// No description provided for @addDriverErrMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number'**
  String get addDriverErrMobile;

  /// No description provided for @addDriverMobileHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number.'**
  String get addDriverMobileHelper;

  /// No description provided for @addDriverErrLicense.
  ///
  /// In en, this message translates to:
  /// **'Enter license number'**
  String get addDriverErrLicense;

  /// No description provided for @brokerNotificationsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get brokerNotificationsRetry;

  /// No description provided for @brokerNotificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get brokerNotificationsEmptyTitle;

  /// No description provided for @brokerNotificationsGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get brokerNotificationsGenericTitle;

  /// No description provided for @brokerNotificationsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get brokerNotificationsToday;

  /// No description provided for @brokerNotificationsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get brokerNotificationsYesterday;

  /// No description provided for @brokerNotificationsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get brokerNotificationsEarlier;

  /// No description provided for @brokerNotificationsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get brokerNotificationsViewDetails;

  /// No description provided for @brokerNotificationsViewTrip.
  ///
  /// In en, this message translates to:
  /// **'View trip'**
  String get brokerNotificationsViewTrip;

  /// No description provided for @brokerNotificationsOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get brokerNotificationsOpenChat;

  /// No description provided for @clientSavedSearchHintField.
  ///
  /// In en, this message translates to:
  /// **'Search saved addresses...'**
  String get clientSavedSearchHintField;

  /// No description provided for @clientSavedTooltipOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map picker'**
  String get clientSavedTooltipOpenMap;

  /// No description provided for @clientSavedTooltipSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get clientSavedTooltipSetDefault;

  /// No description provided for @clientSavedTooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get clientSavedTooltipEdit;

  /// No description provided for @clientSavedTooltipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get clientSavedTooltipRemove;

  /// No description provided for @clientSavedDropoffTag.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get clientSavedDropoffTag;

  /// No description provided for @clientSavedPickupTag.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get clientSavedPickupTag;

  /// No description provided for @clientSavedErrorLoadOne.
  ///
  /// In en, this message translates to:
  /// **'Could not load this address'**
  String get clientSavedErrorLoadOne;

  /// No description provided for @clientSavedBackToAddresses.
  ///
  /// In en, this message translates to:
  /// **'Back to saved addresses'**
  String get clientSavedBackToAddresses;

  /// No description provided for @clientSavedSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get clientSavedSaveChanges;

  /// No description provided for @clientSavedSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get clientSavedSaveAddress;

  /// No description provided for @clientSavedMapPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Search, tap the map, or drag the pin once it is placed.'**
  String get clientSavedMapPickerHint;

  /// No description provided for @clientSavedCurrentLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get your current location.'**
  String get clientSavedCurrentLocationError;

  /// No description provided for @clientSavedSignInToSave.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to save this address.'**
  String get clientSavedSignInToSave;

  /// No description provided for @clientBookingStepNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get clientBookingStepNext;

  /// No description provided for @clientBookingStepContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get clientBookingStepContinue;

  /// No description provided for @clientBookingChooseTrucks.
  ///
  /// In en, this message translates to:
  /// **'Choose trucks'**
  String get clientBookingChooseTrucks;

  /// No description provided for @clientBookingChooseTrucksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select truck type and search radius'**
  String get clientBookingChooseTrucksSubtitle;

  /// No description provided for @clientBookingCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get clientBookingCancelling;

  /// No description provided for @clientBookingCancelSearch.
  ///
  /// In en, this message translates to:
  /// **'Cancel search'**
  String get clientBookingCancelSearch;

  /// No description provided for @clientBookingEnterLoading.
  ///
  /// In en, this message translates to:
  /// **'Enter loading location'**
  String get clientBookingEnterLoading;

  /// No description provided for @clientBookingEnterUnloading.
  ///
  /// In en, this message translates to:
  /// **'Enter unloading location'**
  String get clientBookingEnterUnloading;

  /// No description provided for @clientBookingConfirmToPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm to pay'**
  String get clientBookingConfirmToPay;

  /// No description provided for @clientBookingConfirmBilling.
  ///
  /// In en, this message translates to:
  /// **'Confirm billing'**
  String get clientBookingConfirmBilling;

  /// No description provided for @clientBookingChoosePayment.
  ///
  /// In en, this message translates to:
  /// **'Choose payment'**
  String get clientBookingChoosePayment;

  /// No description provided for @clientBookingNoDriverInWindow.
  ///
  /// In en, this message translates to:
  /// **'No driver found within the search window'**
  String get clientBookingNoDriverInWindow;

  /// No description provided for @clientBookingBookNowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get clientBookingBookNowTooltip;

  /// No description provided for @checkoutStatusBookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get checkoutStatusBookingConfirmedTitle;

  /// No description provided for @checkoutStatusBookingConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your booking has been successfully placed.'**
  String get checkoutStatusBookingConfirmedMessage;

  /// No description provided for @clientNegotiationRefreshBrokerOfferFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the live broker offer.'**
  String get clientNegotiationRefreshBrokerOfferFailed;

  /// No description provided for @clientNegotiationRefreshRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the live request.'**
  String get clientNegotiationRefreshRequestFailed;

  /// No description provided for @clientNegotiationRefreshDriverOfferFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the live driver offer.'**
  String get clientNegotiationRefreshDriverOfferFailed;

  /// No description provided for @clientTrackingProofLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load delivery proof.'**
  String get clientTrackingProofLoadFailed;

  /// No description provided for @clientTrackingVideoPlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play delivery video.'**
  String get clientTrackingVideoPlayFailed;

  /// No description provided for @clientTrackingCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get clientTrackingCancelTitle;

  /// No description provided for @clientTrackingYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get clientTrackingYesCancel;

  /// No description provided for @clientTrackingChatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this chat.'**
  String get clientTrackingChatLoadFailed;

  /// No description provided for @clientTrackingNegotiationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load negotiation data.'**
  String get clientTrackingNegotiationLoadFailed;

  /// No description provided for @clientTrackingConfirmedDriver.
  ///
  /// In en, this message translates to:
  /// **'Confirmed driver'**
  String get clientTrackingConfirmedDriver;

  /// No description provided for @clientTrackingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get clientTrackingConfirmed;

  /// No description provided for @clientTrackingNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get clientTrackingNoLongerAvailable;

  /// No description provided for @clientBookingRemoveStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove stop'**
  String get clientBookingRemoveStopTooltip;

  /// No description provided for @clientTrackingLiveLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Live location'**
  String get clientTrackingLiveLocationLabel;

  /// No description provided for @clientTrackingLocationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Location pending'**
  String get clientTrackingLocationPendingTitle;

  /// No description provided for @locationFlowSelectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select on map'**
  String get locationFlowSelectOnMap;

  /// No description provided for @brokerFlowVehicleIdleLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get brokerFlowVehicleIdleLocation;

  /// No description provided for @brokerFlowVehicleHeadingTo.
  ///
  /// In en, this message translates to:
  /// **'Heading to'**
  String get brokerFlowVehicleHeadingTo;

  /// No description provided for @brokerFlowVehicleLastKnown.
  ///
  /// In en, this message translates to:
  /// **'Last known'**
  String get brokerFlowVehicleLastKnown;

  /// No description provided for @brokerFlowNoVehicleAssigned.
  ///
  /// In en, this message translates to:
  /// **'No vehicle assigned'**
  String get brokerFlowNoVehicleAssigned;

  /// No description provided for @brokerFlowCtaViewMap.
  ///
  /// In en, this message translates to:
  /// **'View map'**
  String get brokerFlowCtaViewMap;

  /// No description provided for @brokerFlowCtaViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get brokerFlowCtaViewDetails;

  /// No description provided for @brokerFlowLastSeenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get brokerFlowLastSeenUnavailable;

  /// No description provided for @coreDigilockerAadhaarMaskHint.
  ///
  /// In en, this message translates to:
  /// **'XXXX XXXX XXXX'**
  String get coreDigilockerAadhaarMaskHint;

  /// No description provided for @coreDigilockerPanMaskHint.
  ///
  /// In en, this message translates to:
  /// **'ABCDE1234F'**
  String get coreDigilockerPanMaskHint;

  /// No description provided for @coreDigilockerVehicleRegMaskHint.
  ///
  /// In en, this message translates to:
  /// **'MH-2020123456789'**
  String get coreDigilockerVehicleRegMaskHint;

  /// No description provided for @coreDigilockerDateMaskHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get coreDigilockerDateMaskHint;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route unavailable'**
  String get statusRouteUnavailable;

  /// No description provided for @historyDetailsInvoiceDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Invoice downloaded successfully.'**
  String get historyDetailsInvoiceDownloaded;

  /// No description provided for @historyDetailsInvoiceDownloadedBytes.
  ///
  /// In en, this message translates to:
  /// **'Invoice downloaded ({size} bytes).'**
  String historyDetailsInvoiceDownloadedBytes(Object size);

  /// No description provided for @historyDetailsEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Invoice for booking {bookingRef}'**
  String historyDetailsEmailSubject(Object bookingRef);

  /// No description provided for @historyDetailsInvoiceEmailed.
  ///
  /// In en, this message translates to:
  /// **'Invoice emailed successfully.'**
  String get historyDetailsInvoiceEmailed;

  /// No description provided for @historyDetailsClientNotified.
  ///
  /// In en, this message translates to:
  /// **'Client notified successfully.'**
  String get historyDetailsClientNotified;

  /// No description provided for @timePeriodAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get timePeriodAm;

  /// No description provided for @timePeriodPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get timePeriodPm;

  /// No description provided for @addDriverCreateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a driver account'**
  String get addDriverCreateAccountSubtitle;

  /// No description provided for @brokerNotificationsMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String brokerNotificationsMinsAgo(Object minutes);

  /// No description provided for @brokerNotifRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get brokerNotifRetryAction;

  /// No description provided for @brokerNotifEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get brokerNotifEmptySubtitle;

  /// No description provided for @brokerNotifUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String brokerNotifUnreadCount(Object count);

  /// No description provided for @brokerNotifTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notifications'**
  String brokerNotifTotalCount(Object count);

  /// No description provided for @bookingRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'{radius} km'**
  String bookingRadiusKm(Object radius);

  /// No description provided for @bookingBookNowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookingBookNowTooltip;

  /// No description provided for @savedAddressCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load this address'**
  String get savedAddressCouldNotLoad;

  /// No description provided for @savedAddressMapPickerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open map picker'**
  String get savedAddressMapPickerTooltip;

  /// No description provided for @savedAddressSetDefaultTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set default'**
  String get savedAddressSetDefaultTooltip;

  /// No description provided for @savedAddressEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get savedAddressEditTooltip;

  /// No description provided for @savedAddressRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get savedAddressRemoveTooltip;

  /// No description provided for @savedAddressDropoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get savedAddressDropoffLabel;

  /// No description provided for @savedAddressPickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get savedAddressPickupLabel;

  /// No description provided for @trackingAssignedDriver.
  ///
  /// In en, this message translates to:
  /// **'Assigned driver'**
  String get trackingAssignedDriver;

  /// No description provided for @trackingPackageInformation.
  ///
  /// In en, this message translates to:
  /// **'Package information'**
  String get trackingPackageInformation;

  /// No description provided for @trackingDeliveryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Type:'**
  String get trackingDeliveryTypeLabel;

  /// No description provided for @trackingExpressDelivery.
  ///
  /// In en, this message translates to:
  /// **'Express delivery'**
  String get trackingExpressDelivery;

  /// No description provided for @trackingStandardDelivery.
  ///
  /// In en, this message translates to:
  /// **'Standard delivery'**
  String get trackingStandardDelivery;

  /// No description provided for @trackingPackageWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Package weight:'**
  String get trackingPackageWeightLabel;

  /// No description provided for @trackingDriverNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver not assigned'**
  String get trackingDriverNotAssigned;

  /// No description provided for @trackingPickupCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup Code'**
  String get trackingPickupCodeTitle;

  /// No description provided for @trackingPickupVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get trackingPickupVerifiedBadge;

  /// No description provided for @trackingPickupConfirmedText.
  ///
  /// In en, this message translates to:
  /// **'Pickup confirmed with your code.'**
  String get trackingPickupConfirmedText;

  /// No description provided for @trackingPickupCodeShareHint.
  ///
  /// In en, this message translates to:
  /// **'Share this with your driver when they arrive to confirm pickup.'**
  String get trackingPickupCodeShareHint;

  /// No description provided for @trackingLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get trackingLiveBadge;

  /// No description provided for @trackingTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipment Timeline'**
  String get trackingTimelineTitle;

  /// No description provided for @trackingPodTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery'**
  String get trackingPodTitle;

  /// No description provided for @trackingPodApprovalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Does this look right? Approve to let the driver close out the trip, or reject to ask for new photos.'**
  String get trackingPodApprovalPrompt;

  /// No description provided for @trackingPodApproving.
  ///
  /// In en, this message translates to:
  /// **'Approving...'**
  String get trackingPodApproving;

  /// No description provided for @trackingPodApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get trackingPodApprove;

  /// No description provided for @trackingPodApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get trackingPodApproved;

  /// No description provided for @trackingPodRejectionWithReason.
  ///
  /// In en, this message translates to:
  /// **'You asked the driver to re-upload: \"{reason}.\" Waiting for new photos.'**
  String trackingPodRejectionWithReason(Object reason);

  /// No description provided for @trackingPodRejection.
  ///
  /// In en, this message translates to:
  /// **'You asked the driver to re-upload. Waiting for new photos.'**
  String get trackingPodRejection;

  /// No description provided for @trackingPodLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load delivery proof.'**
  String get trackingPodLoadFailed;

  /// No description provided for @trackingPodPlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play delivery video.'**
  String get trackingPodPlayFailed;

  /// No description provided for @bookingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Booking scheduled'**
  String get bookingScheduled;

  /// No description provided for @bookingScheduledNotifyMessage.
  ///
  /// In en, this message translates to:
  /// **'We will notify drivers or brokers closer to your pickup time.'**
  String get bookingScheduledNotifyMessage;

  /// No description provided for @checkoutOpeningActivity.
  ///
  /// In en, this message translates to:
  /// **'Opening activity'**
  String get checkoutOpeningActivity;

  /// No description provided for @checkoutBookLater.
  ///
  /// In en, this message translates to:
  /// **'Book later'**
  String get checkoutBookLater;

  /// No description provided for @checkoutWhereIsYourDrop.
  ///
  /// In en, this message translates to:
  /// **'Where is your Drop ?'**
  String get checkoutWhereIsYourDrop;

  /// No description provided for @weightStepAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get weightStepAddLocation;

  /// No description provided for @weightStepTapToAddDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add details'**
  String get weightStepTapToAddDetails;

  /// No description provided for @deliveryDetailsLoadingPoint.
  ///
  /// In en, this message translates to:
  /// **'Loading Point'**
  String get deliveryDetailsLoadingPoint;

  /// No description provided for @deliveryDetailsUnloadingPoint.
  ///
  /// In en, this message translates to:
  /// **'Unloading Point'**
  String get deliveryDetailsUnloadingPoint;

  /// No description provided for @deliveryDetailsStartTripToPickup.
  ///
  /// In en, this message translates to:
  /// **'Start Trip to Pickup'**
  String get deliveryDetailsStartTripToPickup;

  /// No description provided for @deliveryDetailsReachedPickup.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Reached Pickup'**
  String get deliveryDetailsReachedPickup;

  /// No description provided for @deliveryDetailsStartDelivery.
  ///
  /// In en, this message translates to:
  /// **'Start Delivery'**
  String get deliveryDetailsStartDelivery;

  /// No description provided for @deliveryDetailsMarkAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get deliveryDetailsMarkAsDelivered;

  /// No description provided for @driverKycVerificationCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification Complete'**
  String get driverKycVerificationCompleteTitle;

  /// No description provided for @driverKycSubmittedSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Submitted Successfully'**
  String get driverKycSubmittedSuccessTitle;

  /// No description provided for @driverKycVerifiedBadgeUpper.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get driverKycVerifiedBadgeUpper;

  /// No description provided for @driverKycSubmittedBadgeUpper.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED'**
  String get driverKycSubmittedBadgeUpper;

  /// No description provided for @driverKycVerifiedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your KYC has been verified. Your driver account is now active.'**
  String get driverKycVerifiedDescription;

  /// No description provided for @driverKycSubmittedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your KYC has been successfully submitted. Our verification team will review your documents. This usually takes 24-48 hours.'**
  String get driverKycSubmittedDescription;

  /// No description provided for @vehicleOption3Wheeler.
  ///
  /// In en, this message translates to:
  /// **'3 Wheeler'**
  String get vehicleOption3Wheeler;

  /// No description provided for @vehicleOptionTataAce.
  ///
  /// In en, this message translates to:
  /// **'Tata Ace'**
  String get vehicleOptionTataAce;

  /// No description provided for @vehicleOptionPickup8ft.
  ///
  /// In en, this message translates to:
  /// **'Pickup 8ft'**
  String get vehicleOptionPickup8ft;

  /// No description provided for @vehicleOptionPickup10ft.
  ///
  /// In en, this message translates to:
  /// **'Pickup 10ft'**
  String get vehicleOptionPickup10ft;

  /// No description provided for @vehicleOption14ftTruck.
  ///
  /// In en, this message translates to:
  /// **'14ft Truck'**
  String get vehicleOption14ftTruck;

  /// No description provided for @vehicleOption17ftTruck.
  ///
  /// In en, this message translates to:
  /// **'17ft Truck'**
  String get vehicleOption17ftTruck;

  /// No description provided for @vehicleOption19ftTruck.
  ///
  /// In en, this message translates to:
  /// **'19ft Truck'**
  String get vehicleOption19ftTruck;

  /// No description provided for @vehicleOption22ftTruck.
  ///
  /// In en, this message translates to:
  /// **'22ft Truck'**
  String get vehicleOption22ftTruck;

  /// No description provided for @vehiclePriceShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get vehiclePriceShared;

  /// No description provided for @vehiclePriceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'On request'**
  String get vehiclePriceOnRequest;

  /// No description provided for @vehiclePriceWithToll.
  ///
  /// In en, this message translates to:
  /// **'{baseFare} + toll {toll}'**
  String vehiclePriceWithToll(Object baseFare, Object toll);

  /// No description provided for @pickupOtpVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup verified'**
  String get pickupOtpVerifiedTitle;

  /// No description provided for @pickupOtpCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup code'**
  String get pickupOtpCodeTitle;

  /// No description provided for @pickupOtpVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pickup verified with your code'**
  String get pickupOtpVerifiedMessage;

  /// No description provided for @pickupOtpShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your driver when they arrive to confirm pickup'**
  String get pickupOtpShareMessage;

  /// No description provided for @trackingTimelineBookingCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking created'**
  String get trackingTimelineBookingCreated;

  /// No description provided for @trackingTimelineVehicleAssigned.
  ///
  /// In en, this message translates to:
  /// **'Vehicle assigned'**
  String get trackingTimelineVehicleAssigned;

  /// No description provided for @trackingTimelineDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get trackingTimelineDriverAssigned;

  /// No description provided for @trackingTimelineCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Completed successfully'**
  String get trackingTimelineCompletedSuccessfully;

  /// No description provided for @trackingTimelineWaitingForAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for assignment'**
  String get trackingTimelineWaitingForAssignment;

  /// No description provided for @trackingTimelineBookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking was cancelled'**
  String get trackingTimelineBookingCancelled;

  /// No description provided for @locationArcPickUpFrom.
  ///
  /// In en, this message translates to:
  /// **'Pick up from'**
  String get locationArcPickUpFrom;

  /// No description provided for @packageCardTrackingId.
  ///
  /// In en, this message translates to:
  /// **'#Tracking ID: {trackingId}'**
  String packageCardTrackingId(Object trackingId);

  /// No description provided for @tripTypeChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose trip type'**
  String get tripTypeChooseTitle;

  /// No description provided for @tripTypeFullTruck.
  ///
  /// In en, this message translates to:
  /// **'Full truck'**
  String get tripTypeFullTruck;

  /// No description provided for @tripTypePartTruck.
  ///
  /// In en, this message translates to:
  /// **'Part truck'**
  String get tripTypePartTruck;

  /// No description provided for @tripTypeFullTruckHelper.
  ///
  /// In en, this message translates to:
  /// **'Dedicated truck for one shipment'**
  String get tripTypeFullTruckHelper;

  /// No description provided for @tripTypePartTruckHelper.
  ///
  /// In en, this message translates to:
  /// **'Share capacity and optimize cost'**
  String get tripTypePartTruckHelper;

  /// No description provided for @locationFlowSavedAddress.
  ///
  /// In en, this message translates to:
  /// **'Saved address'**
  String get locationFlowSavedAddress;

  /// No description provided for @locationFlowSetPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Set pickup location'**
  String get locationFlowSetPickupLocation;

  /// No description provided for @locationFlowSetDropLocation.
  ///
  /// In en, this message translates to:
  /// **'Set drop-off location'**
  String get locationFlowSetDropLocation;

  /// No description provided for @locationFlowFindingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding address...'**
  String get locationFlowFindingAddress;

  /// No description provided for @locationFlowUseThisPickup.
  ///
  /// In en, this message translates to:
  /// **'Use this pickup'**
  String get locationFlowUseThisPickup;

  /// No description provided for @locationFlowUseThisDrop.
  ///
  /// In en, this message translates to:
  /// **'Use this drop-off'**
  String get locationFlowUseThisDrop;

  /// No description provided for @clientBookingAvailableTruck.
  ///
  /// In en, this message translates to:
  /// **'Available truck'**
  String get clientBookingAvailableTruck;

  /// No description provided for @clientBookingLocationValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'These pickup/drop locations are not valid for this trip'**
  String get clientBookingLocationValidationFailed;

  /// No description provided for @clientBookingStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get clientBookingStepLocation;

  /// No description provided for @clientBookingStepWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get clientBookingStepWeight;

  /// No description provided for @clientBookingStepPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get clientBookingStepPayment;

  /// No description provided for @clientBookingStepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get clientBookingStepWaiting;

  /// No description provided for @clientBookingFindingBrokers.
  ///
  /// In en, this message translates to:
  /// **'Finding brokers'**
  String get clientBookingFindingBrokers;

  /// No description provided for @clientBookingScanningBrokerOffers.
  ///
  /// In en, this message translates to:
  /// **'Scanning for broker offers on this route.'**
  String get clientBookingScanningBrokerOffers;

  /// No description provided for @clientBookingNegotiateWith.
  ///
  /// In en, this message translates to:
  /// **'Negotiate with {broker}'**
  String clientBookingNegotiateWith(Object broker);

  /// No description provided for @clientBookingChooseTrucksTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Trucks'**
  String get clientBookingChooseTrucksTitle;

  /// No description provided for @clientBookingPickBrokerForRoute.
  ///
  /// In en, this message translates to:
  /// **'Pick a broker for this route'**
  String get clientBookingPickBrokerForRoute;

  /// No description provided for @clientBookingLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get clientBookingLocating;

  /// No description provided for @clientBookingMaterialWeight.
  ///
  /// In en, this message translates to:
  /// **'Material weight'**
  String get clientBookingMaterialWeight;

  /// No description provided for @clientBookingBookLaterAt.
  ///
  /// In en, this message translates to:
  /// **'Book later: {time}'**
  String clientBookingBookLaterAt(Object time);

  /// No description provided for @clientBookingFreeHaltingNote.
  ///
  /// In en, this message translates to:
  /// **'Free halting: {hours}h, then {rate}/hr.'**
  String clientBookingFreeHaltingNote(Object hours, Object rate);

  /// No description provided for @clientBookingFetchingAdvance.
  ///
  /// In en, this message translates to:
  /// **'Fetching advance'**
  String get clientBookingFetchingAdvance;

  /// No description provided for @clientBookingAdvanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Advance unavailable'**
  String get clientBookingAdvanceUnavailable;

  /// No description provided for @clientBookingAdvanceAmountNow.
  ///
  /// In en, this message translates to:
  /// **'{amount} now'**
  String clientBookingAdvanceAmountNow(Object amount);

  /// No description provided for @clientBookingPayAdvance.
  ///
  /// In en, this message translates to:
  /// **'Pay Advance'**
  String get clientBookingPayAdvance;

  /// No description provided for @clientBookingPaySecurely.
  ///
  /// In en, this message translates to:
  /// **'Pay Securely'**
  String get clientBookingPaySecurely;

  /// No description provided for @clientBookingCheckoutMapNote.
  ///
  /// In en, this message translates to:
  /// **'Map stays live while you finish checkout.'**
  String get clientBookingCheckoutMapNote;

  /// No description provided for @clientDeliveryBookingFallback.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get clientDeliveryBookingFallback;

  /// No description provided for @clientDeliveryTruckFallback.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get clientDeliveryTruckFallback;

  /// No description provided for @clientPublicTimelineBookingCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking created'**
  String get clientPublicTimelineBookingCreated;

  /// No description provided for @clientPublicTimelineVehicleAssigned.
  ///
  /// In en, this message translates to:
  /// **'Vehicle assigned'**
  String get clientPublicTimelineVehicleAssigned;

  /// No description provided for @clientPublicTimelineDropLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop-off location'**
  String get clientPublicTimelineDropLocation;

  /// No description provided for @clientPublicTimelineCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Completed successfully'**
  String get clientPublicTimelineCompletedSuccessfully;

  /// No description provided for @clientSavedAddressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated.'**
  String get clientSavedAddressUpdated;

  /// No description provided for @clientSavedAddressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved.'**
  String get clientSavedAddressSaved;

  /// No description provided for @clientSavedLocationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off.'**
  String get clientSavedLocationServicesOff;

  /// No description provided for @clientSavedLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get clientSavedLocationPermissionRequired;

  /// No description provided for @clientSavedLoadErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go back to saved addresses and try editing it again.'**
  String get clientSavedLoadErrorSubtitle;

  /// No description provided for @clientSavedTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get clientSavedTypeLabel;

  /// No description provided for @clientSavedNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get clientSavedNameLabel;

  /// No description provided for @clientSavedAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get clientSavedAddressLabel;

  /// No description provided for @clientSavedCityValue.
  ///
  /// In en, this message translates to:
  /// **'City: {city}'**
  String clientSavedCityValue(Object city);

  /// No description provided for @clientSavedFloorUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor / Unit'**
  String get clientSavedFloorUnitLabel;

  /// No description provided for @clientSavedTapMapForExactSpot.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to choose an exact spot'**
  String get clientSavedTapMapForExactSpot;

  /// No description provided for @clientSavedDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get clientSavedDefaultBadge;

  /// No description provided for @trackingPodFilesPosted.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) posted by driver'**
  String trackingPodFilesPosted(Object count);

  /// No description provided for @trackingDriverPending.
  ///
  /// In en, this message translates to:
  /// **'Driver pending'**
  String get trackingDriverPending;

  /// No description provided for @trackingTruckNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Truck not assigned'**
  String get trackingTruckNotAssigned;

  /// No description provided for @trackingCrewHandoff.
  ///
  /// In en, this message translates to:
  /// **'{from} -> {to}'**
  String trackingCrewHandoff(Object from, Object to);

  /// No description provided for @trackingDriverChangedCount.
  ///
  /// In en, this message translates to:
  /// **'Driver changed ({count})'**
  String trackingDriverChangedCount(Object count);

  /// No description provided for @trackingCancelWhyHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us why — it helps us do better.'**
  String get trackingCancelWhyHint;

  /// No description provided for @trackingKeepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get trackingKeepBooking;

  /// No description provided for @trackingBookingActions.
  ///
  /// In en, this message translates to:
  /// **'Booking actions'**
  String get trackingBookingActions;

  /// No description provided for @trackingBookingChat.
  ///
  /// In en, this message translates to:
  /// **'Booking chat'**
  String get trackingBookingChat;

  /// No description provided for @trackingChatSocketHint.
  ///
  /// In en, this message translates to:
  /// **'Thread updates over REST + Socket.IO'**
  String get trackingChatSocketHint;

  /// No description provided for @trackingChatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get trackingChatNoMessages;

  /// No description provided for @trackingChatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get trackingChatEmptyMessage;

  /// No description provided for @trackingChatRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get trackingChatRead;

  /// No description provided for @trackingChatTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get trackingChatTyping;

  /// No description provided for @trackingChangeDriverFare.
  ///
  /// In en, this message translates to:
  /// **'Change driver fare'**
  String get trackingChangeDriverFare;

  /// No description provided for @trackingCurrentOffer.
  ///
  /// In en, this message translates to:
  /// **'Current offer: {amount}'**
  String trackingCurrentOffer(Object amount);

  /// No description provided for @trackingYourFareChange.
  ///
  /// In en, this message translates to:
  /// **'Your fare change: {amount}'**
  String trackingYourFareChange(Object amount);

  /// No description provided for @trackingNegotiationOffers.
  ///
  /// In en, this message translates to:
  /// **'Negotiation & offers'**
  String get trackingNegotiationOffers;

  /// No description provided for @trackingNegotiationOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Driver requests and broker offers from the client flow.'**
  String get trackingNegotiationOffersSubtitle;

  /// No description provided for @trackingNegotiationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load negotiation data.'**
  String get trackingNegotiationLoadFailed;

  /// No description provided for @trackingBrokerOffer.
  ///
  /// In en, this message translates to:
  /// **'Broker offer'**
  String get trackingBrokerOffer;

  /// No description provided for @trackingBrokerOfferReceived.
  ///
  /// In en, this message translates to:
  /// **'Broker offer received'**
  String get trackingBrokerOfferReceived;

  /// No description provided for @trackingYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get trackingYourTurn;

  /// No description provided for @trackingWaitingBrokerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for broker confirmation'**
  String get trackingWaitingBrokerConfirmation;

  /// No description provided for @trackingWaitingBrokerResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for broker response'**
  String get trackingWaitingBrokerResponse;

  /// No description provided for @trackingWaitingDriverConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver confirmation'**
  String get trackingWaitingDriverConfirmation;

  /// No description provided for @trackingWaitingDriverResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver response'**
  String get trackingWaitingDriverResponse;

  /// No description provided for @trackingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get trackingConfirmed;

  /// No description provided for @trackingDirectTruckRequest.
  ///
  /// In en, this message translates to:
  /// **'Direct truck request'**
  String get trackingDirectTruckRequest;

  /// No description provided for @trackingNegotiationHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'Negotiation history ({count})'**
  String trackingNegotiationHistoryCount(Object count);

  /// No description provided for @brokerFlowDropOffUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Drop-off location unavailable'**
  String get brokerFlowDropOffUnavailable;

  /// No description provided for @brokerFlowTripWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Trip {status}'**
  String brokerFlowTripWithStatus(Object status);

  /// No description provided for @brokerFlowActiveOnTrip.
  ///
  /// In en, this message translates to:
  /// **'Active on trip'**
  String get brokerFlowActiveOnTrip;

  /// No description provided for @brokerFlowActiveOnBooking.
  ///
  /// In en, this message translates to:
  /// **'Active on Booking {bookingRef}'**
  String brokerFlowActiveOnBooking(Object bookingRef);

  /// No description provided for @brokerFlowIdleAwaitingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Idle - Awaiting Assignment'**
  String get brokerFlowIdleAwaitingAssignment;

  /// No description provided for @brokerFlowVehicleIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get brokerFlowVehicleIdle;

  /// No description provided for @brokerFlowOnTrip.
  ///
  /// In en, this message translates to:
  /// **'On Trip'**
  String get brokerFlowOnTrip;

  /// No description provided for @brokerFlowMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get brokerFlowMaintenance;

  /// No description provided for @brokerFlowRecentlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recently completed'**
  String get brokerFlowRecentlyCompleted;

  /// No description provided for @brokerFlowSinceAgo.
  ///
  /// In en, this message translates to:
  /// **'{value} ago'**
  String brokerFlowSinceAgo(Object value);

  /// No description provided for @brokerFlowReassigning.
  ///
  /// In en, this message translates to:
  /// **'Reassigning...'**
  String get brokerFlowReassigning;

  /// No description provided for @brokerActiveJobsNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get brokerActiveJobsNotAssigned;

  /// No description provided for @brokerActiveJobsBreakdownReported.
  ///
  /// In en, this message translates to:
  /// **'Breakdown Reported'**
  String get brokerActiveJobsBreakdownReported;

  /// No description provided for @brokerActiveJobsIssueReported.
  ///
  /// In en, this message translates to:
  /// **'Issue Reported'**
  String get brokerActiveJobsIssueReported;

  /// No description provided for @brokerActiveJobsRouteDistancePending.
  ///
  /// In en, this message translates to:
  /// **'Route distance pending'**
  String get brokerActiveJobsRouteDistancePending;

  /// No description provided for @brokerActiveJobsRouteKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km route'**
  String brokerActiveJobsRouteKm(Object distance);

  /// No description provided for @brokerActiveJobsStepEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get brokerActiveJobsStepEnRoute;

  /// No description provided for @brokerActiveJobsStepPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get brokerActiveJobsStepPickedUp;

  /// No description provided for @brokerActiveJobsStepInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get brokerActiveJobsStepInTransit;

  /// No description provided for @brokerActiveJobsIssueDamagedGoods.
  ///
  /// In en, this message translates to:
  /// **'Damaged Goods'**
  String get brokerActiveJobsIssueDamagedGoods;

  /// No description provided for @brokerActiveJobsIssuePaymentDelay.
  ///
  /// In en, this message translates to:
  /// **'Payment Delay'**
  String get brokerActiveJobsIssuePaymentDelay;

  /// No description provided for @brokerActiveJobsIssueCancellationFee.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Fee'**
  String get brokerActiveJobsIssueCancellationFee;

  /// No description provided for @brokerActiveJobsIssueRouteDispute.
  ///
  /// In en, this message translates to:
  /// **'Route Dispute'**
  String get brokerActiveJobsIssueRouteDispute;

  /// No description provided for @brokerActiveJobsIssueLateDelivery.
  ///
  /// In en, this message translates to:
  /// **'Late Delivery'**
  String get brokerActiveJobsIssueLateDelivery;

  /// No description provided for @brokerActiveJobsIssueFuelSurcharge.
  ///
  /// In en, this message translates to:
  /// **'Fuel Surcharge'**
  String get brokerActiveJobsIssueFuelSurcharge;

  /// No description provided for @brokerActiveJobsIssueWrongItems.
  ///
  /// In en, this message translates to:
  /// **'Wrong Items'**
  String get brokerActiveJobsIssueWrongItems;

  /// No description provided for @brokerActiveJobsIssueWeightDiscrepancy.
  ///
  /// In en, this message translates to:
  /// **'Weight Discrepancy'**
  String get brokerActiveJobsIssueWeightDiscrepancy;

  /// No description provided for @brokerPickupLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Pickup location not available'**
  String get brokerPickupLocationNotAvailable;

  /// No description provided for @brokerDropLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Drop location not available'**
  String get brokerDropLocationNotAvailable;

  /// No description provided for @brokerTruckHistoryNoTripsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No trips match your search'**
  String get brokerTruckHistoryNoTripsMatchSearch;

  /// No description provided for @brokerTruckHistoryDriverPending.
  ///
  /// In en, this message translates to:
  /// **'Driver pending'**
  String get brokerTruckHistoryDriverPending;

  /// No description provided for @brokerTruckHistoryDistancePending.
  ///
  /// In en, this message translates to:
  /// **'Distance pending'**
  String get brokerTruckHistoryDistancePending;

  /// No description provided for @brokerTruckHistoryEarningsPending.
  ///
  /// In en, this message translates to:
  /// **'Earnings pending'**
  String get brokerTruckHistoryEarningsPending;

  /// No description provided for @brokerTrackingAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {plate}'**
  String brokerTrackingAssignedTo(Object plate);

  /// No description provided for @brokerTrackingTimedOutNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Timed-out negotiation'**
  String get brokerTrackingTimedOutNegotiation;

  /// No description provided for @brokerTrackingOpenToContinueNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Open to continue negotiation.'**
  String get brokerTrackingOpenToContinueNegotiation;

  /// No description provided for @brokerTrackingNoDriversYet.
  ///
  /// In en, this message translates to:
  /// **'No drivers yet'**
  String get brokerTrackingNoDriversYet;

  /// No description provided for @brokerTrackingNoDriversMatch.
  ///
  /// In en, this message translates to:
  /// **'No drivers match \"{query}\"'**
  String brokerTrackingNoDriversMatch(Object query);

  /// No description provided for @brokerTrackingCreateDriverFromPlus.
  ///
  /// In en, this message translates to:
  /// **'Create a driver from the + button to start tracking.'**
  String get brokerTrackingCreateDriverFromPlus;

  /// No description provided for @brokerTrackingTryDifferentQuery.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, phone or vehicle number.'**
  String get brokerTrackingTryDifferentQuery;

  /// No description provided for @brokerTrackingNoActiveTripIncidentData.
  ///
  /// In en, this message translates to:
  /// **'No active trip incident data for this driver.'**
  String get brokerTrackingNoActiveTripIncidentData;

  /// No description provided for @brokerTrackingNoIncidentsYet.
  ///
  /// In en, this message translates to:
  /// **'No incidents reported yet.'**
  String get brokerTrackingNoIncidentsYet;

  /// No description provided for @brokerTrackingIncident.
  ///
  /// In en, this message translates to:
  /// **'Incident'**
  String get brokerTrackingIncident;

  /// No description provided for @brokerTrackingDestinationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Destination not available'**
  String get brokerTrackingDestinationNotAvailable;

  /// No description provided for @addTruckAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Truck added successfully.'**
  String get addTruckAddedSuccessfully;

  /// No description provided for @addTruckUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Truck updated successfully.'**
  String get addTruckUpdatedSuccessfully;

  /// No description provided for @addTruckEditTruck.
  ///
  /// In en, this message translates to:
  /// **'Edit Truck'**
  String get addTruckEditTruck;

  /// No description provided for @addTruckAddTruck.
  ///
  /// In en, this message translates to:
  /// **'Add Truck'**
  String get addTruckAddTruck;

  /// No description provided for @addTruckErrRegistrationLooksInvalid.
  ///
  /// In en, this message translates to:
  /// **'Registration looks invalid, e.g. MH-12-AB-1234.'**
  String get addTruckErrRegistrationLooksInvalid;

  /// No description provided for @brokerHomeTheDriver.
  ///
  /// In en, this message translates to:
  /// **'The driver'**
  String get brokerHomeTheDriver;

  /// No description provided for @brokerNotificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get brokerNotificationsMarkAllRead;

  /// No description provided for @brokerNotificationsTabOps.
  ///
  /// In en, this message translates to:
  /// **'Ops'**
  String get brokerNotificationsTabOps;

  /// No description provided for @brokerNotificationsTabSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get brokerNotificationsTabSystem;

  /// No description provided for @brokerNotificationsTabMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get brokerNotificationsTabMoney;

  /// No description provided for @brokerVehiclesRowType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get brokerVehiclesRowType;

  /// No description provided for @brokerVehiclesRowInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get brokerVehiclesRowInsurance;

  /// No description provided for @brokerEarningsAcrossAllSettledTrips.
  ///
  /// In en, this message translates to:
  /// **'Across all settled trips'**
  String get brokerEarningsAcrossAllSettledTrips;

  /// No description provided for @brokerEarningsAcrossAllSettledTripsVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Across all settled trips • vs last month'**
  String get brokerEarningsAcrossAllSettledTripsVsLastMonth;

  /// No description provided for @brokerEarningsFlatVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Flat vs last month — steady performance.'**
  String get brokerEarningsFlatVsLastMonth;

  /// No description provided for @brokerEarningsUpVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Up {change}% vs last month — keep the momentum.'**
  String brokerEarningsUpVsLastMonth(Object change);

  /// No description provided for @brokerEarningsDownVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Down {change}% vs last month.'**
  String brokerEarningsDownVsLastMonth(Object change);

  /// No description provided for @brokerEarningsSettlementPending.
  ///
  /// In en, this message translates to:
  /// **'Settlement pending'**
  String get brokerEarningsSettlementPending;

  /// No description provided for @brokerReqDetailAutoSelectedDriver.
  ///
  /// In en, this message translates to:
  /// **'Auto-selected driver'**
  String get brokerReqDetailAutoSelectedDriver;

  /// No description provided for @brokerReqDetailAutoSelectedTruck.
  ///
  /// In en, this message translates to:
  /// **'Auto-selected truck'**
  String get brokerReqDetailAutoSelectedTruck;

  /// No description provided for @brokerTruckLocationDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String brokerTruckLocationDriverLabel(Object name);

  /// No description provided for @brokerDriverRequestsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted.'**
  String get brokerDriverRequestsAccepted;

  /// No description provided for @brokerDriverRequestsDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined.'**
  String get brokerDriverRequestsDeclined;

  /// No description provided for @brokerDriverRequestsTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get brokerDriverRequestsTimedOut;

  /// No description provided for @driverDetailNotOnTrip.
  ///
  /// In en, this message translates to:
  /// **'Not on trip'**
  String get driverDetailNotOnTrip;

  /// No description provided for @driverDetailAwaitingLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting live location'**
  String get driverDetailAwaitingLiveLocation;

  /// No description provided for @brokerTruckAssignAssigning.
  ///
  /// In en, this message translates to:
  /// **'Assigning...'**
  String get brokerTruckAssignAssigning;

  /// No description provided for @driverTripToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get driverTripToday;

  /// No description provided for @driverEarningsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get driverEarningsRecent;

  /// No description provided for @driverRiderAllTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Trips'**
  String get driverRiderAllTripsTitle;

  /// No description provided for @driverRiderAllTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest activity and completed deliveries'**
  String get driverRiderAllTripsSubtitle;

  /// No description provided for @driverRiderRecentlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recently completed deliveries'**
  String get driverRiderRecentlyCompleted;

  /// No description provided for @driverRiderPendingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Pending deliveries and settlements'**
  String get driverRiderPendingDeliveries;

  /// No description provided for @driverRiderViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get driverRiderViewAll;

  /// No description provided for @driverRiderNoDeliveriesDoneYet.
  ///
  /// In en, this message translates to:
  /// **'No deliveries done yet, start working'**
  String get driverRiderNoDeliveriesDoneYet;

  /// No description provided for @driverRiderNoLatestTripYet.
  ///
  /// In en, this message translates to:
  /// **'No latest trip yet'**
  String get driverRiderNoLatestTripYet;

  /// No description provided for @driverRiderToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get driverRiderToday;

  /// No description provided for @driverRiderYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get driverRiderYesterday;

  /// No description provided for @driverRiderTripCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip} other{{count} trips}}'**
  String driverRiderTripCount(num count);

  /// No description provided for @driverRiderToLabel.
  ///
  /// In en, this message translates to:
  /// **'To:'**
  String get driverRiderToLabel;

  /// No description provided for @driverRiderStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get driverRiderStatusLabel;

  /// No description provided for @driverRiderFromLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'From location unavailable'**
  String get driverRiderFromLocationUnavailable;

  /// No description provided for @driverRiderToLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'To location unavailable'**
  String get driverRiderToLocationUnavailable;

  /// No description provided for @driverRiderLocatingPickup.
  ///
  /// In en, this message translates to:
  /// **'Locating pickup…'**
  String get driverRiderLocatingPickup;

  /// No description provided for @driverRiderLocatingDropoff.
  ///
  /// In en, this message translates to:
  /// **'Locating drop-off…'**
  String get driverRiderLocatingDropoff;

  /// No description provided for @driverRiderViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get driverRiderViewDetails;

  /// No description provided for @driverHomeOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get driverHomeOffline;

  /// No description provided for @driverHomeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get driverHomeOnline;

  /// No description provided for @driverHomeToggleOffline.
  ///
  /// In en, this message translates to:
  /// **'Toggle offline'**
  String get driverHomeToggleOffline;

  /// No description provided for @driverHomeToggleOnline.
  ///
  /// In en, this message translates to:
  /// **'Toggle online'**
  String get driverHomeToggleOnline;

  /// No description provided for @driverHomeCantGoOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t go offline while you have an active trip'**
  String get driverHomeCantGoOffline;

  /// No description provided for @driverHomeCannotGoOfflineSnack.
  ///
  /// In en, this message translates to:
  /// **'You cannot go offline while a trip is active.'**
  String get driverHomeCannotGoOfflineSnack;

  /// No description provided for @driverHomeActiveTripLocksOnline.
  ///
  /// In en, this message translates to:
  /// **'Active trip in progress. Online mode stays locked until the trip is completed.'**
  String get driverHomeActiveTripLocksOnline;

  /// No description provided for @driverHomeMoreRequests.
  ///
  /// In en, this message translates to:
  /// **'More requests'**
  String get driverHomeMoreRequests;

  /// No description provided for @driverHomeDeliveryId.
  ///
  /// In en, this message translates to:
  /// **'Delivery ID'**
  String get driverHomeDeliveryId;

  /// No description provided for @driverHomeBrokerHandoffActive.
  ///
  /// In en, this message translates to:
  /// **'Broker handoff active'**
  String get driverHomeBrokerHandoffActive;

  /// No description provided for @driverHomeClientCountered.
  ///
  /// In en, this message translates to:
  /// **'Client countered. Open the request to respond.'**
  String get driverHomeClientCountered;

  /// No description provided for @driverHomeWaitingForClientResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the client response'**
  String get driverHomeWaitingForClientResponse;

  /// No description provided for @driverHomeClientAccepted.
  ///
  /// In en, this message translates to:
  /// **'Client accepted. Open the request to confirm.'**
  String get driverHomeClientAccepted;

  /// No description provided for @driverHomeWaitingForClientConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client confirmation'**
  String get driverHomeWaitingForClientConfirmation;

  /// No description provided for @driverHomeNegotiationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Negotiation unavailable'**
  String get driverHomeNegotiationUnavailable;

  /// No description provided for @driverHomeClientRequest.
  ///
  /// In en, this message translates to:
  /// **'Client request'**
  String get driverHomeClientRequest;

  /// No description provided for @driverHomeBrokerAssignedNotice.
  ///
  /// In en, this message translates to:
  /// **'Broker-assigned - accept or decline, no negotiation.'**
  String get driverHomeBrokerAssignedNotice;

  /// No description provided for @driverHomeLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'{label} location'**
  String driverHomeLocationFallback(Object label);

  /// No description provided for @driverOrderClientAcceptedRequest.
  ///
  /// In en, this message translates to:
  /// **'Client accepted the request'**
  String get driverOrderClientAcceptedRequest;

  /// No description provided for @driverOrderClientAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'The client accepted your offer. Please confirm to finalize the booking or reject to decline it.'**
  String get driverOrderClientAcceptedBody;

  /// No description provided for @driverOrderBookingSyncing.
  ///
  /// In en, this message translates to:
  /// **'Booking is still syncing.'**
  String get driverOrderBookingSyncing;

  /// No description provided for @driverOrderOpeningTripWhenReady.
  ///
  /// In en, this message translates to:
  /// **'We are opening the active trip view as soon as the trip is ready.'**
  String get driverOrderOpeningTripWhenReady;

  /// No description provided for @driverOrderCheckingApis.
  ///
  /// In en, this message translates to:
  /// **'We check the request, booking, and trip APIs every 5 seconds.'**
  String get driverOrderCheckingApis;

  /// No description provided for @driverOrderCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get driverOrderCheckNow;

  /// No description provided for @driverOrderBookingFinalized.
  ///
  /// In en, this message translates to:
  /// **'Booking finalized'**
  String get driverOrderBookingFinalized;

  /// No description provided for @driverOrderOpeningActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'Opening the active trip view.'**
  String get driverOrderOpeningActiveTrip;

  /// No description provided for @driverOrderYourOffer.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get driverOrderYourOffer;

  /// No description provided for @driverOrderBaseAmount.
  ///
  /// In en, this message translates to:
  /// **'Base {amount}'**
  String driverOrderBaseAmount(Object amount);

  /// No description provided for @driverOrderClientAcceptedYourRequest.
  ///
  /// In en, this message translates to:
  /// **'Client accepted your request'**
  String get driverOrderClientAcceptedYourRequest;

  /// No description provided for @driverOrderConfirmOrDeclinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm or decline from the prompt that appeared above.'**
  String get driverOrderConfirmOrDeclinePrompt;

  /// No description provided for @driverOrderAcceptedWaitingClient.
  ///
  /// In en, this message translates to:
  /// **'Accepted - waiting for the client to confirm.'**
  String get driverOrderAcceptedWaitingClient;

  /// No description provided for @driverOrderRealtimeUpdates.
  ///
  /// In en, this message translates to:
  /// **'We update this in real time.'**
  String get driverOrderRealtimeUpdates;

  /// No description provided for @driverOrderFareChangeSent.
  ///
  /// In en, this message translates to:
  /// **'Fare change sent. Waiting for client response...'**
  String get driverOrderFareChangeSent;

  /// No description provided for @driverOrderUnlockAfterClientAccepts.
  ///
  /// In en, this message translates to:
  /// **'We will unlock the tracking button once the client accepts the offer.'**
  String get driverOrderUnlockAfterClientAccepts;

  /// No description provided for @driverOrderFareChangesUsedUp.
  ///
  /// In en, this message translates to:
  /// **'You have used your fare changes - accept or decline instead.'**
  String get driverOrderFareChangesUsedUp;

  /// No description provided for @driverOrderBrokerTakeover.
  ///
  /// In en, this message translates to:
  /// **'Broker takeover'**
  String get driverOrderBrokerTakeover;

  /// No description provided for @driverOrderLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get driverOrderLocked;

  /// No description provided for @driverOrderAnyMomentNow.
  ///
  /// In en, this message translates to:
  /// **'Any moment now'**
  String get driverOrderAnyMomentNow;

  /// No description provided for @driverOrderHandedOverToBroker.
  ///
  /// In en, this message translates to:
  /// **'Handed over to broker'**
  String get driverOrderHandedOverToBroker;

  /// No description provided for @driverOrderFinalizingTrip.
  ///
  /// In en, this message translates to:
  /// **'Finalizing the trip'**
  String get driverOrderFinalizingTrip;

  /// No description provided for @driverOrderSetYourFareChange.
  ///
  /// In en, this message translates to:
  /// **'Set your fare change'**
  String get driverOrderSetYourFareChange;

  /// No description provided for @driverOrderNegotiatingWithClient.
  ///
  /// In en, this message translates to:
  /// **'Negotiating with the client'**
  String get driverOrderNegotiatingWithClient;

  /// No description provided for @driverOrderHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get driverOrderHandedOver;

  /// No description provided for @driverOrderHandoff.
  ///
  /// In en, this message translates to:
  /// **'Handoff'**
  String get driverOrderHandoff;

  /// No description provided for @driverOrderBrokerAssignedTrip.
  ///
  /// In en, this message translates to:
  /// **'Broker-assigned trip'**
  String get driverOrderBrokerAssignedTrip;

  /// No description provided for @driverOrderAlreadyAgreedWithBroker.
  ///
  /// In en, this message translates to:
  /// **'Already agreed with the broker - accept or decline, no fare changes.'**
  String get driverOrderAlreadyAgreedWithBroker;

  /// No description provided for @driverOrderFixedPrice.
  ///
  /// In en, this message translates to:
  /// **'Fixed price'**
  String get driverOrderFixedPrice;

  /// No description provided for @driverOrderAgreedAmount.
  ///
  /// In en, this message translates to:
  /// **'AGREED AMOUNT'**
  String get driverOrderAgreedAmount;

  /// No description provided for @driverOrderAssignedTripBody.
  ///
  /// In en, this message translates to:
  /// **'This trip was assigned by the broker at the agreed amount. You can decline it if you are not available.'**
  String get driverOrderAssignedTripBody;

  /// No description provided for @driverOrderBrokerControlsRequest.
  ///
  /// In en, this message translates to:
  /// **'Broker controls this request now - waiting for new leads.'**
  String get driverOrderBrokerControlsRequest;

  /// No description provided for @driverOrderBaseOffer.
  ///
  /// In en, this message translates to:
  /// **'BASE OFFER'**
  String get driverOrderBaseOffer;

  /// No description provided for @driverOrderBrokerHandling.
  ///
  /// In en, this message translates to:
  /// **'Broker handling'**
  String get driverOrderBrokerHandling;

  /// No description provided for @driverOrderClientResponded.
  ///
  /// In en, this message translates to:
  /// **'Client responded'**
  String get driverOrderClientResponded;

  /// No description provided for @driverOrderFareWindow.
  ///
  /// In en, this message translates to:
  /// **'Fare window'**
  String get driverOrderFareWindow;

  /// No description provided for @driverOrderAwaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get driverOrderAwaitingResponse;

  /// No description provided for @deliveryDetailsTripStartedHeadingToPickup.
  ///
  /// In en, this message translates to:
  /// **'Trip started. Heading to pickup.'**
  String get deliveryDetailsTripStartedHeadingToPickup;

  /// No description provided for @deliveryDetailsPickupMarkedStartDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pickup marked. Start delivery next.'**
  String get deliveryDetailsPickupMarkedStartDelivery;

  /// No description provided for @deliveryDetailsNowInTransit.
  ///
  /// In en, this message translates to:
  /// **'Delivery is now in transit.'**
  String get deliveryDetailsNowInTransit;

  /// No description provided for @deliveryDetailsMarkedAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivery marked as delivered.'**
  String get deliveryDetailsMarkedAsDelivered;

  /// No description provided for @deliveryDetailsCompleteLoadingStopsFirst.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Complete 1 loading stop first} other{Complete {count} loading stops first}}'**
  String deliveryDetailsCompleteLoadingStopsFirst(num count);

  /// No description provided for @deliveryDetailsCompleteUnloadingStopsFirst.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Complete 1 unloading stop first} other{Complete {count} unloading stops first}}'**
  String deliveryDetailsCompleteUnloadingStopsFirst(num count);

  /// No description provided for @deliveryDetailsOnRoute.
  ///
  /// In en, this message translates to:
  /// **'On route'**
  String get deliveryDetailsOnRoute;

  /// No description provided for @deliveryDetailsActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get deliveryDetailsActiveBadge;

  /// No description provided for @deliveryDetailsUseActionToAdvance.
  ///
  /// In en, this message translates to:
  /// **'Use the action below to advance the trip.'**
  String get deliveryDetailsUseActionToAdvance;

  /// No description provided for @deliveryDetailsCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current status'**
  String get deliveryDetailsCurrentStatus;

  /// No description provided for @deliveryDetailsSyncingTrip.
  ///
  /// In en, this message translates to:
  /// **'Syncing trip...'**
  String get deliveryDetailsSyncingTrip;

  /// No description provided for @deliveryDetailsDecliningEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Declining...'**
  String get deliveryDetailsDecliningEllipsis;

  /// No description provided for @deliveryDetailsTripFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get deliveryDetailsTripFallbackLabel;

  /// No description provided for @deliveryDetailsEmergencyAssistance.
  ///
  /// In en, this message translates to:
  /// **'Emergency Assistance'**
  String get deliveryDetailsEmergencyAssistance;

  /// No description provided for @deliveryDetailsNavigateToPickup.
  ///
  /// In en, this message translates to:
  /// **'Navigate to pickup'**
  String get deliveryDetailsNavigateToPickup;

  /// No description provided for @deliveryDetailsAskCustomerForCode.
  ///
  /// In en, this message translates to:
  /// **'Ask the customer to share their 4-digit code'**
  String get deliveryDetailsAskCustomerForCode;

  /// No description provided for @deliveryDetailsDelayCharge.
  ///
  /// In en, this message translates to:
  /// **'Delivery delay charge'**
  String get deliveryDetailsDelayCharge;

  /// No description provided for @deliveryDetailsSla.
  ///
  /// In en, this message translates to:
  /// **'Delivery SLA'**
  String get deliveryDetailsSla;

  /// No description provided for @deliveryDetailsDelayChargeBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} for {hours}h over the expected delivery time.'**
  String deliveryDetailsDelayChargeBody(Object amount, Object hours);

  /// No description provided for @deliveryDetailsExpectedWithin.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery within ~{hours}h.'**
  String deliveryDetailsExpectedWithin(Object hours);

  /// No description provided for @deliveryDetailsBookingChat.
  ///
  /// In en, this message translates to:
  /// **'Booking chat'**
  String get deliveryDetailsBookingChat;

  /// No description provided for @deliveryDetailsMechanicStatus.
  ///
  /// In en, this message translates to:
  /// **'Mechanic Status'**
  String get deliveryDetailsMechanicStatus;

  /// No description provided for @deliveryDetailsLiveIncidentUpdates.
  ///
  /// In en, this message translates to:
  /// **'Live incident updates for this trip.'**
  String get deliveryDetailsLiveIncidentUpdates;

  /// No description provided for @deliveryDetailsIncident.
  ///
  /// In en, this message translates to:
  /// **'Incident'**
  String get deliveryDetailsIncident;

  /// No description provided for @deliveryDetailsMechanicLine.
  ///
  /// In en, this message translates to:
  /// **'Mechanic: {name}'**
  String deliveryDetailsMechanicLine(Object name);

  /// No description provided for @deliveryDetailsPendingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Pending assignment'**
  String get deliveryDetailsPendingAssignment;

  /// No description provided for @deliveryDetailsPhoneLine.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String deliveryDetailsPhoneLine(Object phone);

  /// No description provided for @deliveryDetailsStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String deliveryDetailsStatusLine(Object status);

  /// No description provided for @deliveryDetailsRequestedLabel.
  ///
  /// In en, this message translates to:
  /// **'requested'**
  String get deliveryDetailsRequestedLabel;

  /// No description provided for @driverKycVerifiedSnack.
  ///
  /// In en, this message translates to:
  /// **'You\'re verified - full access unlocked.'**
  String get driverKycVerifiedSnack;

  /// No description provided for @driverKycSubmittedForReviewSnack.
  ///
  /// In en, this message translates to:
  /// **'KYC submitted for review.'**
  String get driverKycSubmittedForReviewSnack;

  /// No description provided for @driverKycConfirmAccuracyDeclaration.
  ///
  /// In en, this message translates to:
  /// **'I confirm that all the information provided is accurate.'**
  String get driverKycConfirmAccuracyDeclaration;

  /// No description provided for @driverKycVerifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Identity'**
  String get driverKycVerifyIdentity;

  /// No description provided for @driverKycFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get driverKycFinish;

  /// No description provided for @driverKycResubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Resubmit for Review'**
  String get driverKycResubmitForReview;

  /// No description provided for @driverKycDriverKycTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver KYC'**
  String get driverKycDriverKycTitle;

  /// No description provided for @chatCurrentUserSenderName.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatCurrentUserSenderName;

  /// No description provided for @clientNotificationsTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String clientNotificationsTimeMinutesAgo(Object minutes);

  /// No description provided for @clientNotificationsTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String clientNotificationsTimeHoursAgo(Object hours);

  /// No description provided for @clientNotificationsTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String clientNotificationsTimeDaysAgo(Object days);

  /// No description provided for @negotiationYourFare.
  ///
  /// In en, this message translates to:
  /// **'Your fare'**
  String get negotiationYourFare;

  /// No description provided for @negotiationFareChangesExhausted.
  ///
  /// In en, this message translates to:
  /// **'You have used your fare changes — accept or decline instead.'**
  String get negotiationFareChangesExhausted;

  /// No description provided for @negotiationWaitingDriverAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted the request'**
  String get negotiationWaitingDriverAcceptedTitle;

  /// No description provided for @negotiationWaitingDriverTurnToConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted - your turn to confirm'**
  String get negotiationWaitingDriverTurnToConfirmTitle;

  /// No description provided for @negotiationWaitingDriverConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver confirmation'**
  String get negotiationWaitingDriverConfirmationTitle;

  /// No description provided for @negotiationWaitingFareChangeReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare change received'**
  String get negotiationWaitingFareChangeReceivedTitle;

  /// No description provided for @negotiationWaitingDriverResponseTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver response'**
  String get negotiationWaitingDriverResponseTypeTitle;

  /// No description provided for @negotiationWaitingDriverAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'The driver accepted your request. You can confirm the booking and continue to payment.'**
  String get negotiationWaitingDriverAcceptedBody;

  /// No description provided for @negotiationWaitingDriverCommittedBody.
  ///
  /// In en, this message translates to:
  /// **'The driver already committed. Confirm or decline to finish the handshake.'**
  String get negotiationWaitingDriverCommittedBody;

  /// No description provided for @negotiationWaitingDriverYourConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You already confirmed this offer. We are waiting for the driver to confirm now.'**
  String get negotiationWaitingDriverYourConfirmBody;

  /// No description provided for @negotiationWaitingDriverChangedFareBody.
  ///
  /// In en, this message translates to:
  /// **'The driver changed the fare. Review it here and respond instantly.'**
  String get negotiationWaitingDriverChangedFareBody;

  /// No description provided for @negotiationWaitingDriverTimedOutBody.
  ///
  /// In en, this message translates to:
  /// **'The driver did not respond in time. The broker can step in now.'**
  String get negotiationWaitingDriverTimedOutBody;

  /// No description provided for @negotiationWaitingDriverLiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your request is live. We will update this popup as soon as the truck responds.'**
  String get negotiationWaitingDriverLiveBody;

  /// No description provided for @negotiationBookingReference.
  ///
  /// In en, this message translates to:
  /// **'Booking #{bookingNumber}'**
  String negotiationBookingReference(Object bookingNumber);

  /// No description provided for @negotiationLiveUpdatesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Live updates will appear here.'**
  String get negotiationLiveUpdatesAppearHere;

  /// No description provided for @negotiationCurrentAmount.
  ///
  /// In en, this message translates to:
  /// **'Current amount: {amount}'**
  String negotiationCurrentAmount(Object amount);

  /// No description provided for @negotiationHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'Negotiation history ({count})'**
  String negotiationHistoryCount(Object count);

  /// No description provided for @negotiationHistoryEntryOffered.
  ///
  /// In en, this message translates to:
  /// **'{displayBy} offered ₹{amount}'**
  String negotiationHistoryEntryOffered(Object amount, Object displayBy);

  /// No description provided for @negotiationWaitingLiveFareChange.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a live fare change...'**
  String get negotiationWaitingLiveFareChange;

  /// No description provided for @negotiationPickPayment.
  ///
  /// In en, this message translates to:
  /// **'Pick how this freight booking should be settled. Advance uses the latest admin-configured amount.'**
  String get negotiationPickPayment;

  /// No description provided for @negotiationRazorpayCheckoutNote.
  ///
  /// In en, this message translates to:
  /// **'Razorpay checkout will show the available payment methods before you pay.'**
  String get negotiationRazorpayCheckoutNote;

  /// No description provided for @negotiationConfirmPaymentStage.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment stage'**
  String get negotiationConfirmPaymentStage;

  /// No description provided for @negotiationContinueToSecureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Continue to secure checkout'**
  String get negotiationContinueToSecureCheckout;

  /// No description provided for @negotiationWaitingNextDriverUpdate.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the next driver update...'**
  String get negotiationWaitingNextDriverUpdate;

  /// No description provided for @negotiationUseSliderHint.
  ///
  /// In en, this message translates to:
  /// **'Use the slider to set the amount you want to continue with.'**
  String get negotiationUseSliderHint;

  /// No description provided for @negotiationDragToSetPrice.
  ///
  /// In en, this message translates to:
  /// **'Drag to set your price'**
  String get negotiationDragToSetPrice;

  /// No description provided for @brokerSettlementsGrossAmount.
  ///
  /// In en, this message translates to:
  /// **'Gross amount'**
  String get brokerSettlementsGrossAmount;

  /// No description provided for @brokerSettlementsPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform fee'**
  String get brokerSettlementsPlatformFee;

  /// No description provided for @brokerSettlementsRoutePending.
  ///
  /// In en, this message translates to:
  /// **'Route pending'**
  String get brokerSettlementsRoutePending;

  /// No description provided for @brokerTrackLiveStepEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get brokerTrackLiveStepEnRoute;

  /// No description provided for @brokerTrackLiveStepPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get brokerTrackLiveStepPickedUp;

  /// No description provided for @brokerTrackLiveStepInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get brokerTrackLiveStepInTransit;

  /// No description provided for @addDriverSharedSeparately.
  ///
  /// In en, this message translates to:
  /// **'Shared separately'**
  String get addDriverSharedSeparately;

  /// No description provided for @addDriverAadhaarMustBe12Digits.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar must be 12 digits'**
  String get addDriverAadhaarMustBe12Digits;

  /// No description provided for @addDriverUseAValidDate.
  ///
  /// In en, this message translates to:
  /// **'Use a valid date'**
  String get addDriverUseAValidDate;

  /// No description provided for @addDriverLicenseExpiryCannotBeInThePast.
  ///
  /// In en, this message translates to:
  /// **'License expiry cannot be in the past.'**
  String get addDriverLicenseExpiryCannotBeInThePast;

  /// No description provided for @addDriverTapToUpdateTheDriverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to update the driver photo'**
  String get addDriverTapToUpdateTheDriverPhoto;

  /// No description provided for @addDriverTapTheCameraToAddADriverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera to add a driver photo'**
  String get addDriverTapTheCameraToAddADriverPhoto;

  /// No description provided for @addVehicleTruckAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Truck added successfully.'**
  String get addVehicleTruckAddedSuccessfully;

  /// No description provided for @addVehicleTruckUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Truck updated successfully.'**
  String get addVehicleTruckUpdatedSuccessfully;

  /// No description provided for @addVehicleUseYyyyMmdd.
  ///
  /// In en, this message translates to:
  /// **'Use YYYY-MM-DD'**
  String get addVehicleUseYyyyMmdd;

  /// No description provided for @brokerKycInDetails.
  ///
  /// In en, this message translates to:
  /// **'In details'**
  String get brokerKycInDetails;

  /// No description provided for @brokerKycIncludedInDetails.
  ///
  /// In en, this message translates to:
  /// **'Included in details'**
  String get brokerKycIncludedInDetails;

  /// No description provided for @brokerKycSubmittedUrl.
  ///
  /// In en, this message translates to:
  /// **'Submitted URL'**
  String get brokerKycSubmittedUrl;

  /// No description provided for @brokerKycNoActiveSessionFound.
  ///
  /// In en, this message translates to:
  /// **'No active session found.'**
  String get brokerKycNoActiveSessionFound;

  /// No description provided for @brokerKycPleaseConfirmAllInformationIsAccurate.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that all information is accurate.'**
  String get brokerKycPleaseConfirmAllInformationIsAccurate;

  /// No description provided for @brokerKycYouAreVerified.
  ///
  /// In en, this message translates to:
  /// **'You\'re verified - full access unlocked.'**
  String get brokerKycYouAreVerified;

  /// No description provided for @brokerKycSubmittedForReview.
  ///
  /// In en, this message translates to:
  /// **'KYC submitted for review.'**
  String get brokerKycSubmittedForReview;

  /// No description provided for @driverTrackingSignInAgainBeforeEnablingLocation.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again before enabling location sharing.'**
  String get driverTrackingSignInAgainBeforeEnablingLocation;

  /// No description provided for @driverTrackingEnableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Enable location services on the device to share live tracking.'**
  String get driverTrackingEnableLocationServices;

  /// No description provided for @driverTrackingLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for live driver tracking.'**
  String get driverTrackingLocationPermissionRequired;

  /// No description provided for @driverTrackingLocationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Open app settings to enable it.'**
  String get driverTrackingLocationPermissionDeniedForever;

  /// No description provided for @driverTrackingUnableToStartLiveTracking.
  ///
  /// In en, this message translates to:
  /// **'Unable to start live tracking on this device.'**
  String get driverTrackingUnableToStartLiveTracking;

  /// No description provided for @driverTrackingSignInAgainBeforeRefreshingLocation.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again before refreshing location.'**
  String get driverTrackingSignInAgainBeforeRefreshingLocation;

  /// No description provided for @negotiationWindowAnyMomentNow.
  ///
  /// In en, this message translates to:
  /// **'Any moment now - waiting for the server handoff.'**
  String get negotiationWindowAnyMomentNow;

  /// No description provided for @negotiationWindowRemaining.
  ///
  /// In en, this message translates to:
  /// **'{label} {countdown} remaining'**
  String negotiationWindowRemaining(Object countdown, Object label);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
