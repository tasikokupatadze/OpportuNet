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

  /// No description provided for @catMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get catMath;

  /// No description provided for @catCoding.
  ///
  /// In en, this message translates to:
  /// **'Coding'**
  String get catCoding;

  /// No description provided for @catArts.
  ///
  /// In en, this message translates to:
  /// **'Arts'**
  String get catArts;

  /// No description provided for @catLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get catLanguages;

  /// No description provided for @catCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get catCareer;

  /// No description provided for @catGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get catGeneral;

  /// No description provided for @loadPostsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load posts. Check your connection and try again.'**
  String get loadPostsFailed;

  /// No description provided for @noMatchingPosts.
  ///
  /// In en, this message translates to:
  /// **'No matching posts'**
  String get noMatchingPosts;

  /// No description provided for @noSavedPostsHere.
  ///
  /// In en, this message translates to:
  /// **'No saved posts here'**
  String get noSavedPostsHere;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or category.'**
  String get tryDifferentSearch;

  /// No description provided for @saveWithBookmark.
  ///
  /// In en, this message translates to:
  /// **'Save posts with the bookmark button, or choose All.'**
  String get saveWithBookmark;

  /// No description provided for @beFirst.
  ///
  /// In en, this message translates to:
  /// **'Be the first to start a conversation.'**
  String get beFirst;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPost;

  /// No description provided for @searchPostsOrPeople.
  ///
  /// In en, this message translates to:
  /// **'Search posts or people'**
  String get searchPostsOrPeople;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sortPopular;

  /// No description provided for @invalidUserProfile.
  ///
  /// In en, this message translates to:
  /// **'This post doesn\'t have a valid user profile.'**
  String get invalidUserProfile;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get deletePostTitle;

  /// No description provided for @deletePostBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this post?'**
  String get deletePostBody;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @postDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the post. Try again.'**
  String get postDeleteFailed;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @removedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved posts'**
  String get removedFromSaved;

  /// No description provided for @savedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedConfirm;

  /// No description provided for @agoNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get agoNow;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get seeLess;

  /// No description provided for @commentAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add your comment. Try again.'**
  String get commentAddFailed;

  /// No description provided for @editComment.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get editComment;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write your comment...'**
  String get writeComment;

  /// No description provided for @commentEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t edit your comment. Try again.'**
  String get commentEditFailed;

  /// No description provided for @deleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get deleteCommentTitle;

  /// No description provided for @deleteCommentBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get deleteCommentBody;

  /// No description provided for @commentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your comment. Try again.'**
  String get commentDeleteFailed;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @loadCommentsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load comments.'**
  String get loadCommentsFailed;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addComment;

  /// No description provided for @sendComment.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get sendComment;

  /// No description provided for @writeSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Write something before posting'**
  String get writeSomethingFirst;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be found. Please log out and log in again.'**
  String get profileNotFound;

  /// No description provided for @postFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish your post. Try again.'**
  String get postFailed;

  /// No description provided for @shareSomething.
  ///
  /// In en, this message translates to:
  /// **'Share something'**
  String get shareSomething;

  /// No description provided for @postCategory.
  ///
  /// In en, this message translates to:
  /// **'Post category'**
  String get postCategory;

  /// No description provided for @writeSomething.
  ///
  /// In en, this message translates to:
  /// **'Write something...'**
  String get writeSomething;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @loadSavedFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load saved posts.'**
  String get loadSavedFailed;

  /// No description provided for @noSavedPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet. Tap the bookmark on a post to save it.'**
  String get noSavedPostsYet;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get userProfile;

  /// No description provided for @communityMember.
  ///
  /// In en, this message translates to:
  /// **'Community member'**
  String get communityMember;

  /// No description provided for @notAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notAdded;

  /// No description provided for @noAboutSection.
  ///
  /// In en, this message translates to:
  /// **'This user has not added an about section yet.'**
  String get noAboutSection;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @ageRequirements.
  ///
  /// In en, this message translates to:
  /// **'Age requirements'**
  String get ageRequirements;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit website'**
  String get visitWebsite;

  /// No description provided for @requiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get requiredFields;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Please select an image.'**
  String get selectImage;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed.'**
  String get imageUploadFailed;

  /// No description provided for @activityPublished.
  ///
  /// In en, this message translates to:
  /// **'Opportunity published'**
  String get activityPublished;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish. Try again.'**
  String get publishFailed;

  /// No description provided for @fillWithAi.
  ///
  /// In en, this message translates to:
  /// **'Fill with AI'**
  String get fillWithAi;

  /// No description provided for @pastePostHere.
  ///
  /// In en, this message translates to:
  /// **'Paste the post\'s text here'**
  String get pastePostHere;

  /// No description provided for @fillForm.
  ///
  /// In en, this message translates to:
  /// **'Fill form'**
  String get fillForm;

  /// No description provided for @couldntReadPost.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that post. Try again or fill it in yourself.'**
  String get couldntReadPost;

  /// No description provided for @formFilled.
  ///
  /// In en, this message translates to:
  /// **'Form filled. Check every field against the post before publishing.'**
  String get formFilled;

  /// No description provided for @addActivityImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addActivityImage;

  /// No description provided for @readingPost.
  ///
  /// In en, this message translates to:
  /// **'Reading the post…'**
  String get readingPost;

  /// No description provided for @fillWithAiFromPost.
  ///
  /// In en, this message translates to:
  /// **'Fill with AI from a post'**
  String get fillWithAiFromPost;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get activityTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @selectSubjects.
  ///
  /// In en, this message translates to:
  /// **'Select subjects'**
  String get selectSubjects;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @chooseSubjects.
  ///
  /// In en, this message translates to:
  /// **'Choose subjects'**
  String get chooseSubjects;

  /// No description provided for @deadlineOptional.
  ///
  /// In en, this message translates to:
  /// **'Deadline (optional)'**
  String get deadlineOptional;

  /// No description provided for @removeDeadline.
  ///
  /// In en, this message translates to:
  /// **'Remove deadline'**
  String get removeDeadline;

  /// No description provided for @noDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadline;

  /// No description provided for @publishActivity.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishActivity;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get eventTitle;

  /// No description provided for @enterEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter an event title'**
  String get enterEventTitle;

  /// No description provided for @evCompetitions.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get evCompetitions;

  /// No description provided for @evTests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get evTests;

  /// No description provided for @evDecisions.
  ///
  /// In en, this message translates to:
  /// **'Decisions'**
  String get evDecisions;

  /// No description provided for @addEventFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add the event. Please try again.'**
  String get addEventFailed;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @loadCalendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load calendar events.'**
  String get loadCalendarFailed;

  /// No description provided for @noEventsToday.
  ///
  /// In en, this message translates to:
  /// **'No events for this day'**
  String get noEventsToday;

  /// No description provided for @grade9.
  ///
  /// In en, this message translates to:
  /// **'9th'**
  String get grade9;

  /// No description provided for @grade10.
  ///
  /// In en, this message translates to:
  /// **'10th'**
  String get grade10;

  /// No description provided for @grade11.
  ///
  /// In en, this message translates to:
  /// **'11th'**
  String get grade11;

  /// No description provided for @grade12.
  ///
  /// In en, this message translates to:
  /// **'12th'**
  String get grade12;

  /// No description provided for @privateSchools.
  ///
  /// In en, this message translates to:
  /// **'Private schools'**
  String get privateSchools;

  /// No description provided for @publicSchools.
  ///
  /// In en, this message translates to:
  /// **'Public schools'**
  String get publicSchools;

  /// No description provided for @summer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get summer;

  /// No description provided for @couldntOpenSchool.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this school\'s website. Please try again.'**
  String get couldntOpenSchool;

  /// No description provided for @notificationCantOpen.
  ///
  /// In en, this message translates to:
  /// **'This notification cannot be opened.'**
  String get notificationCantOpen;

  /// No description provided for @markReadFailedView.
  ///
  /// In en, this message translates to:
  /// **'Could not mark this notification as read. You can still view the update.'**
  String get markReadFailedView;

  /// No description provided for @eventUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This calendar event is no longer available.'**
  String get eventUnavailable;

  /// No description provided for @eventOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this event. Check your connection and try again.'**
  String get eventOpenFailed;

  /// No description provided for @markAllReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark notifications as read. Please try again.'**
  String get markAllReadFailed;

  /// No description provided for @newUpdate.
  ///
  /// In en, this message translates to:
  /// **'New update'**
  String get newUpdate;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnection;

  /// No description provided for @loadPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this post.'**
  String get loadPostFailed;

  /// No description provided for @postUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get postUnavailable;

  /// No description provided for @latestUpdates.
  ///
  /// In en, this message translates to:
  /// **'Latest updates'**
  String get latestUpdates;

  /// No description provided for @markingRead.
  ///
  /// In en, this message translates to:
  /// **'Marking as read…'**
  String get markingRead;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @updatesWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your updates are waiting'**
  String get updatesWaiting;

  /// No description provided for @signInForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see new posts and academic calendar updates.'**
  String get signInForUpdates;

  /// No description provided for @updatesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your updates'**
  String get updatesLoadFailed;

  /// No description provided for @gettingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Getting your updates'**
  String get gettingUpdates;

  /// No description provided for @notificationsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your latest notifications will appear here.'**
  String get notificationsAppearHere;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New posts and calendar events will appear here. Check back soon.'**
  String get notificationsEmptyBody;

  /// No description provided for @showingRecent.
  ///
  /// In en, this message translates to:
  /// **'Showing recent notifications'**
  String get showingRecent;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New posts and academic calendar updates, all in one place.'**
  String get notificationsSubtitle;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone and browser alerts'**
  String get alertsTitle;

  /// No description provided for @alertsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled on this device'**
  String get alertsEnabled;

  /// No description provided for @stayUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Stay up to date'**
  String get stayUpToDate;

  /// No description provided for @alertsEnabledBody.
  ///
  /// In en, this message translates to:
  /// **'Alerts for new posts and calendar events are enabled for this account on this device.'**
  String get alertsEnabledBody;

  /// No description provided for @alertsOffBody.
  ///
  /// In en, this message translates to:
  /// **'Get an alert when someone adds a post or an academic calendar event.'**
  String get alertsOffBody;

  /// No description provided for @updatingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Updating alerts…'**
  String get updatingAlerts;

  /// No description provided for @turnOffAlerts.
  ///
  /// In en, this message translates to:
  /// **'Turn off on this device'**
  String get turnOffAlerts;

  /// No description provided for @enableAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable alerts'**
  String get enableAlerts;

  /// No description provided for @unreadNotification.
  ///
  /// In en, this message translates to:
  /// **'Unread notification'**
  String get unreadNotification;

  /// No description provided for @readNotification.
  ///
  /// In en, this message translates to:
  /// **'Read notification'**
  String get readNotification;

  /// No description provided for @communityPost.
  ///
  /// In en, this message translates to:
  /// **'Community post'**
  String get communityPost;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get opening;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications. Open to retry.'**
  String get notificationsLoadFailed;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get enterEmail;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, you will receive a password reset link.'**
  String get resetLinkSent;

  /// No description provided for @checkInternet.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection.'**
  String get checkInternet;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to process your request. Please try again.'**
  String get requestFailed;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @noCategoryPosts.
  ///
  /// In en, this message translates to:
  /// **'No {category} posts yet'**
  String noCategoryPosts(String category);

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String agoMinutes(int n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String agoHours(int n);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String agoDays(int n);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on {date}'**
  String dueOn(String date);

  /// No description provided for @visitSchoolWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit {name} website'**
  String visitSchoolWebsite(String name);

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String unreadCount(int count);

  /// No description provided for @notificationsUnreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications: {count} unread recent updates'**
  String notificationsUnreadLabel(int count);

  /// No description provided for @saveOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Save opportunity'**
  String get saveOpportunity;

  /// No description provided for @unsaveOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get unsaveOpportunity;

  /// No description provided for @removedFromSavedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get removedFromSavedOpportunities;

  /// No description provided for @savedWithReminder.
  ///
  /// In en, this message translates to:
  /// **'Saved. You\'ll get a reminder 7 days and 1 day before the deadline.'**
  String get savedWithReminder;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your saved list. Try again.'**
  String get saveFailed;

  /// No description provided for @opportunityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This opportunity is no longer available.'**
  String get opportunityUnavailable;

  /// No description provided for @opportunityOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this opportunity. Check your connection and try again.'**
  String get opportunityOpenFailed;

  /// No description provided for @savedAlertsOff.
  ///
  /// In en, this message translates to:
  /// **'Saved. Deadline reminders need alerts turned on for this device.'**
  String get savedAlertsOff;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @sortForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get sortForYou;

  /// No description provided for @forYouEmptyProfile.
  ///
  /// In en, this message translates to:
  /// **'Add your age and interests to your profile to see the opportunities that fit you first.'**
  String get forYouEmptyProfile;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @usageStats.
  ///
  /// In en, this message translates to:
  /// **'Usage stats'**
  String get usageStats;

  /// No description provided for @loadStatsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the stats. Check your connection and try again.'**
  String get loadStatsFailed;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @statViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get statViews;

  /// No description provided for @statSaves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get statSaves;

  /// No description provided for @statShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get statShares;

  /// No description provided for @topOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Top opportunities'**
  String get topOpportunities;

  /// No description provided for @noStatsYet.
  ///
  /// In en, this message translates to:
  /// **'No activity in this period yet.'**
  String get noStatsYet;

  /// No description provided for @statsUpdatedDaily.
  ///
  /// In en, this message translates to:
  /// **'Each student counts once per opportunity per day. Stats update once a day, so today\'s activity appears tomorrow.'**
  String get statsUpdatedDaily;

  /// No description provided for @reviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get reviewQueue;

  /// No description provided for @noPendingOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review. New drafts from your sources arrive every morning.'**
  String get noPendingOpportunities;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @reviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update this draft. Check your connection and try again.'**
  String get reviewFailed;

  /// No description provided for @needTitleCategory.
  ///
  /// In en, this message translates to:
  /// **'Add a title and a category before approving.'**
  String get needTitleCategory;

  /// No description provided for @titleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleField;

  /// No description provided for @fromSource.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String fromSource(String name);

  /// No description provided for @opportunitySources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get opportunitySources;

  /// No description provided for @addSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get addSource;

  /// No description provided for @feedUrl.
  ///
  /// In en, this message translates to:
  /// **'Feed URL'**
  String get feedUrl;

  /// No description provided for @invalidFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a full feed link starting with https://'**
  String get invalidFeedUrl;

  /// No description provided for @sourcesHelp.
  ///
  /// In en, this message translates to:
  /// **'Every morning OpportuNet reads these feeds (RSS, or a WordPress site\'s /feed), drafts new opportunities with AI and puts them in the review queue. Nothing is published without your approval.'**
  String get sourcesHelp;

  /// No description provided for @sourceError.
  ///
  /// In en, this message translates to:
  /// **'Last check failed: {error}'**
  String sourceError(String error);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareFoundOn.
  ///
  /// In en, this message translates to:
  /// **'Found on OpportuNet: {url}'**
  String shareFoundOn(String url);
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
