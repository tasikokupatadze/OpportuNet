import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';

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
    Locale('ka')
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get navAskAi;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @academicCalendar.
  ///
  /// In en, this message translates to:
  /// **'Academic calendar'**
  String get academicCalendar;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile. Check your connection and try again.'**
  String get profileLoadFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Try again.'**
  String get profileSaveFailed;

  /// No description provided for @profileImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the profile picture.'**
  String get profileImageFailed;

  /// No description provided for @notAddedYet.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get notAddedYet;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @aboutMePrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap edit below to add something about yourself.'**
  String get aboutMePrompt;

  /// No description provided for @savedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved posts'**
  String get savedPosts;

  /// No description provided for @openCollection.
  ///
  /// In en, this message translates to:
  /// **'Open collection'**
  String get openCollection;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @leaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Leave account'**
  String get leaveAccount;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish logging out. Check your connection and try again.'**
  String get logoutFailed;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileDetails;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @enterSurname.
  ///
  /// In en, this message translates to:
  /// **'Enter your surname'**
  String get enterSurname;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get enterAge;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @aboutMeHint.
  ///
  /// In en, this message translates to:
  /// **'Tell people something about yourself'**
  String get aboutMeHint;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark mode'**
  String get appearanceSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app\'s language'**
  String get languageSubtitle;

  /// No description provided for @catOlympiads.
  ///
  /// In en, this message translates to:
  /// **'Olympiads'**
  String get catOlympiads;

  /// No description provided for @catVolunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get catVolunteering;

  /// No description provided for @catExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get catExchange;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get sortDeadline;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get sortTitle;

  /// No description provided for @sortFreeFirst.
  ///
  /// In en, this message translates to:
  /// **'Free first'**
  String get sortFreeFirst;

  /// No description provided for @loadOpportunitiesFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load opportunities. Check your connection and try again.'**
  String get loadOpportunitiesFailed;

  /// No description provided for @searchOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Search opportunities'**
  String get searchOpportunities;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filtersAndLayout.
  ///
  /// In en, this message translates to:
  /// **'Filters and layout'**
  String get filtersAndLayout;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @opportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get opportunities;

  /// No description provided for @addOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Add opportunity'**
  String get addOpportunity;

  /// No description provided for @sortOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Sort opportunities'**
  String get sortOpportunities;

  /// No description provided for @roadmaps.
  ///
  /// In en, this message translates to:
  /// **'Roadmaps'**
  String get roadmaps;

  /// No description provided for @schoolsInGeorgia.
  ///
  /// In en, this message translates to:
  /// **'Schools in Georgia'**
  String get schoolsInGeorgia;

  /// No description provided for @nothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your filters'**
  String get nothingMatches;

  /// No description provided for @noOpportunitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No opportunities yet'**
  String get noOpportunitiesYet;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @autoGrid.
  ///
  /// In en, this message translates to:
  /// **'Auto grid'**
  String get autoGrid;

  /// No description provided for @singleColumn.
  ///
  /// In en, this message translates to:
  /// **'Single column'**
  String get singleColumn;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @olympiadSubject.
  ///
  /// In en, this message translates to:
  /// **'Olympiad subject'**
  String get olympiadSubject;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @costAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get costAny;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @myAge.
  ///
  /// In en, this message translates to:
  /// **'My age'**
  String get myAge;

  /// No description provided for @anyAge.
  ///
  /// In en, this message translates to:
  /// **'Any age'**
  String get anyAge;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @costNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Cost not specified'**
  String get costNotSpecified;

  /// No description provided for @untitledOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Untitled opportunity'**
  String get untitledOpportunity;

  /// No description provided for @closesToday.
  ///
  /// In en, this message translates to:
  /// **'Closes today'**
  String get closesToday;

  /// No description provided for @closesTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Closes tomorrow'**
  String get closesTomorrow;

  /// No description provided for @subjectMaths.
  ///
  /// In en, this message translates to:
  /// **'Maths'**
  String get subjectMaths;

  /// No description provided for @subjectPhysics.
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get subjectPhysics;

  /// No description provided for @subjectChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get subjectChemistry;

  /// No description provided for @subjectBiology.
  ///
  /// In en, this message translates to:
  /// **'Biology'**
  String get subjectBiology;

  /// No description provided for @subjectRobotics.
  ///
  /// In en, this message translates to:
  /// **'Robotics'**
  String get subjectRobotics;

  /// No description provided for @subjectInformatics.
  ///
  /// In en, this message translates to:
  /// **'Informatics'**
  String get subjectInformatics;

  /// No description provided for @subjectProgramming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get subjectProgramming;

  /// No description provided for @subjectAstrophysics.
  ///
  /// In en, this message translates to:
  /// **'Astrophysics'**
  String get subjectAstrophysics;

  /// No description provided for @subjectLinguistics.
  ///
  /// In en, this message translates to:
  /// **'Linguistics'**
  String get subjectLinguistics;

  /// No description provided for @subjectEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get subjectEnglish;

  /// No description provided for @subjectEconomics.
  ///
  /// In en, this message translates to:
  /// **'Economics'**
  String get subjectEconomics;

  /// No description provided for @subjectOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get subjectOther;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get deleteChatTitle;

  /// No description provided for @deleteChatBody.
  ///
  /// In en, this message translates to:
  /// **'Its messages will be removed. This can\'t be undone.'**
  String get deleteChatBody;

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatDeleted;

  /// No description provided for @chatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the chat. Try again.'**
  String get chatDeleteFailed;

  /// No description provided for @loadMessagesFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your messages. Check your connection and try again.'**
  String get loadMessagesFailed;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get chatHistory;

  /// No description provided for @deleteThisChat.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat'**
  String get deleteThisChat;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @askSomething.
  ///
  /// In en, this message translates to:
  /// **'Ask something…'**
  String get askSomething;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @recentChats.
  ///
  /// In en, this message translates to:
  /// **'Recent chats'**
  String get recentChats;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your chats will show up here.'**
  String get chatsEmpty;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteChat;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinking;

  /// No description provided for @noAnswer.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get an answer. Check your connection and ask again.'**
  String get noAnswer;

  /// No description provided for @starterSummer.
  ///
  /// In en, this message translates to:
  /// **'Which summer programs should I apply to this year?'**
  String get starterSummer;

  /// No description provided for @starterScholarships.
  ///
  /// In en, this message translates to:
  /// **'Which scholarships cover full tuition abroad?'**
  String get starterScholarships;

  /// No description provided for @starterSat.
  ///
  /// In en, this message translates to:
  /// **'How do I prepare for the SAT from Georgia?'**
  String get starterSat;

  /// No description provided for @aiEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about studying abroad'**
  String get aiEmptyTitle;

  /// No description provided for @aiEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Deadlines, essays, scholarships, tests.'**
  String get aiEmptyBody;

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

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields.'**
  String get fillAllFields;

  /// No description provided for @verifyEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before logging in.'**
  String get verifyEmailFirst;

  /// No description provided for @wrongEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get wrongEmailOrPassword;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get invalidEmail;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyAttempts;

  /// No description provided for @emailLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please log in using your email and password first.'**
  String get emailLoginFirst;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @linkGoogleNeedsEmail.
  ///
  /// In en, this message translates to:
  /// **'Log in with email/password first to link Google.'**
  String get linkGoogleNeedsEmail;

  /// No description provided for @googleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get googleCancelled;

  /// No description provided for @googleCouldNotFinish.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in could not finish. Please try again.'**
  String get googleCouldNotFinish;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @agreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreePrefix;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 8 characters, one letter and one number.'**
  String get passwordRule;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDontMatch;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and privacy policy.'**
  String get mustAcceptTerms;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to your email address. Please verify your email before logging in.'**
  String get verifyEmailBody;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailInUse;

  /// No description provided for @strongerPassword.
  ///
  /// In en, this message translates to:
  /// **'Please choose a stronger password.'**
  String get strongerPassword;

  /// No description provided for @accountPartlyCreated.
  ///
  /// In en, this message translates to:
  /// **'Your account could not be fully created. Please try again.'**
  String get accountPartlyCreated;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccount;

  /// No description provided for @opportunityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 opportunity} other{{count} opportunities}}'**
  String opportunityCount(int count);

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String yearsOld(int age);

  /// No description provided for @deadlineClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed · {date}'**
  String deadlineClosed(String date);

  /// No description provided for @closesInDays.
  ///
  /// In en, this message translates to:
  /// **'Closes in {days} days · {date}'**
  String closesInDays(int days, String date);

  /// No description provided for @deadlineOn.
  ///
  /// In en, this message translates to:
  /// **'Deadline · {date}'**
  String deadlineOn(String date);

  /// No description provided for @googleCouldNotFinishCode.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in could not finish ({code}). Please try again.'**
  String googleCouldNotFinishCode(String code);

  /// No description provided for @googleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed ({code}): {details}'**
  String googleFailed(String code, String details);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;
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
      <String>['en', 'ka'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ka':
      return AppLocalizationsKa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
