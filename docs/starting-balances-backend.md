# Starting balances and guest access

Flutter displays 500 coins and Rs 10 for signed-in accounts, and 200 coins and Rs 0 for guests. These opening allowances are separate from leaderboard scores. There is currently no authoritative wallet API integrated; the UI does not issue real credits or track spending.

Backend work needed:
- Initialize each account wallet once with 500 coins and Rs 10, transactionally. Do not add this amount on every login. Decide separately how to migrate existing accounts.
- Return authoritative balances through a documented authenticated API, including updates after spending or rewards, so Flutter can replace its opening allowance provider.
- Enforce authenticated access to custom-room creation/joining and all friend operations. Flutter now blocks guests with a signup prompt, but server enforcement must be independent of the UI.

Guest allowance: 200 coins, Rs 0; ordinary guest play stays available.
