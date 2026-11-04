import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KovaiWorks'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Connecting Work with Opportunity'**
  String get tagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Please select your role'**
  String get chooseRole;

  /// No description provided for @iAmWorker.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Worker'**
  String get iAmWorker;

  /// No description provided for @iAmWorkerDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover daily wage opportunities near you'**
  String get iAmWorkerDesc;

  /// No description provided for @iAmOwner.
  ///
  /// In en, this message translates to:
  /// **'I\'m an Employer'**
  String get iAmOwner;

  /// No description provided for @iAmOwnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Hire verified workers for your mill, factory or event requirements'**
  String get iAmOwnerDesc;

  /// No description provided for @onb1Title.
  ///
  /// In en, this message translates to:
  /// **'Find Work Near You'**
  String get onb1Title;

  /// No description provided for @onb1Desc.
  ///
  /// In en, this message translates to:
  /// **'Discover daily job opportunities in Gandhipuram, Peelamedu, Sulur and nearby areas'**
  String get onb1Desc;

  /// No description provided for @onb2Title.
  ///
  /// In en, this message translates to:
  /// **'Verified Workers'**
  String get onb2Title;

  /// No description provided for @onb2Desc.
  ///
  /// In en, this message translates to:
  /// **'Connect with Aadhaar-verified workers and review their ratings'**
  String get onb2Desc;

  /// No description provided for @onb3Title.
  ///
  /// In en, this message translates to:
  /// **'Timely Payments'**
  String get onb3Title;

  /// No description provided for @onb3Desc.
  ///
  /// In en, this message translates to:
  /// **'Receive your daily wages directly through UPI without intermediaries'**
  String get onb3Desc;

  /// No description provided for @emptyJobs.
  ///
  /// In en, this message translates to:
  /// **'No job opportunities are currently available. Please check again later.'**
  String get emptyJobs;

  /// No description provided for @emptyWorkers.
  ///
  /// In en, this message translates to:
  /// **'No workers are currently available in this area. Please try again later.'**
  String get emptyWorkers;

  /// No description provided for @emptyEvents.
  ///
  /// In en, this message translates to:
  /// **'No events are currently scheduled.'**
  String get emptyEvents;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login with Your Mobile Number'**
  String get loginTitle;

  /// No description provided for @loginDesc.
  ///
  /// In en, this message translates to:
  /// **'We will send a 6-digit OTP to your registered mobile number'**
  String get loginDesc;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get phoneLabel;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP has been sent to'**
  String get otpSentTo;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verify;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number.'**
  String get invalidPhone;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit OTP.'**
  String get invalidOtp;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Mobile Number'**
  String get changeNumber;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @workerHome.
  ///
  /// In en, this message translates to:
  /// **'Worker Dashboard'**
  String get workerHome;

  /// No description provided for @ownerHome.
  ///
  /// In en, this message translates to:
  /// **'Employer Dashboard'**
  String get ownerHome;

  /// No description provided for @profileSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get profileSetup;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @selectSkills.
  ///
  /// In en, this message translates to:
  /// **'Please Select Your Skills'**
  String get selectSkills;

  /// No description provided for @industrialSkills.
  ///
  /// In en, this message translates to:
  /// **'Industrial Skills'**
  String get industrialSkills;

  /// No description provided for @eventSkills.
  ///
  /// In en, this message translates to:
  /// **'Event Services'**
  String get eventSkills;

  /// No description provided for @selectArea.
  ///
  /// In en, this message translates to:
  /// **'Select Your Location'**
  String get selectArea;

  /// No description provided for @aadhaarLast4.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number (Last 4 Digits)'**
  String get aadhaarLast4;

  /// No description provided for @aadhaarNote.
  ///
  /// In en, this message translates to:
  /// **'Your verified badge will be activated after manual verification.'**
  String get aadhaarNote;

  /// No description provided for @saveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and Continue'**
  String get saveContinue;

  /// No description provided for @employerSetup.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Business Profile'**
  String get employerSetup;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Mill / Factory / Event Business Name'**
  String get businessName;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get required;

  /// No description provided for @pickSkill.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one skill.'**
  String get pickSkill;

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

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get tamil;

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get postJob;

  /// No description provided for @jobCategory.
  ///
  /// In en, this message translates to:
  /// **'Job Category'**
  String get jobCategory;

  /// No description provided for @industrial.
  ///
  /// In en, this message translates to:
  /// **'Industrial'**
  String get industrial;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @skillNeeded.
  ///
  /// In en, this message translates to:
  /// **'Required Skill'**
  String get skillNeeded;

  /// No description provided for @workersNeeded.
  ///
  /// In en, this message translates to:
  /// **'Number of Workers Required'**
  String get workersNeeded;

  /// No description provided for @wagePerDay.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage (₹)'**
  String get wagePerDay;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventType;

  /// No description provided for @eventDate.
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get eventDate;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get pickDate;

  /// No description provided for @postNow.
  ///
  /// In en, this message translates to:
  /// **'Publish Job'**
  String get postNow;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Job Listings'**
  String get myJobs;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get busy;

  /// No description provided for @youAre.
  ///
  /// In en, this message translates to:
  /// **'Your Current Status'**
  String get youAre;

  /// No description provided for @openJobs.
  ///
  /// In en, this message translates to:
  /// **'Available Job Opportunities Near You'**
  String get openJobs;

  /// No description provided for @workersLabel.
  ///
  /// In en, this message translates to:
  /// **'workers'**
  String get workersLabel;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get perDay;

  /// No description provided for @nearbyWorkers.
  ///
  /// In en, this message translates to:
  /// **'Available Workers Nearby'**
  String get nearbyWorkers;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share My Location'**
  String get shareLocation;

  /// No description provided for @locationOn.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is enabled.'**
  String get locationOn;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. Please enable location access in your device settings.'**
  String get locationDenied;

  /// No description provided for @noWorkersNearby.
  ///
  /// In en, this message translates to:
  /// **'No workers are currently available nearby. Please check again later.'**
  String get noWorkersNearby;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'km away'**
  String get distanceKm;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Job Request'**
  String get sendRequest;

  /// No description provided for @selectJob.
  ///
  /// In en, this message translates to:
  /// **'Select a Job'**
  String get selectJob;

  /// No description provided for @noOpenJobs.
  ///
  /// In en, this message translates to:
  /// **'There are currently no open jobs. Please post a job to get started.'**
  String get noOpenJobs;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent successfully.'**
  String get requestSent;

  /// No description provided for @jobRequests.
  ///
  /// In en, this message translates to:
  /// **'Job Requests'**
  String get jobRequests;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept Request'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Decline Request'**
  String get reject;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get rejected;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'You have no pending requests at the moment.'**
  String get noRequests;

  /// No description provided for @trackWorker.
  ///
  /// In en, this message translates to:
  /// **'Track Worker'**
  String get trackWorker;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Job Requests'**
  String get myRequests;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message here'**
  String get typeMessage;

  /// No description provided for @completePay.
  ///
  /// In en, this message translates to:
  /// **'Complete Job and Pay'**
  String get completePay;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Payment Completed'**
  String get paid;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @rateWorker.
  ///
  /// In en, this message translates to:
  /// **'Rate the Worker'**
  String get rateWorker;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @myWork.
  ///
  /// In en, this message translates to:
  /// **'My Work History'**
  String get myWork;

  /// No description provided for @noWork.
  ///
  /// In en, this message translates to:
  /// **'You have no work history yet.'**
  String get noWork;

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get bill;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRating;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Profile Photo'**
  String get removePhoto;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @aboutHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 5 years of experience in a spinning mill, punctual and hardworking.'**
  String get aboutHint;

  /// No description provided for @experienceYears.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get experienceYears;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been updated successfully.'**
  String get profileSaved;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadge;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get notVerified;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get avgRating;

  /// No description provided for @jobsDone.
  ///
  /// In en, this message translates to:
  /// **'Jobs Completed'**
  String get jobsDone;

  /// No description provided for @phoneLabelRo.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number (Cannot Be Changed)'**
  String get phoneLabelRo;

  /// No description provided for @ownerProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get ownerProfile;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Category'**
  String get businessType;

  /// No description provided for @typeMill.
  ///
  /// In en, this message translates to:
  /// **'Textile Mill'**
  String get typeMill;

  /// No description provided for @typeFoundry.
  ///
  /// In en, this message translates to:
  /// **'Foundry / Workshop'**
  String get typeFoundry;

  /// No description provided for @typeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event Organiser'**
  String get typeEvent;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Business Address / Landmark'**
  String get address;

  /// No description provided for @aboutBusiness.
  ///
  /// In en, this message translates to:
  /// **'About Your Business'**
  String get aboutBusiness;

  /// No description provided for @aboutBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'Example: A spinning mill with 20 years of experience located near Peelamedu, employing 100 workers.'**
  String get aboutBusinessHint;

  /// No description provided for @jobsPosted.
  ///
  /// In en, this message translates to:
  /// **'Jobs Posted'**
  String get jobsPosted;

  /// No description provided for @workersHired.
  ///
  /// In en, this message translates to:
  /// **'Workers Hired'**
  String get workersHired;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Update Business Logo'**
  String get changeLogo;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifRequest.
  ///
  /// In en, this message translates to:
  /// **'You have received a new job request.'**
  String get notifRequest;

  /// No description provided for @notifAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your job request has been accepted.'**
  String get notifAccepted;

  /// No description provided for @notifRejected.
  ///
  /// In en, this message translates to:
  /// **'Your job request has been declined.'**
  String get notifRejected;

  /// No description provided for @notifPaid.
  ///
  /// In en, this message translates to:
  /// **'Your payment has been received.'**
  String get notifPaid;

  /// No description provided for @noNotifs.
  ///
  /// In en, this message translates to:
  /// **'You have no new notifications.'**
  String get noNotifs;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view;

  /// No description provided for @heroSub.
  ///
  /// In en, this message translates to:
  /// **'Hire verified daily wage workers across Coimbatore quickly and conveniently, without intermediaries.'**
  String get heroSub;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @how1.
  ///
  /// In en, this message translates to:
  /// **'Register using your mobile number.'**
  String get how1;

  /// No description provided for @how2.
  ///
  /// In en, this message translates to:
  /// **'Post a job or accept a job request.'**
  String get how2;

  /// No description provided for @how3.
  ///
  /// In en, this message translates to:
  /// **'Complete the work, receive payment and share feedback.'**
  String get how3;

  /// No description provided for @madeInKovai.
  ///
  /// In en, this message translates to:
  /// **'Proudly Made in Kovai'**
  String get madeInKovai;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo Number'**
  String get demoHint;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in'**
  String get resendIn;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resend;

  /// No description provided for @wrongOtp.
  ///
  /// In en, this message translates to:
  /// **'The OTP entered is incorrect. Please try again.'**
  String get wrongOtp;

  /// No description provided for @welcomeWorker.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KovaiWorks!'**
  String get welcomeWorker;

  /// No description provided for @welcomeEmployer.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KovaiWorks!'**
  String get welcomeEmployer;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get offline;

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Start a Conversation'**
  String get sayHi;

  /// No description provided for @totalPerDay.
  ///
  /// In en, this message translates to:
  /// **'Total Daily Wage'**
  String get totalPerDay;

  /// No description provided for @stepRequested.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get stepRequested;

  /// No description provided for @findWorkers.
  ///
  /// In en, this message translates to:
  /// **'Find Workers'**
  String get findWorkers;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
