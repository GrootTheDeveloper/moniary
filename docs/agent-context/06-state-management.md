# State Management

**Confidence / Verification Status**: `VERIFIED`

## Framework
- **Package**: `flutter_riverpod`

## Patterns Used
- **`Provider`**: Used for read-only dependencies like Repositories, Supabase Client, and GoRouter.
- **`Notifier` / `AutoDisposeNotifier`**: Used in the `application` layer for feature controllers. 
- **`AsyncNotifier` / `AutoDisposeAsyncNotifier`**: Used for fetching asynchronous data (e.g., list of transactions).

## Common Conventions
- Providers are usually named `<Name>Provider` (e.g., `transactionRepositoryProvider`).
- Controllers are usually named `<Name>Controller` (e.g., `AuthController`, `TransactionComposerController`).
- State mutations are done by calling methods on the controller (e.g., `ref.read(authControllerProvider.notifier).login()`).

## Loading & Error Handling
Controllers updating states typically use `AsyncValue.loading()`, `AsyncValue.data()`, and `AsyncValue.error()`. The UI maps these using `when()` (e.g., `state.when(data: ..., loading: ..., error: ...)`).
