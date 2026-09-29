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
