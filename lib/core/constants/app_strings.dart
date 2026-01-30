class AppStrings {
  static const appName = 'Finger Licking';
  static const restaurantName = 'Finger Licking Restaurant';
  static const restaurantLocation = 'Bekwai';

  static const serviceAreaTitle = 'Bekwai deliveries only';
  static const serviceAreaBody =
      'We currently deliver within Bekwai. Add a landmark and we’ll confirm fast.';

  static const welcomeHeadline = 'Warm food, right on time.';
  static const welcomeSubhead =
      'From Finger Licking Restaurant in Bekwai — packed fresh and delivered with care.';

  static const browseAsGuest = 'Continue as guest';
  static const browseMenu = 'Browse menu';
  static const logIn = 'Log in';
  static const signUp = 'Create account';

  static const email = 'Email';
  static const password = 'Password';
  static const name = 'Name';
  static const phone = 'Phone number';
  static const landmarkHint = 'e.g. “Opposite St. Mary’s School”';
  static const profileSetupTitle = 'Finish your profile';
  static const defaultDeliveryNote = 'Default delivery note';

  static const cart = 'Cart';
  static const checkout = 'Checkout';
  static const home = 'Home';
  static const orders = 'Orders';
  static const inbox = 'Inbox';
  static const account = 'Account';

  static const search = 'Search';
  static const searchHint = 'Search jollof, waakye, banku…';
  static const searching = 'Searching…';
  static const whatAreYouCravingTitle = 'What are you craving?';
  static const whatAreYouCravingBody = 'Start typing and we’ll suggest dishes from the menu.';
  static const searchFailedTitle = 'Search failed';
  static String noResultsFor(String query) => 'No results for “$query”';
  static const noResultsBody = 'Try a shorter search, or browse categories.';

  static const categoriesTitle = 'Categories';
  static const popularTodayTitle = 'Popular today';
  static const handpicked = 'Handpicked';
  static const loading = 'Loading…';
  static const soldOut = 'Sold out';

  static const reorderFromHistory = 'Reorder from history';
  static const reorderFromHistoryBody = 'Your recent orders will show here for a one‑tap repeat.';

  static const menuTitle = 'Menu';
  static const couldntLoadHomeTitle = 'Couldn’t load home';
  static const couldntLoadMenuTitle = 'Couldn’t load menu';
  static const couldntLoadItemTitle = 'Couldn’t load item';
  static const nothingHereTitle = 'Nothing here yet';
  static const nothingHereBody = 'This category will be back soon — try another one.';

  static const chooseSize = 'Choose size';
  static const extras = 'Extras';
  static const anyNotes = 'Any notes?';
  static const notesHint = 'e.g. “No onions”, “Extra pepper”, “Cutlery please”';
  static const free = 'Free';
  static const frequentlyBoughtTogether = 'Frequently bought together';

  static const spiceMild = 'Mild';
  static const spicePepper = 'Pepper';
  static const spiceHot = 'Hot';
  static const spiceExtraHot = 'Extra hot';

  static const categoryHintDrinks = 'Chilled & fresh';
  static const categoryHintGrills = 'Charcoal‑kissed';
  static const categoryHintSides = 'Small but mighty';
  static const categoryHintRice = 'Smoky favourites';
  static const categoryHintDefault = 'Chef picks';

  static const promoOffYourNextOrder = 'off your next order';
  static const promoApplyAtCheckout = 'Apply at checkout';
  static const promoBekwaiOnly = 'Bekwai only';
  static String promoPercentHeadline(String percent) => '$percent% $promoOffYourNextOrder';
  static String promoFixedHeadline(String amount) => '$amount $promoOffYourNextOrder';
  static String promoSubheadNoMin() => '$promoApplyAtCheckout • $promoBekwaiOnly';
  static String promoSubheadWithMin(String min) => 'Orders from $min • $promoApplyAtCheckout';

  static const somethingWentWrong = 'Something went wrong';
  static const tryAgain = 'Try again';
  static const continueText = 'Continue';
  static const add = 'Add';
  static const cartComingSoon = 'Cart is coming next — finishing checkout flow.';

  static String withPriceDelta({required String label, required String delta}) =>
      '$label (+$delta)';

  static const supabaseMissingTitle = 'Connect Supabase to continue';
  static const supabaseMissingBody =
      'Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` via --dart-define to run the app.';
}
