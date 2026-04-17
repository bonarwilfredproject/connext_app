# connext_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google Places autocomplete

Event location input supports Google Places autocomplete. Configure the API key in one of these ways:

1. Pass `GOOGLE_PLACES_API_KEY` with `--dart-define` when running the app.
2. Store the key in Firestore at `app_config/google_maps` using a field named `places_api_key`.

If no key is configured, the location field still works as a normal text field and Google Maps preview/open actions continue to use the typed address.
